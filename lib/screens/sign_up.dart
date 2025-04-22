import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:frontend/Widget/snack_bar.dart';
import 'package:frontend/screens/chat_screen.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/services/auth_service.dart';
import '../Widget/button.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  bool isLoading = false;

  final List<String> ncdOptions = [
    'โรคเบาหวาน', // เบาหวาน
    'โรคความดันโลหิตสูง', // ความดันโลหิตสูง
    'โรคหัวใจ', // โรคหัวใจ
    'โรคมะเร็ง', // มะเร็ง
    'โรคทางเดินหายใจเรื้อรัง',
  ];

  Map<String, bool> selectedNCDs = {
    'โรคเบาหวาน': false,
    'โรคความดันโลหิตสูง': false,
    'โรคหัวใจ': false,
    'โรคมะเร็ง': false,
    'โรคทางเดินหายใจเรื้อรัง': false,
  };

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  void signUpUser() async {
    final phone = phoneController.text.trim();

    // ✅ ตรวจสอบเบอร์โทรต้องยาว 10 ตัว
    if (phone.isNotEmpty) {
      if (phone.length < 10) {
        showSnackBar(
            context, "หมายเลขโทรศัพท์น้อยกว่า 10 หลัก กรุณาตรวจสอบอีกครั้ง");
        return;
      } else if (phone.length > 10) {
        showSnackBar(context, "หมายเลขโทรศัพท์จะต้องมี 10 หลัก");
        return;
      }
    }

    setState(() => isLoading = true);

    String res = await AuthService().signUpUser(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
      name: nameController.text.trim(),
      phone: phone,
    );

    if (res == "success") {
      String userId = FirebaseAuth.instance.currentUser!.uid;

      List<String> selectedNCDList = selectedNCDs.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'ncds': selectedNCDList,
      });

      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => ChatScreen(userId: userId),
      ));
    } else {
      setState(() => isLoading = false);
      showSnackBar(context, res);
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
              const SizedBox(height: 80),
              SizedBox(
                width: double.infinity,
                height: 250,
                child: Image.asset("assets/images/robot.png", height: 200),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                child: TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    hintText: "กรอกชื่อของคุณ",
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                  ),
                ),
              ),
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
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                child: TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: const InputDecoration(
                    hintText: "ป้อนหมายเลขโทรศัพท์ของคุณ",
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "เลือก NCDs ที่คุณมี (ถ้ามี)",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    // First row - โรคเบาหวาน and โรคความดันโลหิตสูง
                    Row(
                      children: [
                        Expanded(
                          child: CheckboxListTile(
                            dense: true,
                            title: Text('โรคเบาหวาน',
                                style: const TextStyle(fontSize: 14)),
                            value: selectedNCDs['โรคเบาหวาน'],
                            onChanged: (bool? value) {
                              setState(() {
                                selectedNCDs['โรคเบาหวาน'] = value ?? false;
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        Expanded(
                          child: CheckboxListTile(
                            dense: true,
                            title: Text('โรคความดันโลหิตสูง',
                                style: const TextStyle(fontSize: 14)),
                            value: selectedNCDs['โรคความดันโลหิตสูง'],
                            onChanged: (bool? value) {
                              setState(() {
                                selectedNCDs['โรคความดันโลหิตสูง'] =
                                    value ?? false;
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),

                    // Second row - โรคหัวใจ and โรคมะเร็ง
                    Row(
                      children: [
                        Expanded(
                          child: CheckboxListTile(
                            dense: true,
                            title: Text('โรคหัวใจ',
                                style: const TextStyle(fontSize: 14)),
                            value: selectedNCDs['โรคหัวใจ'],
                            onChanged: (bool? value) {
                              setState(() {
                                selectedNCDs['โรคหัวใจ'] = value ?? false;
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        Expanded(
                          child: CheckboxListTile(
                            dense: true,
                            title: Text('โรคมะเร็ง',
                                style: const TextStyle(fontSize: 14)),
                            value: selectedNCDs['โรคมะเร็ง'],
                            onChanged: (bool? value) {
                              setState(() {
                                selectedNCDs['โรคมะเร็ง'] = value ?? false;
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),

                    // Third row - โรคทางเดินหายใจเรื้อรัง (only on left side)
                    Row(
                      children: [
                        Expanded(
                          child: CheckboxListTile(
                            dense: true,
                            title: Text('โรคทางเดินหายใจเรื้อรัง',
                                style: const TextStyle(fontSize: 14)),
                            value: selectedNCDs['โรคทางเดินหายใจเรื้อรัง'],
                            onChanged: (bool? value) {
                              setState(() {
                                selectedNCDs['โรคทางเดินหายใจเรื้อรัง'] =
                                    value ?? false;
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        Expanded(
                            child: Container()), // Empty container for balance
                      ],
                    ),
                  ],
                ),
              ),
              MyButton(
                onTab: signUpUser,
                text: "สมัครสมาชิก",
                isLoading: isLoading,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("มีบัญชีอยู่แล้วใช่ไหม? ",
                        style: TextStyle(fontSize: 16)),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        "เข้าสู่ระบบ",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: height / 20),
            ],
          ),
        ),
      ),
    );
  }
}
