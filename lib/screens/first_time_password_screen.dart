import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard_screen.dart';

class FirstTimePasswordScreen extends StatefulWidget {
  final String usuarioDocId;
  final String usuario;
  final String departamento;

  const FirstTimePasswordScreen({
    super.key,
    required this.usuarioDocId,
    required this.usuario,
    required this.departamento,
  });

  @override
  State<FirstTimePasswordScreen> createState() =>
      _FirstTimePasswordScreenState();
}

class _FirstTimePasswordScreenState extends State<FirstTimePasswordScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController passController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();

  final FocusNode passFocus = FocusNode();
  final FocusNode confirmFocus = FocusNode();

  final FirebaseFirestore db = FirebaseFirestore.instance;

  String errorMessage = "";
  bool isLoading = false;

  @override
  void dispose() {
    passController.dispose();
    confirmController.dispose();
    passFocus.dispose();
    confirmFocus.dispose();
    super.dispose();
  }

  Future<void> guardarPassword() async {
    String pass = passController.text.trim();
    String confirm = confirmController.text.trim();

    if (pass.isEmpty || confirm.isEmpty) {
      setState(() => errorMessage = "Completa todos los campos");
      return;
    }

    if (pass.length < 6) {
      setState(() =>
          errorMessage = "La contraseña debe tener al menos 6 caracteres");
      return;
    }

    if (pass != confirm) {
      setState(() => errorMessage = "Las contraseñas no coinciden");
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    try {
      await db.collection('usuarios').doc(widget.usuarioDocId).update({
        'password': pass,
      });

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardScreen(
            isAdmin: false,
            usuario: widget.usuario,
            departamento: widget.departamento,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        errorMessage = "Error al guardar contraseña";
        isLoading = false;
      });
    }
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

          // Blur de fondo
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
                      color: Colors.black.withValues(alpha: 0.45),
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
          "Crear nueva contraseña",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 28),

        _buildAnimatedField(
          controller: passController,
          label: "Nueva contraseña",
          focusNode: passFocus,
          obscure: true,
        ),
        const SizedBox(height: 18),

        _buildAnimatedField(
          controller: confirmController,
          label: "Confirmar contraseña",
          focusNode: confirmFocus,
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
            onPressed: isLoading ? null : guardarPassword,
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
                      "Guardar contraseña",
                      key: ValueKey("text"),
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
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
