import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard_screen.dart';
import 'change_password_screen.dart'; // <- pantalla para crear/cambiar contraseña

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController userController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  final FirebaseFirestore db = FirebaseFirestore.instance;

  String errorMessage = "";

  Future<void> login() async {
    String user = userController.text.trim().toLowerCase();
    String pass = passController.text.trim();

    if (user.isEmpty) {
      setState(() {
        errorMessage = "Por favor ingrese usuario";
      });
      return;
    }

    try {
      final snapshot = await db
          .collection('usuarios')
          .where('usuario', isEqualTo: user)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          errorMessage = "Usuario no encontrado";
        });
        return;
      }

      final doc = snapshot.docs.first;
      final data = doc.data();
      final storedPass = data['password'] as String? ?? "";
      final isAdmin = data['isAdmin'] as bool? ?? false;
      final departamento = data['departamento'] as String? ?? "";

      if (isAdmin) {
        // Admin requiere contraseña siempre
        if (pass != storedPass) {
          setState(() {
            errorMessage = "Contraseña incorrecta";
          });
          return;
        }
      } else {
        // Representante
        if (storedPass == "") {
          // Primer acceso -> ir a ChangePasswordScreen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ChangePasswordScreen(
                usuarioDocId: doc.id,
              ),
            ),
          );
          return;
        } else {
          // Login normal de representante
          if (pass != storedPass) {
            setState(() {
              errorMessage = "Contraseña incorrecta";
            });
            return;
          }
        }
      }

      // Login exitoso -> abrir Dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardScreen(
            isAdmin: isAdmin,
            usuario: departamento,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        errorMessage = "Error al iniciar sesión: $e";
      });
    }
  }

  Future<void> forgotPassword() async {
    String user = userController.text.trim().toLowerCase();
    if (user.isEmpty) {
      setState(() {
        errorMessage = "Ingresa tu usuario primero";
      });
      return;
    }

    final snapshot = await db
        .collection('usuarios')
        .where('usuario', isEqualTo: user)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      setState(() {
        errorMessage = "Usuario no encontrado";
      });
      return;
    }

    final doc = snapshot.docs.first;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangePasswordScreen(
          usuarioDocId: doc.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
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
                  const Text(
                    "Sentidos | Aromatización Profesional",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: userController,
                    decoration: const InputDecoration(
                      labelText: "Usuario",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Contraseña",
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
                      onPressed: login,
                      child: const Text("Ingresar"),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: forgotPassword,
                    child: const Text("¿Olvidaste tu contraseña?"),
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
