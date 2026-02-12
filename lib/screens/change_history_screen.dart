import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChangeHistoryScreen extends StatelessWidget {
  final String codigo; // Código del dispositivo

  const ChangeHistoryScreen({super.key, required this.codigo});

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore db = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: Text('Historial de cambios: $codigo'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: db
            .collection('dispositivos')
            .doc(codigo)
            .collection('cambios')
            .orderBy('fechaId', descending: true)
            .orderBy('numero', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No hay cambios registrados aún.'),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${data['opcion']} — ${data['detalle']}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text('Usuario: ${data['usuario']}'),
                      Text('Fecha y hora: ${data['fechaHora']}'),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
