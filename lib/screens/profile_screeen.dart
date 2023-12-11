import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';

import '../service/profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _passwordController = TextEditingController();
  late ProfileService srv;

  String _currentUserName = '';

  final currentUser = FirebaseAuth.instance.currentUser!;
  final TextEditingController _currentPasswordController =
      TextEditingController();

  DatabaseReference get userRef {
    String key = currentUser.email!.split('@').first;
    return FirebaseDatabase.instance.ref().child('users').child(key);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    srv = context.watch<ProfileService>();
    _currentUserName = srv.userName;
    super.didChangeDependencies();
  }

  Future<void> _pickAndSaveImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    debugPrint('picked image ${pickedFile.path}');
    if (!context.mounted) return;

    showLoaderDialog(context);
    await srv.updatePhoto(File(pickedFile.path));
    // Dismiss loader dialog
    if (context.mounted) {
      Navigator.of(context).pop();
    }
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
            onTap: () => _pickAndSaveImage(),
            child: const ProfileAvatar(avatarSize: 72 * 2, iconSize: 72),
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
      await currentUser.updateDisplayName(_currentUserName);

      await srv.saveMeta(
        email: currentUser.email!,
        userName: _currentUserName,
      );
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

void showLoaderDialog(BuildContext context) {
  AlertDialog alert = AlertDialog(
    content: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(),
        Container(
            margin: const EdgeInsets.only(left: 24),
            child: const Text("Loading...")),
      ],
    ),
  );
  showDialog(
    barrierDismissible: false,
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar(
      {super.key, required this.avatarSize, required this.iconSize});
  final double avatarSize;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final srv = context.watch<ProfileService>();
    final img = srv.profileImage;
    return Center(
      child: CircleAvatar(
        // Reference to a dynamic key to prevent FileImage cache on same file name
        key: ValueKey(srv.lastUpdated),
        radius: avatarSize / 2,
        backgroundColor: Colors.grey[300],
        backgroundImage: img != null ? FileImage(img) : null,
        child: img != null
            ? Container()
            : Icon(
                Icons.person,
                size: iconSize,
                color: Colors.black,
              ),
      ),
    );
  }
}
