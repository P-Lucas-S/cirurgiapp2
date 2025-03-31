import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cirurgiapp/src/core/constants/app_colors.dart' as core_colors;
import 'package:cirurgiapp/src/components/style_constants/typography.dart';
import 'package:cirurgiapp/src/core/models/user_model.dart';
import 'package:cirurgiapp/src/features/surgery/widgets/surgery_card.dart';

class OpmeConfirmationScreen extends StatefulWidget {
  final HospitalUser user;

  const OpmeConfirmationScreen({
    super.key,
    required this.user,
  });

  @override
  State<OpmeConfirmationScreen> createState() => _OpmeConfirmationScreenState();
}

class _OpmeConfirmation {
  final BuildContext context;
  final String surgeryId;
  final Map<String, dynamic> surgery;

  _OpmeConfirmation({
    required this.context,
    required this.surgeryId,
    required this.surgery,
  });

  Future<void> execute() async {
    final requestedMaterials = (surgery['opme'] as List<dynamic>)
        .map((item) => OpmeItem.fromMap(item))
        .toList();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) =>
          _ConfirmationDialog(requestedMaterials: requestedMaterials),
    );

    if (result == null || !context.mounted) return;

    try {
      final surgeryRef =
          FirebaseFirestore.instance.collection('surgeries').doc(surgeryId);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final surgerySnapshot = await transaction.get(surgeryRef);
        if (!surgerySnapshot.exists) {
          throw Exception('Cirurgia não encontrada');
        }
        // Obter dados atuais da cirurgia
        Map<String, dynamic> surgeryData =
            surgerySnapshot.data() as Map<String, dynamic>;
        List<String> requiredConfirmations =
            (surgeryData['requiredConfirmations'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [];
        Map<String, dynamic> confirmations =
            Map<String, dynamic>.from(surgeryData['confirmations'] ?? {});

        // Atualiza a confirmação para Material Hospitalar
        confirmations['material_hospitalar'] = result['confirmed'];
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
          newStatus = 'pendente';
        }

        final Map<String, dynamic> updateData = {
          'confirmations.material_hospitalar': result['confirmed'],
          'opmeConfirmation': result['materials'],
          'status': newStatus,
        };

        if (result['confirmed'] == false) {
          updateData['denialReason'] =
              'Falta dos seguintes materiais: ${result['missingMaterials']}';
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

class _OpmeConfirmationScreenState extends State<OpmeConfirmationScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> get _surgeriesStream => _firestore
      .collection('surgeries')
      .where('status', whereIn: ['pendente', 'negada', 'confirmada'])
      .where('requiredConfirmations', arrayContains: 'material_hospitalar')
      .snapshots();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Centro de Material Hospitalar'),
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
      userRole: 'Centro de Material Hospitalar',
      canConfirm: true,
      onConfirm: () => _OpmeConfirmation(
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

class _ConfirmationDialog extends StatefulWidget {
  final List<OpmeItem> requestedMaterials;

  const _ConfirmationDialog({required this.requestedMaterials});

  @override
  State<_ConfirmationDialog> createState() => _ConfirmationDialogState();
}

class _ConfirmationDialogState extends State<_ConfirmationDialog> {
  final Map<String, bool> _confirmedMaterials = {};

  @override
  void initState() {
    super.initState();
    // Inicializa todos os materiais como não confirmados
    for (var material in widget.requestedMaterials) {
      _confirmedMaterials[material.materialId] = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirmar Materiais Disponíveis'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: widget.requestedMaterials.map((item) {
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('opme')
                  .doc(item.materialId)
                  .get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();

                final material = snapshot.data!.data() as Map<String, dynamic>;
                return CheckboxListTile(
                  title: Text(material['name']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quantidade solicitada: ${item.quantity}'),
                      if (item.specification.isNotEmpty)
                        Text('Especificação: ${item.specification}'),
                    ],
                  ),
                  value: _confirmedMaterials[item.materialId] ?? false,
                  onChanged: (value) => setState(() {
                    _confirmedMaterials[item.materialId] = value ?? false;
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
                _confirmedMaterials.entries.where((e) => !e.value).toList();

            if (unconfirmed.isNotEmpty) {
              final missingMaterials = unconfirmed.map((e) => e.key).join(', ');

              Navigator.pop(context, {
                'confirmed': false,
                'missingMaterials': missingMaterials,
                'materials': _confirmedMaterials,
              });
            } else {
              Navigator.pop(context, {
                'confirmed': true,
                'materials': _confirmedMaterials,
              });
            }
          },
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
