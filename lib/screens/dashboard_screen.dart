import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'register_change_screen.dart';
import 'change_history_screen.dart';
import 'login_screen.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  final bool isAdmin;
  final String usuario;

  const DashboardScreen({
    super.key,
    required this.isAdmin,
    required this.usuario,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  // Obtener departamento por usuario
  String _obtenerDepartamentoPorUsuario() {
    if (widget.isAdmin) return "TODOS";

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
        return "Desconocido";
    }
  }

  // Cerrar sesión
  void _cerrarSesion(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cerrar sesión"),
        content: const Text("¿Estás seguro que deseas cerrar sesión?"),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            child: const Text("Cerrar sesión"),
          ),
        ],
      ),
    );
  }

  // ---------- ALTA DE DISPOSITIVO ----------
  void _mostrarFormularioAlta(BuildContext context) async {
    final TextEditingController localController = TextEditingController();
    final TextEditingController ambienteController = TextEditingController();
    final TextEditingController fechaAltaController = TextEditingController();
    final TextEditingController proximaFechaController = TextEditingController();

    String depto = widget.isAdmin ? "Montevideo" : _obtenerDepartamentoPorUsuario();
    String siglas = _siglasDepartamento(depto);

    String? selectedDepto = depto;

    // Fecha de alta y próxima fecha automáticas
    DateTime? fechaAlta;
    DateTime? fechaProxima;

    // Función para actualizar próxima fecha
    void actualizarProximaFecha() {
      if (fechaAlta != null) {
        fechaProxima = fechaAlta!.add(const Duration(days: 30));
        proximaFechaController.text = DateFormat('dd/MM/yyyy').format(fechaProxima!);
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text("Alta de dispositivo"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                // Dropdown de departamento si es admin
                if (widget.isAdmin)
                  DropdownButtonFormField<String>(
                    value: selectedDepto,
                    decoration: const InputDecoration(labelText: "Departamento"),
                    items: [
                      "Montevideo",
                      "Canelones",
                      "Maldonado",
                      "Colonia",
                      "Salto",
                      "Rocha",
                      "Lavalleja",
                      "Flores",
                      "Florida",
                      "Soriano",
                      "Durazno",
                      "Treinta y Tres",
                      "Cerro Largo",
                      "Rivera",
                      "Tacuarembó",
                      "Artigas",
                      "Río Negro",
                      "Paysandú",
                    ]
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (value) {
                      setStateDialog(() {
                        selectedDepto = value;
                        siglas = _siglasDepartamento(selectedDepto!);
                      });
                    },
                  ),
                TextField(controller: localController, decoration: const InputDecoration(labelText: "Local")),
                TextField(controller: ambienteController, decoration: const InputDecoration(labelText: "Ambiente")),
                TextField(
                  controller: fechaAltaController,
                  decoration: const InputDecoration(labelText: "Fecha de alta (dd/MM/yyyy)"),
                  readOnly: true,
                  onTap: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setStateDialog(() {
                        fechaAlta = picked;
                        fechaAltaController.text = DateFormat('dd/MM/yyyy').format(fechaAlta!);
                        actualizarProximaFecha();
                      });
                    }
                  },
                ),
                TextField(
                  controller: proximaFechaController,
                  decoration: const InputDecoration(labelText: "Próxima fecha (automática)"),
                  readOnly: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
            ElevatedButton(
              onPressed: () async {
                if (localController.text.isEmpty ||
                    ambienteController.text.isEmpty ||
                    fechaAlta == null ||
                    selectedDepto == null) return;

                // Obtener último número para ese departamento
                QuerySnapshot query = await db
                    .collection('dispositivos')
                    .where('departamento', isEqualTo: selectedDepto)
                    .get();

                int maxNum = 0;
                for (var doc in query.docs) {
                  String codigo = doc['codigo'] ?? '';
                  if (codigo.startsWith(siglas)) {
                    int? num = int.tryParse(codigo.split('-')[1]);
                    if (num != null && num > maxNum) maxNum = num;
                  }
                }

                String codigoAutogenerado = '$siglas-${(maxNum + 1).toString().padLeft(3, '0')}';

                await db.collection('dispositivos').doc(codigoAutogenerado).set({
                  'codigo': codigoAutogenerado,
                  'departamento': selectedDepto,
                  'local': localController.text,
                  'ambiente': ambienteController.text,
                  'fechaAlta': DateFormat('dd/MM/yyyy').format(fechaAlta!),
                  'proximaFecha': DateFormat('dd/MM/yyyy').format(fechaProxima!),
                  'diasRestantes': fechaProxima!.difference(fechaAlta!).inDays,
                });

                if (!mounted) return;
                Navigator.pop(context);
                setState(() {});
              },
              child: const Text("Agregar"),
            ),
          ],
        ),
      ),
    );
  }

  String _siglasDepartamento(String depto) {
    switch (depto.toLowerCase()) {
      case 'montevideo':
        return 'MVD';
      case 'canelones':
        return 'CNL';
      case 'maldonado':
        return 'MAL';
      case 'colonia':
        return 'COL';
      case 'salto':
        return 'SAL';
      case 'rocha':
        return 'ROC';
      case 'lavalleja':
        return 'LAV';
      case 'flores':
        return 'FLO';
      case 'florida':
        return 'FLD';
      case 'soriano':
        return 'SOR';
      case 'durazno':
        return 'DUR';
      case 'treinta y tres':
        return 'TRE';
      case 'cerro largo':
        return 'CER';
      case 'rivera':
        return 'RIV';
      case 'tacuarembo':
        return 'TAC';
      case 'artigas':
        return 'ART';
      case 'río negro':
        return 'RNE';
      case 'paysandú':
        return 'PAY';
      default:
        return 'XXX';
    }
  }

  // ---------- STREAM DE DISPOSITIVOS ----------
  Stream<QuerySnapshot> _dispositivosFiltradosStream() {
    final depto = _obtenerDepartamentoPorUsuario();
    if (widget.isAdmin || depto == "TODOS") {
      return db.collection('dispositivos').snapshots();
    } else {
      return db.collection('dispositivos').where('departamento', isEqualTo: depto).snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    final depto = _obtenerDepartamentoPorUsuario();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.isAdmin ? "Panel Administrador - Todos los departamentos" : "Panel - $depto",
                style: const TextStyle(fontSize: 16)),
            Text("Conectado como: ${widget.usuario}", style: const TextStyle(fontSize: 12)),
          ],
        ),
        backgroundColor: const Color(0xFF0B2B3C),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.logout), tooltip: "Cerrar sesión", onPressed: () => _cerrarSesion(context)),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _dispositivosFiltradosStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inbox_outlined, size: 60, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      "No hay dispositivos asignados a este departamento.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            );
          }

          List docs = snapshot.data!.docs;
          docs.sort((a, b) => (a['diasRestantes'] as int).compareTo(b['diasRestantes'] as int));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Column(
                children: [
                  DeviceCard(
                    codigo: data['codigo'],
                    local: data['local'],
                    ambiente: data['ambiente'],
                    proximaFecha: data['proximaFecha'],
                    diasRestantes: data['diasRestantes'],
                    usuario: widget.usuario,
                  ),
                  const SizedBox(height: 12),
                ],
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormularioAlta(context),
        backgroundColor: const Color.fromARGB(255, 74, 183, 241),
        tooltip: "Agregar dispositivo",
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ---------- DeviceCard con botón de baja ----------
class DeviceCard extends StatelessWidget {
  final String codigo;
  final String local;
  final String ambiente;
  final String proximaFecha;
  final int diasRestantes;
  final String usuario;

  const DeviceCard({
    super.key,
    required this.codigo,
    required this.local,
    required this.ambiente,
    required this.proximaFecha,
    required this.diasRestantes,
    required this.usuario,
  });

  @override
  Widget build(BuildContext context) {
    final Color estadoColor = diasRestantes <= 5 ? Colors.red : Colors.orange;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("$local — $ambiente", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text("Código: $codigo"),
          Text("Próximo cambio: $proximaFecha"),
          Text("En $diasRestantes días", style: TextStyle(color: estadoColor)),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RegisterChangeScreen(
                            codigo: codigo,
                            usuario: usuario,
                          ),
                        ),
                      );
                    },
                    child: const Text("Registrar cambio"),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.history),
                  tooltip: 'Ver historial',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChangeHistoryScreen(codigo: codigo),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Dar de baja',
                  onPressed: () async {
                    bool confirm = false;
                    confirm = await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Confirmar baja"),
                        content: Text("¿Seguro que deseas dar de baja el dispositivo $codigo?"),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("Dar de baja"),
                          ),
                        ],
                      ),
                    );

                    if (confirm) {
                      await FirebaseFirestore.instance.collection('dispositivos').doc(codigo).delete();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Dispositivo $codigo dado de baja")),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
