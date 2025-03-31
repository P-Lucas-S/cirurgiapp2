import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cirurgiapp/src/core/constants/app_colors.dart' as core_colors;
import 'package:cirurgiapp/src/components/style_constants/typography.dart';
import 'package:cirurgiapp/src/core/models/user_model.dart';
import 'package:cirurgiapp/src/features/surgery/widgets/surgery_card.dart';

class BloodBankConfirmationScreen extends StatefulWidget {
  final HospitalUser user;

  const BloodBankConfirmationScreen({
    super.key,
    required this.user,
  });

  @override
  State<BloodBankConfirmationScreen> createState() =>
      _BloodBankConfirmationScreenState();
}

class _BloodBankConfirmation {
  final BuildContext context;
  final String surgeryId;
  final Map<String, dynamic> surgery;

  _BloodBankConfirmation({
    required this.context,
    required this.surgeryId,
    required this.surgery,
  });

  Future<void> execute() async {
    // Converte os produtos sanguíneos para Map<String, int>
    final requestedProducts = (surgery['bloodProducts'] as Map<String, dynamic>)
        .map((key, value) => MapEntry(key, (value as num).toInt()));
    // Agora, usamos o parâmetro "requestedProducts"
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) =>
          _ConfirmationDialog(requestedProducts: requestedProducts),
    );

    if (result == null || !context.mounted) return;

    try {
      final surgeryRef =
          FirebaseFirestore.instance.collection('surgeries').doc(surgeryId);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot surgerySnapshot = await transaction.get(surgeryRef);
        if (!surgerySnapshot.exists) throw Exception('Cirurgia não encontrada');

        Map<String, dynamic> surgeryData =
            surgerySnapshot.data() as Map<String, dynamic>;
        List<String> requiredConfirmations =
            (surgeryData['requiredConfirmations'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [];
        Map<String, dynamic> confirmations =
            Map<String, dynamic>.from(surgeryData['confirmations'] ?? {});

        // Atualiza a confirmação atual para banco de sangue
        confirmations['banco_sangue'] = result['confirmed'];
        surgeryData['confirmations'] = confirmations;

        bool anyDenied = requiredConfirmations.any((role) =>
            confirmations.containsKey(role) && confirmations[role] == false);

        bool allConfirmed = requiredConfirmations.every((role) =>
            confirmations.containsKey(role) && confirmations[role] == true);

        String newStatus;
        if (anyDenied) {
          newStatus = 'negada';
        } else if (allConfirmed) {
          newStatus = 'confirmada';
        } else {
          newStatus =
              'pendente'; // Mantém como pendente se faltar alguma confirmação
        }

        final Map<String, dynamic> updateData = {
          'confirmations.banco_sangue': result['confirmed'],
          'bloodProductsConfirmation': result['products'],
          'status': newStatus,
        };

        if (result['confirmed'] == false) {
          updateData['denialReason'] =
              'Falta dos seguintes hemoderivados: ${result['missingProducts']}';
        } else {
          updateData['denialReason'] = FieldValue.delete();
        }

        transaction.update(surgeryRef, updateData);
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro na confirmação: ${e.toString()}')),
        );
      }
    }
  }
}

class _BloodBankConfirmationScreenState
    extends State<BloodBankConfirmationScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> get _surgeriesStream => _firestore
      .collection('surgeries')
      .where('status', isEqualTo: 'pendente')
      .snapshots();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Banco de Sangue',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: core_colors.AppColors.primary,
        foregroundColor: core_colors.AppColors.onPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context, '/login', (route) => false),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _surgeriesStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) return _buildErrorWidget();
          if (!snapshot.hasData) return _buildLoadingIndicator();

          final surgeries = snapshot.data!.docs;
          if (surgeries.isEmpty) return _buildEmptyListWidget();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: surgeries.length,
            itemBuilder: (context, index) {
              final doc = surgeries[index];
              final surgery = doc.data() as Map<String, dynamic>;
              return _buildSurgeryCard(doc.id, surgery);
            },
          );
        },
      ),
    );
  }

  Widget _buildSurgeryCard(String surgeryId, Map<String, dynamic> surgery) {
    return SurgeryCard(
      surgeryId: surgeryId,
      surgery: surgery,
      userRole: 'Banco de Sangue',
      canConfirm: true,
      onConfirm: () => _BloodBankConfirmation(
        context: context,
        surgeryId: surgeryId,
        surgery: surgery,
      ).execute(),
    );
  }

  Widget _buildLoadingIndicator() =>
      const Center(child: CircularProgressIndicator());

  Widget _buildErrorWidget() => Center(
        child: Text(
          'Erro ao carregar cirurgias',
          style: H2(textColor: core_colors.AppColors.onSurface),
        ),
      );

  Widget _buildEmptyListWidget() => Center(
        child: Text(
          'Nenhuma cirurgia pendente',
          style: H2(textColor: core_colors.AppColors.onSurface),
        ),
      );
}

class OpmeItem {
  final String materialId;
  final int quantity;
  final String specification;

  OpmeItem({
    required this.materialId,
    required this.quantity,
    required this.specification,
  });

  factory OpmeItem.fromMap(Map<String, dynamic> map) {
    return OpmeItem(
      materialId: map['materialId'],
      quantity: map['quantity'],
      specification: map['specification'] ?? '',
    );
  }
}

/// Diálogo de confirmação para produtos sanguíneos, agora usando o parâmetro "requestedProducts"
class _ConfirmationDialog extends StatefulWidget {
  final Map<String, int> requestedProducts;

  const _ConfirmationDialog({required this.requestedProducts});

  @override
  State<_ConfirmationDialog> createState() => _ConfirmationDialogState();
}

class _ConfirmationDialogState extends State<_ConfirmationDialog> {
  final Map<String, bool> _confirmedProducts = {};

  @override
  void initState() {
    super.initState();
    // Inicializa todos os produtos como não confirmados
    _confirmedProducts.addAll(
      widget.requestedProducts.map((key, value) => MapEntry(key, false)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirmar Hemoderivados Disponíveis'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: widget.requestedProducts.entries.map((entry) {
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('blood_products')
                  .doc(entry.key)
                  .get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();

                final product = snapshot.data!.data() as Map<String, dynamic>;
                return CheckboxListTile(
                  title: Text(product['name']),
                  subtitle: Text('Quantidade solicitada: ${entry.value}'),
                  value: _confirmedProducts[entry.key] ?? false,
                  onChanged: (value) => setState(() {
                    _confirmedProducts[entry.key] = value ?? false;
                  }),
                );
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final unconfirmed =
                _confirmedProducts.entries.where((e) => !e.value).toList();

            if (unconfirmed.isNotEmpty) {
              final missingProducts = unconfirmed.map((e) => e.key).join(', ');

              Navigator.pop(context, {
                'confirmed': false,
                'missingProducts': missingProducts,
                'products': _confirmedProducts,
              });
            } else {
              Navigator.pop(context, {
                'confirmed': true,
                'products': _confirmedProducts,
              });
            }
          },
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
