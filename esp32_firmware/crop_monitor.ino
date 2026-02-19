/*
 * ESP32 Crop Monitoring System Firmware - AgroSmart
 * 
 * Firebase Project: AgroSmart (fir-42101)
 * 
 * This firmware reads sensor data (DHT22, Soil Moisture) and sends
 * it to Firebase Realtime Database for the Flutter app to consume.
 * 
 * Hardware Connections:
 * - DHT22: Data pin -> GPIO4
 * - Soil Moisture Sensor: Analog -> GPIO34
 * - Relay (Pump Control): GPIO25
 * 
 * Libraries Required (Install via Arduino Library Manager):
 * - Firebase ESP Client by Mobizt
 * - DHT sensor library by Adafruit
 * - Adafruit Unified Sensor
 */

#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include "DHT.h"
#include <addons/TokenHelper.h>
#include <addons/RTDBHelper.h>

// ===========================================
// CONFIGURATION - UPDATE THESE VALUES
// ===========================================

// WiFi credentials - UPDATE THESE
#define WIFI_SSID "VVELAN M"
#define WIFI_PASSWORD "velan123"

// Firebase configuration - AgroSmart Project
#define API_KEY "AIzaSyDummyKeyReplaceMeWithActualKey"  // Get from Firebase Console -> Project Settings -> Web API Key
#define DATABASE_URL "https://fir-42101-default-rtdb.firebaseio.com"  // Your Realtime Database URL

// Device ID - unique for each ESP32/field
// Use one of: field-001, field-002, field-003, field-004
#define DEVICE_ID "field-001"

// ===========================================
// Pin Definitions
// ===========================================

#define DHTPIN 4              // DHT22 data pin
#define DHTTYPE DHT22         // DHT22 sensor type
#define SOIL_MOISTURE_PIN 34  // Soil moisture analog pin
#define RELAY_PIN 25          // Relay control pin for pump
#define LED_PIN 2             // Built-in LED

// ===========================================
// Constants
// ===========================================

#define SAMPLING_INTERVAL 5000    // 5 seconds between readings
#define WIFI_TIMEOUT 20000        // WiFi connection timeout (20 sec)
#define FIREBASE_TIMEOUT 10000    // Firebase operation timeout

// Soil moisture calibration (adjust based on your sensor)
// Capacitive sensor: Lower value = more moisture
#define SOIL_DRY_VALUE 3500       // ADC value when soil is completely dry
#define SOIL_WET_VALUE 1500       // ADC value when soil is fully saturated

// ===========================================
// Global Objects
// ===========================================

DHT dht(DHTPIN, DHTTYPE);
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

// ===========================================
// State Variables
// ===========================================

unsigned long lastSensorRead = 0;
unsigned long lastFirebaseSync = 0;
unsigned long lastHistoryPush = 0;
#define HISTORY_INTERVAL 300000 // 5 minutes between history points
bool pumpStatus = false;
bool isConnected = false;
bool firebaseReady = false;

// Thresholds from Firebase
float minMoistureThreshold = 35.0;
bool autoIrrigationEnabled = false;
unsigned long lastSettingsFetch = 0;
#define SETTINGS_FETCH_INTERVAL 60000 // Fetch settings every minute

// Sensor data structure
struct SensorData {
  float temperature;
  float humidity;
  float soilMoisture;
  unsigned long timestamp;
  bool valid;
};

// Offline buffer for when network is unavailable
#define BUFFER_SIZE 20
SensorData offlineBuffer[BUFFER_SIZE];
int bufferIndex = 0;
int bufferCount = 0;

// ===========================================
// Function Prototypes
// ===========================================

void connectWiFi();
void initFirebase();
SensorData readSensors();
bool sendDataToFirebase(SensorData data, bool pushHistory);
void syncOfflineBuffer();
void checkPumpCommand();
void fetchSettings();
void controlPump(bool state);
float mapSoilMoisture(int adcValue);
void storeInBuffer(SensorData data);
void blinkLED(int times, int delayMs);

// ===========================================
// Setup
// ===========================================

void setup() {
  Serial.begin(115200);
  delay(1000);
  
  Serial.println("\n╔══════════════════════════════════════════╗");
  Serial.println("║   ESP32 Crop Monitoring System           ║");
  Serial.println("║   AgroSmart - Firebase Project           ║");
  Serial.println("╚══════════════════════════════════════════╝\n");
  
  Serial.printf("Device ID: %s\n", DEVICE_ID);
  Serial.println();
  
  // Initialize pins
  pinMode(LED_PIN, OUTPUT);
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, LOW);  // Pump off by default
  
  // Startup LED indication
  blinkLED(3, 200);
  
  // Initialize DHT sensor
  dht.begin();
  Serial.println("[OK] DHT22 sensor initialized");
  
  // Wait for sensor to stabilize
  delay(2000);
  
  // Connect to WiFi
  connectWiFi();
  
  // Initialize Firebase
  if (isConnected) {
    initFirebase();
  }
  
  Serial.println("\n[OK] System ready! Starting monitoring...");
  Serial.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");
}

// ===========================================
// Main Loop
// ===========================================

void loop() {
  unsigned long currentMillis = millis();
  
  // Heartbeat LED - blink every 2 seconds when running
  static unsigned long lastBlink = 0;
  if (currentMillis - lastBlink >= 2000) {
    lastBlink = currentMillis;
    digitalWrite(LED_PIN, HIGH);
    delay(50);
    digitalWrite(LED_PIN, LOW);
  }
  
  // Check WiFi connection
  if (WiFi.status() != WL_CONNECTED) {
    isConnected = false;
    Serial.println("[WARN] WiFi disconnected, reconnecting...");
    connectWiFi();
    if (isConnected && !firebaseReady) {
      initFirebase();
    }
  }
  
  // Read sensors at sampling interval
  if (currentMillis - lastSensorRead >= SAMPLING_INTERVAL) {
    lastSensorRead = currentMillis;
    
    SensorData data = readSensors();
    
      if (data.valid) {
        // Print sensor data
        Serial.println("┌─────────────────────────────────────────┐");
        Serial.printf("│ Temperature:    %6.1f °C               │\n", data.temperature);
        Serial.printf("│ Humidity:       %6.1f %%               │\n", data.humidity);
        Serial.printf("│ Soil Moisture:  %6.1f %%               │\n", data.soilMoisture);
        Serial.printf("│ Pump Status:    %s                    │\n", pumpStatus ? "ON " : "OFF");
        Serial.println("└─────────────────────────────────────────┘");
        
        // Auto Irrigation Logic
        if (autoIrrigationEnabled) {
          if (data.soilMoisture < minMoistureThreshold && !pumpStatus) {
            Serial.println("[AUTO] Soil dry! Activating pump...");
            controlPump(true);
          } else if (data.soilMoisture >= minMoistureThreshold + 10.0 && pumpStatus) {
            // Stop pump when it's 10% above threshold (hysteresis)
            Serial.println("[AUTO] Soil moisture restored. Deactivating pump...");
            controlPump(false);
          }
        }

        if (isConnected && firebaseReady && Firebase.ready()) {
        // Only push to history at history interval
        bool shouldPushHistory = false;
        if (currentMillis - lastHistoryPush >= HISTORY_INTERVAL || lastHistoryPush == 0) {
          lastHistoryPush = currentMillis;
          shouldPushHistory = true;
          Serial.println("[INFO] Detailed history record will be pushed");
        }

        // Send data to Firebase
        if (sendDataToFirebase(data, shouldPushHistory)) {
          if (shouldPushHistory) Serial.println("[OK] Data + History sent to Firebase");
          else Serial.println("[OK] Real-time data updated");
          
          // Sync buffered data if any
          syncOfflineBuffer();
        } else {
          // Store in offline buffer
          storeInBuffer(data);
          Serial.println("[WARN] Firebase failed, data buffered");
        }
        
        // Check for pump commands from app
        checkPumpCommand();
      } else {
        // Store in offline buffer
        storeInBuffer(data);
        Serial.printf("[OFFLINE] Data buffered (%d/%d)\n", bufferCount, BUFFER_SIZE);
      }
      
      Serial.println();
    } else {
      Serial.println("[ERROR] Failed to read sensors!");
    }
  }
  
  // Fetch settings from Firebase periodically
  if (firebaseReady && (currentMillis - lastSettingsFetch >= SETTINGS_FETCH_INTERVAL || lastSettingsFetch == 0)) {
    lastSettingsFetch = currentMillis;
    fetchSettings();
  }
  
  delay(100);
}

// ===========================================
// WiFi Connection
// ===========================================

void connectWiFi() {
  Serial.print("[...] Connecting to WiFi: ");
  Serial.println(WIFI_SSID);
  
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  
  unsigned long startAttempt = millis();
  int dots = 0;
  
  while (WiFi.status() != WL_CONNECTED && 
         millis() - startAttempt < WIFI_TIMEOUT) {
    delay(500);
    Serial.print(".");
    dots++;
    if (dots % 20 == 0) Serial.println();
    
    // Blink LED while connecting
    digitalWrite(LED_PIN, !digitalRead(LED_PIN));
  }
  
  digitalWrite(LED_PIN, LOW);
  
  if (WiFi.status() == WL_CONNECTED) {
    isConnected = true;
    Serial.println();
    Serial.println("[OK] WiFi connected!");
    Serial.print("     IP Address: ");
    Serial.println(WiFi.localIP());
    Serial.print("     Signal Strength: ");
    Serial.print(WiFi.RSSI());
    Serial.println(" dBm");
  } else {
    isConnected = false;
    Serial.println();
    Serial.println("[FAIL] WiFi connection failed!");
    Serial.println("       Check SSID and password");
  }
}

// ===========================================
// Firebase Initialization
// ===========================================

void initFirebase() {
  Serial.println("[...] Initializing Firebase...");
  
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;
  
  // Anonymous authentication (no email/password required)
  auth.user.email = "";
  auth.user.password = "";
  
  config.token_status_callback = tokenStatusCallback;
  
  // Initialize Firebase
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
  
  // Configure buffer sizes
  fbdo.setBSSLBufferSize(4096, 1024);
  fbdo.setResponseSize(2048);
  
  // Wait for Firebase to be ready
  unsigned long startWait = millis();
  while (!Firebase.ready() && millis() - startWait < 10000) {
    delay(100);
  }
  
  if (Firebase.ready()) {
    firebaseReady = true;
    Serial.println("[OK] Firebase connected!");
    Serial.print("     Database: ");
    Serial.println(DATABASE_URL);
    
    // Set initial device info
    Firebase.RTDB.setString(&fbdo, 
      String("/devices/") + DEVICE_ID + "/name", 
      "ESP32 Sensor Node");
    Firebase.RTDB.setBool(&fbdo, 
      String("/devices/") + DEVICE_ID + "/online", 
      true);
  } else {
    firebaseReady = false;
    Serial.println("[FAIL] Firebase connection failed!");
    Serial.println("       Check API_KEY and DATABASE_URL");
  }
}

// ===========================================
// Sensor Reading
// ===========================================

SensorData readSensors() {
  SensorData data;
  data.valid = false;
  data.timestamp = millis();
  
  // Read DHT22 - try up to 3 times
  for (int attempt = 0; attempt < 3; attempt++) {
    float t = dht.readTemperature();
    float h = dht.readHumidity();
    
    if (!isnan(t) && !isnan(h)) {
      data.temperature = t;
      data.humidity = h;
      break;
    }
    delay(100);
  }
  
  if (isnan(data.temperature) || isnan(data.humidity)) {
    Serial.println("[ERROR] DHT22 read failed!");
    return data;
  }
  
  // Read soil moisture (average of 5 readings for stability)
  long soilSum = 0;
  for (int i = 0; i < 5; i++) {
    soilSum += analogRead(SOIL_MOISTURE_PIN);
    delay(10);
  }
  int soilRaw = soilSum / 5;
  data.soilMoisture = mapSoilMoisture(soilRaw);
  
  data.valid = true;
  return data;
}

// ===========================================
// Soil Moisture Mapping
// ===========================================

float mapSoilMoisture(int adcValue) {
  // Map ADC value to percentage (0-100)
  // Capacitive sensor: Lower ADC = more moisture
  float moisture = (float)(SOIL_DRY_VALUE - adcValue) / 
                   (float)(SOIL_DRY_VALUE - SOIL_WET_VALUE) * 100.0;
  
  // Clamp to 0-100 range
  if (moisture < 0) moisture = 0;
  if (moisture > 100) moisture = 100;
  
  return moisture;
}

// ===========================================
// Firebase Data Upload
// ===========================================

bool sendDataToFirebase(SensorData data, bool pushHistory) {
  if (!Firebase.ready()) return false;
  
  // Path matching the user's database structure: AgroSmart
  String basePath = "/AgroSmart";
  
  // 1. Send DHT22 data (Humidity and Temperature)
  FirebaseJson dhtJson;
  dhtJson.set("Humidity", data.humidity);
  dhtJson.set("Temperature", data.temperature);
  
  if (!Firebase.RTDB.setJSON(&fbdo, basePath + "/DHT22", &dhtJson)) {
    Serial.print("[ERROR] DHT22 update failed: ");
    Serial.println(fbdo.errorReason());
    return false;
  }
  
  // 2. Send Soil Moisture
  if (!Firebase.RTDB.setFloat(&fbdo, basePath + "/SoilMoisture", data.soilMoisture)) {
    Serial.print("[ERROR] Soil Moisture update failed: ");
    Serial.println(fbdo.errorReason());
    return false;
  }
  
  // 3. Send Pump Status
  if (!Firebase.RTDB.setBool(&fbdo, basePath + "/PumpStatus", pumpStatus)) {
    Serial.print("[ERROR] Pump Status update failed: ");
    Serial.println(fbdo.errorReason());
    return false;
  }

  // 4. Update additional fields for the app (historical data)
  FirebaseJson appJson;
  appJson.set("temperature", data.temperature);
  appJson.set("humidity", data.humidity);
  appJson.set("soilMoisture", data.soilMoisture);
  appJson.set("pumpStatus", pumpStatus);
  appJson.set("timestamp/.sv", "timestamp");
  appJson.set("deviceId", DEVICE_ID);
  
  // Maintain backward compatibility with the devices/DEVICE_ID/latest path if needed by other app parts
  String devicePath = "/devices/" + String(DEVICE_ID);
  Firebase.RTDB.setJSON(&fbdo, devicePath + "/latest", &appJson);
  
  if (pushHistory) {
    Firebase.RTDB.pushJSON(&fbdo, devicePath + "/history", &appJson);
  }
  
  return true;
}

// ===========================================
// Offline Buffer Management
// ===========================================

void storeInBuffer(SensorData data) {
  if (bufferCount < BUFFER_SIZE) {
    offlineBuffer[bufferIndex] = data;
    bufferIndex = (bufferIndex + 1) % BUFFER_SIZE;
    bufferCount++;
  } else {
    // Buffer full, overwrite oldest
    offlineBuffer[bufferIndex] = data;
    bufferIndex = (bufferIndex + 1) % BUFFER_SIZE;
  }
}

void syncOfflineBuffer() {
  if (bufferCount == 0) return;
  
  Serial.printf("[...] Syncing %d buffered readings...\n", bufferCount);
  
  int synced = 0;
  int startIdx = (bufferIndex - bufferCount + BUFFER_SIZE) % BUFFER_SIZE;
  
  for (int i = 0; i < bufferCount; i++) {
    int idx = (startIdx + i) % BUFFER_SIZE;
    if (sendDataToFirebase(offlineBuffer[idx], true)) { // Buffered data is always history
      synced++;
    } else {
      break;  // Stop on first failure
    }
  }
  
  if (synced > 0) {
    Serial.printf("[OK] Synced %d readings\n", synced);
    bufferCount -= synced;
  }
}

// ===========================================
// Pump Control
// ===========================================

void checkPumpCommand() {
  String path = "/users/default_user/field/PumpStatus"; // Check app's control path
  
  // Also check AgroSmart path for legacy support
  if (!Firebase.RTDB.getBool(&fbdo, path)) {
    path = "/AgroSmart/PumpStatus";
    if (!Firebase.RTDB.getBool(&fbdo, path)) return;
  }
  
  bool newStatus = fbdo.boolData();
  if (newStatus != pumpStatus) {
    controlPump(newStatus);
  }
}

void fetchSettings() {
  if (!Firebase.ready()) return;
  
  String path = "/users/default_user/field/settings";
  Serial.println("[...] Fetching settings from Firebase...");
  
  if (Firebase.RTDB.getJSON(&fbdo, path)) {
    FirebaseJson &json = fbdo.jsonObject();
    FirebaseJsonData jsonData;
    
    json.get(jsonData, "minMoisture");
    if (jsonData.success) minMoistureThreshold = jsonData.floatValue;
    
    json.get(jsonData, "autoIrrigation");
    if (jsonData.success) autoIrrigationEnabled = jsonData.boolValue;
    
    Serial.printf("[OK] Settings: MinMoisture=%.1f%%, AutoIrrigation=%s\n", 
                  minMoistureThreshold, autoIrrigationEnabled ? "ON" : "OFF");
  }
}

void controlPump(bool state) {
  pumpStatus = state;
  digitalWrite(RELAY_PIN, state ? HIGH : LOW);
  
  Serial.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  Serial.printf("     PUMP %s\n", state ? "ACTIVATED 💧" : "DEACTIVATED ⏹️");
  Serial.println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  
  // Log pump action to Firebase
  if (Firebase.ready()) {
    // Update both paths to keep app synced
    Firebase.RTDB.setBool(&fbdo, "/users/default_user/field/PumpStatus", state);
    Firebase.RTDB.setBool(&fbdo, "/AgroSmart/PumpStatus", state);
    
    String path = "/devices/" + String(DEVICE_ID) + "/pumpLog";
    
    FirebaseJson json;
    json.set("action", state ? "ON" : "OFF");
    json.set("timestamp/.sv", "timestamp");
    
    Firebase.RTDB.pushJSON(&fbdo, path, &json);
  }
}

// ===========================================
// Utility Functions
// ===========================================

void blinkLED(int times, int delayMs) {
  for (int i = 0; i < times; i++) {
    digitalWrite(LED_PIN, HIGH);
    delay(delayMs);
    digitalWrite(LED_PIN, LOW);
    delay(delayMs);
  }
}

// ===========================================
// Token Status Callback
// ===========================================

void tokenStatusCallback(token_info_t info) {
  if (info.status == token_status_error) {
    Serial.printf("[ERROR] Token: %s\n", info.error.message.c_str());
  }
}
