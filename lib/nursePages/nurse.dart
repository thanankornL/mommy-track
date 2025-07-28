import 'package:carebellmom/nursePages/Chatbot_index_Nurse.dart';
import 'package:flutter/material.dart';
//import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'NurseHomePage.dart';
import '../notification.dart';
import '../PersonalPage.dart';

class NursePage extends StatefulWidget {
  const NursePage({super.key});

  @override
  _NursePageState createState() => _NursePageState();
}

class _NursePageState extends State<NursePage> {
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
          });

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
            icon: Icon(Icons.notifications),
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
               ?  NurseHomePage()// Show Text when index is 0
                : currentPageIndex == 1
                ? NotificationPage()
                : currentPageIndex == 2
                ? Chatbot_index_Nurse()
                : currentPageIndex == 3
                ? PersonalPage() // Show Index3Page when index is 3
                : Text("Other Content"), // Default content for other indices
      ),
    );
  }
}
