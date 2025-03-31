import 'package:intl/intl.dart';
import 'package:cirurgiapp/src/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cirurgiapp/src/core/models/user_model.dart';
import 'package:cirurgiapp/src/services/surgery_service.dart';

class RoleConfirmationScreen extends StatelessWidget {
  final String roleKey;
  final HospitalUser user;

  const RoleConfirmationScreen({
    super.key,
    required this.roleKey,
    required this.user,
  });

  String _getFieldName() {
    return switch (roleKey) {
      'Residente de Cirurgia' => 'residente',
      'Centro Cirúrgico' => 'centro_cirurgico',
      'Banco de Sangue' => 'banco_sangue',
      'UTI' => 'uti',
      'Centro de Material Hospitalar' => 'material_hospitalar',
      _ => '',
    };
  }

  Widget _buildConfirmationUI(Map<String, dynamic> surgery, String docId) {
    final SurgeryService surgeryService = SurgeryService();
    final confirmationField = _getFieldName();

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(surgery['patientName'],
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Procedimento: ${surgery['procedureName']}'),
            const SizedBox(height: 8),
            Text('Data: ${_formatDate(surgery['dateTime'])}'),
            const SizedBox(height: 12),
            _buildConfirmationSwitch(
                surgeryService, docId, confirmationField, surgery),
            if (roleKey == 'Centro Cirúrgico')
              _buildSurgeryRoomSelector(surgery, docId),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmationSwitch(
    SurgeryService service,
    String docId,
    String field,
    Map<String, dynamic> surgery,
  ) {
    final confirmations = surgery['confirmations'] ?? {}; // Null-check
    return SwitchListTile(
      title: Text('Confirmar $roleKey'),
      value: (confirmations[field] ?? false), // Default para false
      onChanged: (value) async {
        await service.confirmRequirement(
            docId, field, user.uid, value ?? false);
      },
    );
  }

  Widget _buildSurgeryRoomSelector(Map<String, dynamic> surgery, String docId) {
    final List<String> rooms = ['Sala 1', 'Sala 2', 'Sala 3', 'Sala 4'];
    String selectedRoom = surgery['surgeryRoom'] ?? '';

    return DropdownButtonFormField<String>(
      value: selectedRoom.isNotEmpty ? selectedRoom : null,
      decoration: const InputDecoration(
        labelText: 'Selecionar Sala',
        border: OutlineInputBorder(),
      ),
      items: rooms
          .map((room) => DropdownMenuItem(
                value: room,
                child: Text(room),
              ))
          .toList(),
      onChanged: (value) async {
        await FirebaseFirestore.instance
            .collection('surgeries')
            .doc(docId)
            .update({'surgeryRoom': value});
      },
    );
  }

  String _formatDate(Timestamp timestamp) {
    return DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Confirmações - $roleKey'),
        actions: [
          IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => AuthService().signOut())
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('surgeries')
            .where('status', isEqualTo: 'pendente')
            .where('confirmations.${_getFieldName()}',
                isEqualTo: false) // Filtro adicional
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return const Center(child: Text('Erro ao carregar dados'));
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              return FutureBuilder<DocumentSnapshot>(
                future: (doc['procedure'] as DocumentReference).get(),
                builder: (context, procedureSnapshot) {
                  if (!procedureSnapshot.hasData)
                    return const SizedBox.shrink();

                  final surgeryData = doc.data() as Map<String, dynamic>;
                  surgeryData['procedureName'] =
                      procedureSnapshot.data!['name'];

                  return _buildConfirmationUI(surgeryData, doc.id);
                },
              );
            },
          );
        },
      ),
    );
  }
}
