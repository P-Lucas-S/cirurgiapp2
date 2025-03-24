import 'package:cloud_firestore/cloud_firestore.dart';
import 'procedures_list.dart';

class FirestoreInitializer {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initializeProcedures() async {
    try {
      // Verifica procedimentos existentes
      final existingProcedures = await _getExistingProcedures();

      // Prepara batch de escrita
      WriteBatch batch = _firestore.batch();
      int addedCount = 0;

      for (int i = 0; i < surgicalProcedures.length; i++) {
        final name = surgicalProcedures[i];
        if (!existingProcedures.contains(name.toLowerCase())) {
          final ref = _firestore.collection('procedures').doc();
          batch.set(ref, {
            'name': name,
            'createdAt': FieldValue.serverTimestamp(),
            'order': i + 1,
            'active': true
          });
          addedCount++;
        }
      }

      // Executa batch se houver alterações
      if (addedCount > 0) {
        await batch.commit();
        print('✅ $addedCount novos procedimentos adicionados!');
      } else {
        print('ℹ️ Nenhum novo procedimento para adicionar');
      }
    } catch (e) {
      print('❌ Erro: ${e.toString()}');
      rethrow;
    }
  }

  Future<Set<String>> _getExistingProcedures() async {
    final snapshot = await _firestore.collection('procedures').get();
    return snapshot.docs
        .map((doc) => doc['name'].toString().toLowerCase())
        .toSet();
  }
}
