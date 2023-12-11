// ignore_for_file: library_private_types_in_public_api, prefer_const_constructors

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import 'models.dart';

class Waste extends StatefulWidget {
  const Waste({Key? key}) : super(key: key);

  @override
  _Waste createState() => _Waste();
}

class _Waste extends State<Waste> {
  final TextEditingController wasteController = TextEditingController();

  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  double totalCO2 = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 120),
              Center(
                child: Text(
                  'Waste',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
              Container(
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
                      fontSize: 16, color: Color.fromARGB(255, 58, 111, 60)),
                ),
              ),
              const SizedBox(height: 20),
              buildTextField('Watse', wasteController),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: calculateCO2,
                child: Text('Calculate CO2'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: '$label Usage (kg)',
      ),
    );
  }

  void calculateCO2() async {
    if (_anyFieldIsEmpty()) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Please enter all values')));
      return;
    }

    double wasteUsage = _parseDouble(wasteController.text);

    final doc = _database.child('carbon_data');
    await doc.once().then((DatabaseEvent? event) {
      if (event?.snapshot.exists != true) {
        return ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: Snapshot is null')));
      }
      try {
        final snapshot = event!.snapshot;
        final carbonData =
            CarbonData.fromJson(jsonDecode(jsonEncode(snapshot.value)));

        totalCO2 = wasteUsage * carbonData.waste['General']! * 1000;
        setState(() {});
        saveTotalCO2ToDatabase();
      } catch (e) {
        debugPrint('Parse error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: Unable to perform calculations')));
      }
    });
  }

  void saveTotalCO2ToDatabase() {
    DatabaseReference totalCO2Ref =
        _database.child('totalCo2').child('Element');

    // Lưu giá trị totalCO2 vào nhánh totalCo2
    totalCO2Ref.child('Waste').set(totalCO2);
  }

  bool _anyFieldIsEmpty() {
    return wasteController.text.isEmpty;
  }

  double _parseDouble(String value) {
    return double.tryParse(value) ?? 0;
  }
}
