import 'package:carebellmom/chatting/chat_list_screen.dart';
import 'package:carebellmom/notification.dart';
import 'package:carebellmom/patientPages/Chatbot_index_patient.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_image_slideshow/flutter_image_slideshow.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:carebellmom/patientPages/Chatbot_index_patient.dart';
import 'package:carebellmom/patientPages/viewDetails.dart';
import 'package:carebellmom/PersonalPage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carebellmom/config.dart';
import 'dart:math';
import 'package:carebellmom/chatting/chat_list_screen.dart';

class PatientHomePage extends StatefulWidget {
  const PatientHomePage({super.key});

  @override
  _PatientHomePage createState() => _PatientHomePage();
}

class _PatientHomePage extends State<PatientHomePage> {
  String? username;
  String? role;
  String? name;
  String? action;
  String? displayName;
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
          displayName =
              userJson?['display_name'] ?? userJson?['name'] ?? username;
          action = userJson?['action']?.toString() ?? '';
          isLoading = false;
        });
      } else {
        setState(() {
          displayName = username; // fallback
          isLoading = false;
        });
        throw Exception('Failed to load user data');
      }
    } catch (e) {
      print("Error: $e");
      setState(() {
        displayName = username; // fallback
        isLoading = false;
      });
    }
  }

  // Function to get AI food recommendation
  Future<void> getAIFoodRecommendation() async {
    try {
      int totalDays = int.tryParse(userJson?['GA']?.toString() ?? '0') ?? 0;
      int weeks = totalDays ~/ 7;

      final response = await http.post(
        Uri.parse('$baseUrl/api/ai_food_recommendation'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'gestational_weeks': weeks,
          'user_data': userJson,
          'action': action,
        }),
      );

      if (response.statusCode == 200) {
        final recommendation = json.decode(response.body);
        _showFoodRecommendationDialog(recommendation['recommendation']);
      } else {
        _showErrorDialog('ไม่สามารถรับคำแนะนำจาก AI ได้ในขณะนี้');
      }
    } catch (e) {
      print("Error getting AI recommendation: $e");
      _showErrorDialog('เกิดข้อผิดพลาดในการเชื่อมต่อ');
    }
  }

  void _showFoodRecommendationDialog(String recommendation) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.smart_toy, color: Colors.blue),
              SizedBox(width: 8),
              Text('คำแนะนำอาหารจาก AI'),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(
              recommendation,
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('ปิด'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('เกิดข้อผิดพลาด'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('ปิด'),
            ),
          ],
        );
      },
    );
  }

  // ฟังก์ชันสำหรับไปหน้าแชท
  void _navigateToChat() {
    if (username != null && displayName != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => ChatListScreen(
                username: username!,
                userRole: 'patient',
                displayName: displayName!,
              ),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    loadUserData();
     
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) { 

      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFA8D5BA)),
        ),
      );
    }

    int totalDays = int.tryParse(userJson?['GA']?.toString() ?? '0') ?? 0;
    int weeks = totalDays ~/ 7;
    int days = totalDays % 7;
    String actionDisplay = action ?? '';
    String usernameDisplay = username ?? '';

    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Color(0xFFE8F5E8),
      body: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 20,
                left: 20,
                right: 20,
                bottom: 20,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ยินดีต้อนรับเข้าสู่ Mommy Track',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      Text(
                        'คุณ : $usernameDisplay',
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    ],
                  ),
                  IconButton.outlined(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => NotificationPage()),
                      );
                    },
                    icon: Icon(Icons.notifications),
                  ),
                ],
              ),
            ),

            // Pregnancy Info Card
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.orange, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.pink[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.pregnant_woman,
                      size: 50,
                      color: Colors.pink[300],
                    ),
                  ),
                  SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'การแจ้งเตือนครั้งที่ : $actionDisplay',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        '$weeks Weeks $days Day',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Appointment Button
         

            // AI Food Recommendation Card
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Chatbot_index_patient(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    padding: EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.smart_toy,
                            size: 30,
                            color: Colors.blue[600],
                          ),
                        ),
                        SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'สวัสดีค่ะ',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'มีอะไรให้ช่วยคะ?',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Chat with Nurse Button - แก้ไขการเรียก ChatListScreen
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: ElevatedButton(
                onPressed: _navigateToChat, // ใช้ฟังก์ชันที่แก้ไขแล้ว
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFA8D5BA),
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_outline, color: Colors.black),
                    SizedBox(width: 10),
                    Text(
                      'แชทกับพยาบาล',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Statistics Section
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                children: [
                  Text(
                    'สัดส่วนโภชนาการ',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      // Pie Chart (you can replace with actual chart widget)
                      Expanded(
                        flex: 1,
                        child: SizedBox(
                          height: 150,
                          child: CustomPaint(
                            painter: PieChartPainter(),
                            child: Container(),
                          ),
                        ),
                      ),
                      SizedBox(width: 20),
                      // Legend
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLegendItem(
                              Colors.blue,
                              'คาร์โบไฮเดรต',
                              '40%',
                            ),
                            _buildLegendItem(Colors.orange, 'โปรตีน', '25%'),
                            _buildLegendItem(Colors.yellow, 'ไขมัน', '20%'),
                            _buildLegendItem(Colors.green, 'วิตามิน', '10%'),
                            _buildLegendItem(Colors.purple, 'เกลือแร่', '5%'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Add more content to demonstrate scrolling
            SizedBox(height: 20),

            // Additional content sections
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'เคล็ดลับสำหรับคุณแม่',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 15),

                  // Tip cards
                  _buildTipCard(
                    icon: Icons.local_drink,
                    title: 'ดื่มน้ำให้เพียงพอ',
                    description: 'ดื่มน้ำอย่างน้อย 8-10 แก้วต่อวัน',
                    color: Colors.blue,
                  ),
                  SizedBox(height: 10),

                  _buildTipCard(
                    icon: Icons.fitness_center,
                    title: 'ออกกำลังกายเบาๆ',
                    description: 'เดิน โยคะคนท้อง หรือว่ายน้ำ',
                    color: Colors.green,
                  ),
                  SizedBox(height: 10),

                  _buildTipCard(
                    icon: Icons.bedtime,
                    title: 'พักผ่อนให้เพียงพอ',
                    description: 'นอนหลับ 7-9 ชั่วโมงต่อวัน',
                    color: Colors.purple,
                  ),
                  SizedBox(height: 10),

                  _buildTipCard(
                    icon: Icons.restaurant,
                    title: 'รับประทานอาหารครบ 5 หมู่',
                    description: 'เน้นผักใส่ ผลไม้ และโปรตีน',
                    color: Colors.orange,
                  ),
                ],
              ),
            ),

            // Weekly progress section
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ความก้าวหน้ารายสัปดาห์',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 15),

                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('น้ำหนัก'),
                            Text(
                              '65.5 kg',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('ความดันโลหิต'),
                            Text(
                              '120/80 mmHg',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('อัตราการเต้นของหัวใจเด็ก'),
                            Text(
                              '145 BPM',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Add padding at bottom for better scrolling
            SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, String percentage) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 8),
          Expanded(child: Text(label, style: TextStyle(fontSize: 12))),
          Text(
            percentage,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// Custom Pie Chart Painter
class PieChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..style = PaintingStyle.fill;
    final Rect rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: size.width / 2,
    );

    // Draw pie segments
    double startAngle = 0;
    final segments = [
      {'color': Colors.blue, 'value': 0.4},
      {'color': Colors.orange, 'value': 0.25},
      {'color': Colors.yellow, 'value': 0.2},
      {'color': Colors.green, 'value': 0.1},
      {'color': Colors.purple, 'value': 0.05},
    ];

    for (var segment in segments) {
      paint.color = segment['color'] as Color;
      double sweepAngle = 2 * pi * (segment['value'] as double);
      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);
      startAngle += sweepAngle;
    }

    // Draw center circle for donut effect
    paint.color = Colors.white;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 4,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class NavigationProvider extends ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void setCurrentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }
}
