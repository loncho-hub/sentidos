import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart'; // Asegúrate de importar Firebase core
import 'package:flutter/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Necesario para inicializar Firebase
  await Firebase.initializeApp(); // Inicializar Firebase
  await crearUsuariosDepartamentos();
}

Future<void> crearUsuariosDepartamentos() async {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  final List<String> departamentos = [
    'Artigas', 'Canelones', 'Cerro Largo', 'Colonia', 'Durazno', 'Flores',
    'Florida', 'Lavalleja', 'Maldonado', 'Montevideo', 'Paysandú', 'Río Negro',
    'Rivera', 'Rocha', 'Salto', 'San José', 'Soriano', 'Tacuarembó', 'Treinta y Tres',
  ];

  for (var depto in departamentos) {
    String docId = 'representante${depto.replaceAll(' ', '')}';
    await db.collection('usuarios').doc(docId).set({
      'departamento': depto,
      'usuario': '',
      'password': '',
      'isAdmin': false,
    });
    print('Usuario creado para $depto con ID $docId');
  }

  print('¡Todos los documentos de usuarios de departamentos creados!');
}
