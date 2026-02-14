import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard_screen.dart';
import 'first_time_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController userController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  final FirebaseFirestore db = FirebaseFirestore.instance;

  final FocusNode userFocus = FocusNode();
  final FocusNode passFocus = FocusNode();

  String errorMessage = "";
  bool isLoading = false;

  @override
  void dispose() {
    userController.dispose();
    passController.dispose();
    userFocus.dispose();
    passFocus.dispose();
    super.dispose();
  }

  Future<void> login() async {
    String user = userController.text.trim().toLowerCase();
    String pass = passController.text.trim();

    if (user.isEmpty) {
      setState(() => errorMessage = "Por favor ingrese usuario");
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    try {
      final snapshot = await db
          .collection('usuarios')
          .where('usuario', isEqualTo: user)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          errorMessage = "Usuario no encontrado";
          isLoading = false;
        });
        return;
      }

      final doc = snapshot.docs.first;
      final data = doc.data();
      final storedPass = data['password'] as String? ?? "";
      final isAdmin = data['isAdmin'] as bool? ?? false;
      final departamento = data['departamento'] as String? ?? "";

      if (isAdmin) {
        if (pass != storedPass) {
          setState(() {
            errorMessage = "Contraseña incorrecta";
            isLoading = false;
          });
          return;
        }
      } else {
        if (storedPass == "") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => FirstTimePasswordScreen(
                usuarioDocId: doc.id,
                usuario: user,
                departamento: departamento,
              ),
            ),
          );
          return;
        } else {
          if (pass != storedPass) {
            setState(() {
              errorMessage = "Contraseña incorrecta";
              isLoading = false;
            });
            return;
          }
        }
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardScreen(
            isAdmin: isAdmin,
            usuario: user,
            departamento: departamento,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        errorMessage = "Error al iniciar sesión";
        isLoading = false;
      });
    }
  }

  Future<void> forgotPassword() async {
    String user = userController.text.trim().toLowerCase();

    if (user.isEmpty) {
      setState(() => errorMessage = "Ingresa tu usuario primero");
      return;
    }

    final snapshot = await db
        .collection('usuarios')
        .where('usuario', isEqualTo: user)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      setState(() => errorMessage = "Usuario no encontrado");
      return;
    }

    final doc = snapshot.docs.first;
    final data = doc.data();
    final departamento = data['departamento'] as String? ?? "";

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FirstTimePasswordScreen(
          usuarioDocId: doc.id,
          usuario: user,
          departamento: departamento,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo degradado
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFD48585),
                  Color(0xFFDEDE95),
                  Color(0xFFEBDD65),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Blur de fondo general
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(color: Colors.transparent),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width: 420,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45), // más contraste
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: _buildForm(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          "Sentidos | Aromatización Profesional",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 28),

        _buildAnimatedField(
          controller: userController,
          label: "Usuario",
          focusNode: userFocus,
        ),
        const SizedBox(height: 18),

        _buildAnimatedField(
          controller: passController,
          label: "Contraseña",
          focusNode: passFocus,
          obscure: true,
        ),
        const SizedBox(height: 18),

        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: errorMessage.isNotEmpty
              ? Text(
                  errorMessage,
                  key: const ValueKey("error"),
                  style: const TextStyle(color: Colors.redAccent),
                )
              : const SizedBox(key: ValueKey("no_error")),
        ),

        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: isLoading ? null : login,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
              shadowColor: Colors.black.withValues(alpha: 0.25),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              layoutBuilder: (currentChild, previousChildren) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    ...previousChildren,
                    if (currentChild != null) currentChild,
                  ],
                );
              },
              child: isLoading
                  ? const SizedBox(
                      key: ValueKey("loader"),
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      "Ingresar",
                      key: ValueKey("text"),
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        TextButton(
          onPressed: forgotPassword,
          child: const Text(
            "¿Olvidaste tu contraseña?",
            style: TextStyle(color: Colors.white70),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedField({
    required TextEditingController controller,
    required String label,
    required FocusNode focusNode,
    bool obscure = false,
  }) {
    return AnimatedBuilder(
      animation: focusNode,
      builder: (context, child) {
        final isFocused = focusNode.hasFocus;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          transform: Matrix4.identity()..scale(isFocused ? 1.02 : 1.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              if (isFocused)
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.35),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            obscureText: obscure,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: const TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.8),
                  width: 2,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
