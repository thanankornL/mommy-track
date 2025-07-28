import 'package:carebellmom/patientPages/PatientHomePage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../notification.dart';
import '../PersonalPage.dart';
import 'package:carebellmom/patientPages/Chatbot_index_patient.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Make status bar transparent
      statusBarIconBrightness:
          Brightness
              .light, // For dark icons (use Brightness.light for white icons)
    ),
  );
  await dotenv.load(fileName: '.env');
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: chatbot_Patient(),
    ),
  );
}

class chatbot_Patient extends StatefulWidget {
  const chatbot_Patient({super.key});

  @override
  State<chatbot_Patient> createState() => _chatbot_Patient();
}

class _chatbot_Patient extends State<chatbot_Patient> {
  int currentPageIndex = 1; // Default index

  @override
  Widget build(BuildContext context) {
    //double screenwidth = MediaQuery.of(context).size.width;
    //double screenheight = MediaQuery.of(context).size.height;
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        indicatorColor: const Color.fromARGB(255, 135, 191, 255),
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.notifications_active),
            icon: Badge(child: Icon(Icons.notifications_outlined)),
            label: 'Notifications',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.home),
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.message),
            icon: Icon(Icons.message_outlined),
            label: 'Chatbot',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.person),
            icon: Icon(Icons.person_outlined),
            label: 'User',
          ),
        ],
      ),
      body: Center(
        child:
            currentPageIndex == 0
                ? NotificationPage() // Show Text when index is 0
                : currentPageIndex == 1
                ? PatientHomePage()
                : currentPageIndex == 2
                ? Chatbot_index_patient()
                : currentPageIndex == 3
                ? PersonalPage() // Show Index3Page when index is 3
                : Text("Other Content"), // Default content for other indices
      ),
    );
  }
}
