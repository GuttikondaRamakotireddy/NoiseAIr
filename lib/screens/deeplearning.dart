import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart'; // Import flutter_tts for text-to-speech
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';

class DeepLearning extends StatefulWidget {
  const DeepLearning({super.key});

  @override
  _DeepLearningState createState() => _DeepLearningState();
}

class _DeepLearningState extends State<DeepLearning> {
  String? _filePath; // To store the selected file path
  String _uploadStatus = ""; // To display the upload status
  String _predictedClass = ""; // To display the predicted class
  final AudioPlayer _audioPlayer = AudioPlayer(); // AudioPlayer instance
  final FlutterTts _flutterTts = FlutterTts(); // FlutterTts instance for text-to-speech
  bool _isPlaying = false; // To track if audio is playing

  // Function to pick a file
  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio, // Only allow audio files
        allowMultiple: false,
      );

      if (result != null) {
        setState(() {
          _filePath = result.files.single.path ?? "File path is empty.";
          _uploadStatus = ""; // Reset upload status
          _predictedClass = ""; // Reset prediction
        });
      } else {
        setState(() {
          _filePath = "No file selected.";
        });
      }
    } catch (e) {
      setState(() {
        _filePath = "Error: $e";
      });
    }
  }

  // Function to play/pause the audio file
  Future<void> _togglePlayPause() async {
    if (_filePath == null || _filePath!.isEmpty || _filePath == "No file selected.") {
      setState(() {
        _uploadStatus = "Please select an audio file to play.";
      });
      return;
    }

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        setState(() {
          _isPlaying = false;
        });
      } else {
        await _audioPlayer.play(DeviceFileSource(_filePath!));
        setState(() {
          _isPlaying = true;
        });
      }
    } catch (e) {
      setState(() {
        _uploadStatus = "Error: $e";
      });
    }
  }

  // Function to upload the file and get the prediction from the backend
  Future<void> _uploadAndPredict() async {
    if (_filePath == null || _filePath!.isEmpty || _filePath == "No file selected.") {
      setState(() {
        _uploadStatus = "Please select an audio file before uploading.";
      });
      return;
    }

    try {
      final uri = Uri.parse("http://10.0.2.2:5000/predict_audio"); // Replace with backend IP
      final request = http.MultipartRequest('POST', uri);

      // Attach the audio file
      request.files.add(await http.MultipartFile.fromPath('audio_file', _filePath!));

      setState(() {
        _uploadStatus = "Uploading...";
      });

      // Send the request
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final responseData = json.decode(responseBody);

        setState(() {
          // Display the predicted class returned by Flask API
          _predictedClass = responseData['predicted_class'] ?? "Unknown";
          _uploadStatus = "Upload and prediction successful!";
        });

        // Speak the prediction (cleaned text)
        _speakPrediction();
      } else {
        setState(() {
          _uploadStatus = "Failed to upload and predict. Server responded with status code: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _uploadStatus = "Error: $e";
      });
    }
  }

  // Function to clean the predicted class text by removing special characters
  String _cleanText(String text) {
    // Replace special characters with an empty string or space
    return text.replaceAll(RegExp(r'[_@#\$\%\^&\*\(\)\[\]\{\};:,.<>?/\\|`~!]'), '');
  }

  // Function to speak the cleaned prediction using text-to-speech
  Future<void> _speakPrediction() async {
    if (_predictedClass.isNotEmpty) {
      String cleanedText = _cleanText(_predictedClass); // Clean the prediction text
      await _flutterTts.speak(cleanedText);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DeepLearning File Picker & Audio Player'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _pickFile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: const Text('Browse Audio Files'),
            ),
            const SizedBox(height: 20),
            Text(
              _filePath ?? 'No file selected yet.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _togglePlayPause,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isPlaying ? Colors.red : Colors.green,
              ),
              child: Text(_isPlaying ? 'Pause Audio' : 'Play Audio'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _uploadAndPredict,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text('Upload and Predict'),
            ),
            const SizedBox(height: 20),
            Text(
              _uploadStatus,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.red),
            ),
            const SizedBox(height: 20),

            // Prediction Box
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 2),
                borderRadius: BorderRadius.circular(8),
                color: Colors.blue[50], // Light background color
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _predictedClass.isNotEmpty
                        ? "Sound: $_predictedClass" // Updated text format
                        : "Prediction will appear here.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.volume_up),
                    onPressed: _speakPrediction, // Play the cleaned prediction text
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

