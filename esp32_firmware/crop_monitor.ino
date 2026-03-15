/*
 * AgroSmart ESP8266 Firmware v4.0 (Memory-Optimized)
 * 
 * Single FirebaseData object + polling (no stream).
 * Saves ~10KB RAM vs stream approach.
 *
 * Paths:
 *   Live:     /users/{USER_ID}/field/live
 *   Settings: /users/{USER_ID}/field/settings
 *   History:  /users/{USER_ID}/field/history/{yyyy-mm}/days/{dd-mm-yyyy}/records/{hh:mm}
 *   DailyAvg: /users/{USER_ID}/field/history/{yyyy-mm}/days/{dd-mm-yyyy}/dailyAvg
 *   Alerts:   /users/{USER_ID}/field/alerts
 *
 * Pump control:
 *   App writes → /live/pumpCommand   (ESP reads)
 *   ESP writes → /live/pumpStatus    (App reads for display)
 */

#include <ESP8266WiFi.h>
#include <FirebaseESP8266.h>
#include <DHT.h>
#include <time.h>

// ── CONFIG ──
char ssid[] = "CITAR-NW-BH";
char password[] = "CIT@R@98";

#define FIREBASE_HOST "fir-42101-default-rtdb.firebaseio.com"
#define FIREBASE_AUTH "svXqzvzdtZSqz8IaqBADw3POATaJLcPiCC5yFwrn"
#define USER_ID       "default_user"
#define DEVICE_ID     "field-001"

#define NTP_SERVER    "pool.ntp.org"
#define GMT_OFFSET    19800  // IST UTC+5:30

// ── PINS ──
#define DHTPIN    D4
#define DHTTYPE   DHT22
#define SOIL_PIN  A0
#define PUMP_PIN  D1

// ── INTERVALS ──
#define LIVE_INTERVAL      10000UL   // 10s  - sensor + poll
#define HISTORY_INTERVAL   300000UL  // 5min - graph data
#define DAILY_AVG_INTERVAL 900000UL  // 15min
#define PUMP_COOLDOWN      30000UL   // 30s min between toggles
#define SETTINGS_INTERVAL  15000UL   // 15s - poll settings

// ── SOIL CALIBRATION ──
#define SOIL_RAW_DRY  1024
#define SOIL_RAW_WET  200

// ── OBJECTS (single FirebaseData = single SSL connection) ──
DHT dht(DHTPIN, DHTTYPE);
FirebaseData fbdo;
FirebaseConfig fbConfig;
FirebaseAuth fbAuth;

// ── TIMING ──
unsigned long lastLive     = 0;
unsigned long lastHistory  = 0;
unsigned long lastDailyAvg = 0;
unsigned long lastSettings = 0;
unsigned long lastPumpToggle = 0;

// ── SETTINGS (from Firebase) ──
bool  autoIrrigation = false;
float minMoisture    = 35.0;
float maxMoisture    = 75.0;
float maxTemperature = 32.0;

// ── SENSOR VALUES ──
float currentTemp     = 0;
float currentHumidity = 0;
int   currentMoisture = 0;

// ── PUMP STATE ──
bool isPumpRunning        = false;
bool manualPumpCmd        = false;
bool manualOverrideActive = false;
unsigned long manualOverrideTime = 0;
#define MANUAL_OVERRIDE_WINDOW 60000UL  // 60s

// ── MISC ──
int  heartbeat    = 0;
bool ntpSynced    = false;
float dailyTempSum = 0, dailyHumSum = 0, dailyMoistSum = 0;
int   dailyCount   = 0;
int   currentDay   = -1;

// ── HELPERS ──

String basePath() {
  return String(F("/users/")) + USER_ID + F("/field");
}

bool isNtpValid() {
  return time(nullptr) > 1577836800;
}

String getMonthKey() {
  time_t now = time(nullptr);
  struct tm* t = localtime(&now);
  char buf[8];
  snprintf(buf, sizeof(buf), "%04d-%02d", t->tm_year + 1900, t->tm_mon + 1);
  return String(buf);
}

String getDateKey() {
  time_t now = time(nullptr);
  struct tm* t = localtime(&now);
  char buf[12];
  snprintf(buf, sizeof(buf), "%02d-%02d-%04d", t->tm_mday, t->tm_mon + 1, t->tm_year + 1900);
  return String(buf);
}

String getTimeKey() {
  time_t now = time(nullptr);
  struct tm* t = localtime(&now);
  char buf[6];
  snprintf(buf, sizeof(buf), "%02d:%02d", t->tm_hour, t->tm_min);
  return String(buf);
}

int getDayOfMonth() {
  time_t now = time(nullptr);
  return localtime(&now)->tm_mday;
}

unsigned long getEpoch() {
  return (unsigned long)time(nullptr);
}

// ══════════════════════════════════════
// SETUP
// ══════════════════════════════════════

void setup() {
  Serial.begin(115200);
  delay(500);
  Serial.println(F("\n[AgroSmart v4.0 - Memory Optimized]"));

  // Pins
  pinMode(PUMP_PIN, OUTPUT);
  digitalWrite(PUMP_PIN, HIGH);  // OFF (active LOW)
  isPumpRunning = false;

  // DHT
  dht.begin();
  delay(2000);

  // WiFi
  WiFi.mode(WIFI_STA);
  WiFi.setAutoReconnect(true);
  WiFi.persistent(true);
  WiFi.begin(ssid, password);
  Serial.print(F("WiFi"));
  int tries = 0;
  while (WiFi.status() != WL_CONNECTED && tries < 40) {
    delay(500);
    Serial.print('.');
    tries++;
  }
  if (WiFi.status() == WL_CONNECTED) {
    Serial.print(F(" OK IP:"));
    Serial.println(WiFi.localIP());
  } else {
    Serial.println(F(" FAIL"));
  }

  // NTP
  configTime(GMT_OFFSET, 0, NTP_SERVER);
  tries = 0;
  while (!isNtpValid() && tries < 20) { delay(500); tries++; }
  ntpSynced = isNtpValid();
  Serial.printf("NTP: %s\n", ntpSynced ? "OK" : "FAIL");

  // Firebase - single connection
  fbConfig.database_url = FIREBASE_HOST;
  fbConfig.signer.tokens.legacy_token = FIREBASE_AUTH;
  Firebase.begin(&fbConfig, &fbAuth);
  Firebase.reconnectWiFi(true);
  fbdo.setBSSLBufferSize(1024, 1024);

  Serial.printf("Heap: %d\n", ESP.getFreeHeap());

  // Fetch initial state
  fetchSettings();
  fetchPumpCommand();

  // Sync actual relay state to Firebase
  String sp = basePath() + F("/live/pumpStatus");
  Firebase.setBool(fbdo, sp, isPumpRunning);

  Serial.printf("Ready! Auto:%s Min:%.0f Max:%.0f\n",
    autoIrrigation ? "ON" : "OFF", minMoisture, maxMoisture);
}

// ══════════════════════════════════════
// LOOP
// ══════════════════════════════════════

void loop() {
  // WiFi reconnect
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println(F("WiFi lost, reconnecting..."));
    WiFi.begin(ssid, password);
    delay(5000);
    return;
  }

  // Read sensors
  readSensors();

  // Apply pump logic
  applyPumpLogic();

  unsigned long now = millis();

  // Poll pumpCommand + send live data (every 10s)
  if (now - lastLive >= LIVE_INTERVAL) {
    fetchPumpCommand();   // Check if app sent a command
    updateLiveData();
    lastLive = now;
  }

  // Poll settings (every 15s)
  if (now - lastSettings >= SETTINGS_INTERVAL) {
    fetchSettings();
    lastSettings = now;
  }

  // History (every 5min)
  if (now - lastHistory >= HISTORY_INTERVAL || lastHistory == 0) {
    uploadHistory();
    lastHistory = now;
  }

  // Daily average (every 15min)
  if (now - lastDailyAvg >= DAILY_AVG_INTERVAL || lastDailyAvg == 0) {
    updateDailyAvg();
    lastDailyAvg = now;
  }

  delay(200);
}

// ══════════════════════════════════════
// SENSORS
// ══════════════════════════════════════

void readSensors() {
  int raw = analogRead(SOIL_PIN);
  currentMoisture = constrain(map(raw, SOIL_RAW_DRY, SOIL_RAW_WET, 0, 100), 0, 100);

  float t = dht.readTemperature();
  float h = dht.readHumidity();
  if (!isnan(t)) currentTemp = t;
  if (!isnan(h)) currentHumidity = h;
}

// ══════════════════════════════════════
// PUMP LOGIC
// ══════════════════════════════════════

void applyPumpLogic() {
  if (autoIrrigation) {
    unsigned long now = millis();

    // Manual override window (app command during auto mode)
    if (manualOverrideActive) {
      if (now - manualOverrideTime < MANUAL_OVERRIDE_WINDOW) {
        if (manualPumpCmd != isPumpRunning) {
          setPumpState(manualPumpCmd);
        }
        return;
      }
      manualOverrideActive = false;
    }

    // Cooldown
    if (now - lastPumpToggle < PUMP_COOLDOWN && lastPumpToggle != 0) return;

    // Auto ON: soil too dry
    if (currentMoisture < (int)minMoisture && !isPumpRunning) {
      setPumpState(true);
      lastPumpToggle = now;
      pushAlert("lowMoisture",
        "Auto-irrigation activated. Soil moisture below threshold.",
        (float)currentMoisture, minMoisture);
    }
    // Auto OFF: soil wet enough
    else if (currentMoisture >= (int)maxMoisture && isPumpRunning) {
      setPumpState(false);
      lastPumpToggle = now;
      pushAlert("pumpDeactivated",
        "Auto-irrigation stopped. Soil moisture restored.",
        (float)currentMoisture, maxMoisture);
    }

  } else {
    // Manual mode: follow app command
    if (manualPumpCmd != isPumpRunning) {
      setPumpState(manualPumpCmd);
    }
  }
}

void setPumpState(bool turnOn) {
  if (isPumpRunning == turnOn) return;
  isPumpRunning = turnOn;
  digitalWrite(PUMP_PIN, turnOn ? LOW : HIGH);

  Serial.printf("PUMP: %s\n", turnOn ? "ON" : "OFF");

  // Write to pumpStatus (ESP owns this, app reads for display)
  String p = basePath() + F("/live/pumpStatus");
  if (!Firebase.setBool(fbdo, p, turnOn)) {
    Serial.println(F("pumpStatus sync fail"));
  }
}

// ══════════════════════════════════════
// FIREBASE POLLING (replaces stream)
// ══════════════════════════════════════

void fetchPumpCommand() {
  String p = basePath() + F("/live/pumpCommand");
  if (Firebase.getBool(fbdo, p)) {
    bool cmd = fbdo.boolData();
    if (cmd != manualPumpCmd) {
      manualPumpCmd = cmd;
      Serial.printf("PumpCmd: %s\n", cmd ? "ON" : "OFF");

      if (!autoIrrigation) {
        setPumpState(manualPumpCmd);
      } else {
        // In auto mode: activate manual override
        manualOverrideActive = true;
        manualOverrideTime = millis();
        setPumpState(manualPumpCmd);
      }
      lastPumpToggle = millis();
    }
  }
  // If key doesn't exist yet, that's fine — default is false
}

void fetchSettings() {
  String p = basePath() + F("/settings");
  if (Firebase.getJSON(fbdo, p)) {
    FirebaseJson &json = fbdo.jsonObject();
    FirebaseJsonData jd;

    bool prevAuto = autoIrrigation;

    json.get(jd, "autoIrrigation");
    if (jd.success) autoIrrigation = jd.boolValue;

    json.get(jd, "minMoisture");
    if (jd.success) minMoisture = jd.floatValue;

    json.get(jd, "maxMoisture");
    if (jd.success) maxMoisture = jd.floatValue;

    json.get(jd, "maxTemperature");
    if (jd.success) maxTemperature = jd.floatValue;

    // If auto mode changed, reset override
    if (prevAuto != autoIrrigation) {
      manualOverrideActive = false;
      Serial.printf("Auto: %s\n", autoIrrigation ? "ON" : "OFF");
    }
  }
}

// ══════════════════════════════════════
// LIVE DATA (every 10s)
// ══════════════════════════════════════

void updateLiveData() {
  if (isnan(currentTemp) || isnan(currentHumidity)) return;

  heartbeat++;

  FirebaseJson json;
  json.set("temperature", currentTemp);
  json.set("humidity", currentHumidity);
  json.set("soilMoisture", currentMoisture);
  json.set("heartbeat", heartbeat);
  json.set("timestamp/.sv", "timestamp");
  json.set("deviceId", DEVICE_ID);
  json.set("dht22/temperature", currentTemp);
  json.set("dht22/humidity", currentHumidity);

  String p = basePath() + F("/live");
  if (Firebase.updateNode(fbdo, p, json)) {
    Serial.printf("T:%.1f H:%.1f M:%d%% P:%s HB:%d H:%d\n",
      currentTemp, currentHumidity, currentMoisture,
      isPumpRunning ? "ON" : "OFF", heartbeat, ESP.getFreeHeap());
  } else {
    Serial.println(F("Live update fail"));
  }

  // Accumulate for daily avg
  dailyTempSum += currentTemp;
  dailyHumSum += currentHumidity;
  dailyMoistSum += currentMoisture;
  dailyCount++;

  // Reset on day change
  if (ntpSynced) {
    int today = getDayOfMonth();
    if (currentDay != -1 && currentDay != today) {
      dailyTempSum = currentTemp;
      dailyHumSum = currentHumidity;
      dailyMoistSum = currentMoisture;
      dailyCount = 1;
    }
    currentDay = today;
  }
}

// ══════════════════════════════════════
// HISTORY (every 5min)
// ══════════════════════════════════════

void uploadHistory() {
  if (!ntpSynced || isnan(currentTemp) || isnan(currentHumidity)) return;

  FirebaseJson json;
  json.set("dht22/temperature", currentTemp);
  json.set("dht22/humidity", currentHumidity);
  json.set("soilMoisture", currentMoisture);

  String p = basePath() + "/history/" + getMonthKey()
    + "/days/" + getDateKey() + "/records/" + getTimeKey();

  if (Firebase.setJSON(fbdo, p, json)) {
    Serial.printf("HIST: %s %s\n", getDateKey().c_str(), getTimeKey().c_str());
  }
}

// ══════════════════════════════════════
// DAILY AVERAGE (every 15min)
// ══════════════════════════════════════

void updateDailyAvg() {
  if (!ntpSynced || dailyCount == 0) return;

  float aT = ((int)((dailyTempSum / dailyCount) * 100)) / 100.0;
  float aH = ((int)((dailyHumSum / dailyCount) * 100)) / 100.0;
  float aM = ((int)((dailyMoistSum / dailyCount) * 100)) / 100.0;

  String p = basePath() + "/history/" + getMonthKey()
    + "/days/" + getDateKey() + "/dailyAvg";

  FirebaseJson json;
  json.set("temperature", aT);
  json.set("humidity", aH);
  json.set("soilMoisture", aM);

  if (Firebase.setJSON(fbdo, p, json)) {
    Serial.printf("AVG(%d): T%.1f H%.1f M%.1f\n", dailyCount, aT, aH, aM);
  }
}

// ══════════════════════════════════════
// ALERTS
// ══════════════════════════════════════

void pushAlert(const char* type, const char* msg, float val, float thresh) {
  if (!ntpSynced) return;

  String id = "alert-" + String(getEpoch()) + String(random(100, 999));
  String p = basePath() + "/alerts/" + id;

  FirebaseJson json;
  json.set("type", type);
  json.set("message", msg);
  json.set("value", val);
  json.set("threshold", thresh);
  json.set("ts/.sv", "timestamp");
  json.set("deviceId", DEVICE_ID);
  json.set("source", "ESP8266");

  Firebase.setJSON(fbdo, p, json);
}
