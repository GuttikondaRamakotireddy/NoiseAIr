import 'package:flutter/material.dart';
import 'homepage1.dart';
import 'homepage2.dart';

class DecisionPage extends StatelessWidget {
  const DecisionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Decision Page')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Please choose the prediction model:',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to HomePage (Random Forest Prediction)
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) =>  HomePage()),
                );
              },
              child: const Text('Go to Random Forest Prediction'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to HomePage2 (ARIMA Prediction)
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) =>  HomePage2()),
                );
              },
              child: const Text('Go to ARIMA Prediction'),
            ),
          ],
        ),
      ),
    );
  }
}

