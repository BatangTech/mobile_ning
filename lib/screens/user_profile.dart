import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Removed firebase_auth import as it wasn't used directly in this screen's logic
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/screens/editncds_screen.dart'; // Assuming this path is correct

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final List<String> ncdOptions = [
    'โรคเบาหวาน', // เบาหวาน
    'โรคความดันโลหิตสูง', // ความดันโลหิตสูง
    'โรคหัวใจ', // โรคหัวใจ
    'โรคมะเร็ง', // มะเร็ง
    'โรคทางเดินหายใจเรื้อรัง',
  ];

  Map<String, bool> selectedNCDs = {};
  String name = '';
  // String email = ''; // Controlled by _emailController now
  // String phone = ''; // Controlled by _phoneController now
  bool isLoading = true;
  List<String> userNCDs = []; // Store the NCDs as a string list for display

  // Controllers for editable fields
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    // Initialize controllers before loading data
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _loadUserProfile();
  }

  // Clean up controllers when the widget is disposed
  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    if (!mounted) return; // Check if the widget is still in the tree
    setState(() => isLoading = true);

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists && mounted) {
        // Check mounted again before setState
        final data = userDoc.data()!;
        final List<dynamic> ncds = data['ncds'] ?? [];

        setState(() {
          name = data['name'] ?? 'N/A'; // Provide default if null
          // Set text for controllers
          _emailController.text = data['email'] ?? '';
          _phoneController.text = data['phone'] ?? '';

          // Store NCDs both as a map for checkboxes and list for display
          userNCDs = List<String>.from(ncds);
          selectedNCDs.clear(); // Clear previous selections
          for (var ncd in ncdOptions) {
            selectedNCDs[ncd] = ncds.contains(ncd);
          }
          isLoading = false;
        });
      } else {
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error loading user profile: $e");
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading profile: $e")),
        );
      }
    }
  }

  Future<void> _saveChanges() async {
    // Basic validation (optional but recommended)
    if (_emailController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email and Phone cannot be empty.")),
      );
      return;
    }
    if (!mounted) return;

    try {
      final selected = selectedNCDs.entries
          .where((entry) => entry.value)
          .map((e) => e.key)
          .toList();

      // Update Firestore with email, phone, and NCDs
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
        'ncds': selected,
        'email': _emailController.text.trim(), // Get value from controller
        'phone': _phoneController.text.trim(), // Get value from controller
      });

      if (!mounted) return;
      // Update the userNCDs list after saving
      setState(() {
        userNCDs = selected;
        // No need to update local email/phone strings as controllers hold the state
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("✅ Profile updated successfully")), // Updated message
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving changes: $e")),
        );
      }
    }
  }

  // Navigate to the EditNCDHistoryScreen
  Future<void> _navigateToEditNCDs() async {
    if (!mounted) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditNCDHistoryScreen(userId: widget.userId),
      ),
    );

    // If changes might have been made in the other screen, refresh the data
    if (result == true || result == null) {
      // Refresh even if back button is pressed
      _loadUserProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('User Profile')),
      body: GestureDetector(
        // Add GestureDetector to dismiss keyboard on tap outside
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              // --- Basic Info (Name non-editable, Email/Phone editable) ---
              Text("Name: $name", style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 15),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 25),

              // --- NCDs Display Section ---
              _buildNCDsSection(),
              const SizedBox(height: 25),

              // --- Edit NCDs in Current Screen Section ---
              const Text("แก้ไข NCDs",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Container(
                // Optional: Wrap checkboxes in a bordered container
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: ncdOptions.map((ncd) {
                    return CheckboxListTile(
                      title: Text(ncd),
                      value: selectedNCDs[ncd] ?? false,
                      controlAffinity:
                          ListTileControlAffinity.leading, // Checkbox on left
                      dense: true, // Make tiles more compact
                      onChanged: (value) {
                        setState(() {
                          selectedNCDs[ncd] = value ?? false;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 25),

              // --- Save Button ---
              ElevatedButton.icon(
                onPressed: _saveChanges,
                icon: const Icon(Icons.save),
                label: const Text("Save Profile Changes"), // Updated label
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white, // Text color
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 30),

              // --- Button to Navigate to the Separate EditNCDHistoryScreen ---
              ElevatedButton.icon(
                onPressed:
                    _navigateToEditNCDs, // Still navigates to the other screen
                icon: const Icon(Icons.edit_note),
                label: const Text(
                    "Edit NCDs History (Full Screen)"), // Clarified label
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00796B),
                  foregroundColor: Colors.white, // Text color
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget to display the current NCDs (No changes needed here)
  Widget _buildNCDsSection() {
    // ... (Keep the existing _buildNCDsSection code) ...
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'โรคประจำตัว',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF212529),
                  ),
                ),
                // IconButton still navigates to the full screen editor
                IconButton(
                  icon: const Icon(Icons.edit, color: Color(0xFF00796B)),
                  tooltip: 'Edit NCDs in Full Screen', // Add tooltip
                  onPressed: _navigateToEditNCDs,
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            userNCDs.isEmpty
                ? const Text(
                    'ไม่มีข้อมูลโรคประจำตัว',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6C757D),
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        userNCDs.map((ncd) => _buildNCDChip(ncd)).toList(),
                  ),
          ],
        ),
      ),
    );
  }

  // Visual representation of each NCD (No changes needed here)
  Widget _buildNCDChip(String ncd) {
    // ... (Keep the existing _buildNCDChip code) ...
    return Chip(
      backgroundColor: const Color(0xFFE0F2F1),
      side: const BorderSide(color: Color(0xFF4DB6AC)),
      label: Text(
        ncd,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF00796B),
        ),
      ),
      avatar: const Icon(
        Icons.medical_services,
        size: 16,
        color: Color(0xFF00796B),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}

// Placeholder for the EditNCDHistoryScreen to avoid compile errors
// Replace with your actual import if it's in a different file structure
// namespace frontend { namespace screens { class EditNCDHistoryScreen {} } }
class EditNCDHistoryScreen extends StatelessWidget {
  final String userId;
  const EditNCDHistoryScreen({Key? key, required this.userId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('แก้ไขประวัติ NCDs')),
      body: Center(
        child: ElevatedButton(
          onPressed: () =>
              Navigator.pop(context, true), // Simulate making a change
          child: const Text('Simulate Save and Go Back'),
        ),
      ),
    );
  }
}
