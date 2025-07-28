# Flutter Project: Carebell Mom

## Overview
Carebell Mom is a Flutter application designed to manage healthcare services for mothers. The app provides interfaces for admins, nurses, and patients, allowing for efficient management and communication.

## Project Structure
```
flutter-project
├── lib
│   ├── main.dart
│   ├── screens
│   │   ├── admin.dart
│   │   ├── nurses.dart
│   │   └── patients.dart
│   ├── widgets
│   │   └── common_widgets.dart
│   └── utils
│       └── constants.dart
├── pubspec.yaml
└── README.md
```

## Setup Instructions
1. **Clone the repository:**
   ```
   git clone <repository-url>
   cd flutter-project
   ```

2. **Install dependencies:**
   ```
   flutter pub get
   ```

3. **Run the application:**
   ```
   flutter run
   ```

## Usage
- **Admin Interface:** Accessed through the AdminPage, where admins can manage users and view reports.
- **Nurse Interface:** Accessed through the NursePage, where nurses can manage patient care and view schedules.
- **Patient Interface:** Accessed through the PatientsPage, where patients can view their health information and communicate with healthcare providers.

## Contributing
Contributions are welcome! Please open an issue or submit a pull request for any enhancements or bug fixes.

## License
This project is licensed under the MIT License. See the LICENSE file for more details.