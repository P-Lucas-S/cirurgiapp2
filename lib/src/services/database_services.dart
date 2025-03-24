import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

abstract class BaseDatabaseService {
  final CollectionReference collection;

  BaseDatabaseService(String collectionName)
      : collection = FirebaseFirestore.instance.collection(collectionName);

  Future<List<String>> getItems() async {
    try {
      final snapshot = await collection
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();
      return snapshot.docs
          .map((doc) => doc['name']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toList();
    } on FirebaseException catch (e) {
      debugPrint('Error getting items: $e');
      throw 'Falha ao carregar dados';
    }
  }

  Future<void> addItem(String name) async {
    try {
      if (name.isEmpty) throw 'Nome inválido';

      final exists = await _checkItemExists(name);
      if (exists) throw 'Item já existe';

      await collection.add({
        'name': name.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'searchKeywords': _generateSearchKeywords(name),
      });
    } on FirebaseException catch (e) {
      debugPrint('Error adding item: $e');
      throw 'Falha ao adicionar item';
    }
  }

  Future<bool> _checkItemExists(String name) async {
    final result =
        await collection.where('name', isEqualTo: name.trim()).limit(1).get();
    return result.docs.isNotEmpty;
  }

  List<String> _generateSearchKeywords(String name) {
    final keywords = <String>[];
    final cleanedName = name.trim().toLowerCase();

    for (int i = 1; i <= cleanedName.length; i++) {
      keywords.add(cleanedName.substring(0, i));
    }

    return keywords;
  }
}

// Serviços Especializados
class SurgeonService extends BaseDatabaseService {
  SurgeonService() : super('surgeons');
}

class ProceduresService extends BaseDatabaseService {
  ProceduresService() : super('procedures');
}

class AnesthesiologistService extends BaseDatabaseService {
  AnesthesiologistService() : super('anesthesiologists');
}

class ResidentsService extends BaseDatabaseService {
  ResidentsService() : super('residents');
}

class OpmeService extends BaseDatabaseService {
  OpmeService() : super('opme');
}

class BloodProductsService extends BaseDatabaseService {
  BloodProductsService() : super('blood_products');
}
