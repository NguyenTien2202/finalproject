// ignore_for_file: prefer_const_constructors

import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:finalapp/data/models.dart';

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
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  double electricityCO2 = 0.0;
  double transportCO2 = 0.0;
  double wasteCO2 = 0.0;
  double totalCO2 = 0.0;
  double displaytotalCO2 = 0.0;

  @override
  void initState() {
    super.initState();
    fetchDataFromDatabase();
    _database.child('totalCo2').onValue.listen((event) {
      fetchDataFromDatabase(); // Update data when changes occur
    });
  }

  Future<void> fetchDataFromDatabase() async {
    try {
      // Change the reference to 'totalCo2'
      final doc = _database.child('totalCo2');

      await doc.once().then((DatabaseEvent? event) {
        if (event?.snapshot.exists != true) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error: Snapshot is null')));
          return;
        }
        final snapshot = event!.snapshot;

        final totalData =
            TotalData.fromJson(jsonDecode(jsonEncode(snapshot.value)));

        electricityCO2 = totalData.element['Electricity']!;
        transportCO2 = totalData.element['Transport']!;
        wasteCO2 = totalData.element['Waste']!;
        displaytotalCO2 = totalData.total;
        setState(() {});
      });
    } catch (e) {
      debugPrint('Fetch data error: $e');
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Unable to fetch data')));
    }
  }

  void saveTotalCO2ToDatabase() {
    // Tạo một DatabaseReference tới nhánh TotalCo2 với key là ngày tháng năm hiện tại
    DatabaseReference totalCO2Ref = _database.child('totalCo2').child('Total');

    // Lưu giá trị totalCO2 vào nhánh TotalCo2
    totalCO2Ref.set(totalCO2);
  }

  void calculateCO2() async {
    final doc = _database.child('totalCo2');
    await doc.once().then((DatabaseEvent? event) {
      if (event?.snapshot.exists != true) {
        return ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: Snapshot is null')));
      }
      try {
        final snapshot = event!.snapshot;
        final totalData =
            TotalData.fromJson(jsonDecode(jsonEncode(snapshot.value)));
        totalCO2 = totalData.element['Electricity']! +
            totalData.element['Transport']! +
            totalData.element['Waste']!;
        setState(() {});

        saveTotalCO2ToDatabase();
      } catch (e) {
        debugPrint('Parse error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: Unable to perform calculations')));
      }
    });
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
          Container(
            alignment: Alignment.center,
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color:
                  const Color.fromARGB(255, 220, 227, 212), // Màu nền của round
            ),
            child: Text(
              'Total CO2 Emission:\n${displaytotalCO2.toStringAsFixed(2)} gCO2',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                color: Color.fromARGB(255, 58, 111, 60),
                fontWeight: FontWeight.bold,
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
          ElevatedButton(
            onPressed: calculateCO2,
            child: const Text('Calculate CO2'),
          ),
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
}
