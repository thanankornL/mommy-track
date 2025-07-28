<<<<<<< HEAD
# app
=======
<<<<<<< HEAD
# app
=======
# CareBellMom - Vaccine Tracker

**CareBellMom** is a Flutter mobile application designed to help mothers track their child's vaccination schedule in an intuitive and visually appealing way. It fetches baby data from a backend and displays vaccine progress through a vertical stepper interface.

---

## ✨ Features

- ✅ Fetch baby data using the logged-in mother's username
- 🎨 Gender-based theme (blue for boys, pink for girls)
- 🧬 Vertical stepper showing:
  - Completed vaccines
  - Current vaccine stage
  - Upcoming vaccines
- 📱 Slide actions and animated dialogs
- ⚠️ Error handling with user-friendly SnackBars

---

## 🚀 Getting Started

### 1. Clone the repository

```bash
git https://github.com/thanankornL/app.git
cd app
```
2. Install dependencies
```bash
flutter pub get
```
3. Configure API
Edit the config.dart file:
```bash
const String baseUrl = 'https://your-api-endpoint.com';
```
4. Run the app
```bash
flutter run
```

## 🔐 Authentication
The app uses SharedPreferences to store the mother's username after login. This username is used to fetch baby data.
```bash
SharedPreferences prefs = await SharedPreferences.getInstance();
prefs.setString('username', 'motherUsername');
```
## 📬 API Response Structure
```json
{
  "success": true,
  "data": {
    "child": "Baby Name",
    "action": 2,
    "gender": "male"
  }
}
```
child: Child's name
action: Current vaccine step (0 = not started, 1–4 = stages)
gender: Either "male" or "female"

🤝 Contributing
Pull requests are welcome! Feel free to fork the repo and submit improvements. Open an issue first if you'd like to discuss significant changes.

📄 License
This project is licensed under the MIT License.

Made with ❤️ by Lucky
>>>>>>> 2707ef7 (Initial commit)
>>>>>>> 3199079 (Remove embedded git repo from server_things)
