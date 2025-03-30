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

class _BloodBankConfirmationScreenState
    extends State<BloodBankConfirmationScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> get _surgeriesStream => _firestore
      .collection('surgeries')
      .where('status', isEqualTo: 'pendente')
      .snapshots();

  // Método de confirmação atualizado
  Future<void> _confirmBloodProducts(
      String surgeryId, Map<String, dynamic> surgery) async {
    final requestedProducts =
        Map<String, int>.from(surgery['bloodProducts'] ?? {});
    final confirmedProducts = await showDialog<Map<String, int>>(
      context: context,
      builder: (context) =>
          _ConfirmationDialog(requestedProducts: requestedProducts),
    );

    if (confirmedProducts == null || !mounted) return; //✅ Verificação added

    try {
      await _firestore.collection('surgeries').doc(surgeryId).update({
        'confirmations.banco_sangue': true,
        'bloodProductsConfirmation': confirmedProducts,
        'confirmedBy.banco_sangue': widget.user.uid,
        'timestamps.updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (mounted) {
        //✅ Verificação added
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro na confirmação: ${e.toString()}')));
      }
    }
  }

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
      // Exemplo: ao confirmar, o SurgeryCard pode chamar esse método
      onConfirm: () => _confirmBloodProducts(surgeryId, surgery),
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

/// Diálogo de confirmação personalizado para os produtos sanguíneos
class _ConfirmationDialog extends StatefulWidget {
  final Map<String, int> requestedProducts;

  const _ConfirmationDialog({required this.requestedProducts});

  @override
  State<_ConfirmationDialog> createState() => _ConfirmationDialogState();
}

class _ConfirmationDialogState extends State<_ConfirmationDialog> {
  final Map<String, int> _confirmedProducts = {};

  @override
  void initState() {
    super.initState();
    _confirmedProducts.addAll(widget.requestedProducts);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirmar Produtos Sanguíneos'),
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
                final currentQty = _confirmedProducts[entry.key] ?? 0;

                return ListTile(
                  title: Text(product['name']),
                  subtitle: Text('Solicitado: ${entry.value}'),
                  trailing: SizedBox(
                    width: 100,
                    child: TextFormField(
                      initialValue: currentQty.toString(),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final qty = int.tryParse(value) ?? 0;
                        setState(() {
                          _confirmedProducts[entry.key] = qty;
                        });
                      },
                    ),
                  ),
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
          onPressed: () => Navigator.pop(
              context, _confirmedProducts..removeWhere((k, v) => v <= 0)),
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
