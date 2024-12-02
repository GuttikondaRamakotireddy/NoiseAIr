import 'package:flutter/material.dart';
import 'decisionpage.dart';
import 'deeplearning.dart';

class ProjectDecisionPage extends StatelessWidget {
  const ProjectDecisionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Project Decision')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Please choose the prediction model:',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Navigate to HomePage (Random Forest Prediction)
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) =>  DeepLearning()),
                );
              },
              child: const Text('Urban Sound Classification'),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Navigate to HomePage2 (ARIMA Prediction)
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) =>  const DecisionPage()),
                );
              },
              child: const Text('Traffic Noise Forecast'),
            ),
          ],
        ),
      ),
    );
  }
}


