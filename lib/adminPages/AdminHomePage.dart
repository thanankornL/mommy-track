import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:carebellmom/patient_management/patients_management.dart';
import '../nursePages/AddNurse.dart';
import '../notification.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:popup_menu_plus/popup_menu_plus.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:carebellmom/adminPages/admin.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});
  @override
  State<AdminHomePage> createState() => _AdminHomePage();
}

class _AdminHomePage extends State<AdminHomePage> {
  late String formattedTime;
  late Timer _timer;
  @override
  void initState() {
    super.initState();
    _updateTime(); // เรียกตอนเริ่ม
    _timer = Timer.periodic(Duration(seconds: 1), (Timer t) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      formattedTime = DateFormat('HH:mm:ss').format(now);
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // ป้องกัน memory leak
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: const Color(0xFFA8D5BA),
      appBar: AppBar(
        
        title: Column(
          children: [
            Align(
              
              alignment: Alignment.topLeft,
              child: Padding(
                padding: EdgeInsets.only(bottom: screenHeight * 0.01, left: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // เว้นระยะห่างระหว่างรูปกับข้อความ
                    Text(
                      "ยินดีต้อนรับเข้าสู่ Care bell mom",
                      style: TextStyle(
                        fontFamily: "Inter",
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.w700,
                        color : Colors.white
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: screenHeight * 0.05,
                  left: 20.0,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // เว้นระยะห่างระหว่างรูปกับข้อความ
                    Text(
                      "Appication Care bell mom",
                      style: TextStyle(
                        fontFamily: "Inter",
                        fontSize: screenWidth * 0.03,
                        fontWeight: FontWeight.w400,
                        color: const Color.fromARGB(255, 20, 20, 20),
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    Icon(Icons.notifications_none, color: Colors.amber),
                  ],
                ),
              ),
            ),

            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: screenHeight * 0.01,
                  left: screenWidth * 0.25,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,

                  children: [
                    Icon(Icons.person_2),
                    SizedBox(width: 5),
                    Text(': 200', style: TextStyle(fontSize: 15)),
                    SizedBox(width: screenWidth * 0.2),
                    Icon(Icons.access_time_rounded),
                    SizedBox(width: 5),
                    Text('$formattedTime', style: TextStyle(fontSize: 15,color : Colors.white),),

                  ],
                ),
              ),
            ),
          ],
        ),

        toolbarHeight: 200,
        backgroundColor : Color.fromARGB(255, 255, 255, 255),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(50)),
        ),
      ),
      body: Container(
        child: Column(  
          children: [
            SizedBox(height: screenHeight * 0.025),
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: EdgeInsets.only(top: 5.0, left: 30.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // เว้นระยะห่างระหว่างรูปกับข้อความ
                    Text(
                      "หมวดหมู่",
                      style: TextStyle(
                        fontFamily: "Anuphan",
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.bold,
                        color: const Color.fromARGB(255, 0, 0, 0),
                        
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: EdgeInsets.only(top: 5.0, left: 65),

                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        print('กดปุ่มแล้ว');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserManagementPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(
                          screenWidth * 0.16,
                          screenHeight * 0.10,
                        ), // ความกว้าง x ความสูง
                        backgroundColor: const Color.fromARGB(
                          255,
                          255,
                          255,
                          255,
                        ), // สีพื้นหลังปุ่ม
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100), // มุมมน
                        ),
                      ),
                      child: Icon(
                        Icons.person_add_rounded,
                        color: Colors.black,
                        size: screenHeight * 0.02,
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.15),
                    ElevatedButton(
                      onPressed: () {
                        print('กดปุ่มแล้ว');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => sendNotification(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(
                          screenWidth * 0.16,
                          screenHeight * 0.10,
                        ), // ความกว้าง x ความสูง
                        backgroundColor: const Color.fromARGB(
                          255,
                          255,
                          255,
                          255,
                        ), // สีพื้นหลังปุ่ม
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100), // มุมมน
                        ),
                      ),
                      child: Icon(
                        Icons.notification_add,
                        color: Colors.black,
                        size: screenHeight * 0.02,
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.15),
                    ElevatedButton(
                      onPressed: () {
                        print('กดปุ่มแล้ว');
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AddNurse()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(
                          screenWidth * 0.16,
                          screenHeight * 0.10,
                        ), // ความกว้าง x ความสูง
                        backgroundColor: const Color.fromARGB(
                          255,
                          255,
                          255,
                          255,
                        ), // สีพื้นหลังปุ่ม
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100), // มุมมน
                        ),
                      ),
                      child: Icon(
                        FontAwesomeIcons.userNurse,
                        color: Colors.black,
                        size: screenHeight * 0.02,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 15),

            Align(
              child: Padding(
                padding: EdgeInsets.only(top: 10, left: 70),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'add Pateint',
                      style: TextStyle(fontWeight: FontWeight.w300),
                    ),
                    SizedBox(width: screenWidth * 0.1),
                    Text(
                      'Send notificaition',
                      style: TextStyle(fontWeight: FontWeight.w300),
                    ),
                    SizedBox(width: screenWidth * 0.1),
                    Text(
                      'add nurse',
                      style: TextStyle(fontWeight: FontWeight.w300),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            Align(
              child: Padding(
                padding: EdgeInsets.only(top: 0, left: 28),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'ประชาสัมพันธ์',
                      style: TextStyle(
                        fontFamily: "Anuphan",
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.bold,
                        color: const Color.fromARGB(255, 0, 0, 0),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(child: content(context)),
          ],
        ),
      ),
    );
  }

  Widget content(BuildContext context) {
    return Container(
      child: CarouselSlider(
        items:
            ['assets/jk/1.jpg', 'assets/jk/2.jpg', 'assets/jk/3.jpg'].map((
              imagePath,
            ) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 5,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.fill,
                    width: MediaQuery.of(context).size.width * 0.5,
                  ),
                ),
              );
            }).toList(),
        options: CarouselOptions(
          height: MediaQuery.of(context).size.height * 0.35,
          autoPlay: true,
          enlargeCenterPage: true,
          aspectRatio: 16 / 9,
          viewportFraction: 0.55,
        ),
      ),
    );
  }
}
