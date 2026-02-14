import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterUserScreen extends StatefulWidget {
  const RegisterUserScreen({super.key});

  @override
  State<RegisterUserScreen> createState() => _RegisterUserScreenState();
}

class _RegisterUserScreenState extends State<RegisterUserScreen> {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  final TextEditingController usuarioController = TextEditingController();

  String? departamentoSeleccionado;
  bool esAdmin = false;
  String errorMessage = "";
  bool loading = false;

  final List<String> departamentos = [
    "Artigas",
    "Canelones",
    "Cerro Largo",
    "Colonia",
    "Durazno",
    "Flores",
    "Florida",
    "Lavalleja",
    "Maldonado",
    "Montevideo",
    "Paysandú",
    "Río Negro",
    "Rivera",
    "Rocha",
    "Salto",
    "San José",
    "Soriano",
    "Tacuarembó",
    "Treinta y Tres",
  ];

  Future<void> crearUsuario() async {
    String usuario = usuarioController.text.trim().toLowerCase();

    if (usuario.isEmpty || departamentoSeleccionado == null) {
      setState(() {
        errorMessage = "Complete todos los campos";
      });
      return;
    }

    setState(() {
      loading = true;
      errorMessage = "";
    });

    try {
      // 🔎 Verificar si ya existe
      final existente = await db
          .collection('usuarios')
          .where('usuario', isEqualTo: usuario)
          .limit(1)
          .get();

      if (existente.docs.isNotEmpty) {
        setState(() {
          errorMessage = "El usuario ya existe";
          loading = false;
        });
        return;
      }

      // ✅ Crear usuario con password vacío (primer acceso)
      await db.collection('usuarios').add({
        'usuario': usuario,
        'departamento': departamentoSeleccionado,
        'password': "",
        'isAdmin': esAdmin,
        'fechaCreacion': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.pop(context); // volver al dashboard
    } catch (e) {
      setState(() {
        errorMessage = "Error al crear usuario: $e";
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Crear Usuario"),
        backgroundColor: const Color(0xFF0B2B3C),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Nuevo Usuario",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Usuario
                  TextField(
                    controller: usuarioController,
                    decoration: const InputDecoration(
                      labelText: "Nombre de usuario",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Departamento
                  DropdownButtonFormField<String>(
                    value: departamentoSeleccionado,
                    decoration: const InputDecoration(
                      labelText: "Departamento",
                      border: OutlineInputBorder(),
                    ),
                    items: departamentos
                        .map(
                          (depto) => DropdownMenuItem(
                            value: depto,
                            child: Text(depto),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        departamentoSeleccionado = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Admin switch
                  SwitchListTile(
                    title: const Text("Es administrador"),
                    value: esAdmin,
                    onChanged: (value) {
                      setState(() {
                        esAdmin = value;
                      });
                    },
                  ),

                  if (errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: loading ? null : crearUsuario,
                      child: loading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text("Crear Usuario"),
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
