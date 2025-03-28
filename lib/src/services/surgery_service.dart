import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart' as pdf;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class SurgeryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();

  Future<void> createSurgery(Map<String, dynamic> surgeryData) async {
    try {
      final procedureRef = surgeryData['procedure'] as DocumentReference;
      final surgeonRef = surgeryData['surgeon'] as DocumentReference;

      final futures = await Future.wait([
        procedureRef.get(),
        surgeonRef.get(),
      ]);

      if (!futures[0].exists || !futures[1].exists) {
        throw Exception('Referências inválidas para procedimento ou cirurgião');
      }

      // Garantir que os campos estão sendo salvos corretamente
      final opme = surgeryData['opme'] ?? [];
      final bloodProducts = surgeryData['bloodProducts'] ?? [];
      final dateTime = surgeryData['dateTime'] as DateTime;

      await _firestore.collection('surgeries').add({
        ...surgeryData,
        'procedure': procedureRef,
        'surgeon': surgeonRef,
        'status': 'pendente',
        'createdBy': _firestore.doc('users/${_auth.currentUser!.uid}'),
        'confirmations': _initConfirmations(),
        'timestamps': _initTimestamps(),
        'opme': opme,
        'bloodProducts': bloodProducts,
        'dateTime': Timestamp.fromDate(dateTime),
      });
    } on FirebaseException catch (e) {
      _logger.e('Erro Firestore [${e.code}]: ${e.message}');
      rethrow;
    } catch (e) {
      _logger.e('Erro geral: $e');
      rethrow;
    }
  }

  Map<String, bool> _initConfirmations() {
    return {
      'residente': false,
      'centro_cirurgico': false,
      'banco_sangue': false,
      'uti': false,
      'material_hospitalar': false,
    };
  }

  Map<String, dynamic> _initTimestamps() {
    final now = FieldValue.serverTimestamp();
    return {
      'createdAt': now,
      'updatedAt': now,
    };
  }

  Future<void> confirmRequirement(
      String surgeryId, String field, String userId, bool value) async {
    try {
      await _firestore.collection('surgeries').doc(surgeryId).update({
        'confirmations.$field': value,
        'confirmedBy.$field': userId,
        'timestamps.updatedAt': FieldValue.serverTimestamp(),
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
        'timestamps.updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      _logger.e('Erro ao cancelar [${e.code}]: ${e.message}');
      rethrow;
    }
  }

  Future<void> confirmResidentPreOp(
      String surgeryId, String userId, bool value) async {
    try {
      await _firestore.collection('surgeries').doc(surgeryId).update({
        'confirmations.residente': value,
        'confirmedBy.residente': userId,
        'timestamps.updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _logger.e('Erro na confirmação do residente: $e');
      rethrow;
    }
  }

  Future<void> generateDailyReport() async {
    try {
      final now = DateTime.now();
      final range = _getDailyRange(now);

      final surgeries = await _fetchSurgeries(range);

      final pdfDoc = _buildPdfDocument(now, surgeries);
      await Printing.layoutPdf(onLayout: (_) => pdfDoc.save());
    } catch (e) {
      _logger.e('Erro no relatório: $e');
      rethrow;
    }
  }

  List<DateTime> _getDailyRange(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    return [start, start.add(const Duration(days: 1))];
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _fetchSurgeries(
      List<DateTime> range) async {
    final snapshot = await _firestore
        .collection('surgeries')
        .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(range[0]))
        .where('dateTime', isLessThan: Timestamp.fromDate(range[1]))
        .get();

    return snapshot.docs;
  }

  pw.Document _buildPdfDocument(DateTime now,
      List<QueryDocumentSnapshot<Map<String, dynamic>>> surgeries) {
    final pdfDoc = pw.Document();

    pdfDoc.addPage(
      pw.Page(
        pageFormat: pdf.PdfPageFormat.a4,
        build: (context) => pw.Column(
          children: [
            _buildHeader(now),
            _buildSurgeryTable(surgeries),
          ],
        ),
      ),
    );

    return pdfDoc;
  }

  pw.Widget _buildHeader(DateTime date) {
    return pw.Header(
      level: 1,
      text: 'Relatório Diário - ${DateFormat('dd/MM/yyyy').format(date)}',
      textStyle: pw.TextStyle(
        fontSize: 18,
        fontWeight: pw.FontWeight.bold,
      ),
    );
  }

  pw.Table _buildSurgeryTable(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> surgeries) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      cellAlignment: pw.Alignment.centerLeft,
      headers: _tableHeaders,
      data: surgeries.map(_mapSurgeryToTableRow).toList(),
    );
  }

  final List<String> _tableHeaders = [
    'Paciente',
    'Procedimento',
    'Cirurgião',
    'Horário',
    'Status',
    'Confirmações',
  ];

  List<String> _mapSurgeryToTableRow(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final surgery = doc.data();
    return [
      surgery['patientName'] ?? 'N/A',
      _getDocumentName(surgery['procedure']?.id ?? ''), // Passa o ID
      _getDocumentName(surgery['surgeon']?.id ?? ''),
      _formatDateTime(surgery['dateTime']),
      surgery['status']?.toString().toUpperCase() ?? 'N/A',
      _formatConfirmations(surgery['confirmations']),
    ];
  }

  String _getDocumentName(dynamic docRef) {
    return (docRef as DocumentReference)
        .id; // Implementar cache de nomes se necessário
  }

  String _formatDateTime(dynamic timestamp) {
    try {
      return DateFormat('HH:mm').format((timestamp as Timestamp).toDate());
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatConfirmations(Map<String, dynamic> confirmations) {
    return confirmations.entries
        .map((e) => '${_getRoleName(e.key)}: ${e.value ? '✔' : '✖'}')
        .join('\n');
  }

  String _getRoleName(String key) {
    const names = {
      'residente': 'Residente',
      'centro_cirurgico': 'Centro Cirúrgico',
      'banco_sangue': 'Banco de Sangue',
      'uti': 'UTI',
      'material_hospitalar': 'Material',
    };
    return names[key] ?? key;
  }
}
