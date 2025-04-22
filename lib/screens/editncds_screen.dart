import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EditNCDHistoryScreen extends StatefulWidget {
  final String userId;

  const EditNCDHistoryScreen({super.key, required this.userId});

  @override
  State<EditNCDHistoryScreen> createState() => _EditNCDHistoryScreenState();
}

class _EditNCDHistoryScreenState extends State<EditNCDHistoryScreen> {
  // --- Modern UI Colors & Gradients ---
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF3949AB), Color(0xFF1A237E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const accentGradient = LinearGradient(
    colors: [Color(0xFF00ACC1), Color(0xFF006064)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const backgroundGradient = LinearGradient(
    colors: [Color(0xFFF5F7FA), Color(0xFFE4E8F0)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const cardBackgroundColor = Colors.white;
  static const textColor = Color(0xFF2C3E50);
  static const subtleTextColor = Color(0xFF7F8C8D);
  static const selectedItemColor = Color(0xFFE1F5FE);
  static const selectedItemBorderColor = Color(0xFF039BE5);
  static const iconColor = Color(0xFF0288D1);

  final List<Map<String, dynamic>> ncdOptions = [
    {
      'title': 'โรคเบาหวาน',
      'icon': Icons.monitor_heart_outlined,
      'description': 'โรคที่มีระดับน้ำตาลในเลือดสูงกว่าปกติ',
    },
    {
      'title': 'โรคความดันโลหิตสูง',
      'icon': Icons.speed_outlined,
      'description': 'โรคที่มีความดันเลือดสูงกว่าค่าปกติ',
    },
    {
      'title': 'โรคหัวใจ',
      'icon': Icons.favorite_outline,
      'description': 'โรคที่มีความผิดปกติของระบบหัวใจและหลอดเลือด',
    },
    {
      'title': 'โรคมะเร็ง',
      'icon': Icons.medical_services_outlined,
      'description': 'กลุ่มโรคที่มีการเจริญเติบโตผิดปกติของเซลล์',
    },
    {
      'title': 'โรคทางเดินหายใจเรื้อรัง',
      'icon': Icons.air_outlined,
      'description': 'โรคที่ส่งผลกระทบต่อปอดและระบบทางเดินหายใจ',
    }
  ];

  Map<String, bool> selectedNCDs = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserNCDs();
  }

  Future<void> _loadUserNCDs() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (!mounted) return;

      final data = doc.data();
      final List<dynamic> userNCDs = data?['ncds'] as List<dynamic>? ?? [];

      setState(() {
        selectedNCDs = {
          for (var ncd in ncdOptions)
            ncd['title']: userNCDs.contains(ncd['title']),
        };
      });
    } catch (e) {
      if (!mounted) return;

      _showErrorSnackBar('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e');
      setState(() {
        selectedNCDs = {for (var ncd in ncdOptions) ncd['title']: false};
      });

      print("Error loading NCDs: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _saveNCDs() async {
    setState(() => isLoading = true);

    final selected = selectedNCDs.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({'ncds': selected});

      if (mounted) {
        _showSuccessSnackBar('บันทึกข้อมูลสำเร็จ');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('เกิดข้อผิดพลาดในการบันทึก: $e');
        setState(() => isLoading = false);
      }
      print("Error saving NCDs: $e");
    }
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 0, 137, 16),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        margin: const EdgeInsets.all(15.0),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        margin: const EdgeInsets.all(15.0),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('ประวัติโรคประจำตัว',
            style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        centerTitle: true,
        foregroundColor: Colors.white,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          TextButton(
            onPressed: !isLoading ? _saveNCDs : null,
            child: Text(
              'บันทึก',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          SizedBox(width: 8),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: primaryGradient,
        ),
        // แก้ปัญหา RenderFlex overflow โดยใช้ SingleChildScrollView แทน Column
        child: SafeArea(
          bottom: true, // เพิ่ม bottom margin ให้กับ SafeArea
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.medical_information_outlined,
                          size: 42,
                          color: Colors.white,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'เลือกโรคประจำตัวของคุณ',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'ข้อมูลนี้จะช่วยให้เราสามารถให้คำแนะนำที่เหมาะสมกับสุขภาพของคุณ',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                // Main Content - List of NCDs
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: isLoading
                      ? Container(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: Center(
                            child: SingleChildScrollView(
                              // เพิ่ม SingleChildScrollView ครอบ Column
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          iconColor),
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'กำลังโหลดข้อมูล...',
                                      style: GoogleFonts.poppins(
                                        color: subtleTextColor,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                      : _buildNCDList(),
                ),

                // เพิ่ม padding ที่ด้านล่างเพื่อป้องกัน overflow
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNCDList() {
    // เปลี่ยนจาก ListView.builder เป็นการแสดงรายการแบบ Column
    // เพื่อหลีกเลี่ยงปัญหา ListView ซ้อนใน SingleChildScrollView
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
      child: Column(
        children: List.generate(ncdOptions.length, (index) {
          final ncd = ncdOptions[index];
          final title = ncd['title'];
          final icon = ncd['icon'];
          final description = ncd['description'];
          final isSelected = selectedNCDs[title] ?? false;

          return Padding(
            // ลดขนาด padding สำหรับรายการสุดท้าย
            padding: EdgeInsets.only(
                bottom: index == ncdOptions.length - 1 ? 0.0 : 16.0),
            child: _NCDListItem(
              title: title,
              description: description,
              icon: icon,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  selectedNCDs[title] = !isSelected;
                });
              },
            ),
          );
        }),
      ),
    );
  }
}

class _NCDListItem extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _NCDListItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18.0),
      elevation: isSelected ? 4.0 : 1.0,
      shadowColor: isSelected
          ? _EditNCDHistoryScreenState.selectedItemBorderColor.withOpacity(0.3)
          : Colors.grey.withOpacity(0.2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18.0),
        splashColor:
            _EditNCDHistoryScreenState.selectedItemColor.withOpacity(0.5),
        highlightColor:
            _EditNCDHistoryScreenState.selectedItemColor.withOpacity(0.3),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutQuint,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? _EditNCDHistoryScreenState.selectedItemColor
                : _EditNCDHistoryScreenState.cardBackgroundColor,
            border: Border.all(
              color: isSelected
                  ? _EditNCDHistoryScreenState.selectedItemBorderColor
                  : Colors.grey.shade200,
              width: isSelected ? 2.0 : 1.0,
            ),
            borderRadius: BorderRadius.circular(18.0),
          ),
          child: Row(
            children: [
              // Left part: Icon in a circle
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? _EditNCDHistoryScreenState.selectedItemBorderColor
                          .withOpacity(0.15)
                      : Colors.grey.shade100,
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: isSelected
                      ? _EditNCDHistoryScreenState.selectedItemBorderColor
                      : Colors.grey.shade600,
                ),
              ),

              SizedBox(width: 16),

              // Middle part: Title and description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        color: _EditNCDHistoryScreenState.textColor,
                        fontSize: 16,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.poppins(
                        color: _EditNCDHistoryScreenState.subtleTextColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: 12),

              // Right part: Checkbox
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: isSelected
                    ? Container(
                        key: ValueKey('selected'),
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: _EditNCDHistoryScreenState
                              .selectedItemBorderColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _EditNCDHistoryScreenState
                                  .selectedItemBorderColor
                                  .withOpacity(0.3),
                              blurRadius: 5,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 18,
                        ),
                      )
                    : Container(
                        key: ValueKey('unselected'),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
