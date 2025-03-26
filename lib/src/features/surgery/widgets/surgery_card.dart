import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cirurgiapp/src/core/constants/app_colors.dart';
import 'package:cirurgiapp/src/core/extensions/string_extensions.dart';
import 'package:cirurgiapp/src/features/surgery/screens/surgery_details_screen.dart';
import 'package:cirurgiapp/src/services/surgery_service.dart';
import 'package:provider/provider.dart';
import 'package:cirurgiapp/src/core/models/user_model.dart';

class SurgeryCard extends StatelessWidget {
  final String surgeryId;
  final Map<String, dynamic> surgery;
  final bool canCancel;

  static const double _iconSize = 32;
  static const double _cardElevation = 3;
  static const EdgeInsets _cardMargin =
      EdgeInsets.symmetric(vertical: 8, horizontal: 16);
  static const EdgeInsets _contentPadding = EdgeInsets.all(16);

  const SurgeryCard({
    super.key,
    required this.surgeryId,
    required this.surgery,
    this.canCancel = false,
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
          child: _buildCardContent(context),
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
          collection: 'procedures',
          documentId: surgery['procedure']?.toString() ?? '',
        ),
        _buildReferenceItem(
          label: 'Cirurgião:',
          collection: 'surgeons',
          documentId: surgery['surgeon']?.toString() ?? '',
        ),
      ],
    );
  }

  Widget _buildReferenceItem({
    required String label,
    required String collection,
    required String documentId,
  }) {
    if (documentId.isEmpty) return _buildDetailItem(label, 'Não especificado');

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection(collection)
          .doc(documentId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildDetailItem(label, 'Carregando...');
        }

        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final value =
            data?['name']?.toString().capitalize() ?? 'Não encontrado';
        return _buildDetailItem(label, value);
      },
    );
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
    return Icon(
      _statusIcon,
      color: _statusColor,
      size: _iconSize,
    );
  }

  Widget _buildCancelButton(BuildContext context) {
    final user = Provider.of<HospitalUser?>(context);
    if (user == null || !user.roles.contains('NIR'))
      return const SizedBox.shrink();

    return IconButton(
      icon: const Icon(Icons.cancel, color: AppColors.error),
      onPressed: () => _confirmCancellation(context),
    );
  }

  void _navigateToDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SurgeryDetailsScreen(
          surgeryId: surgeryId,
          surgeryData: surgery,
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
      if (timestamp is Timestamp) {
        return DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate());
      }
      return 'Data inválida';
    } catch (e) {
      return 'Formato incorreto';
    }
  }

  String get _formattedStatus => _status.capitalize();

  String get _status =>
      (surgery['status'] as String? ?? 'pendente').toLowerCase();

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
}
