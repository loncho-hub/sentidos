import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'register_change_screen.dart';
import 'change_history_screen.dart';
import 'login_screen.dart';
import 'package:intl/intl.dart';
import 'register_device_screen.dart';
import 'register_user_screen.dart';

class DashboardScreen extends StatefulWidget {
  final bool isAdmin;
  final String usuario;
  final String departamento;

  const DashboardScreen({
    super.key,
    required this.isAdmin,
    required this.usuario,
    required this.departamento,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  // ================= CALCULAR DÍAS RESTANTES =================
  int calcularDiasRestantes(String fechaTexto) {
    final DateFormat formato = DateFormat('dd/MM/yyyy');

    final fechaProxima = formato.parse(fechaTexto);
    final hoy = DateTime.now();

    final hoyNormalizado = DateTime(hoy.year, hoy.month, hoy.day);
    final fechaNormalizada =
        DateTime(fechaProxima.year, fechaProxima.month, fechaProxima.day);

    return fechaNormalizada.difference(hoyNormalizado).inDays;
  }

  // ================= STREAM FILTRADO =================
  Stream<QuerySnapshot> _dispositivosFiltradosStream() {
    final depto = widget.departamento;
    if (widget.isAdmin || depto == "TODOS") {
      return db.collection('dispositivos').snapshots();
    } else {
      return db
          .collection('dispositivos')
          .where('departamento', isEqualTo: depto)
          .snapshots();
    }
  }

  // ================= CERRAR SESIÓN CON CONFIRMACIÓN =================
  void _cerrarSesion(BuildContext context) async {
    bool confirmar = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmar cierre de sesión"),
        content: const Text(
            "¿Estás seguro de que quieres cerrar sesión?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              "Cerrar sesión",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    final depto = widget.departamento;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isAdmin
                  ? "Panel Administrador - Todos los departamentos"
                  : "Panel - $depto",
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              "Conectado como: ${widget.usuario}",
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF28282B),
        foregroundColor: Colors.white,
        actions: [
          if (widget.isAdmin)
            IconButton(
              icon: const Icon(Icons.person_add),
              tooltip: "Crear usuario",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegisterUserScreen(),
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _cerrarSesion(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _dispositivosFiltradosStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No hay dispositivos registrados"),
            );
          }

          List docs = snapshot.data!.docs;

          // ORDENAR POR DÍAS RESTANTES
          docs.sort((a, b) {
            final diasA = calcularDiasRestantes(a['proximaFecha']);
            final diasB = calcularDiasRestantes(b['proximaFecha']);
            return diasA.compareTo(diasB);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final dias =
                  calcularDiasRestantes(data['proximaFecha'] ?? "01/01/2000");

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DeviceCard(
                  codigo: data['codigo'] ?? '',
                  local: data['local'] ?? '',
                  ambiente: data['ambiente'] ?? '',
                  proximaFecha: data['proximaFecha'] ?? '',
                  diasRestantes: dias,
                  usuario: widget.usuario,
                  departamento: data['departamento'] ?? '',
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF28282B),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RegisterDeviceScreen(
                isAdmin: widget.isAdmin,
                usuario: widget.usuario,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ================= DEVICE CARD =================
class DeviceCard extends StatelessWidget {
  final String codigo;
  final String local;
  final String ambiente;
  final String proximaFecha;
  final int diasRestantes;
  final String usuario;
  final String departamento;

  const DeviceCard({
    super.key,
    required this.codigo,
    required this.local,
    required this.ambiente,
    required this.proximaFecha,
    required this.diasRestantes,
    required this.usuario,
    required this.departamento,
  });

  @override
  Widget build(BuildContext context) {
    String textoEstado;
    Color estadoColor;

    if (diasRestantes > 10) {
      textoEstado = "En $diasRestantes días";
      estadoColor = Colors.green;
    } else if (diasRestantes > 5) {
      textoEstado = "En $diasRestantes días";
      estadoColor = Colors.orange;
    } else if (diasRestantes > 1) {
      textoEstado = "En $diasRestantes días";
      estadoColor = Colors.red;
    } else if (diasRestantes == 1) {
      textoEstado = "Mañana";
      estadoColor = Colors.red;
    } else if (diasRestantes == 0) {
      textoEstado = "Hoy";
      estadoColor = Colors.red.shade900;
    } else {
      textoEstado = "Atrasado ${diasRestantes.abs()} días";
      estadoColor = Colors.red.shade900;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF28282B), width: 1), // borde negro
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("$local — $ambiente",
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text("Código: $codigo"),
            Text("Próximo cambio: $proximaFecha"),
            const SizedBox(height: 4),
            Text(
              textoEstado,
              style: TextStyle(
                color: estadoColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
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
                            departamento: departamento,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.black, // texto negro
                    ),
                    child: const Text("Registrar cambio"),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.history),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ChangeHistoryScreen(codigo: codigo),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    bool confirmar = await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Confirmar eliminación"),
                        content: const Text(
                            "¿Estás seguro de que quieres dar de baja este dispositivo? Esta acción no se puede deshacer."),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text("Cancelar"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text(
                              "Eliminar",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirmar == true) {
                      await FirebaseFirestore.instance
                          .collection('dispositivos')
                          .doc(codigo)
                          .delete();
                    }
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
