import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomePage> {
  final TextEditingController _stationController = TextEditingController();
  final TextEditingController _monthController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();

  String? errorMessage;
  String? predictedDayValue;
  String? predictedNightValue;
  String? r2day;
  String? r2night;

  Future<void> handlePredict() async {
    final String station = _stationController.text.trim();
    final String month = _monthController.text.trim();
    final String year = _yearController.text.trim();

    if (station.isEmpty || month.isEmpty || year.isEmpty) {
      setState(() {
        errorMessage = 'Please fill in all details.';
        predictedDayValue = null;
        predictedNightValue = null;
        r2day = null;
        r2night = null;
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/predict_random_forest'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'month': month, 'year': year, 'station': station}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          predictedDayValue = data['predicted_day_value'].toString();
          predictedNightValue = data['predicted_night_value'].toString();
          r2day = data['r2_day'].toString();
          r2night = data['r2_night'].toString();
          errorMessage = null;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to fetch prediction. Please try again.';
          predictedDayValue = null;
          predictedNightValue = null;
          r2day = null;
          r2night = null;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to fetch prediction. Please check your connection.';
        predictedDayValue = null;
        predictedNightValue = null;
        r2day = null;
        r2night = null;
      });
    }
  }

  @override
  void dispose() {
    _stationController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Prediction Page'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Enter Station, Month, and Year',
                style: TextStyle(color: Colors.red, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _stationController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Enter Station (e.g., BEN01)',
                  labelStyle: TextStyle(color: Colors.white),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _monthController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Month (e.g., 6)',
                  labelStyle: TextStyle(color: Colors.white),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _yearController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Year (e.g., 2023)',
                  labelStyle: TextStyle(color: Colors.white),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: handlePredict,
                // ignore: prefer_const_constructors
                style: ElevatedButton.styleFrom(backgroundColor: Colors.lightBlue, padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30)),
                child: Text('Predict'),
              ),
              const SizedBox(height: 20),
              if (errorMessage != null)
                Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              if (predictedDayValue != null && predictedNightValue != null)
                Container(
                  margin: const EdgeInsets.only(top: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 5)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Prediction Results:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text('Day Value: $predictedDayValue', style: const TextStyle(fontSize: 16)),
                      Text('Night Value: $predictedNightValue', style: const TextStyle(fontSize: 16)),
                      Text('Day Accuracy: $r2day', style: const TextStyle(fontSize: 16)),
                      Text('Night Accuracy: $r2night', style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
