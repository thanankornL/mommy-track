import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';
import 'main.dart';
import 'dart:math';

class PersonalPage extends StatefulWidget {
  const PersonalPage({super.key});

  @override
  State<PersonalPage> createState() => _PersonalPageState();
}

class _PersonalPageState extends State<PersonalPage> {
  String? username;
  String? role;
  String? name;
  Map<String, dynamic>? userJson;
  bool isLoading = true;

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    username = prefs.getString('username');
    role = prefs.getString('role');
    if (username == null || role == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/get_user_data'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'role': role}),
      );

      if (response.statusCode == 200) {
        setState(() {
          userJson = json.decode(response.body);
          name = userJson?['name'];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        throw Exception('Failed to load user data');
      }
    } catch (e) {
      print("Error: $e");
      setState(() {
        isLoading = false;
      });
    }
    print(userJson.toString());
    print(pow(2, (userJson?.length ?? 0)).toString());
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => IntroPage()),
      (route) => false,
    );
  }

  // ฟังก์ชันแสดง Bottom Sheet การตั้งค่า
  void _showSettingsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: EdgeInsets.only(top: 10, bottom: 10),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.arrow_back_ios, size: 20, color: Colors.black),
                    ),
                    SizedBox(width: 10),
                    Text(
                      "การตั้งค่า & ความเป็นส่วนตัว",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),

              // Settings options
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // แก้ไขโปรไฟล์
                      _buildSettingsItem(
                        icon: Icons.person_outline,
                        title: "แก้ไขโปรไฟล์",
                        onTap: () {
                          Navigator.pop(context);
                          // เพิ่มฟังก์ชันแก้ไขโปรไฟล์
                          _showEditProfileDialog();
                        },
                      ),
                      
                      // รักษาความปลอดภัย
                      _buildSettingsItem(
                        icon: Icons.security,
                        title: "รักษาความปลอดภัย",
                        onTap: () {
                          Navigator.pop(context);
                          // เพิ่มฟังก์ชันรักษาความปลอดภัย
                          _showSecurityDialog();
                        },
                      ),
                      
                      // ภาษา
                      _buildSettingsItem(
                        icon: Icons.language,
                        title: "ภาษา",
                        onTap: () {
                          Navigator.pop(context);
                          // เพิ่มฟังก์ชันเปลี่ยนภาษา
                          _showLanguageDialog();
                        },
                      ),

                      Spacer(),

                      // Logout button
                      Padding(
                        padding: const EdgeInsets.only(bottom: 40),
                        child: SizedBox(
                          width: 200,
                          height: 45,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 255, 91, 91),
                              foregroundColor: const Color.fromARGB(255, 255, 255, 255),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              logout();
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.logout, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Logout',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // สร้างรายการการตั้งค่า
  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 15),
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: Colors.black87),
            SizedBox(width: 15),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // Dialog แก้ไขโปรไฟล์
  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("แก้ไขโปรไฟล์"),
        content: Text("ฟังก์ชันนี้จะพัฒนาในอนาคต"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("ตกลง"),
          ),
        ],
      ),
    );
  }

  // Dialog รักษาความปลอดภัย
  void _showSecurityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("รักษาความปลอดภัย"),
        content: Text("ฟังก์ชันนี้จะพัฒนาในอนาคต"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("ตกลง"),
            
          ),
        ],
      ),
    );
  }

  // Dialog เปลี่ยนภาษา
  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("เลือกภาษา"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text("ไทย"),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: Text("English"),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("ยกเลิก"),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    loadUserData();
  }


  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    
    if (isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.lightBlue[200]),
        ),
      );
    }

    if (userJson == null) {
      return const Scaffold(
        body: Center(child: Text("User data not found.")),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFF2E8B57), // Light blue background
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 30),
              child: Text(
                "ข้อมูลของฉัน",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: const Color.fromARGB(255, 255, 255, 255),
                ),
              ),
            ),


            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 255, 255, 255),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(50),
                    topRight: Radius.circular(50),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    
                    // Profile section
                    Padding(
                      padding: const EdgeInsets.only(top: 40, bottom: 20),
                      child: Column(
                        children: [
                          // Profile image
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey[400],
                            backgroundImage: AssetImage("assets/personal_page/profile.png"),
                          ),
                          SizedBox(height: 15),
                          // Display name
                          Text(
                            userJson!['display_name'] ?? "USER",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // User info section
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: ListView(
                          children: [
                            // Build info items
                            ...userJson!.entries.map((entry) {
                              String key = entry.key;
                              String value = entry.value?.toString() ?? '';
                              
                              if (value.isEmpty || 
                                  key == "display_name" || 
                                  key == "lastNotify" || 
                                  key == "action") {
                                return SizedBox.shrink();
                              }

                              String titleText = "";
                              String bodyText = value;

                              if (key == "username") {
                                titleText = "ชื่อผู้ใช้";
                              } else if (key == "GA") {
                                titleText = "อายุครรภ์";
                                int totalDays = int.tryParse(value) ?? 0;
                                int weeks = totalDays ~/ 7;
                                int days = totalDays % 7;
                                bodyText = "$weeks สัปดาห์ $days วัน";
                              } else if (key == "EDC") {
                                titleText = "วันครบกำหนดคลอด";
                              } else if (key == "lastMenstrualPeriod") {
                                titleText = "วันแรกของประจำเดือน";
                                try {
                                  DateTime lmpDate = DateTime.parse(value);
                                  bodyText = "${lmpDate.day.toString().padLeft(2, '0')}/${lmpDate.month.toString().padLeft(2, '0')}/${lmpDate.year}";
                                } catch (e) {
                                  bodyText = value;
                                }
                              } else if (key == "trimester") {
                                titleText = "ไตรมาส";
                              } else if (key == "childDate") {
                                titleText = "วันคลอด";
                                try {
                                  DateTime childDate = DateTime.parse(value);
                                  bodyText = "${childDate.day.toString().padLeft(2, '0')}/${childDate.month.toString().padLeft(2, '0')}/${childDate.year}";
                                } catch (e) {
                                  bodyText = value;
                                }
                              } else if (key == "phone") {
                                titleText = "เบอร์ติดต่อ";
                              } else {
                                titleText = key;
                              }

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      titleText,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        bodyText,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),

                            SizedBox(height: 30),

                            // Settings option - เพิ่ม GestureDetector
                            GestureDetector(
                              onTap: _showSettingsBottomSheet, // เรียกใช้ Bottom Sheet
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(35),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.settings, size: 24, color: Colors.black),
                                    SizedBox(width: 15),
                                    Expanded(
                                      child: Text(
                                        "การตั้งค่า & ความเป็นส่วนตัว",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                                  ],
                                ),
                              ),
                            ),

      
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class UserPage extends StatelessWidget {
  const UserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('User Profile')),
      body: Center(
        child: Text('หน้า User Profile'),
      ),
    );
  }
}