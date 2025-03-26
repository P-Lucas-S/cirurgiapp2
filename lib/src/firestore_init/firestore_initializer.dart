import 'package:cloud_firestore/cloud_firestore.dart';
import 'procedures_list.dart';

class FirestoreInitializer {
  final FirebaseFirestore _firestore;
  static const _maxBatchSize = 500; // Tamanho máximo permitido pelo Firestore

  FirestoreInitializer({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> initializeProcedures() async {
    try {
      final existingNames = await _fetchExistingProcedureNames();
      final operations = _prepareBatchOperations(existingNames);

      if (operations.isEmpty) {
        _log('ℹ️ Nenhum novo procedimento para adicionar');
        return;
      }

      await _executeBatchOperations(operations);
      _log('✅ ${operations.length} novos procedimentos adicionados!');
    } catch (e) {
      _log('❌ Erro crítico: ${e.toString()}');
      rethrow;
    }
  }

  Future<Set<String>> _fetchExistingProcedureNames() async {
    final snapshot = await _firestore.collection('procedures').get();
    return snapshot.docs
        .map((doc) => doc.get('name').toString().toLowerCase())
        .toSet();
  }

  List<WriteBatch> _prepareBatchOperations(Set<String> existingNames) {
    final batches = <WriteBatch>[];
    WriteBatch currentBatch = _firestore.batch();
    int operationCount = 0;

    for (final (index, name) in surgicalProcedures.indexed) {
      if (existingNames.contains(name.toLowerCase())) continue;

      final docRef = _firestore.collection('procedures').doc();
      currentBatch.set(docRef, {
        'name': name,
        'order': index + 1,
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      operationCount++;
      if (operationCount % _maxBatchSize == 0) {
        batches.add(currentBatch);
        currentBatch = _firestore.batch();
      }
    }

    if (operationCount % _maxBatchSize != 0) {
      batches.add(currentBatch);
    }

    return batches;
  }

  Future<void> _executeBatchOperations(List<WriteBatch> batches) async {
    for (final batch in batches) {
      await batch.commit();
    }
  }

  void _log(String message) {
    // Pode ser substituído por um logger profissional em produção
    print('[FirestoreInitializer] $message');
  }
}
