import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatLoadingIndicator extends StatelessWidget {
  const ChatLoadingIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
          ),
          const SizedBox(height: 5),
          Text(
            "AI กำลังตอบ...",
            style: GoogleFonts.poppins(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
