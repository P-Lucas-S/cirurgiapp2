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
  final String userRole; // Propriedade adicionada

  static const double _iconSize = 32;
  static const double _cardElevation = 3;
  static const EdgeInsets _cardMargin =
      EdgeInsets.symmetric(vertical: 8, horizontal: 16);
  static const EdgeInsets _contentPadding = EdgeInsets.all(16);

  // Constante de salas cirúrgicas
  static const List<String> _surgeryRooms = [
    'Sala 1',
    'Sala 2',
    'Sala 3',
    'Sala 4'
  ];

  const SurgeryCard({
    Key? key,
    required this.surgeryId,
    required this.surgery,
    required this.userRole, // Parâmetro obrigatório adicionado
    this.canConfirm = false,
    this.canCancel = false,
  }) : super(key: key);

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
        _buildReferenceItem(
          label: 'Produto Sanguíneo:',
          reference: surgery['bloodProducts'],
        ),
      ],
    );
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
    return Icon(
      _statusIcon,
      color: _statusColor,
      size: _iconSize,
    );
  }

  // Método modificado para confirmação com base na role do usuário
  Widget _buildConfirmButton(BuildContext context) {
    if (!canConfirm) return const SizedBox.shrink();

    // Verifica se a role do usuário é 'Centro Cirúrgico'
    final bool isSurgicalCenter = userRole == 'Centro Cirúrgico';

    if (isSurgicalCenter) {
      return IconButton(
        icon: Icon(
          surgery['confirmations']['centro_cirurgico'] ?? false
              ? Icons.check_circle
              : Icons.meeting_room_outlined,
          color: surgery['confirmations']['centro_cirurgico'] ?? false
              ? AppColors.success
              : AppColors.secondary,
        ),
        onPressed: () => _showSurgicalCenterDialog(context),
      );
    }

    // Confirmação padrão para Residentes
    return IconButton(
      icon: Icon(
        surgery['confirmations']['residente'] ?? false
            ? Icons.check_circle
            : Icons.pending_actions,
        color: surgery['confirmations']['residente'] ?? false
            ? AppColors.success
            : AppColors.secondary,
      ),
      onPressed: () => _toggleResidentConfirmation(context),
    );
  }

  // Novo método para mostrar o diálogo do Centro Cirúrgico
  void _showSurgicalCenterDialog(BuildContext context) {
    String? selectedRoom = surgery['surgeryRoom'];
    bool isConfirmed = surgery['confirmations']['centro_cirurgico'] ?? false;

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
                    .map((room) => DropdownMenuItem(
                          value: room,
                          child: Text(room),
                        ))
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
                  // Atualiza a confirmação e a sala selecionada
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
    final newValue = !(surgery['confirmations']['residente'] ?? false);
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
      return DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate());
    } catch (e) {
      return 'Data inválida';
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
