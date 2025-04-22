import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend/Widget/button.dart';
import 'package:frontend/screens/chat_screen.dart';
import 'package:frontend/screens/sign_up.dart';
import 'package:frontend/services/auth_service.dart';

import '../Widget/snack_bar.dart';
import '../Widget/text_filed.dart'; // ตรวจสอบชื่อไฟล์นี้ว่าถูกต้อง

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    super.dispose();
    emailController.dispose();
    passwordController.dispose();
  }

  void loginUser() async {
    setState(() {
      isLoading = true; // แสดงการโหลดก่อนเรียก API
    });

    String res = await AuthService().loginUser(
      email: emailController.text,
      password: passwordController.text,
      // หมายเหตุ: คุณอาจต้องปรับ AuthService เพื่อรับค่าอายุด้วย
      // age: ageController.text,
    );

    if (res == "success") {
      String userId = FirebaseAuth.instance.currentUser!.uid;

      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => ChatScreen(
          userId: userId,
        ),
      ));
    } else {
      setState(() {
        isLoading = false;
      });
      showSnackBar(context, res);
    }
  }

  Future<void> startChat() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final String userId = user.uid;
    final String apiUrl = "http://localhost:8080/start_chat?user_id=$userId";

    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("AI: ${data['response']}");
    } else {
      print("❌ Error: ${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: SizedBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 80),
              SizedBox(
                width: double.infinity,
                height: height / 2.7,
                child: Image.asset("assets/images/robot.png", height: 289.3),
              ),
              // ช่องกรอกอีเมล
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                child: TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    hintText: "กรอกอีเมล์ของคุณ",
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                  ),
                ),
              ),
              // ช่องกรอกรหัสผ่าน
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                child: TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: "กรอกรหัสผ่านของคุณ",
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                  ),
                ),
              ),
              // เพิ่มช่องกรอกอายุ

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 35),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "ลืมรหัสผ่าน?",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ),
              MyButton(
                onTab: loginUser,
                text: "เข้าสู่ระบบ",
                isLoading: isLoading,
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "ยังไม่มีบัญชีใช่ไหม? ",
                    style: TextStyle(fontSize: 16),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignUpScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "สมัครสมาชิก",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
