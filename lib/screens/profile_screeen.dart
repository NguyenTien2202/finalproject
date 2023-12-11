import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_database/firebase_database.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _passwordController = TextEditingController();
  String _currentUserName = '';
  Uint8List? _profileImageBytes;

  final currentUser = FirebaseAuth.instance.currentUser!;
  final TextEditingController _currentPasswordController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentUserName = _getUserNameFromEmail(currentUser.email!);
// Khởi tạo mật khẩu hiện tại
  }

  String _getUserNameFromEmail(String email) {
    return email.split('@').first.replaceAll(',', '.');
  }

  Future<void> _pickAndSaveImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final File imageFile = File(pickedFile.path);
      final Uint8List bytes = await imageFile.readAsBytes();

      setState(() {
        _profileImageBytes = bytes;
      });

      final String imagePath = await _saveImageToLocalDirectory(bytes);

      _saveUserDataToDatabase(
        currentUser.email!,
        _currentUserName,
        _passwordController.text,
        imagePath,
      );
    }
  }

  Future<String> _saveImageToLocalDirectory(Uint8List bytes) async {
    final appDir = await getApplicationDocumentsDirectory();
    final String imagePath = '${appDir.path}/images/profile_image.jpg';
    final File imageFile = File(imagePath);

    await imageFile.writeAsBytes(bytes);
    return imagePath;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        centerTitle: true,
        backgroundColor: const Color(0xFFdcecca),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          const SizedBox(height: 30),
          GestureDetector(
            onTap: _pickAndSaveImage,
            child: CircleAvatar(
              radius: 72,
              backgroundColor: Colors.grey[300],
              // ignore: sort_child_properties_last
              child: _profileImageBytes != null
                  ? null
                  : const Icon(
                      Icons.person,
                      size: 72,
                      color: Colors.black,
                    ),
              backgroundImage: _profileImageBytes != null
                  ? MemoryImage(_profileImageBytes!)
                  : null,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            currentUser.email!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[700]),
          ),
          const SizedBox(height: 50),
          const Padding(
            padding: EdgeInsets.only(left: 8.0),
            child: Text(
              'My Details',
              style: TextStyle(color: Color.fromARGB(255, 58, 111, 60)),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: const Color.fromARGB(255, 220, 227, 212),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Name ",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.settings,
                        color: Color.fromARGB(255, 58, 111, 60),
                      ),
                      onPressed: _editUserName,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(_currentUserName),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: const Color.fromARGB(255, 220, 227, 212),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Password",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.settings,
                    color: Color.fromARGB(255, 58, 111, 60),
                  ),
                  onPressed: _editPassword,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _updateProfile,
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  Future<void> _saveUserDataToDatabase(
    String email,
    String userName,
    String password,
    String imagePath,
  ) async {
    String key = email.split('@').first;

    DatabaseReference userRef =
        // ignore: deprecated_member_use
        FirebaseDatabase.instance.reference().child('users').child(key);

    await userRef.set({
      'email': email,
      'userName': userName,
      'password': password,
      'imagePath': imagePath,
    });
  }

  Future<void> _editPassword() async {
    _currentPasswordController.text = '';
    String newPassword = '';

    final result = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Password"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Current Password",
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                onChanged: (value) => newPassword = value,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "New Password",
                ),
              ),
            ],
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () async {
                    if (await _checkCurrentPassword()) {
                      // ignore: use_build_context_synchronously
                      Navigator.pop(context, true);
                    } else {
                      _showErrorMessage("Incorrect current password");
                    }
                  },
                  child: const Text("Save"),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (result != null && result == true) {
      _updatePassword(newPassword);
    }
  }

  Future<void> _updatePassword(String newPassword) async {
    try {
      await currentUser.updatePassword(newPassword);
      setState(() {});
      _showSuccessMessage("Password updated successfully!");
    } catch (error) {
      _showErrorMessage("Error: $error");
    }
  }

  Future<bool> _checkCurrentPassword() async {
    try {
      AuthCredential credential = EmailAuthProvider.credential(
        email: currentUser.email!,
        password: _currentPasswordController.text,
      );
      await currentUser.reauthenticateWithCredential(credential);
      return true;
    } catch (error) {
      return false;
    }
  }

  void _updateProfile() async {
    try {
      if (_passwordController.text.isNotEmpty) {
        await currentUser.updatePassword(_passwordController.text);
      }

      await _saveUserDataToDatabase(
        currentUser.email!,
        _currentUserName,
        _passwordController.text,
        _profileImageBytes != null
            ? await _saveImageToLocalDirectory(_profileImageBytes!)
            : '',
      );

      // ignore: deprecated_member_use
      await currentUser.updateProfile(displayName: _currentUserName);

      _showSuccessMessage("Update success!");
    } catch (error) {
      _showErrorMessage("Error: $error");
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _editUserName() {
    String newUserName = _currentUserName;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Name"),
          content: TextField(
            controller: TextEditingController(text: _currentUserName),
            onChanged: (value) {
              newUserName = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);

                setState(() {
                  _currentUserName = newUserName;
                });
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }
}
