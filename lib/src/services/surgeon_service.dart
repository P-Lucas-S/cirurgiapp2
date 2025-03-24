import 'package:cloud_firestore/cloud_firestore.dart';

class SurgeonService {
  final CollectionReference _surgeons =
      FirebaseFirestore.instance.collection('surgeons');

  Future<List<String>> getSurgeons() async {
    final snapshot = await _surgeons.get();
    return snapshot.docs.map((doc) => doc['name'] as String).toList();
  }

  Future<void> addSurgeon(String name) async {
    if (name.isEmpty) return;
    await _surgeons
        .add({'name': name, 'createdAt': FieldValue.serverTimestamp()});
  }
}
