import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cirurgiapp/src/core/constants/app_colors.dart';
import 'package:cirurgiapp/src/services/surgery_service.dart';

class SurgeryDetailsScreen extends StatefulWidget {
  final String surgeryId;
  final Map<String, dynamic> surgeryData;

  const SurgeryDetailsScreen({
    super.key,
    required this.surgeryId,
    required this.surgeryData,
  });

  @override
  State<SurgeryDetailsScreen> createState() => _SurgeryDetailsScreenState();
}

class _SurgeryDetailsScreenState extends State<SurgeryDetailsScreen> {
  late Future<Map<String, String>> _loadedReferences;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadedReferences = _loadReferenceData();
  }

  Future<Map<String, String>> _loadReferenceData() async {
    final references = <String, String>{};

    // Carrega o nome do cirurgião
    if (widget.surgeryData['surgeon'] is DocumentReference) {
      final doc =
          await (widget.surgeryData['surgeon'] as DocumentReference).get();
      references['surgeon'] = doc['name'] ?? 'Cirurgião não especificado';
    } else if (widget.surgeryData['surgeon'] is String) {
      references['surgeon'] = widget.surgeryData['surgeon'];
    } else {
      references['surgeon'] = 'Cirurgião não especificado';
    }

    // Carrega o nome do procedimento
    if (widget.surgeryData['procedure'] is DocumentReference) {
      final doc =
          await (widget.surgeryData['procedure'] as DocumentReference).get();
      references['procedure'] = doc['name'] ?? 'Procedimento não especificado';
    } else if (widget.surgeryData['procedure'] is String) {
      references['procedure'] = widget.surgeryData['procedure'];
    } else {
      references['procedure'] = 'Procedimento não especificado';
    }

    return references;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes da Cirurgia')),
      body: FutureBuilder<Map<String, String>>(
        future: _loadedReferences,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          final references = snapshot.data ?? {};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPatientName(context),
                const SizedBox(height: 20),
                _buildSurgeryDetails(references),
                const SizedBox(height: 20),
                _buildConfirmationStatus(),
                const SizedBox(height: 20),
                _buildStatusChip(),
                if (widget.surgeryData['status']?.toString().toLowerCase() ==
                    'negada')
                  _buildDenialReason(),
                if (_shouldShowCancelButton(context))
                  _buildCancelButton(context),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Caso a cirurgia tenha sido cancelada pelo NIR, exibe a mensagem específica.
  /// Caso contrário, segue a lógica de exibição dos motivos de negação,
  /// incluindo a conversão dos IDs para nomes dos materiais ou hemoderivados.
  Widget _buildDenialReason() {
    if (widget.surgeryData['cancelledBy'] == 'NIR') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text('Cancelamento:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          _buildDetailItem('Motivo:', 'Cirurgia cancelada pelo NIR'),
        ],
      );
    }

    final denialReasons =
        widget.surgeryData['denialReasons'] as Map<String, dynamic>? ?? {};
    final List<Widget> reasonWidgets = [];

    if (widget.surgeryData['denialReason'] != null) {
      final reason = widget.surgeryData['denialReason'];
      if (reason.startsWith("Falta dos seguintes hemoderivados:")) {
        reasonWidgets.add(
            _buildMaterialDenialReason(reason, collection: 'blood_products'));
      } else if (reason.startsWith("Falta dos seguintes materiais:")) {
        reasonWidgets
            .add(_buildMaterialDenialReason(reason, collection: 'opme'));
      } else {
        reasonWidgets.add(_buildDetailItem("Motivo da negação:", reason));
      }
    }

    denialReasons.forEach((key, value) {
      if (value != null && value != false) {
        final reasonText = value is String ? value : 'Não confirmado';
        if (key == 'banco_sangue' &&
            reasonText.startsWith("Falta dos seguintes hemoderivados:")) {
          reasonWidgets.add(_buildMaterialDenialReason(reasonText,
              collection: 'blood_products'));
        } else if (key == 'material_hospitalar' &&
            reasonText.startsWith("Falta dos seguintes materiais:")) {
          reasonWidgets
              .add(_buildMaterialDenialReason(reasonText, collection: 'opme'));
        } else {
          reasonWidgets
              .add(_buildDetailItem('${_getRoleName(key)}:', reasonText));
        }
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text('Motivos da Negação:',
            style: TextStyle(fontWeight: FontWeight.bold)),
        ...reasonWidgets,
      ],
    );
  }

  /// Converte o motivo de negação em nomes reais dos materiais ou hemoderivados.
  Widget _buildMaterialDenialReason(String reason,
      {String collection = 'opme'}) {
    final opmePrefix = "Falta dos seguintes materiais:";
    final bloodPrefix = "Falta dos seguintes hemoderivados:";

    String prefix;
    if (reason.startsWith(bloodPrefix)) {
      prefix = bloodPrefix;
    } else if (reason.startsWith(opmePrefix)) {
      prefix = opmePrefix;
    } else {
      return _buildDetailItem("Motivo da negação:", reason);
    }

    final idsPart = reason.substring(prefix.length).trim();
    final materialIds = idsPart
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return FutureBuilder<List<String>>(
      future: _fetchMaterialNames(materialIds, collection: collection),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildDetailItem(
              "Motivo da negação:", "Carregando nomes dos materiais...");
        }
        if (snapshot.hasError) {
          return _buildDetailItem(
              "Motivo da negação:", "Erro ao carregar nomes dos materiais");
        }
        final materialNames = snapshot.data!.join(", ");
        return _buildDetailItem("Motivo da negação:", "$prefix $materialNames");
      },
    );
  }

  Future<List<String>> _fetchMaterialNames(List<String> materialIds,
      {String collection = 'opme'}) async {
    List<String> names = [];
    for (String id in materialIds) {
      try {
        final doc = await _firestore.collection(collection).doc(id).get();
        if (doc.exists) {
          names.add(doc['name'] ?? id);
        } else {
          names.add(id);
        }
      } catch (e) {
        names.add(id);
      }
    }
    return names;
  }

  Widget _buildPatientName(BuildContext context) {
    return Text(
      widget.surgeryData['patientName'] ?? 'Paciente não informado',
      style: Theme.of(context).textTheme.headlineSmall,
    );
  }

  Widget _buildSurgeryDetails(Map<String, String> references) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailItem('Procedimento:', references['procedure']),
        _buildDetailItem('Cirurgião:', references['surgeon']),
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
    final confirmations =
        widget.surgeryData['confirmations'] as Map<String, dynamic>? ?? {};

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
        widget.surgeryData['status']?.toString().toLowerCase() ?? 'pendente';
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
              await SurgeryService().cancelSurgery(widget.surgeryId);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                if (context.mounted) Navigator.pop(context);
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
      final timestamp = widget.surgeryData['dateTime'];
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
    final status = widget.surgeryData['status']?.toString().toLowerCase();
    return status == 'pendente' && _isNIRUser(context);
  }

  bool _isNIRUser(BuildContext context) {
    // Implementar lógica de verificação do usuário NIR
    return true;
  }
}
