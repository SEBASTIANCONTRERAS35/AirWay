# AirWay - User Guide

## Table of Contents
1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Project Structure](#project-structure)
4. [Installation](#installation)
5. [Running the iOS Application](#running-the-ios-application)
6. [Running the Backend API](#running-the-backend-api)
7. [Features Guide](#features-guide)
8. [Troubleshooting](#troubleshooting)

---

## Overview

**AirWay** is an iOS application that provides real-time air quality information and route optimization based on air pollution levels. The app helps users navigate while minimizing exposure to poor air quality, similar to Waze but with environmental health focus.

### Key Features
- 🗺️ Real-time map navigation with air quality overlay
- 🌬️ Multi-criteria route optimization (cleanest air, fastest, safest)
- 📊 Live AQI (Air Quality Index) monitoring
- 📍 Point A to Point B route calculation
- 🎯 Interactive map with air quality zones
- ⌚ Apple Watch companion app

---

## Prerequisites

### For iOS App Development

1. **macOS** (Monterey 12.0 or later recommended)
2. **Xcode** 15.0 or later
   - Download from [Mac App Store](https://apps.apple.com/us/app/xcode/id497799835)
3. **iOS Simulator** or **Physical Device** (iOS 17.0+)
4. **Apple Developer Account** (for device deployment)

### For Backend API

1. **Python** 3.9 or later
2. **pip** (Python package manager)
3. **Docker** (optional, for containerized deployment)

---

## Project Structure

```
IOSChallengers/
├── frontend/                    # iOS Application
│   ├── AcessNet/               # Main iOS app source code
│   │   ├── Core/               # Core services and managers
│   │   │   ├── App/           # App entry point
│   │   │   ├── Managers/      # LocationManager, etc.
│   │   │   └── Services/      # API services, route optimization
│   │   ├── Features/          # Feature modules
│   │   │   ├── Map/           # Map view and components
│   │   │   ├── AirQuality/    # Air quality screens
│   │   │   └── AR/            # AR particles visualization
│   │   └── Shared/            # Shared models and utilities
│   ├── AirWayWatch Watch App/  # Apple Watch companion app
│   └── legacy-osrm/           # Legacy OSRM integration code
│
├── backend-api/                # Backend Services
│   ├── src/                   # Python backend source
│   │   ├── core/             # Business logic
│   │   ├── adapters/         # External service adapters
│   │   ├── application/      # Application layer
│   │   └── interfaces/       # API interfaces
│   ├── Dockerfile            # Docker configuration
│   ├── docker-compose.yml    # Docker Compose setup
│   └── requirements.txt      # Python dependencies
│
├── documentation/             # Documentation
│   └── technical/            # Technical docs
│
├── .env                      # Environment variables
├── .gitignore               # Git ignore rules
├── LICENSE                  # Project license
├── README.md               # Project overview
└── USER_GUIDE.md          # This file
```

---

## Installation

### Step 1: Clone the Repository

```bash
git clone https://github.com/mrKOmbo/IOSChallengers.git
cd IOSChallengers
```

### Step 2: Set Up Environment Variables

Create or verify the `.env` file in the project root:

```bash
# .env file
OPENAQ_API_KEY=your_openaq_api_key_here
```

To get an OpenAQ API key:
1. Visit [OpenAQ](https://openaq.org/)
2. Sign up for a free account
3. Generate an API key from your dashboard

---

## Running the iOS Application

### Method 1: Using Xcode (Recommended)

1. **Open the Project**
   ```bash
   cd frontend
   open AcessNet.xcodeproj
   ```

2. **Configure Signing**
   - In Xcode, select the project in the navigator
   - Go to "Signing & Capabilities"
   - Select your Apple Developer Team
   - Xcode will automatically manage signing

3. **Select Target Device**
   - Choose a simulator from the device dropdown (e.g., "iPhone 15 Pro")
   - Or connect a physical iOS device via USB

4. **Build and Run**
   - Press `Cmd + R` or click the Play button
   - Wait for the app to build and launch
   - First launch may take 2-3 minutes

### Method 2: Command Line Build

```bash
cd frontend

# Build for simulator
xcodebuild -project AcessNet.xcodeproj \
  -scheme AcessNet \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  build

# Run tests
xcodebuild test -project AcessNet.xcodeproj \
  -scheme AcessNet \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### First Launch Setup

When you first launch the app:

1. **Grant Location Permissions**
   - Tap "Allow While Using App" when prompted
   - Required for real-time navigation

2. **Grant Notification Permissions** (Optional)
   - Allows alerts for air quality changes
   - Tap "Allow" when prompted

---

## Running the Backend API

### Method 1: Using Docker (Recommended)

```bash
cd backend-api

# Build and start services
docker-compose up --build

# The API will be available at http://localhost:8000
```

### Method 2: Local Python Environment

```bash
cd backend-api

# Create virtual environment
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate  # On macOS/Linux
# or
venv\Scripts\activate  # On Windows

# Install dependencies
pip install -r requirements.txt

# Run the API
python -m uvicorn src.main:app --reload --host 0.0.0.0 --port 8000
```

### Verify Backend is Running

```bash
# Test the health endpoint
curl http://localhost:8000/health

# Expected response:
# {"status": "healthy"}
```

---

## Features Guide

### 1. Map Navigation

**How to Navigate:**
1. Open the app
2. The map will center on your current location (blue pulsing circle)
3. Pinch to zoom in/out
4. Drag to pan around the map
5. Tap the compass icon to re-center on your location

**Map Styles:**
- **Standard**: Default Apple Maps view
- **Hybrid**: Satellite imagery with labels
- **Imagery**: Pure satellite view

Toggle styles using the layers button (square icon) in the bottom-right.

### 2. Setting a Destination (Point B)

1. Tap anywhere on the map to drop a pin
2. A green flag marker appears at your selected destination
3. Tap "Calculate Route" in the bottom card
4. The app will calculate 3 route options

### 3. Route Selection

After calculating routes, you'll see:

- **Cleanest Air** (leftmost card, green): Best air quality route
- **Fastest** (middle card, blue): Shortest time route
- **Safest** (rightmost card, yellow): Safest road conditions

**Selecting a Route:**
1. Swipe through route cards
2. Tap "Start Navigation" on your preferred route
3. The app enters navigation mode

### 4. Navigation Mode

During navigation:
- **2D top-down view** follows your movement
- **Heading indicator** shows your direction
- **Turn-by-turn arrows** guide you along the route
- **Speed indicator** shows current speed (km/h)
- **Distance remaining** updates in real-time

**Exit Navigation:**
- Tap the red X button in the top-left corner

### 5. Air Quality Layer

**Toggle Air Quality Overlay:**
1. Tap the wind icon button
2. Colored zones appear on the map:
   - 🟢 Green: Good (AQI 0-50)
   - 🟡 Yellow: Moderate (AQI 51-100)
   - 🟠 Orange: Unhealthy for Sensitive Groups (AQI 101-150)
   - 🔴 Red: Unhealthy (AQI 151-200)
   - 🟣 Purple: Very Unhealthy (AQI 201-300)

### 6. Air Quality Dashboard

**Access AQI Information:**
1. Tap the bottom tab bar "Air Quality" icon
2. View current AQI for your location
3. See PM2.5 and PM10 levels
4. Check hourly and daily forecasts
5. View exposure time breakdown (home/work/outdoor)

**AR Air Quality Visualization:**
1. In the Air Quality tab, tap "AR Air Quality"
2. Point your camera at the environment
3. See visualized PM2.5 particles in augmented reality
4. Particle density reflects real-time air quality

### 7. Location Search

1. Tap the search bar at the bottom of the map
2. Type a city name or address
3. Select from autocomplete suggestions
4. The map will center on the selected location
5. View air quality data for that location

### 8. Apple Watch App

If you have an Apple Watch:
1. The companion app syncs automatically
2. View current AQI on your wrist
3. See active route information
4. Check exposure statistics

---

## Troubleshooting

### App Won't Launch

**Problem:** App crashes on launch
**Solution:**
- Ensure iOS version is 17.0 or later
- Try cleaning build folder: Xcode → Product → Clean Build Folder
- Restart Xcode and rebuild

### Location Not Updating

**Problem:** User location not showing on map
**Solution:**
- Check Location Services: Settings → Privacy → Location Services
- Verify AirWay has "While Using" permission
- Restart the app
- On simulator: Debug → Location → Custom Location

### Routes Not Calculating

**Problem:** "Calculate Route" shows error
**Solution:**
- Verify backend API is running (check `http://localhost:8000/health`)
- Check internet connection
- Ensure destination is reachable by road
- Try selecting a different destination point

### Air Quality Data Not Loading

**Problem:** AQI shows as "—" or loading forever
**Solution:**
- Verify `.env` file has valid `OPENAQ_API_KEY`
- Check backend logs for API errors
- Ensure internet connectivity
- Some remote areas may not have coverage

### Build Errors in Xcode

**Problem:** "Cannot find module" or similar
**Solution:**
```bash
# Clean derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Re-open project
open frontend/AcessNet.xcodeproj
```

### Backend API Connection Issues

**Problem:** App can't connect to backend
**Solution:**
- If running on physical device, use your Mac's local IP instead of localhost
- Update API base URL in app settings
- Check firewall settings
- Ensure backend is running: `docker ps` or check process

### Apple Watch App Not Syncing

**Problem:** Watch app doesn't show data
**Solution:**
- Ensure iPhone and Watch are paired
- Check Bluetooth is enabled on both devices
- Force quit and reopen the iPhone app
- Restart both devices if needed

---

## Development Tips

### Debugging

**Enable Verbose Logging:**
- Logs appear in Xcode console (Cmd + Shift + Y)
- Look for emoji-prefixed logs: 🗺️ (map), 🌬️ (air quality), 🚗 (routes)

**Common Log Filters:**
```
📍  - Location updates
🎯  - Route calculations
✅  - Successful operations
❌  - Errors
```

### Testing Routes

For testing without moving:
1. Use simulator
2. Debug → Location → Freeway Drive
3. This simulates driving movement
4. Routes will update in real-time

### Resetting App State

To clear all app data:
1. Delete app from device/simulator
2. Reinstall
3. Or: Long press app icon → App Info → Storage → Clear Cache

---

## Support

For issues, questions, or contributions:

- **GitHub Issues**: [https://github.com/mrKOmbo/IOSChallengers/issues](https://github.com/mrKOmbo/IOSChallengers/issues)
- **Documentation**: See `documentation/technical/` folder
- **Project README**: See main `README.md`

---

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.

---

**Last Updated**: October 2025
**Version**: 1.0.0
**Minimum iOS**: 17.0
