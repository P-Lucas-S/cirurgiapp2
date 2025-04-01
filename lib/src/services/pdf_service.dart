import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PdfService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> generateDailySurgeriesPdf(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime startOfDay = DateTime(now.year, now.month, now.day);
    final DateTime endOfDay = startOfDay.add(const Duration(days: 1));

    // Busca as cirurgias do dia
    final QuerySnapshot snapshot = await _firestore
        .collection('surgeries')
        .where('dateTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('dateTime', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .get();

    // Processa cada documento para buscar os nomes dos procedimentos e cirurgiões
    final List<Map<String, dynamic>> surgeriesData = await Future.wait(
      snapshot.docs.map((doc) async {
        final data = doc.data() as Map<String, dynamic>;
        String procedureName = 'N/A';
        String surgeonName = 'N/A';

        try {
          final procedureSnapshot =
              await (data['procedure'] as DocumentReference).get();
          procedureName = procedureSnapshot.get('name');
        } catch (e) {
          procedureName = 'Não encontrado';
        }

        try {
          final surgeonSnapshot =
              await (data['surgeon'] as DocumentReference).get();
          surgeonName = surgeonSnapshot.get('name');
        } catch (e) {
          surgeonName = 'Não encontrado';
        }

        return {
          'patientName': data['patientName'] ?? 'N/A',
          'procedureName': procedureName,
          'surgeonName': surgeonName,
          'surgeryRoom': data['surgeryRoom'] ?? 'N/A', // Agora pega a sala
          'dateTime': data['dateTime'],
          'confirmations': data['confirmations'] ?? {},
        };
      }).toList(),
    );

    final pw.Document pdfDoc = pw.Document();

    pdfDoc.addPage(
      pw.Page(
        pageFormat: pdf.PdfPageFormat.a4.landscape.copyWith(
          marginBottom: 20,
          marginLeft: 20,
          marginRight: 20,
          marginTop: 20,
        ),
        build: (pw.Context context) {
          return pw.Column(
            children: [
              _buildHeader(now),
              pw.SizedBox(height: 20),
              _buildSurgeriesTable(surgeriesData),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (pdf.PdfPageFormat format) async => pdfDoc.save(),
    );
  }

  pw.Widget _buildHeader(DateTime date) {
    return pw.Header(
      level: 1,
      child: pw.Text(
        'Cirurgias do Dia - ${DateFormat('dd/MM/yyyy').format(date)}',
        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  // Agora a coluna 'Status' foi substituída por 'Sala'
  pw.Widget _buildSurgeriesTable(List<Map<String, dynamic>> surgeries) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headers: [
        'Paciente',
        'Procedimento',
        'Cirurgião',
        'Horário',
        'Sala',
        'Confirmações'
      ],
      data: surgeries.map((surgery) {
        return [
          surgery['patientName'],
          surgery['procedureName'],
          surgery['surgeonName'],
          _formatDateTime(surgery['dateTime']),
          surgery['surgeryRoom'],
          _formatConfirmations(surgery['confirmations']),
        ];
      }).toList(),
    );
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
        .map((e) => '${_getRoleName(e.key)}: ${e.value ? 'OK' : 'NEGADA'}')
        .join('\n');
  }

  String _getRoleName(String key) {
    return const {
          'residente': 'Pré-operatório',
          'centro_cirurgico': 'OK',
          'banco_sangue': 'Banco de Sangue',
          'uti': 'UTI',
          'material_hospitalar': 'Material',
        }[key] ??
        key;
  }
}
