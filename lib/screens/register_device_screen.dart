import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class RegisterDeviceScreen extends StatefulWidget {
  final bool isAdmin;
  final String usuario;

  const RegisterDeviceScreen({
    super.key,
    required this.isAdmin,
    required this.usuario,
  });

  @override
  State<RegisterDeviceScreen> createState() => _RegisterDeviceScreenState();
}

class _RegisterDeviceScreenState extends State<RegisterDeviceScreen> {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  final TextEditingController ambienteController = TextEditingController();
  final TextEditingController localController = TextEditingController();

  String? departamentoSeleccionado;

  // 🔹 19 Departamentos de Uruguay con siglas oficiales
  final Map<String, String> departamentos = {
    'Artigas': 'ART',
    'Canelones': 'CAN',
    'Cerro Largo': 'CER',
    'Colonia': 'COL',
    'Durazno': 'DUR',
    'Flores': 'FLO',
    'Florida': 'FLA',
    'Lavalleja': 'LAV',
    'Maldonado': 'MAL',
    'Montevideo': 'MVD',
    'Paysandú': 'PAY',
    'Río Negro': 'RNG',
    'Rivera': 'RIV',
    'Rocha': 'ROC',
    'Salto': 'SAL',
    'San José': 'SJO',
    'Soriano': 'SOR',
    'Tacuarembó': 'TAC',
    'Treinta y Tres': 'TYT',
  };

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();

    // Si NO es admin → asignar automáticamente su departamento
    if (!widget.isAdmin) {
      departamentoSeleccionado = _obtenerDepartamentoUsuario();
    }
  }

  // 🔹 Relación usuario → departamento
  String _obtenerDepartamentoUsuario() {
    switch (widget.usuario.toLowerCase()) {
      case "montevideo":
        return "Montevideo";
      case "canelones":
        return "Canelones";
      case "maldonado":
        return "Maldonado";
      case "colonia":
        return "Colonia";
      case "salto":
        return "Salto";
      case "rocha":
        return "Rocha";
      case "lavalleja":
        return "Lavalleja";
      case "flores":
        return "Flores";
      case "florida":
        return "Florida";
      case "soriano":
        return "Soriano";
      case "durazno":
        return "Durazno";
      case "treinta y tres":
        return "Treinta y Tres";
      case "cerro largo":
        return "Cerro Largo";
      case "rivera":
        return "Rivera";
      case "tacuarembo":
        return "Tacuarembó";
      case "artigas":
        return "Artigas";
      case "rio negro":
        return "Río Negro";
      case "paysandu":
        return "Paysandú";
      case "san jose":
        return "San José";
      default:
        return "Montevideo";
    }
  }

  // 🔥 Generador automático de código
  Future<String> _generarCodigo(String prefijo) async {
    final snapshot = await db
        .collection('dispositivos')
        .where('codigo', isGreaterThanOrEqualTo: prefijo)
        .where('codigo', isLessThan: '$prefijo\uf8ff')
        .get();

    int maxNumero = 0;

    for (var doc in snapshot.docs) {
      final codigo = doc['codigo'] as String;
      final partes = codigo.split('-');

      if (partes.length == 2) {
        final numero = int.tryParse(partes[1]) ?? 0;
        if (numero > maxNumero) {
          maxNumero = numero;
        }
      }
    }

    final siguiente = (maxNumero + 1).toString().padLeft(3, '0');
    return '$prefijo-$siguiente';
  }

  Future<void> _guardarDispositivo() async {
    if (departamentoSeleccionado == null ||
        ambienteController.text.trim().isEmpty ||
        localController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Complete todos los campos")),
      );
      return;
    }

    final prefijo = departamentos[departamentoSeleccionado]!;
    final codigo = await _generarCodigo(prefijo);

    final uruguay = tz.getLocation('America/Montevideo');
    final ahora = tz.TZDateTime.now(uruguay);
    final proximaFecha = ahora.add(const Duration(days: 30));

    await db.collection('dispositivos').doc(codigo).set({
      'codigo': codigo,
      'departamento': departamentoSeleccionado,
      'ambiente': ambienteController.text.trim(),
      'local': localController.text.trim(),
      'fechaAlta':
          '${ahora.day.toString().padLeft(2, '0')}/${ahora.month.toString().padLeft(2, '0')}/${ahora.year}',
      'proximaFecha':
          '${proximaFecha.day.toString().padLeft(2, '0')}/${proximaFecha.month.toString().padLeft(2, '0')}/${proximaFecha.year}',
      'ultimaActualizacion': ahora.toIso8601String(),
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Dispositivo $codigo creado correctamente")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dar de alta dispositivo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔹 Admin puede elegir departamento
            if (widget.isAdmin)
              DropdownButtonFormField<String>(
                value: departamentoSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Departamento',
                  border: OutlineInputBorder(),
                ),
                items: departamentos.keys.map((dep) {
                  return DropdownMenuItem(
                    value: dep,
                    child: Text(dep),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    departamentoSeleccionado = value;
                  });
                },
              ),

            // 🔹 Usuario normal solo ve su departamento bloqueado
            if (!widget.isAdmin)
              TextFormField(
                initialValue: departamentoSeleccionado,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Departamento',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

            TextField(
              controller: localController,
              decoration: const InputDecoration(
                labelText: 'Local',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: ambienteController,
              decoration: const InputDecoration(
                labelText: 'Ambiente',
                border: OutlineInputBorder(),
              ),
            ),
            

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _guardarDispositivo,
              child: const Text('Guardar dispositivo'),
            ),
          ],
        ),
      ),
    );
  }
}
