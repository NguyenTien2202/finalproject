// ignore_for_file: library_private_types_in_public_api, prefer_const_constructors

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_phosphor_icons/flutter_phosphor_icons.dart';
import 'package:flutter_svg/svg.dart';

import '../reusable_widgets/pie_chart.dart';
import '../reusable_widgets/reusable_widget.dart';
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

  double get carUsage => _parseDouble(carController.text);
  double get motorbikeUsage => _parseDouble(motorbikeController.text);
  double get busUsage => _parseDouble(busController.text);
  double get trainUsage => _parseDouble(trainController.text);

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

  void showPieChart() {
    final percentList =
        convertPercentage([carUsage, motorbikeUsage, busUsage, trainUsage]);
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => PieChartScreen(
                config: ChartConfig(title: 'Transport', lines: [
              ChartLine(
                  icon: Icon(PhosphorIcons.car_light),
                  value: carUsage,
                  valueDisplay: percentList[0],
                  name: 'Car',
                  color: Colors.amber),
              ChartLine(
                  icon: SvgPicture.string(
                    '<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" fill="#000000" viewBox="0 0 256 256"><path d="M216,122a38.48,38.48,0,0,0-7.87.82L200.9,104a57.83,57.83,0,0,1,15.1-2,6,6,0,0,0,0-12H195.51L181.6,53.85A6,6,0,0,0,176,50H144a6,6,0,0,0,0,12h27.88l10.77,28H152c-18,0-32.58,4.15-42.1,12A18.05,18.05,0,0,1,91,104.35C77.9,98.38,30.4,79.19,26,77.46l-5.72-2.24A14.66,14.66,0,0,0,16,74a6,6,0,0,0-2.15,11.6h0c.46.18,47.13,18.26,72.23,29.67a30.12,30.12,0,0,0,31.47-4c7.34-6,19.25-9.25,34.46-9.25h24.89a70,70,0,0,0-28.32,39.13A17.85,17.85,0,0,1,131.32,154H77.52a38,38,0,1,0,0,12h53.8a29.9,29.9,0,0,0,28.81-21.64,58,58,0,0,1,29.58-36l7.23,18.8A38,38,0,1,0,216,122ZM40,166H65.29a26,26,0,1,1,0-12H40a6,6,0,0,0,0,12Zm176,20a26,26,0,0,1-14.68-47.45l9.08,23.6a6,6,0,0,0,11.2-4.3l-9.08-23.61A26.64,26.64,0,0,1,216,134a26,26,0,0,1,0,52Z"></path></svg>',
                    width: 24,
                    height: 24,
                  ),
                  value: motorbikeUsage,
                  valueDisplay: percentList[1],
                  name: 'Motorbike',
                  color: Colors.cyan),
              ChartLine(
                  icon: Icon(PhosphorIcons.bus_light),
                  value: busUsage,
                  valueDisplay: percentList[2],
                  name: 'Bus',
                  color: Colors.lime),
              ChartLine(
                  icon: Icon(PhosphorIcons.train_light),
                  value: trainUsage,
                  valueDisplay: percentList[2],
                  name: 'Train',
                  color: Colors.deepOrange),
            ]))));
  }
}

double _parseDouble(String value) {
  return double.tryParse(value) ?? 0;
}
