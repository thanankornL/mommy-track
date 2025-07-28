import 'package:carebellmom/patientPages/PatientHomePage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';
import 'package:carebellmom/adminPages/admin.dart';
import 'package:carebellmom/nursePages/nurse.dart';
import 'package:carebellmom/patientPages/patient.dart';
import 'package:flutter/services.dart';
import 'package:page_transition/page_transition.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';
//import 'package:provider/provider.dart';


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
  runApp(const MaterialApp(home: MyApp()));
}
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyApp();
}

class _MyApp extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: const Color(0xffffffff),

        // Main colors
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(
            255,
            255,
            88,
            130,
          ), // Your primary color
          brightness: Brightness.light,
        ),

        // AppBar styling
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(255, 255, 88, 130),
          foregroundColor: Colors.white,
          elevation: 0,
        ),

        // Button style
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 255, 88, 130), // Primary
            foregroundColor: Colors.white, // Text color
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: IntroPage(),
    );
  }
}

class IntroPage extends StatelessWidget {
  const IntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Container(
        /*
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color.fromARGB(255, 249, 184, 255), Colors.white],
          ),
        ),*/
        child: Column(
          children: [
           
            Align(
              alignment: Alignment.topLeft, // จัดตำแหน่งที่มุมบนซ้าย
              child: Padding(
                padding: EdgeInsets.only(
                  top: screenHeight*0.3,
                  left: screenWidth * 0.0155,
                ), // ระยะห่างจากขอบบนและซ้าย
                  child: Image.asset(
              'assets/index_page/Unknown.gif',
              height: screenHeight * 0.3, // 30% of the screen height
              width: screenWidth * 0.8, // 50% of the screen width
              fit: BoxFit.contain, // Ensures the image scales proportionally
            ),// โลโก้
              ),
            ),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
              child: Text(
                """Mommy treck แอปพลิเคชันที่จะช่วยคุณ
  จัดการการตั้งครรภ์และบันทึกสุขภาพ 
  และรับคำแนะนำจากผู้เชี่ยวชาญอย่างใกล้ชิด
                
                """,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: "Inter",
                  fontSize: screenHeight * 0.021,
                  fontWeight: FontWeight.w400,
                  color: const Color.fromARGB(255, 136, 136, 136),
                ),
              ),
            ),

            SizedBox(height: 10),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: EdgeInsets.only(
                  top: screenHeight * 0.065,
                  left: screenWidth * 0.75,
                ),
                child: Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          PageTransition(
                            type:
                                PageTransitionType.rightToLeft, // หรือแบบอื่นๆ
                            child: ConsentPage(), // หน้าถัดไป
                            duration: Duration(
                              milliseconds: 300,
                            ), // ความเร็วของ transition (ไม่บังคับ)
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(
                          screenWidth * 0.2,
                          screenHeight * 0.10,
                        ),
                        backgroundColor: const Color.fromARGB(
                          255,
                          255,
                          255,
                          255,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30), // มุมมน
                        ),
                        shadowColor: Colors.grey,
                      ),
                      child: Icon(
                        Icons.arrow_right_alt_sharp,
                        size: screenHeight * 0.03,
                        color: const Color.fromARGB(255, 21, 150, 255),
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

class ConsentPage extends StatefulWidget {
  const ConsentPage({super.key});

  @override
  State<ConsentPage> createState() => _ConsentPageState();
}

class _ConsentPageState extends State<ConsentPage> {
  bool isChecked = false;

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: EdgeInsets.only(top: screenHeight * 0.08),
                child: Row(
                  children: [
                    Text(
                      'ขอสิทธิ์การขอเข้าถึงข้อมูล',
                      style: TextStyle(
                        fontSize: screenHeight * 0.025,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: screenHeight*0.03,),
            Expanded(
                  child:  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Container(
                      height:
                          screenHeight *
                          0.9, 
                      width: screenWidth*4,// ✅ กำหนดความสูงเพื่อให้เลื่อนภายในได้
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 5,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        // ✅ ห่อด้วย scroll view ภายใน
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'เราอาจมีการเก็บข้อมูลส่วนบุคคลของคุณ เช่น',
                              style: TextStyle(
                                fontSize: screenHeight * 0.018,
                                height: 1.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '- ชื่อ\n- อายุ\n- วันคลอด\n- ข้อมูลสุขภาพ',
                              style: TextStyle(
                                fontSize: screenHeight * 0.018,
                                height: 1.5,
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'คุณสามารถเพิกถอนความยินยอมเมื่อใดก็ได้ผ่านเมนูการตั้งค่าในแอปพลิเคชัน หรือสามารถติดต่อผู้ให้บริการเพื่อดำเนินการดังกล่าว',
                              style: TextStyle(
                                fontSize: screenHeight * 0.018,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.justify,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'การให้ความยินยอมนี้เป็นไปโดยสมัครใจ และจะไม่มีผลกระทบต่อการเข้ารับบริการขั้นพื้นฐานหากคุณเลือกที่จะไม่ยินยอม',
                              style: TextStyle(
                                fontSize: screenHeight * 0.018,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.justify,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'ข้อมูลของคุณจะไม่ถูกเปิดเผยแก่บุคคลภายนอก เว้นแต่จะได้รับความยินยอมจากคุณล่วงหน้า หรือในกรณีที่กฎหมายกำหนดให้เปิดเผยเท่านั้น',
                              style: TextStyle(
                                fontSize: screenHeight * 0.018,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.justify,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'แอปพลิเคชันนี้มุ่งมั่นในการรักษาความลับและความปลอดภัยของข้อมูลของคุณอย่างสูงสุด โดยมีมาตรการด้านเทคนิคและการจัดการเพื่อป้องกันการเข้าถึงโดยไม่ได้รับอนุญาต',
                              style: TextStyle(
                                fontSize: screenHeight * 0.018,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.justify,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
            ),
            SizedBox(height:  screenHeight*0.03),
            Row(
              children: [
                Checkbox(
                  value: isChecked,
                  onChanged: (value) {
                    setState(() {
                      isChecked = value!;
                    });
                  },
                  activeColor: Colors.pink,
                ),
                Expanded(
                  child: Text(
                    "ข้าพเจ้ายินยอมให้แอปเก็บรวบรวมและใช้ข้อมูลของข้าพเจ้า",
                    style: TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),

            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: EdgeInsets.only(
                  top: screenHeight * 0.12,
                  left: screenWidth * 0.7,
                ),
                child: Row(
                  children: [
                    ElevatedButton(
                      onPressed:
                          isChecked
                              ? () {
                                // ดำเนินการต่อเมื่อยินยอม
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LoginForm(),
                                  ),
                                ); // หรือไปหน้าถัดไป
                              }
                              : null,
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(
                          screenWidth * 0.08,
                          screenHeight * 0.10,
                        ), // ความกว้าง x ความสูง
                        backgroundColor: const Color.fromARGB(
                          255,
                          255,
                          255,
                          255,
                        ), // สีพื้นหลังปุ่ม
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30), // มุมมน
                        ),
                        shadowColor: Colors.grey,
                      ),
                      child: Icon(
                        Icons.arrow_right_alt_sharp,
                        size: 40,
                        color: const Color.fromARGB(255, 21, 150, 255),
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

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  bool _showPassword = false;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _togglePasswordVisibility() {
    setState(() {
      _showPassword = !_showPassword;
    });
  }

  Future<void> _login() async {
    final username = _usernameController.text;
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter both username and password"),
        ),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', username);
        await prefs.setString('role', data['role']);
        await prefs.setString('name', data['name']);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Login successful! Welcome ${data['name']}")),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => UserPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Login failed: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("An error occurred: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Container(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 20,
              left: 10.0,
              child: Image.asset("assets/intro_page/pic0.png", height: 40),
            ),

            Positioned(
              top: 59,
              left: 0,
              right: 0,
              child: Center(
                child: Image.asset("assets/login_page/pic2.png", height: 250),
              ),
            ),

            Positioned(
              top: 250,
              left: 40,
              right: 40,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Login",
                      style: TextStyle(
                        fontSize: screenWidth * 0.095,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            offset: Offset(2, 2),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 25),
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: "Username",
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      decoration: InputDecoration(
                        labelText: "Password",
                        prefixIcon: Icon(Icons.lock),
                        suffixIcon: GestureDetector(
                          onTap: _togglePasswordVisibility,
                          child: Icon(
                            _showPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Checkbox(
                          value: _showPassword,
                          onChanged: (bool? value) {
                            _togglePasswordVisibility();
                          },
                        ),
                        Text("Show Password"),
                      ],
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Color.fromARGB(255, 191, 247, 191),
                        
                      ),
                      child: Text(
                        "Login",
                        style: TextStyle(fontSize: 18, color: const Color.fromARGB(255, 0, 0, 0)),
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

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  _UserPageState createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  final NotchBottomBarController _controller = NotchBottomBarController(
    index: 1,
  );
  final int _currentIndex = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<String>(
        future: SharedPreferences.getInstance().then(
          (prefs) => prefs.getString('role') ?? 'user',
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else {
            return getWidgetByRole(snapshot.data ?? 'user');
          }
        },
      ),
    );
  }
}

Widget getWidgetByRole(String role) {
  switch (role) {
    case 'nurse':
      return NursePage();
    case 'admin':
      return AdminPage();
    case 'patient':
    default:
      return PatientPage();
  }
}

