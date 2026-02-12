import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class RegisterChangeScreen extends StatefulWidget {
  final String codigo; // Código del dispositivo
  final String usuario; // Usuario que registra

  const RegisterChangeScreen({
    super.key,
    required this.codigo,
    required this.usuario,
  });

  @override
  State<RegisterChangeScreen> createState() => _RegisterChangeScreenState();
}

class _RegisterChangeScreenState extends State<RegisterChangeScreen> {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final TextEditingController detalleController = TextEditingController();

  String? opcionSeleccionada;
  final List<String> opciones = ['Mantenimiento', 'Limpieza', 'Reemplazo', 'Otros'];

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones(); // Inicializar zona horaria
  }

  Future<void> _guardarCambio() async {
    if (opcionSeleccionada == null || detalleController.text.isEmpty) return;

    final uruguay = tz.getLocation('America/Montevideo');
    final ahora = tz.TZDateTime.now(uruguay);

    final dispositivoRef = db.collection('dispositivos').doc(widget.codigo);
    final cambiosRef = dispositivoRef.collection('cambios');

    // Formato DDMM para ID diario
    String fechaId = '${ahora.day.toString().padLeft(2, '0')}${ahora.month.toString().padLeft(2, '0')}';

    // Obtener último cambio del día para numeración secuencial
    final query = await cambiosRef
        .where('fechaId', isEqualTo: fechaId)
        .orderBy('numero', descending: true)
        .limit(1)
        .get();

    int siguienteNumero = 1;
    if (query.docs.isNotEmpty) {
      siguienteNumero = (query.docs.first.data()['numero'] as int) + 1;
    }

    String idCambio = '$fechaId-${siguienteNumero.toString().padLeft(3, '0')}';

    // Guardar el cambio en la subcolección
    await cambiosRef.doc(idCambio).set({
      'fechaHora': ahora.toIso8601String(),
      'opcion': opcionSeleccionada,
      'detalle': detalleController.text,
      'usuario': widget.usuario, // Usuario real
      'fechaId': fechaId,
      'numero': siguienteNumero,
    });

    // Actualizar el documento principal del dispositivo
    final proximaFecha = ahora.add(const Duration(days: 30));
    final diasRestantes = proximaFecha.difference(ahora).inDays;

    await dispositivoRef.update({
      'proximaFecha': '${proximaFecha.day.toString().padLeft(2, '0')}/${proximaFecha.month.toString().padLeft(2, '0')}/${proximaFecha.year}',
      'diasRestantes': diasRestantes,
      'ultimaActualizacion': ahora.toIso8601String(), // opcional: para control interno
    });

    if (!mounted) return;
    Navigator.pop(context); // Volver al dashboard
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Registrar cambio: ${widget.codigo}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Opciones tipo Radio
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: opciones.map((opcion) {
                return RadioListTile<String>(
                  title: Text(opcion),
                  value: opcion,
                  groupValue: opcionSeleccionada,
                  onChanged: (value) {
                    setState(() {
                      opcionSeleccionada = value;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: detalleController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Detalle del cambio',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _guardarCambio,
              child: const Text('Guardar cambio'),
            ),
          ],
        ),
      ),
    );
  }
}
