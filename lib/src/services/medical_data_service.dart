import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Extensão para adicionar o método [capitalize] à classe [String]
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}

class MedicalDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<String>> showSelectionDialog({
    required BuildContext context,
    required String collection,
  }) async {
    List<String> selectedItems = [];
    TextEditingController searchController = TextEditingController();

    return await showDialog<List<String>>(
          context: context,
          builder: (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text('Selecionar ${collection.capitalize()}'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    children: [
                      TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Buscar ou adicionar',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () async {
                              if (searchController.text.isNotEmpty) {
                                await _addNewItem(
                                    collection, searchController.text);
                                searchController.clear();
                              }
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: _firestore
                              .collection(collection)
                              .orderBy('name')
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            final items = snapshot.data!.docs
                                .map((doc) => doc['name'] as String)
                                .toList();
                            return ListView.builder(
                              itemCount: items.length,
                              itemBuilder: (context, index) => CheckboxListTile(
                                title: Text(items[index]),
                                value: selectedItems.contains(items[index]),
                                onChanged: (value) => setState(() {
                                  if (value!) {
                                    selectedItems.add(items[index]);
                                  } else {
                                    selectedItems.remove(items[index]);
                                  }
                                }),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, selectedItems),
                    child: const Text('Confirmar'),
                  ),
                ],
              );
            },
          ),
        ) ??
        [];
  }

  Future<void> _addNewItem(String collection, String name) async {
    final exists = await _firestore
        .collection(collection)
        .where('name', isEqualTo: name)
        .get()
        .then((snapshot) => snapshot.docs.isNotEmpty);

    if (!exists) {
      await _firestore.collection(collection).add({
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
