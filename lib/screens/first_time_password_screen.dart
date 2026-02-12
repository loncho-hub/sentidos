import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard_screen.dart';

class FirstTimePasswordScreen extends StatefulWidget {
  final String usuarioDocId;
  final String departamento;

  const FirstTimePasswordScreen({
    super.key,
    required this.usuarioDocId,
    required this.departamento,
  });

  @override
  State<FirstTimePasswordScreen> createState() => _FirstTimePasswordScreenState();
}

class _FirstTimePasswordScreenState extends State<FirstTimePasswordScreen> {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();
  String errorMessage = "";

  Future<void> guardarPassword() async {
    String pass = passwordController.text.trim();
    String confirm = confirmController.text.trim();

    if (pass.isEmpty || confirm.isEmpty) {
      setState(() {
        errorMessage = "Complete todos los campos";
      });
      return;
    }

    if (pass != confirm) {
      setState(() {
        errorMessage = "Las contraseñas no coinciden";
      });
      return;
    }

    try {
      await db.collection('usuarios').doc(widget.usuarioDocId).update({
        'password': pass,
      });

      // Después de crear la contraseña, redirige al dashboard
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardScreen(
            isAdmin: false,
            usuario: widget.departamento,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        errorMessage = "Error al guardar contraseña: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Primer acceso - Crear contraseña")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Usuario: ${widget.departamento}",
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Nueva contraseña",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Confirmar contraseña",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (errorMessage.isNotEmpty)
                    Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: guardarPassword,
                      child: const Text("Guardar contraseña"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
