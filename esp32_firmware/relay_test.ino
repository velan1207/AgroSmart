/*
 * Simple Relay Test - Upload this to verify your relay wiring
 * Should click ON/OFF every 3 seconds
 */

#define PUMP_PIN D1  // GPIO5

void setup() {
  Serial.begin(115200);
  delay(1000);
  
  pinMode(PUMP_PIN, OUTPUT);
  digitalWrite(PUMP_PIN, HIGH);  // Start OFF (active LOW relay)
  
  Serial.println("Relay test starting...");
  Serial.printf("Using pin D1 = GPIO%d\n", PUMP_PIN);
  Serial.println("You should hear a click every 3 seconds.");
}

void loop() {
  Serial.println(">>> RELAY ON (pin LOW)");
  digitalWrite(PUMP_PIN, LOW);
  delay(3000);

  Serial.println(">>> RELAY OFF (pin HIGH)");
  digitalWrite(PUMP_PIN, HIGH);
  delay(3000);
}
