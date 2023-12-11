// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:finalapp/data/models.dart';
import 'package:flutter_phosphor_icons/flutter_phosphor_icons.dart';
import 'package:provider/provider.dart';

import '../reusable_widgets/pie_chart.dart';
import '../service/profile_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter Demo',
      home: SummaryScreen(),
    );
  }
}

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _SummaryScreenState createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  late ProfileService profile;

  double electricityCO2 = 0.0;
  double transportCO2 = 0.0;
  double wasteCO2 = 0.0;
  double totalCO2 = 0.0;

  StreamSubscription? stream;

  @override
  void initState() {
    super.initState();
    profile = context.read<ProfileService>();
    stream = profile.userRef.child('totalCo2').onValue.listen((event) {
      try {
        handleData(event); // Update data when changes occur
      } catch (e) {
        debugPrint('Fetch data error: $e');
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Unable to fetch data')));
      }
    });
  }

  @override
  void dispose() {
    stream?.cancel();
    super.dispose();
  }

  void handleData(DatabaseEvent event) {
    final snapshot = event.snapshot;
    final value = snapshot.value;
    if (value == null) return;
    debugPrint('totalData=$value');
    final totalData = TotalData.fromJson(jsonDecode(jsonEncode(value)));

    electricityCO2 = totalData.element['Electricity'] ?? 0;
    transportCO2 = totalData.element['Transport'] ?? 0;
    wasteCO2 = totalData.element['Waste'] ?? 0;
    totalCO2 = electricityCO2 + transportCO2 + wasteCO2;
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Summary"),
        centerTitle: true,
        backgroundColor: const Color(0xFFdcecca),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          const SizedBox(height: 70),
          InkWell(
            onTap: showPieChart,
            child: Container(
              alignment: Alignment.center,
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: const Color.fromARGB(
                    255, 220, 227, 212), // Màu nền của round
              ),
              child: Text(
                'Total CO2 Emission:\n${totalCO2.toStringAsFixed(2)} gCO2',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  color: Color.fromARGB(255, 58, 111, 60),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          buildCO2Container("Electricity CO2 Emission:  ",
              "${electricityCO2.toStringAsFixed(2)} gCO2"),
          const SizedBox(height: 20),
          buildCO2Container("Transport CO2 Emission: ",
              "${transportCO2.toStringAsFixed(2)} gCO2"),
          const SizedBox(height: 20),
          buildCO2Container(
              "Waste CO2 Emission:  ", "${wasteCO2.toStringAsFixed(2)} gCO2"),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget buildCO2Container(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(right: 25.0, left: 25.0),
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  void showPieChart() {
    if (totalCO2 == 0) return;

    final percentList =
        convertPercentage([electricityCO2, transportCO2, wasteCO2]);
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => PieChartScreen(
                config: ChartConfig(title: 'Total CO2 Emission', lines: [
              ChartLine(
                  icon: Icon(PhosphorIcons.lightbulb_light),
                  value: electricityCO2,
                  valueDisplay: percentList[0],
                  name: 'Electricity',
                  color: Colors.yellow),
              ChartLine(
                  icon: Icon(PhosphorIcons.car_light),
                  value: transportCO2,
                  valueDisplay: percentList[1],
                  name: 'Transport',
                  color: Colors.red),
              ChartLine(
                  icon: Icon(PhosphorIcons.trash_light),
                  value: wasteCO2,
                  valueDisplay: percentList[2],
                  name: 'Waste',
                  color: Colors.indigo),
            ]))));
  }
}
