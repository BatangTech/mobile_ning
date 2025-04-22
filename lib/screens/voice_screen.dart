import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:avatar_glow/avatar_glow.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class VoiceScreen extends StatefulWidget {
  final String userId;

  const VoiceScreen(
      {super.key,
      required this.userId,
      required Null Function(dynamic text) onTextReceived,
      required Null Function(dynamic message) onMessageReceived,
      required String chatId});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isListening = false;
  String _userMessage = "";
  String _botResponse = "How can I help you?";
  String _riskLevel = "ไม่ระบุ";
  bool _isLoading = false;
  List<Map<String, String>> _chatHistory = [];

  @override
  void initState() {
    super.initState();
    _initTTS();
    _checkAvailableLanguages();

    fetchInitialMessage();
  }

  Future<void> fetchInitialMessage() async {
    try {
      final response = await http.get(Uri.parse(
          "http://localhost:8080/start_chat?user_id=${widget.userId}"));

      if (response.statusCode == 200) {
        var responseData = jsonDecode(utf8.decode(response.bodyBytes));
        String botReply = responseData["response"];

        if (mounted) {
          setState(() {
            _botResponse = botReply;
            _chatHistory.add({"sender": "bot", "message": botReply});
          });
        }

        await _flutterTts.speak(botReply);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _botResponse = "Error: Unable to get initial message.");
      }
    }
  }

  void _checkAvailableLanguages() async {
    List<dynamic> languages = await _flutterTts.getLanguages;
    if (languages.contains("th-TH")) {
      await _flutterTts.setLanguage("th-TH");
    } else {
      await _flutterTts.setLanguage("en-US");
    }
  }

  void _initTTS() async {
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.awaitSpeakCompletion(true);
  }

  void _startListening() async {
    if (_isListening) return;
    bool available = await _speech.initialize(
      onStatus: (status) => print("STT Status: $status"),
      onError: (error) => print("STT Error: $error"),
    );

    if (available) {
      if (mounted) setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          if (mounted) {
            setState(() {
              _userMessage = result.recognizedWords;
            });
          }
        },
        localeId: "th-TH",
      );
    }
  }

  void _stopListening() {
    if (!_isListening) return;
    _isListening = false;
    _speech.stop();
    if (_userMessage.isNotEmpty) {
      sendMessage();
    }
  }

  Future<void> sendMessage() async {
    if (_userMessage.trim().isEmpty) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
        _botResponse = "Thinking...";
      });
    }

    _chatHistory.add({"sender": "user", "message": _userMessage});

    try {
      final response = await http.post(
        Uri.parse("http://10.0.2.2:8080/chat"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": widget.userId,
          "message": _userMessage.trim(),
        }),
      );

      if (response.statusCode == 200) {
        var responseData = jsonDecode(utf8.decode(response.bodyBytes));
        String botReply = responseData["response"];
        String riskLevel = responseData["risk_level"] ?? "ไม่ระบุ";

        if (mounted) {
          setState(() {
            _botResponse = botReply;
            _riskLevel = riskLevel;
            _chatHistory.add({"sender": "bot", "message": botReply});
          });
        }
        await _flutterTts.speak(botReply);
      } else {
        if (mounted) {
          setState(() => _botResponse = "Error: Unable to get response.");
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _botResponse = "Error: $e");
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        _userMessage = "";
      });
    }
  }

  Color _getRiskColor() {
    switch (_riskLevel.toLowerCase()) {
      case "green":
        return Colors.green;
      case "red":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Voice Assistant"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 2,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _chatHistory.length,
              itemBuilder: (context, index) {
                var chatItem = _chatHistory[index];
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Align(
                    alignment: chatItem["sender"] == "user"
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        color: chatItem["sender"] == "user"
                            ? Colors.blueAccent
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        chatItem["message"]!,
                        style: TextStyle(
                          color: chatItem["sender"] == "user"
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_riskLevel != "ไม่ระบุ")
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "ระดับความเสี่ยง: ",
                    style: TextStyle(fontSize: 16),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getRiskColor(),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _riskLevel.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: AvatarGlow(
              glowColor: Colors.blueAccent,
              animate: _isListening && _speech.isListening,
              child: GestureDetector(
                onTap: _isListening ? _stopListening : _startListening,
                child: const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blueAccent,
                  child: Icon(
                    LucideIcons.mic,
                    color: Colors.white,
                    size: 25,
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            const CircularProgressIndicator(
              color: Colors.blueAccent,
            ),
        ],
      ),
    );
  }
}
