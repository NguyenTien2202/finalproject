// ignore_for_file: library_private_types_in_public_api, prefer_const_constructors

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_phosphor_icons/flutter_phosphor_icons.dart';
import 'package:provider/provider.dart';

import '../reusable_widgets/pie_chart.dart';
import '../reusable_widgets/reusable_widget.dart';
import '../service/profile_service.dart';
import 'data_entry.dart';
import 'models.dart';

class Waste extends StatefulWidget {
  const Waste({Key? key}) : super(key: key);

  @override
  _Waste createState() => _Waste();
}

class _Waste extends State<Waste> {
  final TextEditingController wasteController = TextEditingController();
  double get wasteUsage => _parseDouble(wasteController.text);

  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  double totalCO2 = 0.0;

  late ProfileService profile;

  DatabaseReference get totalCO2Ref =>
      profile.userRef.child('totalCo2').child('Element').child('Waste');

  DatabaseReference get usageRef =>
      profile.userRef.child('totalCo2').child('Usage');

  @override
  void initState() {
    profile = context.read<ProfileService>();
    loadData();
    super.initState();
  }

  void loadData() async {
    await profile.isReady.future;

    totalCO2 = double.tryParse((await totalCO2Ref.get()).value.toString()) ?? 0;
    final usageValue = (await usageRef.get()).value;
    if (usageValue != null) {
      final usageData = usageValue as Map<Object?, Object?>;
      wasteController.text = parseUsageText(usageData['waste']);
    }
    if (mounted) setState(() {});
  }

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
                        fontSize: 16, color: Color.fromARGB(255, 58, 111, 60)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              buildTextField('Waste', wasteController),
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
          suffixIcon: IconButton(
              onPressed: () => controller.text = '',
              icon: Icon(PhosphorIcons.x_circle_light))),
    );
  }

  Future<void> calculateCO2() async {
    showLoaderDialog(context);
    try {
      await _calculateCO2();
    } finally {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _calculateCO2() async {
    if (_anyFieldIsEmpty()) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Please enter all values')));
      return;
    }

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
    totalCO2Ref.set(totalCO2);
    usageRef.update({
      'waste': wasteUsage,
    });
  }

  bool _anyFieldIsEmpty() {
    return wasteController.text.isEmpty;
  }

  double _parseDouble(String value) {
    return double.tryParse(value) ?? 0;
  }

  void showPieChart() {
    if (totalCO2 == 0) return;

    final percentList = convertPercentage([wasteUsage]);
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => PieChartScreen(
                config: ChartConfig(title: 'Waste', lines: [
              ChartLine(
                  icon: Icon(PhosphorIcons.trash_light),
                  value: wasteUsage,
                  valueDisplay: percentList[0],
                  name: 'Waste',
                  color: Colors.indigo),
            ]))));
  }
}
