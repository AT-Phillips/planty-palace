# planty_palace

Plant Cataloging App built with Flutter for Android and iOS. My wife wanted an app that she could use to track all her plants, so I'm building her one. :)

## Getting Started
# 🌿 Planty Palace

**Plant Cataloging App** built with Flutter for iOS.

---

## Overview

Planty Palace is a Flutter-powered mobile app for cataloging and managing plants. Designed for personal use and portfolio demonstration, it includes:

- Adding plants via search  
- Viewing care instructions, species data, and symbolic meanings  
- Setting watering reminders  
- Logging plant care with historical graphs  
- Generating QR codes that link to specific plant entries

---

## Features

- Local SQLite database with CRUD support  
- Modular structure using `models/`, `helpers/`, and `screens/`  
- Clean, scalable Flutter architecture  
- No authentication – designed for fast private access

---

## Tech Stack

- **Flutter (Dart)** – Cross-platform development  
- **SQLite** – Local data persistence  
- **flutter_local_notifications** – Watering reminders  
- **qr_flutter** – QR code generation  
- **Provider** or **Riverpod** *(Unsure yet)* – State management  

---

## Ideal Project Structure

lib/
│
├── main.dart                        # Entry point
├── app.dart                         # App widget with routes and theming
│
├── config/                          # App-wide configs
│   ├── constants.dart               # Static values (colors, padding, strings)
│   ├── themes.dart                  # Light/dark theme settings
│   └── routes.dart                  # Route names and generator
│
├── models/                          # Data models
│   ├── plant.dart
│   ├── care_log.dart
│   └── notification_settings.dart
│
├── services/                        # Business logic, database, APIs
│   ├── database_service.dart        # SQLite wrapper
│   ├── notification_service.dart    # Local notifications
│   ├── qr_service.dart              # QR code generation/reading
│   └── plant_service.dart           # Handles logic for plant actions
│
├── helpers/                         # Utilities
│   ├── date_utils.dart
│   └── image_utils.dart
│
├── providers/                       # State management (Provider/Riverpod)
│   ├── plant_provider.dart
│   ├── log_provider.dart
│   └── settings_provider.dart
│
├── screens/                         # All screens/views
│   ├── home/
│   │   └── home_screen.dart
│   ├── my_plants/
│   │   └── my_plants_screen.dart
│   ├── plant_detail/
│   │   └── plant_detail_screen.dart
│   ├── search/
│   │   └── search_screen.dart
│   ├── add_plant/
│   │   └── add_plant_screen.dart
│   ├── logs/
│   │   └── care_log_screen.dart
│   ├── qr/
│   │   └── qr_screen.dart
│   └── settings/
│       └── settings_screen.dart
│
├── widgets/                         # Reusable UI components
│   ├── plant_card.dart
│   ├── water_reminder_tile.dart
│   └── log_entry_tile.dart
│
└── charts/                          # Chart-related widgets and logic
    └── care_chart.dart
