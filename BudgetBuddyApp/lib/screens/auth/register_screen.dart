import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<UserAuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Create Account")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Icon(Icons.person_add, size: 70, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              "Create a new account",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            // ERROR MESSAGE
            if (auth.errorMessage != null && auth.errorMessage!.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  auth.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            if (auth.errorMessage != null) const SizedBox(height: 16),

            // EMAIL
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: "Email",
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 16),

            // PASSWORD
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 30),

            // REGISTER BUTTON
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: auth.isLoading
                    ? null
                    : () async {
                  final email = emailController.text.trim();
                  final pass = passwordController.text.trim();

                  if (email.isEmpty || pass.isEmpty) {
                    setState(() {
                      auth.errorMessage =
                      "Please enter email and password";
                    });
                    return;
                  }

                  final error = await auth.register(email, pass);

                  if (error != null && mounted) {
                    setState(() {});
                  } else {
                    // SUCCESS → userModel loads & AppWrapper will redirect
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Account created successfully!"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                child: auth.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Create Account"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
