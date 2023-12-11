// ignore_for_file: library_private_types_in_public_api, prefer_const_constructors

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import 'models.dart';

class Transport extends StatefulWidget {
  const Transport({Key? key}) : super(key: key);

  @override
  _Transport createState() => _Transport();
}

class _Transport extends State<Transport> {
  final TextEditingController carController = TextEditingController();
  final TextEditingController motorbikeController = TextEditingController();
  final TextEditingController busController = TextEditingController();
  final TextEditingController trainController = TextEditingController();

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
              const SizedBox(height: 10),
              Center(
                child: Text(
                  'Transport',
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
              buildTextField('Car', carController),
              const SizedBox(height: 20),
              buildTextField('Motorbike', motorbikeController),
              const SizedBox(height: 20),
              buildTextField('Bus', busController),
              const SizedBox(height: 20),
              buildTextField('Train', trainController),
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

    double carUsage = _parseDouble(carController.text);
    double motorbikeUsage = _parseDouble(motorbikeController.text);
    double busUsage = _parseDouble(busController.text);
    double trainUsage = _parseDouble(trainController.text);

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

        totalCO2 = (carUsage * carbonData.transport['Car']! +
                motorbikeUsage * carbonData.transport['Motorbike']! +
                busUsage * carbonData.transport['Bus']! +
                trainUsage * carbonData.transport['Train']!) *
            1000;
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
    // Tạo một DatabaseReference tới nhánh totalCo2 với key là ngày tháng năm hiện tại
    DatabaseReference totalCO2Ref =
        _database.child('totalCo2').child('Element');

    // Lưu giá trị totalCO2 vào nhánh totalCo2
    totalCO2Ref.child('Transport').set(totalCO2);
  }

  bool _anyFieldIsEmpty() {
    return carController.text.isEmpty ||
        motorbikeController.text.isEmpty ||
        busController.text.isEmpty ||
        trainController.text.isEmpty;
  }

  double _parseDouble(String value) {
    return double.tryParse(value) ?? 0;
  }
}
