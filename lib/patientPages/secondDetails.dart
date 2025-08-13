import 'package:carebellmom/config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

class secondState extends StatefulWidget {
  const secondState({super.key});

  @override
  State<secondState> createState() => _secondStateState();
}

class _secondStateState extends State<secondState> {
  bool _isLoading = true;
  String childName = '';
  String? gender;
  int _currentStep = 0; // Make it nullable
  Future<void> loadStepFromServer() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    if (username != null) {
      final data = await fetchBabyAction(username);
      if (data != null) {
        setState(() {
          childName = data.child;
          gender = data.gender;
          _currentStep = data.action;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        // Optionally display an error or fallback message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load step data. Please try again later.'),
          ),
        );
      }
    } else {
      setState(() => _isLoading = false);
      // Optionally display an error message if no username is found
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Username not found. Please log in again.')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    loadStepFromServer(); // Call the function to load the step on init
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData maleTheme = Theme.of(context).copyWith(
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.blue,
      ).copyWith(secondary: Colors.blueAccent),
    );

    final ThemeData femaleTheme = Theme.of(context).copyWith(
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.pink,
      ).copyWith(secondary: Colors.pinkAccent),
    );
    return Theme(
      data: gender == 'Male' ? maleTheme : femaleTheme,
      child: Scaffold(body: Center(child: _buildStepperView())),
    );
  }

  Widget _buildStepperView() {
    Color primaryColor = gender == 'Male' ? Colors.blue : Colors.pink;
    Color completedColor =
        gender == 'Male' ? Colors.blueAccent : Colors.pinkAccent;
    Color inactiveColor = Colors.grey.shade300;

    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        const SizedBox(height: 70),
        Text(
          "บันทึกการได้รับวัคซีนของ $childName",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Stepper(
                connectorThickness: 3,
                connectorColor: WidgetStateProperty.resolveWith<Color>((
                  states,
                ) {
                  if (_currentStep > 0 &&
                      states.contains(WidgetState.selected)) {
                    return completedColor;
                  } else if (states.contains(WidgetState.selected)) {
                    return primaryColor;
                  } else {
                    return inactiveColor;
                  }
                }),
                currentStep: _currentStep,
                onStepTapped: null,
                controlsBuilder: (context, details) => const SizedBox.shrink(),
                physics: const BouncingScrollPhysics(),
                elevation: 2,
                type: StepperType.vertical,
                steps: List.generate(
                  7,
                  (index) => _getSteps(primaryColor, completedColor)[index],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom : 20),
          child: SizedBox(
            width: 300,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: () async {
                Navigator.pop(context);

                // Navigate to the ViewDetails page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            UserPage(), // Replace with your ViewDetails widget
                  ),
                );
              },
              child: Text(
                'Confirm',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Step customStep(
    String title,
    String content,
    int stepIndex,
    Color primaryColor,
    Color completedColor,
  ) {
    final isActive = _currentStep >= stepIndex;
    final isCurrent = _currentStep == stepIndex;
    final isCompleted = _currentStep > stepIndex;

    return Step(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
          fontSize: isCurrent ? 16.0 : 14.0,
          color:
              isCurrent
                  ? primaryColor
                  : (isCompleted ? completedColor : Colors.black),
        ),
      ),
      content: Container(
        padding: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          color: isCurrent ? primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8.0),
          border:
              isCurrent ? Border.all(color: primaryColor, width: 1.0) : null,
        ),
        child: Text(
          content,
          style: TextStyle(color: isCurrent ? Colors.black87 : Colors.black54),
        ),
      ),
      isActive: isActive,
      state:
          isCompleted
              ? StepState.complete
              : (isCurrent ? StepState.editing : StepState.indexed),
    );
  }

  List<Step> _getSteps(Color primaryColor, Color completedColor) {
    return [
      customStep(
        "4 เดือน",
        """1. กินวัคซีนป้องกันโรคโปลิโอ (OPV) ครั้งที่ 2
2. ฉีดวัคซีนป้องกันโรคคอตีบ  -บาดทะยัก - ไอกรน - ตับอักเสบบี - ฮิบ (DTP-HB-Hib) ครั้งที่ 2
3. กินวัคซีนโรต้า (Rota) ครั้งที่ 2
4. ฉีดวัคซีนป้องกันโรคโปลิโอ (IPV)""",
        0,
        primaryColor,
        completedColor,
      ),
      customStep(
        "6 เดือน",
        """1. กินวัคซีนป้องกันโรคโปลิโอ (OPV) ครั้งที่ 3
2. ฉีดวัคซีนป้องกันโรคคอตีบ  -บาดทะยัก - ไอกรน - ตับอักเสบบี - ฮิบ (DTP-HB-Hib) ครั้งที่ 3
3. กินวัคซีนโรต้า (Rota) ครั้งที่ 3 (ยกเว้นได้ Rotarix มาแล้ว 2 ครั้ง)""",
        1,
        primaryColor,
        completedColor,
      ),
      customStep(
        "9 เดือน",
        """1. ฉีดวัคซีนรวมป้องกันโรคหัด-คางทูม-หัดเยอรมัน (MMR) ครั้งที่ 1""",
        2,
        primaryColor,
        completedColor,
      ),
      customStep(
        "1 ปี",
        """1.ฉีดวัคซีนป้องกันโรคไข้สมองอักเสบเจอี ชนิดเชื้อเป็นฤทธิ์อ่อน (LAJE)""",
        3,
        primaryColor,
        completedColor,
      ),
      customStep(
        "1 ปี 6 เดือน",
        """1. กินวัคซีนป้องกันโรคโปลิโอ (OPV) ครั้งที่ 4
2. ฉีดวัคซีนป้องกันโรคคอตีบ  -บาดทะยัก - ไอกรน(DTP) ครั้งที่ 4
3. ฉีดวัคซีนรวมป้องกันโรคหัด-คางทูม-หัดเยอรมัน (MMR) ครั้งที่ 2""",
        4,
        primaryColor,
        completedColor,
      ),
      customStep(
        "2 ปี 6 เดือน",
        """1.ฉีดวัคซีนป้องกันโรคไข้สมองอักเสบเจอี ชนิดเชื้อเป็นฤทธิ์อ่อน (LAJE) ครั้งที่ 2""",
        5,
        primaryColor,
        completedColor,
      ),
      customStep(
        "4 ปี",
        """1. กินวัคซีนป้องกันโรคโปลิโอ (OPV) ครั้งที่ 5
2. ฉีดวัคซีนป้องกันโรคคอตีบ-บาดทะยัก-ไอกรน (DTP) ครั้งที่ 5""",
        6,
        primaryColor,
        completedColor,
      ),
    ];
  }
}

class BabyData {
  final String child;
  final int action;
  final String? gender;

  BabyData({required this.child, required this.action, required this.gender});

  factory BabyData.fromJson(Map<String, dynamic> json) {
    return BabyData(
      child: json['child'],
      action: json['action'],
      gender: json['gender'],
    );
  }
}

Future<BabyData?> fetchBabyAction(String username) async {
  final uri = Uri.parse('$baseUrl/api/get_baby_data');
  try {
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'mother': username}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        return BabyData.fromJson(data['data']);
      } else {
        debugPrint("⚠️ Server responded with an error: ${data['message']}");
      }
    } else {
      debugPrint("❌ Failed: ${response.statusCode}");
    }
  } catch (e) {
    debugPrint("🚨 Error: $e");
  }
  return null;
}
