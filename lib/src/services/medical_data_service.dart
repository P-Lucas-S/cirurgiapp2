import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MedicalDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> showSingleSelectionDialog({
    required BuildContext context,
    required String collection,
  }) async {
    String? selectedId;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          switch (collection) {
            'procedures' => 'Selecione um Procedimento',
            'surgeons' => 'Selecione um Cirurgião',
            'anesthesiologists' => 'Selecione um Anestesista',
            'blood_products' => 'Selecione um Produto Sanguíneo',
            _ => 'Selecione um Item',
          },
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection(collection).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();

              final items = snapshot.data!.docs;

              return ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final doc = items[index];
                  return ListTile(
                    title: Text(doc['name']),
                    onTap: () {
                      selectedId = doc.id;
                      Navigator.pop(context);
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );

    return selectedId;
  }

  Future<String> getItemName(DocumentReference docRef) async {
    final doc = await docRef.get();
    return doc['name'] ?? 'Nome não encontrado';
  }
}
