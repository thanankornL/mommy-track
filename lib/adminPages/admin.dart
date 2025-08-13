import 'package:carebellmom/adminPages/Chatbot_index_Admin.dart';
import 'package:flutter/material.dart';
import 'AdminHomePage.dart';
import '../notification.dart';
import '../PersonalPage.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int currentPageIndex = 0; // Default index

  @override
  Widget build(BuildContext context) {
    double screenwidth = MediaQuery.of(context).size.width;
    double screenheight = MediaQuery.of(context).size.height;
    var navigationBar2 = BottomNavigationBar(
      currentIndex: currentPageIndex,
      onTap: (index) {
        setState(() {
          currentPageIndex = index;
        });
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.green[700],
      unselectedItemColor: Colors.grey,

      items: [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
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
    );
    var navigationBar = navigationBar2;
    return Scaffold(
      bottomNavigationBar: navigationBar,
      body: Center(
        child:
            currentPageIndex == 0
                ? AdminHomePage() // Show Text when index is 0
                : currentPageIndex == 1
                ? NotificationPage()
                : currentPageIndex == 2
                ? Chatbot_index_Admin()
                : currentPageIndex == 3
                ? PersonalPage() // Show Index3Page when index is 3
                : Text("Other Content"), // Default content for other indices
      ),
    );
  }
}
