🚧 PaveGuard
Real-Time Urban Pothole Detection Using Smartphone IMU & GPS Data



📌 Abstract

Potholes significantly impact urban transportation by causing vehicle damage, traffic congestion, and increased maintenance costs. Traditional detection methods rely on manual inspection and citizen reporting, which are inefficient and inconsistent.
PaveGuard introduces a real-time, smartphone-based pothole detection and prediction system that leverages built-in Accelerometer, Gyroscope, and GPS sensors. The system processes IMU data using adaptive statistical thresholding and rolling window analysis to detect abnormal vibration signatures. Confirmed potholes are geo-tagged and stored in Firebase for monitoring and smart-city road maintenance planning.
This solution is scalable, cost-effective, and requires no external hardware.

🎯 Key Features

📈 Real-time Accelerometer & Gyroscope Monitoring
📊 Rolling Window Statistical Thresholding
📍 GPS-based Geo-Tagging
☁️ Firebase Firestore Cloud Storage
🔔 Instant Driver Alerts (Vibration + Snackbar)
🚫 Duplicate Detection Filtering
⏱ Debounce Logic for False Positive Reduction
🗺️ Live Pothole Map Visualization

🧠 System Architecture

Smartphone Sensors (IMU)
        ↓
Magnitude Calculation
        ↓
Rolling Window Buffer (50 samples)
        ↓
Mean (μ) & Standard Deviation (σ)
        ↓
Dynamic Threshold (T = μ + kσ)
        ↓
Dual Sensor Confirmation
        ↓
Debounce + Distance Filtering
        ↓
GPS Tagging
        ↓
Firebase Firestore
        ↓
Map Visualization + User Alert

🔬 Detection Algorithm

1️⃣ Acceleration Magnitude
A single magnitude value is computed from 3-axis accelerometer data:
A = √(x² + y² + z²)

2️⃣ Gyroscope Magnitude
G = √(gx² + gy² + gz²)

3️⃣ Rolling Window Analysis
Window size: 50 samples
Compute:
Mean (μ)
Standard Deviation (σ)

4️⃣ Adaptive Threshold
T = μ + kσ
Where:
μ = rolling mean
σ = rolling standard deviation
k = sensitivity constant

A pothole is confirmed only when:
Acceleration magnitude > threshold
AND
Gyroscope magnitude > threshold

5️⃣ False Positive Control
Technique	Purpose
7-second Debounce	Prevents repeated triggering
20m Distance Filter	Avoids duplicate marking
4-second GPS refresh	Battery optimization
🛠️ Technologies Used
Component	Technology
Mobile App	Flutter
Programming Language	Dart
Sensor Access	sensors_plus
GPS	Geolocator
Cloud Database	Firebase Firestore
State Management	Flutter Reactive UI
Statistical Processing	Rolling Mean & Std Dev

📱 Application Modules

📊 Sensor Dashboard

Real-time IMU visualization
Acceleration (X, Y, Z)
Gyroscope (X, Y, Z)
Start / Pause / Stop sensing

🗺️ Pothole Map Interface

Live user location tracking
Visual warning icons
Nearby pothole awareness

🔔 Alert System

Snackbar notification
Haptic vibration feedback

📂 Project Structure
paveguard/
│
├── lib/
│   ├── main.dart
│   ├── services/
│   ├── models/
│   ├── screens/
│   └── utils/
│
├── android/
├── ios/
├── assets/
├── pubspec.yaml
└── README.md

🚀 Installation & Setup
1️⃣ Clone Repository
git clone https://github.com/239zenali/Paveguard-Pothole-detection-using-smart-phone.git
cd Paveguard-Pothole-detection-using-smart-phone

2️⃣ Install Dependencies
flutter pub get

3️⃣ Configure Firebase
Create Firebase Project
Enable Firestore Database
Add google-services.json (Android)
Configure iOS if required

4️⃣ Run Application
flutter run

📊 Data Stored in Firestore

Each detected pothole contains:
Latitude
Longitude
Severity Level
Timestamp
Sensor Magnitude Values

🌍 Real-World Impact

Enhances road safety
Reduces vehicle maintenance costs
Enables predictive infrastructure planning
Supports Smart City initiatives
Provides scalable urban monitoring

📈 Future Enhancements

Machine Learning-based pothole classification
Severity estimation model
Heatmap visualization
Government admin dashboard
Crowdsourced multi-user data aggregation
Predictive pothole formation analytics

📚 Research References

Smartphone-based vibration anomaly detection studies
Adaptive thresholding for mobile IMU systems
Machine learning approaches for road surface monitoring
