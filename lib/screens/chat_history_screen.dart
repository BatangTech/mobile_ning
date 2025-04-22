import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // Import intl
import 'chat_screen.dart'; // Import ChatScreen

class ChatHistoryScreen extends StatefulWidget {
  final String userId;

  const ChatHistoryScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _ChatHistoryScreenState createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  late Stream<QuerySnapshot> _historyStream;

  @override
  void initState() {
    super.initState();
    _historyStream = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('chat_sessions')
        .orderBy('date', descending: true) // Order by date, newest first
        .snapshots();
  }

  // Helper to get color based on risk level
  Color _getRiskColor(String? riskLevel) {
    switch (riskLevel?.toLowerCase()) {
      case 'red':
      case 'สูง':
      case 'เสี่ยงสูง':
        return Colors.redAccent;
      case 'green':
      case 'เขียว':
      case 'ปลอดภัย':
      case 'ปกติ': // Add other potential green keywords
        return Colors.green.shade600;
      default:
        return Colors.grey; // Default color if no risk level or unknown
    }
  }

  // Helper to get display text for risk level
  String _getRiskText(String? riskLevel) {
    switch (riskLevel?.toLowerCase()) {
      case 'red':
      case 'สูง':
      case 'เสี่ยงสูง':
        return 'Red Zone';
      case 'green':
      case 'เขียว':
      case 'ปลอดภัย':
      case 'ปกติ':
        return 'Green Zone';
      default:
        return 'No Risk Data';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ประวัติการแชท',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.blue.shade700,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.blue.shade700),
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _historyStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print("❌ Error fetching history: ${snapshot.error}");
            return Center(
                child: Text('เกิดข้อผิดพลาดในการโหลดประวัติ',
                    style: GoogleFonts.poppins()));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
                child: Text('ยังไม่มีประวัติการแชท',
                    style: GoogleFonts.poppins(color: Colors.grey.shade600)));
          }

          // Group chats by date (documents are already per date)
          final chatDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chatDocs.length,
            itemBuilder: (context, index) {
              final doc = chatDocs[index];
              final data = doc.data() as Map<String, dynamic>;
              final String dateString = doc.id; // Doc ID is 'YYYY-MM-DD'
              final String? riskLevel = data['riskLevel'] as String?;
              final Timestamp? lastUpdated = data['lastUpdated'] as Timestamp?;

              DateTime chatDate;
              try {
                // Handle potential parsing errors if ID isn't YYYY-MM-DD
                chatDate = DateFormat('yyyy-MM-dd').parse(dateString);
              } catch (e) {
                print("Error parsing date from doc ID: $dateString");
                // Handle the error, maybe skip this entry or show an error indicator
                return const SizedBox
                    .shrink(); // Skip this item if date is invalid
              }

              Color riskColor = _getRiskColor(riskLevel);
              String riskText = _getRiskText(riskLevel);

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  leading:
                      Icon(Icons.calendar_today, color: riskColor, size: 20),
                  title: Text(
                    DateFormat('d MMMM yyyy', 'th_TH')
                        .format(chatDate), // Thai locale
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500, fontSize: 15),
                  ),
                  subtitle: Text(
                    riskText,
                    style: GoogleFonts.poppins(
                        color: riskColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          userId: widget.userId,
                          // Pass the selected date
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
