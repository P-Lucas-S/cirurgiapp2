import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MedicalDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> showSingleSelectionDialog({
    required BuildContext context,
    required String collection,
  }) async {
    String? selectedId;
    String searchQuery = '';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            switch (collection) {
              'procedures' => 'Selecione ou crie um Procedimento',
              'surgeons' => 'Selecione ou crie um Cirurgião',
              'anesthesiologists' => 'Selecione ou crie um Anestesista',
              'blood_products' => 'Selecione ou crie um Produto Sanguíneo',
              _ => 'Selecione ou crie um Item',
            },
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Buscar ou criar novo',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) => setState(() {
                    searchQuery = value.trim();
                  }),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection(collection).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      // Ordenar e filtrar
                      final sortedDocs = _sortAndFilterDocs(
                        snapshot.data!.docs,
                        searchQuery,
                      );

                      return Column(
                        children: [
                          // Botão de adicionar novo se não existir
                          if (searchQuery.isNotEmpty &&
                              !_existsInDocs(sortedDocs, searchQuery))
                            ListTile(
                              leading: const Icon(Icons.add_circle),
                              title: Text('Criar novo: "$searchQuery"'),
                              onTap: () async {
                                final newId = await _createNewItem(
                                  context,
                                  collection,
                                  searchQuery,
                                );
                                if (newId != null) {
                                  selectedId = newId;
                                  Navigator.pop(context);
                                }
                              },
                            ),
                          // Lista de resultados
                          Expanded(
                            child: ListView.builder(
                              itemCount: sortedDocs.length,
                              itemBuilder: (context, index) {
                                final doc = sortedDocs[index];
                                return ListTile(
                                  title: Text(doc['name']),
                                  onTap: () {
                                    selectedId = doc.id;
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
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
    String searchQuery = '';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Selecione os ${_getCollectionName(collection)}'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Buscar ou criar novo',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) => setState(() {
                    searchQuery = value.trim();
                  }),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection(collection).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      // Ordenar e filtrar
                      final sortedDocs = _sortAndFilterDocs(
                        snapshot.data!.docs,
                        searchQuery,
                      );

                      return Column(
                        children: [
                          // Opção para adicionar novo item
                          if (searchQuery.isNotEmpty &&
                              !_existsInDocs(sortedDocs, searchQuery))
                            ListTile(
                              leading: const Icon(Icons.add_circle),
                              title: Text('Adicionar novo: "$searchQuery"'),
                              onTap: () async {
                                final newId = await _createNewItem(
                                  context,
                                  collection,
                                  searchQuery,
                                );
                                if (newId != null) {
                                  setState(() {
                                    selectedIds.add(newId);
                                  });
                                }
                              },
                            ),
                          // Lista de itens existentes
                          Expanded(
                            child: ListView.builder(
                              itemCount: sortedDocs.length,
                              itemBuilder: (context, index) {
                                final doc = sortedDocs[index];
                                return CheckboxListTile(
                                  title: Text(doc['name']),
                                  value: selectedIds.contains(doc.id),
                                  onChanged: (value) => setState(() {
                                    if (value!) {
                                      selectedIds.add(doc.id);
                                    } else {
                                      selectedIds.remove(doc.id);
                                    }
                                  }),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
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

  // Métodos auxiliares
  List<QueryDocumentSnapshot<Object?>> _sortAndFilterDocs(
    List<QueryDocumentSnapshot> docs,
    String searchQuery,
  ) {
    final filtered = docs.where((doc) {
      final name = doc['name'].toString().toLowerCase();
      return name.contains(searchQuery.toLowerCase());
    }).toList();

    filtered.sort((a, b) => a['name']
        .toString()
        .toLowerCase()
        .compareTo(b['name'].toString().toLowerCase()));

    return filtered;
  }

  bool _existsInDocs(List<QueryDocumentSnapshot> docs, String searchQuery) {
    return docs.any((doc) =>
        doc['name'].toString().toLowerCase() == searchQuery.toLowerCase());
  }

  Future<String?> _createNewItem(
    BuildContext context,
    String collection,
    String name,
  ) async {
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite um nome válido')),
      );
      return null;
    }

    try {
      final docRef = await _firestore.collection(collection).add({
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"$name" adicionado com sucesso!')),
      );

      return docRef.id;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao criar item')),
      );
      return null;
    }
  }

  String _getCollectionName(String collection) {
    return switch (collection) {
      'opme' => 'OPMes',
      'blood_products' => 'Produtos Sanguíneos',
      _ => 'Itens',
    };
  }

  Future<String> getItemName(DocumentReference docRef) async {
    final doc = await docRef.get();
    return doc['name'] ?? 'Nome não encontrado';
  }
}
