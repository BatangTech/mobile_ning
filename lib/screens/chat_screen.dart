import 'dart:async';

import 'package:flutter/material.dart';
import 'package:frontend/Widget/chat_input_area.dart';
import 'package:frontend/Widget/drawer_item.dart';
import 'package:frontend/Widget/loading_indicator.dart';
import 'package:frontend/Widget/message_bubble.dart';
import 'package:frontend/Widget/snack_bar.dart';
import 'package:frontend/screens/editncds_screen.dart';
import 'package:frontend/screens/editprofile_screen.dart';

import 'package:frontend/screens/login_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'voice_screen.dart';

class ChatHistory {
  final String id;
  final DateTime createdAt;
  final String lastMessage;
  final String riskLevel; // "green", "yellow", "red"

  ChatHistory({
    required this.id,
    required this.createdAt,
    required this.lastMessage,
    required this.riskLevel,
  });

  factory ChatHistory.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    DateTime createdAt = data['created_at'] != null
        ? (data['created_at'] as Timestamp).toDate()
        : DateTime.now();

    return ChatHistory(
      id: doc.id,
      createdAt: createdAt,
      lastMessage: data['last_message'] ?? 'ไม่มีข้อความ',
      riskLevel: data['risk_level'] ?? 'green',
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String userId;
  final String? chatId;

  const ChatScreen({
    Key? key,
    required this.userId,
    this.chatId,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  StreamSubscription<QuerySnapshot>? _chatHistorySubscription;
  List<Map<String, String>> messages = [];
  bool _isLoading = false;
  String _userName = '';
  String _userEmail = '';
  String _userPhone = '';
  String _currentChatId = '';
  bool _isChatHistoryOpen = false;
  List<ChatHistory> _chatHistories = [];
  List<String> _userMedicalConditions = [];

  Future<void> _fetchUserData() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        setState(() {
          _userName = data['name'] ?? '';
          _userEmail = data['email'] ?? '';
          _userPhone = data['phone'] ?? '';
          _userMedicalConditions = List<String>.from(data['ncds'] ?? []);
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _getUserProfile();
    _loadChatHistory();
    _fetchUserData();
    if (widget.chatId != null) {
      _currentChatId = widget.chatId!;
      _loadChatMessages(_currentChatId);
    } else {
      _createNewChat();
    }
  }

  Future<void> _loadChatHistory() async {
    try {
      _chatHistorySubscription?.cancel();
      _chatHistorySubscription = FirebaseFirestore.instance
          .collection('chat_sessions')
          .where('user_id', isEqualTo: widget.userId)
          .orderBy('created_at', descending: true)
          .snapshots()
          .listen((snapshot) {
        if (mounted) {
          setState(() {
            _chatHistories = snapshot.docs
                .map((doc) => ChatHistory.fromFirestore(doc))
                .toList();
          });
        }
      });
    } catch (e) {
      print("❌ Error loading chat history: $e");
    }
  }

  Future<void> _createNewChat() async {
    setState(() {
      _isLoading = true;
      messages.clear();
    });

    try {
      DocumentReference chatRef =
          await FirebaseFirestore.instance.collection('chat_sessions').add({
        'user_id': widget.userId,
        'created_at': FieldValue.serverTimestamp(),
        'last_message': 'การสนทนาใหม่',
        'risk_level': 'green',
      });

      _currentChatId = chatRef.id;

      await FirebaseFirestore.instance
          .collection('chat_sessions')
          .doc(_currentChatId)
          .collection('messages')
          .add({
        'is_user': false,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('chat_sessions')
          .doc(_currentChatId)
          .update({});

      setState(() {
        _isChatHistoryOpen = false;
        _isLoading = false;
      });

      try {
        final url = Uri.parse(
            'http://localhost:8080/start_chat?user_id=${widget.userId}');

        final response = await http.get(url);
        if (response.statusCode == 200) {
          final responseData = jsonDecode(utf8.decode(response.bodyBytes));
          if (mounted) {
            setState(() {
              messages.add({'query': '', 'response': responseData["response"]});
            });

            await FirebaseFirestore.instance
                .collection('chat_sessions')
                .doc(_currentChatId)
                .collection('messages')
                .add({
              'is_user': false,
              'message': responseData["response"],
              'timestamp': FieldValue.serverTimestamp(),
            });

            await FirebaseFirestore.instance
                .collection('chat_sessions')
                .doc(_currentChatId)
                .update({
              'last_message': responseData["response"],
            });
          }
        }
      } catch (e) {
        print("⚠️ ไม่สามารถเรียกข้อความเริ่มต้นจากเซิร์ฟเวอร์ได้: $e");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print("❌ Error creating new chat: $e");
      showSnackBar(context, "เกิดข้อผิดพลาดในการสร้างแชทใหม่");
    }
  }

  Future _loadChatMessages(String chatId) async {
    setState(() {
      _isLoading = true;
      messages.clear();
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('chat_sessions')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .get();

      if (mounted) {
        setState(() {
          for (var doc in snapshot.docs) {
            Map data = doc.data();
            String userMessage = data['message'] ?? '';

            if (data['is_user'] == true) {
              messages.add({'query': userMessage, 'response': ''});
            } else {
              messages.add({'query': '', 'response': userMessage});
            }

            if (data['is_risk_analysis'] == true) {
              messages.last['color'] = data['risk_color'] ?? '';
            }
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      print("❌ Error loading chat messages: $e");
    }
  }

  Future<void> updateRiskStatus(
      String userId, String chatId, String riskLevel) async {
    if (userId.isEmpty || chatId.isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('high_risk_users')
          .doc(userId)
          .set({
        'user_id': userId,
        'risk_level': riskLevel,
        'timestamp': FieldValue.serverTimestamp(),
        'chat_id': chatId,
      });

      await FirebaseFirestore.instance
          .collection('chat_sessions')
          .doc(chatId)
          .update({
        'risk_level': riskLevel,
      });

      print("✅ อัปเดตข้อมูลความเสี่ยงสำเร็จ");
      _loadChatHistory();
    } catch (e) {
      print("❌ ไม่สามารถอัปเดตข้อมูลความเสี่ยงได้: $e");
    }
  }

  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty ||
        widget.userId.isEmpty ||
        _currentChatId.isEmpty) {
      showSnackBar(context, "ข้อความไม่ถูกต้องหรือยังไม่ได้เริ่มแชท");
      return;
    }

    setState(() {
      messages.add({'query': message, 'response': ''});
      _isLoading = true;
    });

    _controller.clear();

    try {
      await FirebaseFirestore.instance
          .collection('chat_sessions')
          .doc(_currentChatId)
          .collection('messages')
          .add({
        'is_user': true,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('chat_sessions')
          .doc(_currentChatId)
          .update({
        'last_message': "คุณ: " +
            (message.length > 30 ? message.substring(0, 30) + "..." : message),
      });

      final response = await http.post(
        Uri.parse('http://localhost:8080/chat'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': widget.userId,
          'message': message,
        }),
      );

      final responseData = json.decode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        String aiResponse =
            responseData['response'] ?? "AI ไม่สามารถให้คำตอบได้";

        if (mounted) {
          setState(() {
            messages.add({'query': '', 'response': aiResponse});
            _isLoading = false;
          });

          await FirebaseFirestore.instance
              .collection('chat_sessions')
              .doc(_currentChatId)
              .collection('messages')
              .add({
            'is_user': false,
            'message': aiResponse,
            'timestamp': FieldValue.serverTimestamp(),
          });

          await FirebaseFirestore.instance
              .collection('chat_sessions')
              .doc(_currentChatId)
              .update({
            'last_message': aiResponse.length > 30
                ? aiResponse.substring(0, 30) + "..."
                : aiResponse,
          });

          if (responseData.containsKey('next_question') &&
              responseData['next_question'].isNotEmpty) {
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) {
                setState(() {
                  messages.add(
                      {'query': '', 'response': responseData['next_question']});
                });

                FirebaseFirestore.instance
                    .collection('chat_sessions')
                    .doc(_currentChatId)
                    .collection('messages')
                    .add({
                  'is_user': false,
                  'message': responseData['next_question'],
                  'timestamp': FieldValue.serverTimestamp(),
                });
              }
            });
          }

          if (responseData.containsKey('risk_level')) {
            String riskLevel = responseData['risk_level'].toLowerCase();
            bool isHighRisk = riskLevel == "red" ||
                riskLevel.contains("สูง") ||
                riskLevel.contains("เสี่ยงสูง");
            bool isMediumRisk = riskLevel == "yellow" ||
                riskLevel.contains("ปานกลาง") ||
                riskLevel.contains("เสี่ยงปานกลาง");

            Color riskColor;
            if (isHighRisk) {
              riskColor = Colors.red;
            } else if (isMediumRisk) {
              riskColor = Colors.orange;
            } else {
              riskColor = Colors.green;
            }

            IconData riskIcon = isHighRisk
                ? Icons.warning_amber_rounded
                : isMediumRisk
                    ? Icons.info_outline
                    : Icons.check_circle;

            setState(() {
              messages.add({
                'query': '',
                'response': "📢 ผลการวิเคราะห์สุขภาพของคุณ: $riskLevel",
                'color': riskColor.value.toString()
              });
            });

            await FirebaseFirestore.instance
                .collection('chat_sessions')
                .doc(_currentChatId)
                .collection('messages')
                .add({
              'is_user': false,
              'message': "📢 ผลการวิเคราะห์สุขภาพของคุณ: $riskLevel",
              'timestamp': FieldValue.serverTimestamp(),
              'is_risk_analysis': true,
              'risk_color': riskColor.value.toString(),
            });

            String firestoreRiskLevel = isHighRisk
                ? "red"
                : isMediumRisk
                    ? "yellow"
                    : "green";

            await updateRiskStatus(
                widget.userId, _currentChatId, firestoreRiskLevel);

            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return AlertDialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(riskIcon, size: 60, color: riskColor),
                      const SizedBox(height: 10),
                      Text(
                        "ระดับความเสี่ยงของคุณ",
                        style: GoogleFonts.poppins(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        riskLevel,
                        style:
                            GoogleFonts.poppins(fontSize: 16, color: riskColor),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("ตกลง",
                          style: GoogleFonts.poppins(fontSize: 16)),
                    ),
                  ],
                );
              },
            );
          }
        }
      } else {
        String errorMessage = responseData.containsKey('error')
            ? responseData['error']
            : "เกิดข้อผิดพลาด กรุณาลองใหม่";
        showSnackBar(context, errorMessage);
        setState(() => _isLoading = false);
      }
    } catch (e) {
      showSnackBar(context, "❌ เกิดข้อผิดพลาดในการเชื่อมต่อ");
      setState(() => _isLoading = false);
      print("❌ Error: $e");
    }
  }

  Future<void> _getUserProfile() async {
    try {
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists && mounted) {
        setState(() {
          _userName = userDoc['name'] ?? 'ไม่ระบุชื่อ';
          _userEmail = userDoc['email'] ?? '';
          _userPhone = userDoc['phone'] ?? '';
        });
      }
    } catch (e) {
      print("❌ Error getting user profile: $e");
      showSnackBar(context, "ไม่สามารถโหลดข้อมูลผู้ใช้ได้");
    }
  }

  Future<void> resetChat() async {
    _createNewChat();
    Navigator.pop(context);
    showSnackBar(context, "✅ เริ่มแชทใหม่แล้วค่ะ!");
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'yellow':
        return Colors.orange;
      case 'green':
        return Colors.green;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        title: Text(
          'แชท',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isChatHistoryOpen ? Icons.chat_bubble_outline : Icons.history,
              size: 26,
            ),
            onPressed: () {
              setState(() {
                _isChatHistoryOpen = !_isChatHistoryOpen;
              });
            },
          ),
        ],
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        shadowColor: Colors.black26,
      ),
      drawer: Drawer(
        elevation: 10,
        child: Column(
          children: <Widget>[
            Container(
              height: 450,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF1A237E), // เข้มขึ้นเพื่อความสวยงาม
                    Color(0xFF3949AB),
                    Color(0xFFE8EAF6),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // โปรไฟล์ผู้ใช้ที่ปรับปรุงใหม่
                      Stack(
                        children: [
                          Container(
                            width: 85,
                            height: 85,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                _userName.isNotEmpty
                                    ? _userName[0].toUpperCase()
                                    : 'U',
                                style: GoogleFonts.poppins(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF303F9F),
                                ),
                              ),
                            ),
                          ),
                          // ปุ่มแก้ไขที่ปรับปรุงใหม่
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: GestureDetector(
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditProfileScreen(
                                      userId: FirebaseAuth
                                          .instance.currentUser!.uid,
                                    ),
                                  ),
                                );

                                if (result == true) {
                                  _getUserProfile();
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Color(0xFF303F9F),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // ชื่อผู้ใช้
                      Text(
                        _userName,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // อีเมลและเบอร์โทร
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.email_outlined,
                            color: Colors.white.withOpacity(0.9),
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            _userEmail,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            color: Colors.white.withOpacity(0.9),
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            _userPhone,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),

                      // ส่วนของโรคประจำตัว
                      const SizedBox(height: 16),
                      Container(
                        padding:
                            EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            // หัวข้อโรคประจำตัวและปุ่มแก้ไข
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.medical_services_outlined,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'โรคประจำตัว',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 10),
                                GestureDetector(
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            EditNCDHistoryScreen(
                                          userId: FirebaseAuth
                                              .instance.currentUser!.uid,
                                        ),
                                      ),
                                    );

                                    if (result == true) {
                                      _fetchUserData();
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.25),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.edit_outlined,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'แก้ไข',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // รายการโรคประจำตัว
                            _userMedicalConditions.isEmpty
                                ? Text(
                                    'ไม่มีโรคประจำตัว',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  )
                                : Container(
                                    width: 250,
                                    child: Wrap(
                                      alignment: WrapAlignment.center,
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: _userMedicalConditions
                                          .map<Widget>((condition) {
                                        return Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Color(0xFF00796B)
                                                .withOpacity(0.8),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.1),
                                                blurRadius: 4,
                                                spreadRadius: 0,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            condition,
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.white,
                                            ),
                                          ),
                                        );
                                      }).toList(),
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

            // เมนูที่ปรับปรุงใหม่
            const SizedBox(height: 10),
            DrawerItem(
              icon: Icons.chat_bubble_rounded,
              text: 'แชทปัจจุบัน',
              onTap: () {
                Navigator.pop(context);
              },
            ),
            Divider(
                height: 1, thickness: 0.5, color: Colors.grey.withOpacity(0.3)),
            DrawerItem(
              icon: Icons.add_comment_rounded,
              text: 'เริ่มแชทใหม่',
              onTap: () {
                resetChat();
              },
            ),
            Divider(
                height: 1, thickness: 0.5, color: Colors.grey.withOpacity(0.3)),
            DrawerItem(
              icon: Icons.history_rounded,
              text: 'ประวัติแชท',
              onTap: () {
                setState(() {
                  _isChatHistoryOpen = true;
                });
                Navigator.pop(context);
              },
            ),
           

            // ปุ่มออกจากระบบด้านล่าง
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.red.withOpacity(0.1),
              ),
              child: DrawerItem(
                icon: Icons.logout_rounded,
                text: 'ออกจากระบบ',
                iconColor: Colors.red[700],
                textColor: Colors.red[700],
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: _isChatHistoryOpen ? _buildChatHistoryView() : _buildChatView(),
      ),
    );
  }

  Widget _buildChatHistoryView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Row(
            children: [
              const Icon(Icons.history, color: Colors.blueAccent),
              const SizedBox(width: 10),
              Text(
                'ประวัติการสนทนา',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: Text('สร้างแชทใหม่',
                    style: GoogleFonts.poppins(fontSize: 14)),
                onPressed: () {
                  _createNewChat();
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: _chatHistories.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          size: 60, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'ยังไม่มีประวัติการสนทนา',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _createNewChat(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        child: Text(
                          'เริ่มแชทใหม่',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadChatHistory,
                  child: ListView.builder(
                    itemCount: _chatHistories.length,
                    itemBuilder: (context, index) {
                      final chat = _chatHistories[index];
                      final bool isCurrentChat = chat.id == _currentChatId;

                      String riskText = chat.riskLevel == 'red'
                          ? 'เสี่ยงสูง'
                          : chat.riskLevel == 'yellow'
                              ? 'เสี่ยงปานกลาง'
                              : 'ปลอดภัย';

                      IconData riskIcon = chat.riskLevel == 'red'
                          ? Icons.warning_amber_rounded
                          : chat.riskLevel == 'yellow'
                              ? Icons.info_outline
                              : Icons.check_circle;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        elevation: isCurrentChat ? 4 : 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: isCurrentChat
                              ? BorderSide(color: Colors.blueAccent, width: 2)
                              : BorderSide.none,
                        ),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _currentChatId = chat.id;
                              _isChatHistoryOpen = false;
                            });
                            _loadChatMessages(chat.id);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _getRiskColor(chat.riskLevel)
                                        .withOpacity(0.1),
                                  ),
                                  child: Icon(
                                    riskIcon,
                                    color: _getRiskColor(chat.riskLevel),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${chat.createdAt.day}/${chat.createdAt.month}/${chat.createdAt.year} ${chat.createdAt.hour}:${chat.createdAt.minute.toString().padLeft(2, '0')}',
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  _getRiskColor(chat.riskLevel)
                                                      .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              riskText,
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color: _getRiskColor(
                                                    chat.riskLevel),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        chat.lastMessage,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (isCurrentChat)
                                        const SizedBox(height: 4),
                                      if (isCurrentChat)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            'แชทปัจจุบัน',
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              color: Colors.blue,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: Colors.grey[400],
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _currentChatId = chat.id;
                                      _isChatHistoryOpen = false;
                                    });
                                    _loadChatMessages(chat.id);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildChatView() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              return MessageBubble(
                msg: messages[index],
                isUser: messages[index]['query']!.isNotEmpty,
                text: '',
              );
            },
          ),
        ),
        if (_isLoading) const ChatLoadingIndicator(),
        ChatInputArea(
          controller: _controller,
          userId: widget.userId,
          sendMessageCallback: sendMessage,
          onSend: (String message) {},
          onVoice: () {},
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _chatHistorySubscription?.cancel();
    super.dispose();
  }
}
