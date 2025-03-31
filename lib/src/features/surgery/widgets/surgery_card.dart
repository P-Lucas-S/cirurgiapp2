import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cirurgiapp/src/core/constants/app_colors.dart';
import 'package:cirurgiapp/src/core/extensions/string_extensions.dart';
import 'package:cirurgiapp/src/features/surgery/screens/surgery_details_screen.dart';
import 'package:cirurgiapp/src/services/surgery_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  static const List<String> _surgeryRooms = [
    'Sala 1',
    'Sala 2',
    'Sala 3',
    'Sala 4'
  ];

  const SurgeryCard({
    super.key,
    required this.surgeryId,
    required this.surgery,
    required this.userRole,
    required this.canConfirm,
    this.canCancel = false,
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
              _buildCardContent(context),
              if (canConfirm)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    child: const Text('Confirmar'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent(BuildContext context) {
    return Row(
      children: [
        _buildStatusIcon(),
        const SizedBox(width: 16),
        Expanded(child: _buildSurgeryInfo(context)),
        if (canCancel) _buildCancelButton(context),
        if (canConfirm) _buildConfirmButton(context),
      ],
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

  Widget _buildCancelButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.cancel, color: AppColors.error),
      onPressed: () => _confirmCancellation(context),
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

  // Método auxiliar para retornar o valor da confirmação baseado na role
  bool getConfirmationValue(String roleKey) {
    final confirmations = surgery['confirmations'] ?? {};
    return (confirmations[roleKey] ?? false);
  }

  // Retorna a chave de confirmação de acordo com a role do usuário
  String _getRoleKey() {
    return switch (userRole) {
      'Banco de Sangue' => 'banco_sangue',
      'Centro Cirúrgico' => 'centro_cirurgico',
      'Residente de Cirurgia' => 'residente',
      'UTI' => 'uti',
      'Centro de Material Hospitalar' => 'material_hospitalar',
      _ => '',
    };
  }

  // Método _buildConfirmButton refatorado utilizando os métodos auxiliares
  Widget _buildConfirmButton(BuildContext context) {
    if (!canConfirm) return const SizedBox.shrink();

    final roleKey = _getRoleKey();
    final isConfirmed = getConfirmationValue(roleKey);

    switch (userRole) {
      case 'Banco de Sangue':
        return IconButton(
          icon: _getConfirmationIcon(),
          onPressed: () => _handleBloodBankConfirmation(context),
        );
      case 'Centro Cirúrgico':
        return IconButton(
          icon: Icon(
            isConfirmed ? Icons.check_circle : Icons.meeting_room_outlined,
            color: isConfirmed ? AppColors.success : AppColors.secondary,
          ),
          onPressed: () => _showSurgicalCenterDialog(context),
        );
      case 'Residente de Cirurgia':
        return IconButton(
          icon: Icon(
            isConfirmed ? Icons.check_circle : Icons.pending_actions,
            color: isConfirmed ? AppColors.success : AppColors.secondary,
          ),
          onPressed: () => _toggleResidentConfirmation(context),
        );
      case 'UTI':
        return IconButton(
          icon: Icon(
            isConfirmed ? Icons.check_circle : Icons.emergency,
            color: isConfirmed ? AppColors.success : AppColors.secondary,
          ),
          onPressed: onConfirm,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Icon _getConfirmationIcon() {
    final isConfirmed = getConfirmationValue('banco_sangue');
    return Icon(
      isConfirmed ? Icons.check_circle : Icons.bloodtype_outlined,
      color: isConfirmed ? AppColors.success : AppColors.secondary,
    );
  }

  void _handleBloodBankConfirmation(BuildContext context) {
    _BloodBankConfirmation(
      context: context,
      surgeryId: surgeryId,
      surgery: surgery,
    ).execute();
  }

  void _showSurgicalCenterDialog(BuildContext context) {
    String? selectedRoom = surgery['surgeryRoom'];
    bool isConfirmed = getConfirmationValue('centro_cirurgico');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Confirmar Centro Cirúrgico'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Confirmar Cirurgia'),
                value: isConfirmed,
                activeColor: AppColors.success,
                onChanged: (value) => setState(() => isConfirmed = value),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedRoom,
                decoration: InputDecoration(
                  labelText: 'Selecionar Sala',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                ),
                items: _surgeryRooms
                    .map(
                      (room) => DropdownMenuItem(
                        value: room,
                        child: Text(room),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => selectedRoom = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await SurgeryService().confirmRequirement(
                    surgeryId,
                    'centro_cirurgico',
                    FirebaseAuth.instance.currentUser!.uid,
                    isConfirmed,
                  );
                  if (selectedRoom != null) {
                    await FirebaseFirestore.instance
                        .collection('surgeries')
                        .doc(surgeryId)
                        .update({'surgeryRoom': selectedRoom});
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('Erro: ${e.toString()}')),
                    );
                  }
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleResidentConfirmation(BuildContext context) {
    final newValue = !getConfirmationValue('residente');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(newValue
            ? 'Confirmar Pré-Operatório?'
            : 'Desconfirmar Pré-Operatório?'),
        content: Text(newValue
            ? 'Confirmar que o pré-operatório foi realizado conforme protocolo?'
            : 'Deseja retirar a confirmação do pré-operatório?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await SurgeryService().confirmRequirement(
                  surgeryId,
                  'residente',
                  FirebaseAuth.instance.currentUser!.uid,
                  newValue,
                );
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Erro: ${e.toString()}')),
                  );
                }
              }
            },
            child: Text(newValue ? 'Confirmar' : 'Desconfirmar'),
          ),
        ],
      ),
    );
  }

  // Método refatorado com sanitização dos dados
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
          surgeryData: safeSurgeryData, // Usar dados sanitizados
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

  // Getter atualizado conforme as mudanças solicitadas
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
    final bloodProducts = (surgery['bloodProducts'] as Map<String, dynamic>)
        .map((key, value) => MapEntry(key, (value as num).toInt()));
    final result = await _showConfirmationDialog(bloodProducts);

    if (result == null || !context.mounted) return;

    await _updateSurgeryStatus(result);
  }

  Future<Map<String, dynamic>?> _showConfirmationDialog(
      Map<String, int> requestedProducts) async {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _BloodProductsDialog(
        requestedProducts: requestedProducts,
      ),
    );
  }

  Future<void> _updateSurgeryStatus(Map<String, dynamic> result) async {
    try {
      final updateData = {
        'confirmations.banco_sangue': result['confirmed'],
        'status': result['status'],
        'bloodProductsConfirmation': result['products'],
        if (result['denialReason'] != null)
          'denialReason': result['denialReason'],
      };

      await FirebaseFirestore.instance
          .collection('surgeries')
          .doc(surgeryId)
          .update(updateData);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro na confirmação: ${e.toString()}')),
        );
      }
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
