import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cirurgiapp/src/core/constants/app_colors.dart';
import 'package:cirurgiapp/src/services/surgery_service.dart';

class SurgeryDetailsScreen extends StatelessWidget {
  final String surgeryId;
  final Map<String, dynamic> surgeryData;

  const SurgeryDetailsScreen({
    super.key,
    required this.surgeryId,
    required this.surgeryData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes da Cirurgia')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPatientName(context),
            const SizedBox(height: 20),
            _buildSurgeryDetails(),
            const SizedBox(height: 20),
            _buildConfirmationStatus(),
            const SizedBox(height: 20),
            _buildStatusChip(),
            if (_shouldShowCancelButton(context)) _buildCancelButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientName(BuildContext context) {
    return Text(
      surgeryData['patientName'] ?? 'Paciente não informado',
      style: Theme.of(context).textTheme.headlineSmall,
    );
  }

  Widget _buildSurgeryDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailItem('Procedimento:', surgeryData['procedure']),
        _buildDetailItem('Cirurgião:', surgeryData['surgeon']),
        _buildDetailItem('Data:', _formattedDate),
      ],
    );
  }

  Widget _buildDetailItem(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value ?? 'Não informado')),
        ],
      ),
    );
  }

  Widget _buildConfirmationStatus() {
    final confirmations = surgeryData['confirmations'] as Map<String, dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Confirmações:',
            style: TextStyle(fontWeight: FontWeight.bold)),
        ...confirmations.entries.map((entry) => ListTile(
              title: Text(_getRoleName(entry.key)),
              trailing: Icon(
                entry.value ? Icons.check_circle : Icons.cancel,
                color: entry.value ? AppColors.success : AppColors.error,
              ),
            )),
      ],
    );
  }

  Widget _buildStatusChip() {
    final status =
        surgeryData['status']?.toString().toLowerCase() ?? 'pendente';
    final (backgroundColor, textColor) = _getStatusColors(status);

    return Chip(
      label: Text(status.toUpperCase()),
      backgroundColor: backgroundColor,
      labelStyle: TextStyle(color: textColor),
    );
  }

  Widget _buildCancelButton(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.cancel),
      label: const Text('Cancelar Cirurgia'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.error,
        foregroundColor: Colors.white,
      ),
      onPressed: () => _confirmCancellation(context),
    );
  }

  void _confirmCancellation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Cancelamento'),
        content: const Text('Tem certeza que deseja cancelar esta cirurgia?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Voltar'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await SurgeryService().cancelSurgery(surgeryId);

                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cirurgia cancelada com sucesso'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao cancelar: ${e.toString()}'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Confirmar',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  String get _formattedDate {
    try {
      final timestamp = surgeryData['dateTime'];
      if (timestamp is Timestamp) {
        return DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate());
      }
      return 'Data inválida';
    } catch (e) {
      return 'Formato incorreto';
    }
  }

  String _getRoleName(String key) {
    return switch (key) {
      'residente' => 'Residente de Cirurgia',
      'centro_cirurgico' => 'Centro Cirúrgico',
      'banco_sangue' => 'Banco de Sangue',
      'uti' => 'UTI',
      'material_hospitalar' => 'Material Hospitalar',
      _ => key,
    };
  }

  (Color, Color) _getStatusColors(String status) {
    return switch (status) {
      'confirmada' => (AppColors.success.withAlpha(51), AppColors.success),
      'negada' => (AppColors.error.withAlpha(51), AppColors.error),
      _ => (AppColors.secondary.withAlpha(51), AppColors.secondary),
    };
  }

  bool _shouldShowCancelButton(BuildContext context) {
    final status = surgeryData['status']?.toString().toLowerCase();
    return status == 'pendente' && _isNIRUser(context);
  }

  bool _isNIRUser(BuildContext context) {
    // Implementar lógica de verificação do usuário NIR
    return true;
  }
}
