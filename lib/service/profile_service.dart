import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:firebase_database/firebase_database.dart';
import 'package:path_provider/path_provider.dart';

class ProfileService with ChangeNotifier {
  late String appDir;
  DateTime? lastUpdated;

  String _userName = '';
  String get userName => _userName;

  User? _currentUser;
  User get currentUser => _currentUser!;

  final _isReady = Completer<bool>();

  Future<File?> getProfileImage() async {
    await _isReady.future;
    return _profileImage;
  }

  File? _profileImage;

  String _getUserNameFromEmail(String email) {
    return email.split('@').first.replaceAll(',', '.');
  }

  DatabaseReference get userRef {
    return FirebaseDatabase.instance
        .ref()
        .child('users')
        .child(currentUser.uid);
  }

  ProfileService() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      // Reload profile everytime user changes
      _currentUser = user;
      if (user != null) {
        init();
      }
    });
  }

  void init() async {
    appDir = (await getApplicationDocumentsDirectory()).path;

    final snapshot = await userRef.get();
    String? userName;
    String? imagePath;
    if (snapshot.exists) {
      final stored = snapshot.value! as Map;
      userName = stored['userName'];
      imagePath = stored['imagePath'];
      debugPrint('Loaded $appDir meta $stored');
    }
    _userName = userName ?? _getUserNameFromEmail(currentUser.email!);

    if (imagePath != null) {
      // Force image relative path
      if (imagePath.startsWith('/')) {
        imagePath = imagePath.substring(1);
      }

      _profileImage = File(path.join(appDir, imagePath));
    }

    if (!_isReady.isCompleted) {
      _isReady.complete(true);
    }
    notifyListeners();
  }

  Future<void> saveMeta({
    required String email,
    required String userName,
  }) async {
    _userName = userName;
    await userRef.update({
      'email': email,
      'userName': userName,
    });
  }

  Future<void> _savePhotoPath(String imagePath) => userRef.update({
        'imagePath': imagePath,
      });

  Future<void> updatePhoto(File imageFile) async {
    final Uint8List bytes = await imageFile.readAsBytes();

    final savedFile =
        await _saveImageToLocalDirectory(path.basename(imageFile.path), bytes);
    // Retrieve relative path without leading "/"
    final relPath = savedFile.path.split(appDir)[1].substring(1);
    debugPrint('Saving $relPath');

    await _savePhotoPath(relPath);
    _profileImage = savedFile;
    lastUpdated = DateTime.now();
    notifyListeners();
  }

  Future<File> _saveImageToLocalDirectory(String name, Uint8List bytes) async {
    final imagesDir = Directory(path.join(appDir, 'images'));
    if (!imagesDir.existsSync()) {
      await imagesDir.create();
    }
    final imagePath = path.join(imagesDir.path, name);
    final File imageFile = File(imagePath);

    await imageFile.writeAsBytes(bytes);
    return imageFile;
  }
}
