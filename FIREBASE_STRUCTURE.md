# Firebase Realtime Database Structure

## Overview
This document describes the Firebase Realtime Database structure used by the CropWatch app.

## Database Schema

```
/users
  /{userId}
    profile
      name          : string    (e.g., "Farmer John")
      phone         : string    (e.g., "+91 9876543210")
      language      : string    (e.g., "en", "ta", "hi")
      location      : string    (e.g., "Tamil Nadu, India")
    crops
      /{cropId}
        cropName    : string    (e.g., "Paddy", "Groundnut", "Wheat")
        fieldName   : string    (e.g., "North Field", "Main Plot")
        live
          timestamp   : number  (epoch milliseconds)
          dht22
            temperature : number  (°C, e.g., 28.5)
            humidity    : number  (%, e.g., 65.0)
          soilMoisture  : number  (%, e.g., 45.0)
          pumpStatus    : boolean (true = ON, false = OFF)
        alerts
          /{alertId}
            type      : string  (e.g., "lowMoisture", "highTemperature", "criticalStress")
            message   : string  (e.g., "Soil moisture below threshold")
            ts        : number  (epoch milliseconds)
        history (contains only one month of data - past one month from current date)
          /{yyyy-mm}  (e.g., "2026-02")
            monthlyAvg
              temperature   : number
              humidity      : number
              soilMoisture  : number
            days
              /{dd-mm-yyyy}  (e.g., "14-02-2026")
                records
                  /{hh:mm}   (e.g., "08:30", "14:00")
                    dht22
                      temperature : number
                      humidity    : number
                    soilMoisture  : number
                dailyAvg
                  temperature   : number
                  humidity      : number
                  soilMoisture  : number
```

## Data Flow

### ESP32 → Firebase (Hardware writes)
1. **Live Data**: ESP32 writes to `/users/{userId}/crops/{cropId}/live` every few seconds
2. **History Records**: ESP32 writes to `/users/{userId}/crops/{cropId}/history/{yyyy-mm}/days/{dd-mm-yyyy}/records/{hh:mm}`
3. **Daily Averages**: Calculated and written to `.../days/{dd-mm-yyyy}/dailyAvg`
4. **Monthly Averages**: Calculated and written to `.../history/{yyyy-mm}/monthlyAvg`
5. **Alerts**: ESP32 or server writes alerts to `/users/{userId}/crops/{cropId}/alerts/{alertId}`

### App → Firebase (App writes)
1. **Profile Updates**: App writes to `/users/{userId}/profile`
2. **Pump Control**: App writes to `/users/{userId}/crops/{cropId}/live/pumpStatus`
3. **Crop Management**: App writes to `/users/{userId}/crops/{cropId}` (cropName, fieldName)

### Firebase → App (App reads/listens)
1. **Live Data Stream**: App listens to `/users/{userId}/crops/{cropId}/live`
2. **Historical Data**: App reads `/users/{userId}/crops/{cropId}/history/{yyyy-mm}/days/...`
3. **Alerts Stream**: App listens to `/users/{userId}/crops/{cropId}/alerts`
4. **Profile Stream**: App listens to `/users/{userId}/profile`

## Notes
- The `history` node contains only **one month** of data (past one month from the current date)
- Old data beyond one month should be cleaned up either by a Cloud Function or by the ESP32
- The `live` node is constantly updated and represents the **current** state of the sensors
- The `alerts` collection grows over time; consider periodic cleanup
- Date format in days: `dd-mm-yyyy` (e.g., "14-02-2026")
- Time format in records: `hh:mm` (24-hour, e.g., "08:30", "14:00")
- Month format in history: `yyyy-mm` (e.g., "2026-02")
