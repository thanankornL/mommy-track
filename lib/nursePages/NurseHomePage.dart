import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_image_slideshow/flutter_image_slideshow.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:carebellmom/patient_management/patients_management.dart';
import '../nursePages/AddNurse.dart';
import '../notification.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

import 'package:carebellmom/chatting/chat_list_screen.dart';

class NurseHomePage extends StatefulWidget {
  const NurseHomePage({super.key});

  @override
  State<NurseHomePage> createState() => _NurseHomePage();
}

class _NurseHomePage extends State<NurseHomePage> {
  late String formattedTime;
  late Timer _timer;

  // เพิ่มตัวแปรสำหรับเก็บข้อมูลผู้ใช้
  String? username;
  String? role;
  String? displayName;
  Map<String, dynamic>? userJson;
  bool isLoading = true;

  // สีธีมใหม่ - สีเขียวทางการแพทย์
  static const Color primaryGreen = Color(0xFF2E8B57); // Sea Green
  static const Color lightGreen = Color(0xFF90EE90); // Light Green
  static const Color darkGreen = Color(0xFF006B3C); // Dark Green
  static const Color accentGreen = Color(0xFF00C851); // Accent Green
  static const Color backgroundColor = Color(0xFFF0F8F0); // Very Light Green
  static const Color cardColor = Color(0xFFFFFFFF); // White
  static const Color textPrimary = Color(0xFF2C3E50); // Dark Blue Grey
  static const Color textSecondary = Color(0xFF5D6D7E); // Light Blue Grey

  @override
  void initState() {
    super.initState();
    _updateTime(); // เรียกตอนเริ่ม
    _timer = Timer.periodic(Duration(seconds: 1), (Timer t) => _updateTime());
    loadUserData(); // โหลดข้อมูลผู้ใช้
    loadPatientsData();
  }

  // ฟังก์ชันโหลดข้อมูลผู้ใช้
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
          displayName =
              userJson?['display_name'] ?? userJson?['name'] ?? username;
          isLoading = false;
        });
      } else {
        setState(() {
          displayName = username; // ใช้ username เป็น fallback
          isLoading = false;
        });
        throw Exception('Failed to load user data');
      }
    } catch (e) {
      print("Error: $e");
      setState(() {
        displayName = username; // ใช้ username เป็น fallback
        isLoading = false;
      });
    }
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

  // ฟังก์ชันสำหรับไปหน้าแชท

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    // แสดง loading ขณะโหลดข้อมูล
    if (isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: const Color(0xFF2E8B57), strokeWidth: 3),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: EdgeInsets.only(bottom: screenHeight * 0.01, left: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.medical_services,
                      color: Colors.white,
                      size: screenWidth * 0.06,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "ยินดีต้อนรับ ${displayName ?? 'ผู้ใช้'}",
                      style: TextStyle(
                        fontFamily: "Inter",
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
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
                  bottom: screenHeight * 0.03,
                  left: 20.0,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Mommy track - ระบบดูแลผู้ป่วย",
                      style: TextStyle(
                        fontFamily: "Inter",
                        fontSize: screenWidth * 0.035,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    Icon(Icons.local_hospital, color: lightGreen, size: 20),
                  ],
                ),
              ),
            ),

            Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.people, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'ผู้ป่วย: ${patientsList.length} ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        formattedTime,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
        toolbarHeight: 180,
        backgroundColor: primaryGreen,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryGreen, darkGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
      ),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Column(
          children: [
            SizedBox(height: screenHeight * 0.03),

            // หัวข้อหมวดหมู่
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(Icons.dashboard_outlined, color: primaryGreen, size: 24),
                  SizedBox(width: 8),
                  Text(
                    "เมนูการจัดการ",
                    style: TextStyle(
                      fontFamily: "Anuphan",
                      fontSize: screenWidth * 0.05,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.03),

            // แถวแรกของปุ่ม - เลื่อนได้ซ้าย-ขวา
            SizedBox(
              height: screenHeight * 0.15, // กำหนดความสูงให้กับ container
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _buildMenuButton(
                      context: context,
                      icon: Icons.person_add_rounded,
                      label: 'เพิ่มคนไข้',
                      color: accentGreen,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserManagementPage(),
                          ),
                        );
                      },
                    ),
                    SizedBox(width: 20),
                    _buildMenuButton(
                      context: context,
                      icon: Icons.notification_add,
                      label: 'ส่งการแจ้งเตือน',
                      color: Colors.orange[600]!,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => sendNotification(),
                          ),
                        );
                      },
                    ),
                    SizedBox(width: 20),
                    _buildMenuButton(
                      context: context,
                      icon: FontAwesomeIcons.userNurse,
                      label: 'เพิ่มพยาบาล',
                      color: primaryGreen,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AddNurse()),
                        );
                      },
                    ),
                    SizedBox(width: 20),
                    _buildMenuButton(
                      context: context,
                      icon: Icons.chat_bubble_outline,
                      label: 'แชทกับคนไข้',
                      color: Colors.blue[600]!,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => ChatListScreen(
                                  username: username!,
                                  userRole: 'nurse',
                                  displayName: displayName!,
                                ),
                          ),
                        );
                      },
                    ),
                    SizedBox(width: 20),
                    _buildMenuButton(
                      context: context,
                      icon: Icons.settings,
                      label: 'ตั้งค่า',
                      color: Colors.grey[600]!,
                      onPressed: () {
                        // จะเพิ่มฟังก์ชันตั้งค่าในอนาคต
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'ฟีเจอร์ตั้งค่าจะเปิดใช้งานเร็วๆ นี้',
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(width: 20),
                  ],
                ),
              ),
            ),

            // แถวที่สองของปุ่ม - ปุ่มแชท
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(Icons.analytics_outlined, color: primaryGreen),
                  SizedBox(width: 8),
                  Text(
                    "รายงานสถิติ",
                    style: TextStyle(
                      fontFamily: "Anuphan",
                      fontSize: screenWidth * 0.05,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            
            buildPatientsTable(),
            SizedBox(height: screenHeight * 0.02),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(Icons.campaign_outlined, color: primaryGreen, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'ข่าวสารและประชาสัมพันธ์',
                    style: TextStyle(
                      fontFamily: "Anuphan",
                      fontSize: screenWidth * 0.05,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.02),

            // Carousel
            SizedBox(height: screenHeight * 0.3, child: content(context)),

            SizedBox(height: screenHeight * 0.05),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool isLarge = false,
  }) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    // กำหนดขนาดปุ่มที่คงที่เพื่อให้เลื่อนได้
    double buttonWidth = isLarge ? 100 : 80;
    double buttonHeight = isLarge ? 100 : 80;

    return Column(
      children: [
        Container(
          width: buttonWidth,
          height: buttonHeight,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
            border: Border.all(color: color.withOpacity(0.3), width: 2),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onPressed,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Icon(icon, color: color, size: isLarge ? 30 : 24),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 8),
        SizedBox(
          width: buttonWidth,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: isLarge ? 12 : 10,
              color: textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget content(BuildContext context) {
    return CarouselSlider(
      items:
          ['assets/jk/1.jpg', 'assets/jk/2.jpg', 'assets/jk/3.jpg'].map((
            imagePath,
          ) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: primaryGreen.withOpacity(0.3),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
                border: Border.all(
                  color: primaryGreen.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  children: [
                    Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                      width: MediaQuery.of(context).size.width * 0.55,
                      height: double.infinity,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
      options: CarouselOptions(
        height: MediaQuery.of(context).size.height * 0.8,
        autoPlay: true,
        enlargeCenterPage: true,
        aspectRatio: 16 / 9,
        viewportFraction: 0.7,
      ),
    );
  }

  // เพิ่มใน NurseHomePage class

  // เพิ่มตัวแปรสำหรับเก็บข้อมูลผู้ป่วย
  List<Map<String, dynamic>> patientsList = [];
  bool isLoadingPatients = false;

  // ฟังก์ชันดึงข้อมูลผู้ป่วยจาก API
  Future<void> loadPatientsData() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/patients_data'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        List<Map<String, dynamic>> patients = [];

        for (var userData in data) {
          String username = userData['username'] ?? '';
          String displayName = userData['display_name'] ?? '';
          int? action = userData['action'];
          // แปลง action เป็นข้อความ
          String actionText = await getActionText(action);
          String statusText = getStatusFromAction(action);
          Color statusColor = getStatusColor(action);

          patients.add({
            'username': username,
            'displayName': displayName,
            'action': action,
            'actionText': actionText,
            'statusText': statusText,
            'statusColor': statusColor,
            'room':
                'A${(patients.length + 1).toString().padLeft(2, '0')}', // สร้างหมายเลขห้องชั่วคราว
            'temperature': getRandomTemperature(
              action,
            ), // สร้างอุณหภูมิชั่วคราว
          });
        }

        setState(() {
          patientsList = patients;
          isLoadingPatients = false;
        });
      } else {
        throw Exception('Failed to load patients data');
      }
    } catch (e) {
      print("Error loading patients: $e");
      setState(() {
        isLoadingPatients = false;
      });
    }
  }

  // ฟังก์ชันแปลง action เป็นข้อความ
  Future<String> getActionText(int? action) async {
    if (action == null) return '';

    switch (action) {
      case 0:
        return "การแจ้งเตือนครั้งที่ 1";
      case 1:
        return "การแจ้งเตือนครั้งที่ 2";
      case 2:
        return "การแจ้งเตือนครั้งที่ 3";
      case 3:
        return "การแจ้งเตือนครั้งที่ 4";
      case 4:
        return "การแจ้งเตือนครั้งที่ 5";
      case 5:
        return "การแจ้งเตือนครั้งที่ 6";
      case 6:
        return "การแจ้งเตือนครั้งที่ 7";
      case 7:
        return "การแจ้งเตือนครั้งที่ 8";
      case 9:
        return "คลอดแล้ว";
      default:
        return "ไม่ระบุ";
    }
  }

  // ฟังก์ชันแปลง action เป็นสถานะ
  String getStatusFromAction(int? action) {
    if (action == null) return 'ไม่ระบุ';

    if (action >= 0 && action <= 3) {
      return 'ปกติ';
    } else if (action >= 4 && action <= 7) {
      return 'ต้องติดตาม';
    } else if (action == 9) {
      return 'คลอดแล้ว';
    } else {
      return 'ไม่ระบุ';
    }
  }

  // ฟังก์ชันกำหนดสีตามสถานะ
  Color getStatusColor(int? action) {
    if (action == null) return Colors.grey;

    if (action >= 0 && action <= 3) {
      return Colors.green;
    } else if (action >= 4 && action <= 7) {
      return Colors.orange;
    } else if (action == 9) {
      return Colors.blue;
    } else {
      return Colors.grey;
    }
  }

  // ฟังก์ชันสร้างอุณหภูมิชั่วคราว (ควรแทนที่ด้วยข้อมูลจริง)
  String getRandomTemperature(int? action) {
    if (action == null) return '36.5°C';

    if (action >= 0 && action <= 3) {
      return ['36.2°C', '36.5°C', '36.8°C', '36.3°C'][action % 4];
    } else if (action >= 4 && action <= 7) {
      return ['37.2°C', '37.5°C', '37.8°C', '37.1°C'][action % 4];
    } else if (action == 9) {
      return '36.5°C';
    } else {
      return '36.5°C';
    }
  }

  // แทนที่ตารางเดิมด้วยตารางใหม่ที่ใช้ข้อมูลจาก API
  Widget buildPatientsTable() {
    if (isLoadingPatients) {
      return SingleChildScrollView(
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              padding: EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
                border: Border.all(color: primaryGreen.withOpacity(0.3)),
              ),
              child: Center(
                child: CircularProgressIndicator(color: primaryGreen),
              ),
            ),
          ],
        ),
      );
    }

    if (patientsList.isEmpty) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 20),
        padding: EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
          border: Border.all(color: primaryGreen.withOpacity(0.3)),
        ),
        child: Center(
          child: Text(
            'ไม่พบข้อมูลผู้ป่วย',
            style: TextStyle(color: textSecondary, fontSize: 16),
          ),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: primaryGreen.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // หัวข้อและสถิติ
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'รายชื่อผู้ป่วย (${patientsList.length} คน)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: textPrimary,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'ปกติ ${patientsList.where((p) => p['statusText'] == 'ปกติ').length} | ติดตาม ${patientsList.where((p) => p['statusText'] == 'ต้องติดตาม').length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // หัวตาราง
          Container(
            padding: EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'ชื่อผู้ป่วย',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'ห้อง',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'สถานะ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'อุณหภูมิ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),

          // ListView สำหรับข้อมูลผู้ป่วย - เลื่อนได้และมีประสิทธิภาพดี
          SizedBox(
            height: 400, // กำหนดความสูง
            child: ListView.separated(
              physics: BouncingScrollPhysics(),
              itemCount: patientsList.length,
              separatorBuilder: (context, index) => SizedBox(height: 4),
              itemBuilder: (context, index) {
                final patient = patientsList[index];
                return _buildPatientRowFromData(
                  patient['displayName'],
                  patient['room'],
                  patient['statusText'],
                  patient['temperature'],
                  patient['statusColor'],
                  patient['username'],
                  patient['actionText'],
                );
              },
            ),
          ),

          // ปุ่มรีเฟรช
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: loadPatientsData,
                icon: Icon(Icons.refresh, size: 16),
                label: Text('รีเฟรชข้อมูล'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  // เพิ่มฟังก์ชันดูรายละเอียดทั้งหมด
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: Text('สรุปสถิติผู้ป่วย'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildStatCard(
                                'ปกติ',
                                patientsList
                                    .where((p) => p['statusText'] == 'ปกติ')
                                    .length,
                                Colors.green,
                              ),
                              _buildStatCard(
                                'ต้องติดตาม',
                                patientsList
                                    .where(
                                      (p) => p['statusText'] == 'ต้องติดตาม',
                                    )
                                    .length,
                                Colors.orange,
                              ),
                              _buildStatCard(
                                'คลอดแล้ว',
                                patientsList
                                    .where((p) => p['statusText'] == 'คลอดแล้ว')
                                    .length,
                                Colors.blue,
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('ปิด'),
                            ),
                          ],
                        ),
                  );
                },
                icon: Icon(Icons.analytics, size: 16),
                label: Text('สถิติ'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryGreen,
                  side: BorderSide(color: primaryGreen),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // เพิ่มฟังก์ชันสำหรับแสดงสถิติ
  Widget _buildStatCard(String label, int count, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ฟังก์ชันสร้างแถวข้อมูลผู้ป่วยจากข้อมูล API
  Widget _buildPatientRowFromData(
    String name,
    String room,
    String status,
    String temp,
    Color statusColor,
    String username,
    String actionText,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: GestureDetector(
        onTap: () {
          // แสดงรายละเอียดเพิ่มเติมเมื่อแตะ
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: Text('รายละเอียดผู้ป่วย'),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('ชื่อ: $name'),
                      Text('Username: $username'),
                      Text('ห้อง: $room'),
                      Text('สถานะ: $status'),
                      Text('อุณหภูมิ: $temp'),
                      Text('Action: $actionText'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('ปิด'),
                    ),
                  ],
                ),
          );
        },
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 13,
                      color: textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    username,
                    style: TextStyle(fontSize: 10, color: textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                room,
                style: TextStyle(fontSize: 13, color: textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                temp,
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSummary() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'สรุปสถานะผู้ป่วย',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatusIndicator('ปกติ', Colors.green),
                  _buildStatusIndicator('เสี่ยง', Colors.orange),
                  _buildStatusIndicator('วิกฤต', Colors.red),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(String label, Color color) {
    return Column(
      children: [
        CircleAvatar(radius: 10, backgroundColor: color),
        SizedBox(height: 4),
        Text(label),
      ],
    );
  }

  // ในส่วน build method แทนที่ตารางเดิมด้วย
}
