import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResetPasswordScreen extends StatefulWidget {
  final VoidCallback onDone;

  const ResetPasswordScreen({super.key, required this.onDone});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final passwordController = TextEditingController();
  bool isLoading = false;
  String message = "";

  Future<void> updatePassword() async {
    setState(() {
      isLoading = true;
      message = "";
    });

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: passwordController.text.trim()),
      );

      await Supabase.instance.client.auth.signOut();

      widget.onDone();
    } catch (e) {
      setState(() {
        message = "Hata: $e";
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: Center(
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(26),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_reset, color: Color(0xFF38BDF8), size: 52),
              const SizedBox(height: 16),
              const Text(
                "Yeni Şifre Oluştur",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Yeni şifre",
                  labelStyle: TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Color(0xFF0F172A),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 18),
              if (message.isNotEmpty)
                Text(message, style: const TextStyle(color: Colors.redAccent)),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : updatePassword,
                  child: Text(
                    isLoading ? "Kaydediliyor..." : "Şifreyi Güncelle",
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
