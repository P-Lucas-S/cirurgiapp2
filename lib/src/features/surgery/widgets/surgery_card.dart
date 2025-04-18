import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cirurgiapp/src/core/constants/app_colors.dart';
import 'package:cirurgiapp/src/core/extensions/string_extensions.dart';
import 'package:cirurgiapp/src/features/surgery/screens/surgery_details_screen.dart';
import 'package:cirurgiapp/src/services/surgery_service.dart';

class SurgeryCard extends StatelessWidget {
  final String surgeryId;
  final Map<String, dynamic> surgery;
  final bool canCancel;
  final bool canConfirm;
  final String userRole;
  final VoidCallback? onConfirm;

  static const double _iconSize = 32;
  static const double _cardElevation = 3;
  static const EdgeInsets _cardMargin =
      EdgeInsets.symmetric(vertical: 8, horizontal: 16);
  static const EdgeInsets _contentPadding = EdgeInsets.all(16);

  const SurgeryCard({
    super.key,
    required this.surgeryId,
    required this.surgery,
    required this.userRole,
    this.canConfirm = false,
    this.canCancel = false, // Nova propriedade
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: _cardElevation,
      margin: _cardMargin,
      child: InkWell(
        onTap: () => _navigateToDetails(context),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: _contentPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Conteúdo superior do card (mantido igual)
              Row(
                children: [
                  _buildStatusIcon(),
                  const SizedBox(width: 16),
                  Expanded(child: _buildSurgeryInfo(context)),
                  // Ícone de cancelamento removido daqui
                ],
              ),
              // Botões inferiores
              if (canConfirm || canCancel)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    children: [
                      if (canConfirm)
                        ElevatedButton(
                          onPressed: onConfirm,
                          child: const Text('Confirmar'),
                        ),
                      if (canCancel)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _confirmCancellation(context),
                          child: const Text('Cancelar Cirurgia'),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSurgeryInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPatientName(context),
        const SizedBox(height: 8),
        _buildSurgeryDetails(),
      ],
    );
  }

  Widget _buildPatientName(BuildContext context) {
    return Text(
      surgery['patientName']?.toString().capitalize() ??
          'Paciente não informado',
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildSurgeryDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailItem('Data:', _formattedDateTime),
        _buildDetailItem('Status:', _formattedStatus),
        _buildReferenceItem(
          label: 'Procedimento:',
          reference: surgery['procedure'],
        ),
        _buildReferenceItem(
          label: 'Cirurgião:',
          reference: surgery['surgeon'],
        ),
        _buildReferenceItem(
          label: 'Anestesista:',
          reference: surgery['anesthesiologist'],
        ),
        _buildBloodProducts(surgery['bloodProducts']),
      ],
    );
  }

  Widget _buildBloodProducts(dynamic products) {
    if (products is List) {
      products = _convertLegacyListToMap(products);
    }
    final bloodProducts = (products as Map<String, dynamic>)
        .map((key, value) => MapEntry(key, (value is num ? value.toInt() : 0)));

    if (bloodProducts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Produtos Sanguíneos:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        ...bloodProducts.entries.map((entry) => FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('blood_products')
                  .doc(entry.key)
                  .get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                final product = snapshot.data!.data() as Map<String, dynamic>;
                return Text('${product['name']}: ${entry.value}');
              },
            )),
      ],
    );
  }

  Map<String, int> _convertLegacyListToMap(List<dynamic> list) {
    return {for (var item in list) item.toString(): 1};
  }

  Widget _buildReferenceItem({
    required String label,
    required dynamic reference,
  }) {
    try {
      final docRef = _getDocumentReference(reference);
      if (docRef == null) return _buildDetailItem(label, 'Não especificado');

      return FutureBuilder<DocumentSnapshot>(
        future: docRef.get(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildDetailItem(label, 'Erro ao carregar');
          }
          if (!snapshot.hasData) {
            return _buildDetailItem(label, 'Carregando...');
          }
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          return _buildDetailItem(label, data?['name'] ?? 'Não encontrado');
        },
      );
    } catch (e) {
      return _buildDetailItem(label, 'Dado inválido');
    }
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          children: [
            TextSpan(
              text: '$label ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(
          _statusIcon,
          color: _statusColor,
          size: _iconSize,
        ),
        if (_status == 'negada')
          const Icon(Icons.block, color: Colors.white, size: 16),
      ],
    );
  }

  bool getConfirmationValue(String roleKey) {
    final confirmations = surgery['confirmations'] ?? {};
    return (confirmations[roleKey] ?? false);
  }

  void _navigateToDetails(BuildContext context) {
    // Criar cópia segura dos dados
    final safeSurgeryData = Map<String, dynamic>.from(surgery)
      ..['opme'] = surgery['opme'] is List ? surgery['opme'] : []
      ..['bloodProducts'] =
          surgery['bloodProducts'] is Map ? surgery['bloodProducts'] : {};

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SurgeryDetailsScreen(
          surgeryId: surgeryId,
          surgeryData: safeSurgeryData,
        ),
      ),
    );
  }

  void _confirmCancellation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Cancelamento'),
        content: const Text('Deseja realmente cancelar esta cirurgia?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Não'),
          ),
          TextButton(
            onPressed: () async => _handleCancellation(ctx),
            child: const Text('Sim', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCancellation(BuildContext dialogContext) async {
    try {
      await SurgeryService().cancelSurgery(surgeryId);
      if (!dialogContext.mounted) return;
      Navigator.pop(dialogContext);
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        const SnackBar(
          content: Text('Cirurgia cancelada com sucesso'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!dialogContext.mounted) return;
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        SnackBar(
          content: Text('Erro ao cancelar: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String get _formattedDateTime {
    try {
      final timestamp = surgery['dateTime'];
      return DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate());
    } catch (e) {
      return 'Data inválida';
    }
  }

  String get _formattedStatus => _status.capitalize();

  String get _status {
    final status = (surgery['status'] as String? ?? 'pendente').toLowerCase();
    final confirmations = surgery['confirmations'] ?? {};
    final required = surgery['requiredConfirmations'] ?? [];
    if (status == 'confirmada' &&
        required.any((role) => !(confirmations[role] ?? false))) {
      return 'pendente';
    }
    return status;
  }

  IconData get _statusIcon => switch (_status) {
        'confirmada' => Icons.check_circle,
        'negada' => Icons.cancel,
        _ => Icons.pending,
      };

  Color get _statusColor => switch (_status) {
        'confirmada' => AppColors.success,
        'negada' => AppColors.error,
        _ => AppColors.secondary,
      };

  DocumentReference? _getDocumentReference(dynamic value) {
    try {
      if (value is DocumentReference) {
        return value;
      }
      if (value is String) {
        if (value.contains('/')) {
          return FirebaseFirestore.instance.doc(value);
        }
        return FirebaseFirestore.instance.collection('procedures').doc(value);
      }
      return null;
    } catch (e) {
      debugPrint('Erro ao parsear referência: $e');
      return null;
    }
  }
}

class _BloodProductsDialog extends StatefulWidget {
  final Map<String, int> requestedProducts;

  const _BloodProductsDialog({required this.requestedProducts});

  @override
  State<_BloodProductsDialog> createState() => _BloodProductsDialogState();
}

class _BloodProductsDialogState extends State<_BloodProductsDialog> {
  final Map<String, bool> _confirmedProducts = {};

  @override
  void initState() {
    super.initState();
    _initProducts();
  }

  void _initProducts() {
    _confirmedProducts.addAll(
      widget.requestedProducts.map((key, value) => MapEntry(key, false)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirmar Hemoderivados Disponíveis'),
      content: _buildProductsList(),
      actions: _buildDialogActions(),
    );
  }

  Widget _buildProductsList() {
    return SizedBox(
      width: double.maxFinite,
      child: ListView(
        shrinkWrap: true,
        children:
            widget.requestedProducts.entries.map(_buildProductItem).toList(),
      ),
    );
  }

  Widget _buildProductItem(MapEntry<String, int> entry) {
    return FutureBuilder<DocumentSnapshot>(
      future: _getProductDetails(entry.key),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final product = snapshot.data!.data() as Map<String, dynamic>;
        return CheckboxListTile(
          title: Text(product['name']),
          subtitle: Text('Quantidade solicitada: ${entry.value}'),
          value: _confirmedProducts[entry.key] ?? false,
          onChanged: (value) => _updateProductStatus(entry.key, value),
        );
      },
    );
  }

  Future<DocumentSnapshot> _getProductDetails(String productId) {
    return FirebaseFirestore.instance
        .collection('blood_products')
        .doc(productId)
        .get();
  }

  void _updateProductStatus(String productId, bool? value) {
    setState(() => _confirmedProducts[productId] = value ?? false);
  }

  List<Widget> _buildDialogActions() {
    return [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      ElevatedButton(
        onPressed: () => _handleConfirmation(),
        child: const Text('Confirmar'),
      ),
    ];
  }

  void _handleConfirmation() {
    final unconfirmedProducts = _confirmedProducts.entries
        .where((e) => !e.value)
        .map((e) => e.key)
        .toList();

    final result = {
      'products': _confirmedProducts,
      'confirmed': unconfirmedProducts.isEmpty,
      if (unconfirmedProducts.isNotEmpty)
        'denialReason': _buildDenialReason(unconfirmedProducts),
      'status': unconfirmedProducts.isEmpty ? 'confirmada' : 'negada',
    };

    Navigator.pop(context, result);
  }

  String _buildDenialReason(List<String> missingProducts) {
    final products = missingProducts.join(', ');
    return 'Falta dos seguintes hemoderivados: $products';
  }
}
