import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signupscreen.dart';
import 'projectdecision.dart';

class LoginScreen extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  LoginScreen({super.key});

void _login(BuildContext context) async {
  String email = emailController.text.trim();
  String password = passwordController.text.trim();

  try {
    await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);

    // Navigate to Decision Page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) =>  const ProjectDecisionPage()),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Login Successful!")),
    );
  } catch (e) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(e.toString()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => _login(context),
              child: const Text('Login'),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignupScreen()),
                );
              },
              child: const Text(
                "Don't have an account? Sign up",
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
