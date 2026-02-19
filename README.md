# 🌾 CropWatch - IoT-Based Crop Stress Monitoring System

A comprehensive 24×7 IoT-based crop stress monitoring and smart irrigation system built with Flutter. This application provides real-time visualization of soil moisture, temperature, and humidity data from ESP32 sensors, with intelligent alerts and manual pump control.

![Flutter](https://img.shields.io/badge/Flutter-3.8+-02569B?style=flat&logo=flutter)
![Firebase](https://img.shields.io/badge/Firebase-RTDB-FFCA28?style=flat&logo=firebase)
![ESP32](https://img.shields.io/badge/ESP32-IoT-000000?style=flat&logo=espressif)
![License](https://img.shields.io/badge/License-MIT-green.svg)

## ✨ Features

### 📊 Real-Time Monitoring
- Live sensor data updates (temperature, humidity, soil moisture)
- Automatic data refresh every 3-5 seconds
- Visual crop stress level indicators
- Multi-field support with unique device IDs

### 📈 Historical Analytics
- Daily/Weekly/Monthly data visualization
- Line and bar charts for trend analysis
- Min/Max/Average statistics
- Exportable reports

### 🔔 Smart Alerts
- Configurable threshold alerts
- Critical, warning, and info severity levels
- Push notifications for urgent issues
- Alert history and management

### 💧 Irrigation Control
- Manual pump ON/OFF control
- Real-time pump status monitoring
- Auto-irrigation option (configurable)
- Pump action logging

### 🌐 Offline Support
- Data buffering when offline
- Automatic sync when connection returns
- Local storage for preferences

### 🎨 Beautiful UI
- Modern Material Design 3
- Dark and light themes
- Smooth animations
- Farmer-friendly interface

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        HARDWARE LAYER                           │
├─────────────────────────────────────────────────────────────────┤
│  ESP32 + DHT22 + Soil Moisture Sensor + Relay (Pump)           │
└──────────────────────────┬──────────────────────────────────────┘
                           │ WiFi
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                         CLOUD LAYER                             │
├─────────────────────────────────────────────────────────────────┤
│               Firebase Realtime Database                         │
│  ├── devices/                                                    │
│  │   └── field-001/                                             │
│  │       ├── latest/     (current sensor readings)              │
│  │       ├── history/    (historical data)                      │
│  │       ├── pumpStatus  (pump control flag)                    │
│  │       └── settings/   (configuration)                        │
└──────────────────────────┬──────────────────────────────────────┘
                           │ HTTPS
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                      APPLICATION LAYER                          │
├─────────────────────────────────────────────────────────────────┤
│                    Flutter Mobile App                            │
│  ├── Real-time visualization                                    │
│  ├── Historical charts                                          │
│  ├── Alert management                                           │
│  └── Pump control                                               │
└─────────────────────────────────────────────────────────────────┘
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.8+
- Android Studio / VS Code
- Firebase account
- ESP32 development board (for hardware)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/crop_monitor.git
   cd crop_monitor
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase** (for production)
   - Create a Firebase project
   - Enable Realtime Database
   - Download `google-services.json` (Android)
   - Place in `android/app/`
   - Update Firebase rules (see below)

4. **Run the app**
   ```bash
   flutter run
   ```

### Firebase Database Rules

```json
{
  "rules": {
    "devices": {
      "$deviceId": {
        ".read": true,
        ".write": true,
        "latest": {
          ".read": true,
          ".write": true
        },
        "history": {
          ".read": true,
          ".write": true,
          ".indexOn": ["timestamp"]
        }
      }
    }
  }
}
```

## 🔧 Hardware Setup

### Components Required

| Component | Quantity | Purpose |
|-----------|----------|---------|
| ESP32 DevKit | 1 | Main controller |
| DHT22 Sensor | 1 | Temperature & Humidity |
| Capacitive Soil Moisture Sensor | 1 | Soil moisture |
| 5V Relay Module | 1 | Pump control |
| Mini Water Pump | 1 | Irrigation (demo) |
| Jumper Wires | Several | Connections |
| 5V Power Supply | 1 | Power |

### Wiring Diagram

```
ESP32 Pin Connections:
─────────────────────
GPIO4  → DHT22 Data
GPIO34 → Soil Moisture Sensor (Analog)
GPIO25 → Relay IN
3.3V   → DHT22 VCC, Soil Sensor VCC
GND    → DHT22 GND, Soil Sensor GND, Relay GND
5V     → Relay VCC
```

### Uploading Firmware

1. Open `esp32_firmware/crop_monitor.ino` in Arduino IDE
2. Install required libraries:
   - Firebase ESP Client
   - DHT sensor library
3. Update WiFi and Firebase credentials
4. Select ESP32 board and upload

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── sensor_data.dart     # Sensor reading model
│   ├── field.dart           # Farm field model
│   └── alert.dart           # Alert model
├── providers/                # State management
│   ├── field_provider.dart  # Field & sensor state
│   ├── alert_provider.dart  # Alert management
│   └── settings_provider.dart # App settings
├── screens/                  # UI screens
│   ├── splash_screen.dart   # Splash with animation
│   ├── home_screen.dart     # Main navigation
│   ├── dashboard_screen.dart # Live data view
│   ├── graph_screen.dart    # Charts & analytics
│   ├── alerts_screen.dart   # Alert management
│   ├── fields_screen.dart   # Multi-field view
│   └── settings_screen.dart # App preferences
├── services/                 # Backend services
│   ├── firebase_service.dart # Firebase RTDB
│   ├── notification_service.dart # Push notifications
│   └── storage_service.dart # Local storage
├── theme/                    # App theming
│   └── app_theme.dart       # Colors, styles
└── widgets/                  # Reusable widgets
    ├── sensor_card.dart     # Sensor display card
    ├── stress_indicator.dart # Crop stress widget
    ├── field_card.dart      # Field selector
    ├── alert_card.dart      # Alert item
    ├── pump_control.dart    # Pump toggle
    └── charts.dart          # Line & bar charts
```

## 🌱 Crop Stress Calculation

The system calculates crop stress based on three parameters:

| Parameter | Optimal Range | Moderate Stress | High Stress | Critical |
|-----------|--------------|-----------------|-------------|----------|
| Temperature | 20-30°C | 18-32°C | 15-35°C | <15 or >35°C |
| Humidity | 40-70% | 35-80% | 30-85% | <30 or >85% |
| Soil Moisture | 40-70% | 35-75% | 25-85% | <25 or >85% |

## 🎯 Supported Crops

- 🌾 Paddy (Rice)
- 🌾 Wheat
- 🥜 Groundnut
- 🌿 Cotton
- 🎋 Sugarcane
- 🌽 Maize (Corn)
- 🍅 Tomato
- 🥔 Potato
- 🧅 Onion
- 🌶️ Chili
- 🥭 Mango
- 🍌 Banana
- 🥥 Coconut
- ☕ Coffee
- 🍵 Tea

## 📋 Functional Requirements

| ID | Requirement | Status |
|----|-------------|--------|
| FR-1 | Sensor Data Acquisition | ✅ |
| FR-2 | Data Transmission to Cloud | ✅ |
| FR-3 | Real-Time Visualization | ✅ |
| FR-4 | Historical Data View | ✅ |
| FR-5 | Alert System | ✅ |
| FR-6 | Multi-Location Support | ✅ |
| FR-7 | Manual Irrigation Control | ✅ |

## 🔮 Future Enhancements

- [ ] AI-based stress prediction
- [ ] SMS alert system
- [ ] Voice alerts in local languages
- [ ] Solar-powered sensor nodes
- [ ] Weather forecast integration
- [ ] Crop disease detection (camera)
- [ ] Multi-user authentication
- [ ] Farm analytics dashboard

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License.

## 👨‍💻 Author

Developed as an Academic Project for IoT-Based Smart Agriculture

---

<p align="center">
  Made with ❤️ for Smart Agriculture
  <br><br>
  <em>"The proposed system enables 24×7 crop monitoring using IoT sensors and a Flutter‑based mobile application with real‑time visualization, alerts, and offline support."</em>
</p>
