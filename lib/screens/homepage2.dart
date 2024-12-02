import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomePage2 extends StatefulWidget {
  const HomePage2({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomePage2> {
  final TextEditingController stationController = TextEditingController();
  final TextEditingController dateController = TextEditingController();

  Map<String, dynamic>? prediction; // To store prediction data
  bool isLoggedIn = true; // Simulating login status

  Future<void> getPrediction() async {
    final station = stationController.text.trim();
    final date = dateController.text.trim();

    if (station.isEmpty || date.isEmpty) {
      _showAlert('Error', 'Station and Date are required');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/predict_arima'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'station': station, 'date': date}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['Error'] != null) {
          _showAlert('Error', data['Error']);
        } else {
          setState(() {
            prediction = data;
          });
        }
      } else {
        _showAlert('Error', 'Failed to fetch prediction');
      }
    } catch (e) {
      _showAlert('Error', 'Network error. Please try again.');
    }
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Traffic Noise Prediction'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoggedIn
            ? SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Enter Details',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: stationController,
                      decoration: const InputDecoration(
                        labelText: 'Station (e.g., BEN01)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: dateController,
                      decoration: const InputDecoration(
                        labelText: 'Date (YYYY-MM-DD)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.datetime,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: getPrediction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightGreen,
                      ),
                      child: const Text('Get Prediction'),
                    ),
                    if (prediction != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.teal,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Prediction Results:',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Date: ${prediction!['Date']}',
                              style: const TextStyle(color: Colors.white),
                            ),
                            Text(
                              'Day Prediction: ${prediction!['Prediction']}',
                              style: const TextStyle(color: Colors.white),
                            ),
                            Text(
                              'Night Prediction: ${prediction!['Prediction2']}',
                              style: const TextStyle(color: Colors.white),
                            ),
                            Text(
                              'Day Accuracy: ${prediction!['r2_day']}',
                              style: const TextStyle(color: Colors.white),
                            ),
                            Text(
                              'Night Accuracy: ${prediction!['r2_night']}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          isLoggedIn = false; // Simulating logout
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'User not logged in',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 18,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Navigate to login page
                      },
                      child: const Text(
                        'Go to Login Page',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
