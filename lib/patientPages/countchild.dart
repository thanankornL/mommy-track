import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(MaterialApp(debugShowCheckedModeBanner: false, home: Countchild()));
}

class Countchild extends StatefulWidget {
  const Countchild({super.key});

  @override
  State<Countchild> createState() => _Countchild();
}

class _Countchild extends State<Countchild> {
  int number = 0;
  void increment() {
    setState(() {
      number++;
    });
  }
  void decrement() {
    setState(() {
      if (number > 0) {
        number--;
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "การนับลูกดิ้นของคุณแม่",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
      ),
      body: Container(
        decoration: BoxDecoration(color: Colors.white),
        child: Column(
          children: [
            Expanded(
              child: Column(
                children: [
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 25, vertical: 20),
                    height: screenHeight
                        * 0.2, // Adjust height as needed
                    width: screenWidth * 0.9,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: const Color.fromARGB(255, 255, 255, 255),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset: Offset(0, 3), // changes position of shadow
                        ),
                      ],
                    
                    ),
                   child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "จำนวนครั้งที่ลูกดิ้น",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w300, color: const Color.fromARGB(255, 132, 132, 132) ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          "$number",
                          style: TextStyle(fontSize: 70, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                        SizedBox(height: 10),
                        Text(
                          "ครั้ง",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w300, color: const Color.fromARGB(255, 132, 132, 132)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: increment,
                        style: ElevatedButton.styleFrom(
                         backgroundColor:  Colors.green,
                          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text("เพิ่ม", style: TextStyle(fontSize: 20)),
                      ),
                      SizedBox(width: 20),
                      ElevatedButton(
                        onPressed: decrement,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text("ลด", style: TextStyle(fontSize: 20)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
