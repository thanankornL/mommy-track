import 'package:carebellmom/patientPages/Chatbot_index_patient.dart';
import 'package:flutter/material.dart';
import 'PatientHomePage.dart';
import '../notification.dart';
import '../PersonalPage.dart';

class PatientPage extends StatefulWidget {
  const PatientPage({super.key});

  @override
  _PatientPageState createState() => _PatientPageState();
}

class _PatientPageState extends State<PatientPage> {
  int currentPageIndex = 0; // Default index

  @override
  Widget build(BuildContext context) {
    double screenwidth = MediaQuery.of(context).size.width;
    double screenheight = MediaQuery.of(context).size.height;
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        currentIndex : currentPageIndex,
        onTap: (index) {
          setState(() {
             currentPageIndex = index;
          }
          );
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green[700],
        unselectedItemColor: Colors.grey,
           items: [
         BottomNavigationBarItem(
          
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
           
            icon: Badge(child: Icon(Icons.notifications)),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            
            icon: Icon(Icons.chat),
            label: 'Chatbot',
          ),
          BottomNavigationBarItem(
           
           icon: Icon(Icons.person),
            label: 'User',
          ),
        ],
      ),
      body: Center(
        child:
            currentPageIndex == 0
                ?  PatientHomePage()// Show Text when index is 0
                : currentPageIndex == 1
                ? NotificationPage()
                : currentPageIndex == 2
                ? Chatbot_index_patient()
                : currentPageIndex == 3
                ? PersonalPage() // Show Index3Page when index is 3
                : Text("Other Content"), // Default content for other indices
      ),
    );
  }
}
