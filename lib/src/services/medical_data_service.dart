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

  Future<List<String>?> showMultiSelectionDialog({
    required BuildContext context,
    required String collection,
  }) async {
    List<String> selectedIds = [];
    // final List<String> initialSelection = [];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Selecione os ${_getCollectionName(collection)}'),
          content: SizedBox(
            width: double.maxFinite,
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection(collection).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();

                return Column(
                  children: [
                    _buildSearchField(),
                    Expanded(
                      child: _buildCheckboxList(
                        snapshot.data!.docs,
                        selectedIds,
                        setState,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, selectedIds),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );

    return selectedIds;
  }

  String _getCollectionName(String collection) {
    return switch (collection) {
      'opme' => 'OPMes',
      'blood_products' => 'Produtos Sanguíneos',
      _ => 'Itens',
    };
  }

  Widget _buildCheckboxList(
    List<QueryDocumentSnapshot> docs,
    List<String> selectedIds,
    StateSetter setState,
  ) {
    return ListView.builder(
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        return CheckboxListTile(
          title: Text(doc['name']),
          value: selectedIds.contains(doc.id),
          onChanged: (value) {
            setState(() {
              if (value!) {
                selectedIds.add(doc.id);
              } else {
                selectedIds.remove(doc.id);
              }
            });
          },
        );
      },
    );
  }

  Widget _buildSearchField() {
    // Exemplo de campo de busca. Pode ser aprimorado conforme necessidade.
    return TextField(
      decoration: const InputDecoration(
        labelText: 'Buscar',
        prefixIcon: Icon(Icons.search),
      ),
      onChanged: (value) {
        // Implementar funcionalidade de busca se necessário.
      },
    );
  }

  Future<String> getItemName(DocumentReference docRef) async {
    final doc = await docRef.get();
    return doc['name'] ?? 'Nome não encontrado';
  }
}
