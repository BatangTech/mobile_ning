import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MessageBubble extends StatelessWidget {
  final Map<String, String> msg;
  final bool isUser;
  final Animation<double>? animation;

  const MessageBubble({
    Key? key,
    required this.msg,
    required this.isUser,
    this.animation,
    required String text,
    Color? color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // More visually appealing colors
    final Color bgColor = msg.containsKey('color')
        ? Color(int.parse(msg['color']!))
        : isUser
            ? const Color(0xFF3B82F6) // Refined blue for user
            : const Color(0xFFF5F7FA); // Softer gray for other messages

    final String message = isUser ? msg['query']! : msg['response']!;
    final Color textColor = isUser ? Colors.white : const Color(0xFF2D3748);

    Widget bubbleContent = Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: isUser ? const Radius.circular(5) : null,
            bottomLeft: !isUser ? const Radius.circular(5) : null,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            )
          ],
        ),
        child: IntrinsicWidth(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
              minWidth: 60,
            ),
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: textColor,
                fontWeight: FontWeight.w400,
                height: 1.35,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ),
      ),
    );

    if (animation != null) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation!,
          curve: Curves.easeOut,
        ),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset(isUser ? 0.15 : -0.15, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation!,
            curve: Curves.easeOutQuint,
          )),
          child: bubbleContent,
        ),
      );
    }

    return bubbleContent;
  }
}
