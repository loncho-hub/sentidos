import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChangePasswordScreen extends StatefulWidget {
  final String usuarioDocId; // ID del documento del usuario en Firestore

  const ChangePasswordScreen({super.key, required this.usuarioDocId});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final TextEditingController passController = TextEditingController();
  final TextEditingController confirmPassController = TextEditingController();

  String errorMessage = "";

  Future<void> cambiarPassword() async {
    String pass = passController.text.trim();
    String confirm = confirmPassController.text.trim();

    if (pass.isEmpty || confirm.isEmpty) {
      setState(() {
        errorMessage = "Completa ambos campos";
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

      // Cerrar pantalla y volver al login
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Contraseña cambiada con éxito")),
      );
    } catch (e) {
      setState(() {
        errorMessage = "Error al actualizar la contraseña: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cambiar contraseña")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: passController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Nueva contraseña",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPassController,
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
                onPressed: cambiarPassword,
                child: const Text("Guardar"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
