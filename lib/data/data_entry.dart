// ignore_for_file: library_private_types_in_public_api, prefer_const_constructors

import 'dart:convert';

import 'package:finalapp/data/models.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class DataEntry extends StatefulWidget {
  const DataEntry({Key? key}) : super(key: key);

  @override
  _DataEntry createState() => _DataEntry();
}

class _DataEntry extends State<DataEntry> {
  final TextEditingController laptopController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController televisionController = TextEditingController();

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
              const SizedBox(height: 40),
              Center(
                child: Text(
                  'Electricity',
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
              buildTextField('Laptop', laptopController),
              const SizedBox(height: 20),
              buildTextField('Phone', phoneController),
              const SizedBox(height: 20),
              buildTextField('Television', televisionController),
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
        labelText: '$label Usage (hours)',
      ),
    );
  }

  void calculateCO2() async {
    if (_anyFieldIsEmpty()) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Please enter all values')));
      return;
    }

    double laptopUsage = _parseDouble(laptopController.text);
    double phoneUsage = _parseDouble(phoneController.text);
    double televisionUsage = _parseDouble(televisionController.text);

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

        totalCO2 = (laptopUsage * carbonData.electricity['Laptop']! +
                phoneUsage * carbonData.electricity['Phone']! +
                televisionUsage * carbonData.electricity['Television']!) *
            1000;

        setState(() {});

        // Lưu kết quả vào Realtime Database
        saveTotalCO2ToDatabase();
      } catch (e) {
        debugPrint('Parse error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: Unable to perform calculations')));
      }
    });
  }

  void saveTotalCO2ToDatabase() {
    // Tạo một DatabaseReference tới nhánh TotalCo2 với key là ngày tháng năm hiện tại
    DatabaseReference totalCO2Ref =
        _database.child('totalCo2').child('Element').child('Electricity');

    // Lưu giá trị totalCO2 vào nhánh TotalCo2
    totalCO2Ref.set(totalCO2);
  }

  bool _anyFieldIsEmpty() {
    return laptopController.text.isEmpty ||
        phoneController.text.isEmpty ||
        televisionController.text.isEmpty;
  }

  double _parseDouble(String value) {
    return double.tryParse(value) ?? 0;
  }
}
