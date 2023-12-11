// ignore_for_file: prefer_const_constructors

import 'package:finalapp/data/transport.dart';
import 'package:finalapp/data/waste.dart';
import 'package:finalapp/reusable_widgets/drawer.dart';
import 'package:finalapp/screens/signin_screen.dart';
import 'package:finalapp/screens/summary_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:finalapp/data/data_entry.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'profile_screeen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    DataEntry(),
    Transport(),
    Waste(),
  ];

  final user = FirebaseAuth.instance.currentUser;

  void signUserOut() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();

    if (mounted) {
      // ignore: use_build_context_synchronously
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SignInScreen()),
      );
    }
  }

//navigator to profile screen
  void goToProfileScreen() {
    //pop menu drawer
    Navigator.pop(context);

    //go to profile screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfileScreen(),
      ),
    );
  }

  void goToSummaryScreen() {
    //pop menu drawer
    Navigator.pop(context);

    //go to profile screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SummaryScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Calculate CO2"),
        backgroundColor: Color(0xFFdcecca),
      ),
      drawer: MyDrawer(
        onProfileTap: goToProfileScreen,
        onSignOut: signUserOut,
        onSummaryTap: goToSummaryScreen,
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.laptop),
            label: 'Electricity',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.car_repair),
            label: 'Transport',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restore_from_trash_rounded),
            label: 'Waste',
          ),
        ],
        currentIndex: _currentIndex,
        backgroundColor: Color(0xFFdcecca),
        selectedItemColor: Colors.green[800],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
