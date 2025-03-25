import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:pdf/widgets.dart' as pw; // Para criar o documento PDF
import 'package:pdf/pdf.dart' as pdfLib; // Para a classe PdfPageFormat
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SurgeryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> createSurgery(Map<String, dynamic> surgeryData) async {
    try {
      await _firestore.collection('surgeries').add({
        ...surgeryData,
        'status': 'pendente',
        'confirmations': {
          'residente': false,
          'centro_cirurgico': false,
          'banco_sangue': false,
          'uti': false,
          'material_hospitalar': false,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'canceledBy': _auth.currentUser!.uid, // Agora _auth está definido
      });
    } catch (e) {
      _logger.e('Erro ao criar cirurgia: $e');
      rethrow;
    }
  }

  Future<void> confirmRequirement(String surgeryId, String role) async {
    try {
      await _firestore.collection('surgeries').doc(surgeryId).update({
        'confirmations.$role': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _logger.e('Erro na confirmação: $e');
      rethrow;
    }
  }

  Future<void> cancelSurgery(String surgeryId) async {
    try {
      await _firestore.collection('surgeries').doc(surgeryId).update({
        'status': 'negada',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _logger.e('Erro ao cancelar cirurgia: $e');
      rethrow;
    }
  }

  Future<void> generateDailyReport() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final QuerySnapshot<Map<String, dynamic>> surgeriesSnapshot =
        await _firestore
            .collection('surgeries')
            .where('dateTime',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('dateTime', isLessThan: Timestamp.fromDate(endOfDay))
            .get();

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: pdfLib.PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Header(
                text:
                    'Relatório Diário - ${DateFormat('dd/MM/yyyy').format(now)}',
                level: 1,
              ),
              pw.Table.fromTextArray(
                context: context,
                border: pw.TableBorder.all(),
                headers: [
                  'Paciente',
                  'Procedimento',
                  'Cirurgião',
                  'Horário',
                  'Status',
                  'Confirmações',
                ],
                data: surgeriesSnapshot.docs.map((doc) {
                  final surgery = doc.data();
                  return [
                    surgery['patientName'],
                    surgery['procedure'],
                    surgery['surgeon'],
                    DateFormat('HH:mm')
                        .format((surgery['dateTime'] as Timestamp).toDate()),
                    surgery['status'],
                    _formatConfirmations(surgery['confirmations']),
                  ];
                }).toList(),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  String _formatConfirmations(Map<String, dynamic> confirmations) {
    return confirmations.entries
        .map((e) => '${_getRoleName(e.key)}: ${e.value ? '✔' : '✖'}')
        .join('\n');
  }

  String _getRoleName(String key) {
    return switch (key) {
      'residente' => 'Residente',
      'centro_cirurgico' => 'Centro Cirúrgico',
      'banco_sangue' => 'Banco de Sangue',
      'uti' => 'UTI',
      'material_hospitalar' => 'Material',
      _ => key,
    };
  }
}
