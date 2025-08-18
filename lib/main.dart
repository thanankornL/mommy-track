import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  await dotenv.load(fileName: '.env');
  runApp(const MyApp());
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
        child: Column(
          children: [
            Align(
              alignment: Alignment.topLeft, 
              child: Padding(
                padding: EdgeInsets.only(
                  top: screenHeight * 0.3,
                  left: screenWidth * 0.0155,
                ), 
                child: Image.asset(
                  'assets/index_page/Unknown.gif',
                  height: screenHeight * 0.3, // 30% of the screen height
                  width: screenWidth * 0.8, // 50% of the screen width
                  fit:
                      BoxFit.contain, // Ensures the image scales proportionally
                ), // โลโก้
              ),
            ),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
              child: Text(
                """Mommy treckแอปพลิเคชันที่จะช่วยคุณจัดการการตั้งครรภ์และบันทึกสุขภาพและรับคำแนะนำจากผู้เชี่ยวชาญอย่างใกล้ชิด""",
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
  State<ConsentPage> createState() => _ConsentPage();
}

class _ConsentPage extends State<ConsentPage> {
  bool _hasScrolledToBottom = false;
  bool _isConsentChecked = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50) {
      if (!_hasScrolledToBottom) {
        setState(() {
          _hasScrolledToBottom = true;
        });
      }
    }
  }

  void _onConsentChanged(bool? value) {
    if (_hasScrolledToBottom) {
      setState(() {
        _isConsentChecked = value ?? false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาอ่านข้อมูลให้ครบถ้วนก่อนให้ความยินยอม'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  // แก้ไขในฟังก์ชัน _onAccept() ในคลาส _ConsentPage

  void _onAccept() {
    if (!_isConsentChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณายืนยันการยินยอมก่อนดำเนินการต่อ'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(),
          actions: [
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    // ปิด dialog ก่อน
                    Navigator.of(context).pop();

                    // ใช้ pushAndRemoveUntil เพื่อลบหน้าก่อนหน้าทั้งหมด
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => LoginForm()),
                      (route) => false, // ลบหน้าทั้งหมดใน stack
                    );
                  },
                  child: const Text('ตกลง'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _onDecline() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: const [
              Icon(Icons.info, color: Colors.orange),
              SizedBox(width: 8),
              Text('ยืนยันการไม่ยินยอม'),
            ],
          ),
          content: const Text(
            'หากคุณไม่ยินยอม เราจะไม่สามารถให้บริการบางอย่างแก่คุณได้ คุณแน่ใจหรือไม่?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Handle decline action
                // Navigator.pushReplacementNamed(context, '/login');
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('ไม่ยินยอม'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2A8854), Color(0xFF046E3E)],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4CAF50).withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.lock,
                        size: 40,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'ความเป็นส่วนตัว',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 255, 255, 255),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'เพื่อการดูแลสุขภาพที่ดีที่สุด',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color.fromARGB(255, 255, 255, 255),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Column(
                  children: [
                    // Scrollable content
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // App description
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE5FFEB).withOpacity(0.3),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFE5FFEB),
                                  width: 2,
                                ),
                              ),
                              child: const Text(
                                'แอปพลิเคชันนี้จัดทำขึ้นเพื่อใช้เป็นเครื่องมือสนับสนุนการดูแลสุขภาพของมารดาและทารก โดยมีวัตถุประสงค์เพื่อบันทึกข้อมูลสุขภาพ การนัดหมาย การฉีดวัคซีน คำแนะนำด้านโภชนาการ การเติบโตของทารก และข้อมูลที่เกี่ยวข้องกับการตั้งครรภ์และการคลอดบุตร เพื่อให้บริการด้านสุขภาพผ่านเทคโนโลยีสารสนเทศอย่างมีประสิทธิภาพ',
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.6,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            const Text(
                              'เพื่อให้แอปสามารถทำงานได้อย่างครบถ้วน ท่านในฐานะเจ้าของข้อมูล โปรดอ่านและพิจารณาคำยินยอม ต่อไปนี้อย่างละเอียดก่อนทำเครื่องหมายยอมรับ:',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.6,
                                color: Color(0xFF424242),
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            const SizedBox(height: 24),

                            _buildSection(
                              '1. วัตถุประสงค์ในการเก็บข้อมูล',
                              'เราจะเก็บรวบรวม ใช้ และ/หรือเปิดเผยข้อมูลของท่านเพื่อ:',
                              [
                                'บันทึกประวัติสุขภาพของมารดาและทารก',
                                'แสดงข้อมูลการตั้งครรภ์ อาทิ วันคลอดโดยประมาณ น้ำหนักแม่ในแต่ละช่วง อาการผิดปกติ ฯลฯ',
                                'แจ้งเตือนการฉีดวัคซีนที่จำเป็น',
                                'แสดงคำแนะนำด้านสุขภาพ โภชนาการ และพฤติกรรมที่เหมาะสมในแต่ละช่วงการตั้งครรภ์',
                                'ให้การดูแลแบบเฉพาะบุคคลผ่าน AI ที่ประมวลผลจากข้อมูลของท่าน',
                                'วิเคราะห์เชิงสถิติ (แบบไม่เปิดเผยตัวตน) เพื่อพัฒนาระบบบริการสุขภาพในอนาคต',
                              ],
                            ),

                            _buildSection('2. ประเภทข้อมูลที่เราจะเก็บ', '', [
                              'ข้อมูลส่วนบุคคล เช่น ชื่อ-นามสกุล วันเดือนปีเกิด อายุ เลขบัตรประจำตัวประชาชน',
                              'ข้อมูลสุขภาพ เช่น ประวัติการตั้งครรภ์ การคลอด ประวัติโรคประจำตัว น้ำหนัก ส่วนสูง ความดันโลหิต การตรวจทางห้องปฏิบัติการ ฯลฯ',
                              'ข้อมูลของทารก เช่น วันคลอด น้ำหนักแรกคลอด การเจริญเติบโต วัคซีนที่ได้รับ',
                            ]),

                            _buildSection(
                              '3. การรักษาความลับและความปลอดภัยของข้อมูล',
                              '',
                              [
                                'ข้อมูลของท่านจะถูกจัดเก็บในระบบอย่างปลอดภัย ตามมาตรฐานการคุ้มครองข้อมูลส่วนบุคคล (PDPA)',
                                'ข้อมูลจะไม่ถูกส่งต่อ เปิดเผย หรือนำไปใช้ในเชิงพาณิชย์โดยไม่ได้รับความยินยอมจากท่าน',
                                'เฉพาะเจ้าหน้าที่หรือระบบที่มีสิทธิเท่านั้นจึงสามารถเข้าถึงข้อมูลดังกล่าวได้',
                              ],
                            ),

                            _buildSection('4. สิทธิของเจ้าของข้อมูล', '', [
                              'ท่านมีสิทธิในการขอเข้าถึง แก้ไข หรือลบข้อมูลของตนเองได้ทุกเมื่อ',
                              'ท่านสามารถเพิกถอนคำยินยอมได้ โดยการแจ้งผ่านระบบภายในแอป ซึ่งอาจมีผลต่อความสามารถในการใช้งานบางส่วนของแอป',
                              'การไม่ให้ข้อมูลบางประเภทอาจส่งผลต่อการใช้งานบางฟีเจอร์',
                            ]),

                            const SizedBox(height: 20),

                            if (!_hasScrolledToBottom)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.orange.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: const [
                                    Icon(
                                      Icons.privacy_tip,
                                      color: Colors.orange,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'กรุณาเลื่อนอ่านข้อมูลให้ครบถ้วนก่อนให้ความยินยอม',
                                        style: TextStyle(
                                          color: Colors.orange,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Consent section
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FFF9),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Checkbox
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    _hasScrolledToBottom
                                        ? const Color(0xFFE5FFEB)
                                        : Colors.grey.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Transform.scale(
                                  scale: 1.2,
                                  child: Checkbox(
                                    value: _isConsentChecked,
                                    onChanged:
                                        _hasScrolledToBottom
                                            ? _onConsentChanged
                                            : null,
                                    activeColor: const Color(0xFF4CAF50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'ข้าพเจ้ายินยอมให้เก็บรวบรวม ใช้ และเปิดเผยข้อมูลส่วนบุคคลตามที่ระบุไว้ในนโยบายความเป็นส่วนตัว เพื่อให้บริการที่ดีที่สุดแก่ข้าพเจ้าและลูกน้อย',
                                    style: TextStyle(
                                      fontSize: 14,
                                      height: 1.5,
                                      color: Color(0xFF424242),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _onDecline,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    side: const BorderSide(
                                      color: Color(0xFF757575),
                                      width: 2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(
                                        Icons.close,
                                        size: 18,
                                        color: Color(0xFF757575),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'ไม่ยินยอม',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF757575),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed:
                                      (_hasScrolledToBottom &&
                                              _isConsentChecked)
                                          ? _onAccept
                                          : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF046E3E),
                                    disabledBackgroundColor: Colors.grey
                                        .withOpacity(0.3),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    elevation:
                                        (_hasScrolledToBottom &&
                                                _isConsentChecked)
                                            ? 8
                                            : 0,
                                    shadowColor: const Color(
                                      0xFF4CAF50,
                                    ).withOpacity(0.3),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.check, size: 18),
                                      SizedBox(width: 8),
                                      Text(
                                        'ยินยอม',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Privacy note
                          Text(
                            '',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String description, List<String> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Color(0xFF424242),
              ),
            ),
          ],
          const SizedBox(height: 12),
          ...items.map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6, right: 8),
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: Color(0xFF424242),
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
  }
}

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  bool _showPassword = false;
  bool _isPasswordVisible = false;
  bool _isPasswordFocused = false; // เพิ่มตัวแปรเพื่อติดตาม focus state
  bool _isLoading = false;
  bool _isThaiIdLoading = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode(); // เพิ่ม FocusNode

  static const Color primaryGreen = Color(0xFF046E3E);
  static const Color darkGreen = Color(0xFF034f2d);

  @override
  void initState() {
    super.initState();
    // เพิ่ม listener เพื่อติดตาม focus state
    _passwordFocusNode.addListener(() {
      setState(() {
        _isPasswordFocused = _passwordFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _passwordFocusNode.dispose();
    super.dispose();
  }

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

    setState(() {
      _isLoading = true;
    });

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

        // ไม่ต้องแสดง login สำเร็จเหมือนเดิม
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Login successful! Welcome ${data['name']}")),
        );

        // ไปหน้า UserPage
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    await _login();
  }

  Future<void> _handleThaiIdLogin() async {
    setState(() {
      _isThaiIdLoading = true;
    });

    // Simulate Thai ID authentication
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isThaiIdLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'กำลังเปิดหน้าต่าง Thai ID Authentication...\nกรุณาใช้บัตรประชาชนและ PIN ของท่าน',
          ),
          backgroundColor: primaryGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 480),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: primaryGreen.withOpacity(0.1),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: Border.all(
                    color: primaryGreen.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.all(40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      _buildHeader(),
                      const SizedBox(height: 40),

                      // Username Field
                      _buildUsernameField(),
                      const SizedBox(height: 24),

                      // Password Field
                      _buildPasswordField(),
                      const SizedBox(
                        height: 32,
                      ), // เพิ่มระยะห่างเนื่องจากเอา checkbox ออก
                      // Login Button (เอา Show Password Checkbox ออก)
                      _buildLoginButton(),
                      const SizedBox(height: 20),

                      // Divider
                      _buildDivider(),
                      const SizedBox(height: 20),

                      // Thai ID Button
                      _buildThaiIdButton(),
                      const SizedBox(height: 30),

                      // Footer
                      _buildFooter(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'ยินดีต้อนรับ :)',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: primaryGreen,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'เข้าสู่ระบบเพื่อเข้าใช้งาน',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildUsernameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ชื่อบัญชีผู้ใช้',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _usernameController,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            hintText: 'ชื่อบัญชีผู้ใช้',
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: primaryGreen, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            prefixIcon: const Icon(
              Icons.person_outline,
              color: Color(0xFF64748B),
            ),
          ),
          onChanged: (value) {
            // Auto format to uppercase and remove spaces
            final formatted = value.replaceAll(' ', '');
            if (formatted != value) {
              _usernameController.value = TextEditingValue(
                text: formatted,
                selection: TextSelection.collapsed(offset: formatted.length),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'รหัสผ่าน',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          focusNode: _passwordFocusNode, // เพิ่ม focusNode
          obscureText: !_isPasswordVisible,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _handleLogin(),
          decoration: InputDecoration(
            hintText: 'กรอกรหัสผ่าน',
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: primaryGreen, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            prefixIcon: const Icon(Icons.key_sharp, color: Color(0xFF64748B)),
            // แสดง suffixIcon เฉพาะตอนที่ focus อยู่
            suffixIcon:
                _isPasswordFocused
                    ? IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: const Color(0xFF64748B),
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    )
                    : null,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[400],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child:
            _isLoading
                ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'กำลังตรวจสอบ...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
                : const Text(
                  'เข้าสู่ระบบ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey[300])),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'หรือ',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey[300])),
      ],
    );
  }

  Widget _buildThaiIdButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: _isThaiIdLoading ? null : _handleThaiIdLogin,
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          side: const BorderSide(color: primaryGreen, width: 2),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child:
            _isThaiIdLoading
                ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'กำลังเชื่อมต่อ Thai ID...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/login_page/unnamed.png',
                      width: 24,
                      height: 24,
                      
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'เข้าสู่ระบบ ด้วย Thai ID',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Text(
          '© 2025 ระบบสารสนเทศราชการ. สงวนลิขสิทธิ์',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            children: [
              const TextSpan(text: 'หากมีปัญหาการใช้งาน ติดต่อ: '),
              TextSpan(
                text: '02-XXX-XXXX',
                style: TextStyle(
                  color: primaryGreen,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
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
