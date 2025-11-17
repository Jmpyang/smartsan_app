#SmartSan App

SmartSan is a mobile application built with *Flutter* to enhance sanitation management through real-time issue reporting, community engagement, and smart analytics. It supports both citizen users and admin/staff roles, integrating with backend services and IoT devices to improve urban hygiene and waste handling.

-----

🚀 Features

    📸 Report sanitation issues with location & photos
    📊 View live sanitation stats & impact metrics
    👥 Role-based dashboards (Community & Admin)
    🔔 Push notifications for updates & alerts
    🌍 IoT & data integration for smart waste tracking
    🧠 Clean, modern UI matching SmartSan’s web design

----

🛠️ Tech Stack

    Flutter + Dart
    Firebase (Auth, Firestore, Storage, Messaging)
    Google Maps API (optional for geolocation)
    Provider / Riverpod / GetX (state management)
    Android Studio / VS Code (development)

---

📁 Project Structure


lib/
├── core/            # Themes, constants, shared widgets
├── features/        # Modular screens (auth, report, dashboard, etc.)
├── services/        # Firebase & API integrations
├── routes/          # App routing
└── main.dart        # Entry point

----

Getting Started

1. Clone the repo:
   
   git clone https://github.com/Jmpyang/smartsan-app.git
   

2. Install dependencies:
   
   flutter pub get
   

3. Set up Firebase:
   - Create project in [Firebase Console](https://console.firebase.google.com)
   - Add Android app
   - Add google-services.json to /android/app/

4. Run:
   
   flutter run
   

---

📌 License

MIT License — feel free to use, modify, and contribute.

---

Built with community impact in mind 🌱