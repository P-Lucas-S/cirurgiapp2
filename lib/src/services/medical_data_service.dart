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

  /// Exibe um diálogo para seleção única de um item da coleção,
  /// permitindo buscar ou adicionar um novo item.
  Future<String?> showSingleSelectionDialog({
    required BuildContext context,
    required String collection,
  }) async {
    String? selectedId;
    TextEditingController searchController = TextEditingController();

    return await showDialog<String>(
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
                            final newId = await _addNewItem(
                              collection,
                              searchController.text,
                            );
                            if (newId != null) {
                              setState(() => selectedId = newId);
                            }
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
                        final items = snapshot.data!.docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>?;
                          return {
                            'id': doc.id,
                            'name': data?['name']?.toString() ??
                                'Nome não especificado',
                          };
                        }).toList();

                        return ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return RadioListTile<String>(
                              title: Text(item['name'] as String),
                              value: item['id'] as String,
                              groupValue: selectedId,
                              onChanged: (value) =>
                                  setState(() => selectedId = value),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, selectedId),
                child: const Text('Confirmar'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Adiciona um novo item na coleção e retorna o ID do documento criado.
  Future<String?> _addNewItem(String collection, String name) async {
    try {
      final docRef = await _firestore.collection(collection).add({
        'name': name.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      debugPrint('Erro ao adicionar item: $e');
      return null;
    }
  }

  /// Retorna o nome do item a partir do ID fornecido.
  Future<String> getItemName(String collection, String id) async {
    final doc = await _firestore.collection(collection).doc(id).get();

    if (!doc.exists) {
      return 'Item não encontrado';
    }

    final data = doc.data();
    return data?['name']?.toString() ?? 'Nome não especificado';
  }
}
