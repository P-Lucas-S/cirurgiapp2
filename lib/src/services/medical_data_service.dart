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
                      final sortedDocs = _sortAndFilterDocs(
                        snapshot.data!.docs,
                        searchQuery,
                      );

                      return Column(
                        children: [
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
                      final sortedDocs = _sortAndFilterDocs(
                        snapshot.data!.docs,
                        searchQuery,
                      );

                      return Column(
                        children: [
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

  /// Método para seleção de produtos sanguíneos com quantidade
  Future<Map<String, int>?> showBloodProductSelectionDialog(
      BuildContext context) async {
    Map<String, int> selectedProducts = {};
    String searchQuery = '';

    return await showDialog<Map<String, int>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Selecionar Produtos Sanguíneos'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Buscar produto',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) =>
                        setState(() => searchQuery = value.trim()),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream:
                          _firestore.collection('blood_products').snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        final docs =
                            _filterDocs(snapshot.data!.docs, searchQuery);
                        return ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            final productId = doc.id;
                            final productName = doc['name'] as String;
                            final currentQty = selectedProducts[productId] ?? 0;
                            return ListTile(
                              title: Text(productName),
                              trailing: SizedBox(
                                width: 100,
                                child: TextFormField(
                                  initialValue: currentQty > 0
                                      ? currentQty.toString()
                                      : '',
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Qtd',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (value) {
                                    final qty = int.tryParse(value) ?? 0;
                                    setState(() {
                                      if (qty > 0) {
                                        selectedProducts[productId] = qty;
                                      } else {
                                        selectedProducts.remove(productId);
                                      }
                                    });
                                  },
                                ),
                              ),
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
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, selectedProducts),
                child: const Text('Confirmar'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Novo método para seleção de materiais OPME com quantidade e especificação
  Future<List<Map<String, dynamic>>?> showOpmeSelectionDialog(
      BuildContext context) async {
    List<Map<String, dynamic>> selectedMaterials = [];
    String searchQuery = '';

    return await showDialog<List<Map<String, dynamic>>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Selecionar Materiais OPME'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Buscar material',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) =>
                        setState(() => searchQuery = value.trim()),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _firestore.collection('opme').snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        final docs =
                            _filterDocs(snapshot.data!.docs, searchQuery);
                        return ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            return ListTile(
                              title: Text(doc['name']),
                              trailing: IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () async {
                                  final result =
                                      await showDialog<Map<String, dynamic>>(
                                    context: context,
                                    builder: (ctx) =>
                                        _OpmeQuantityDialog(doc: doc),
                                  );
                                  if (result != null) {
                                    setState(() {
                                      selectedMaterials.add(result);
                                    });
                                  }
                                },
                              ),
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
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, selectedMaterials),
                child: const Text('Confirmar'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Métodos auxiliares

  List<QueryDocumentSnapshot<Object?>> _sortAndFilterDocs(
      List<QueryDocumentSnapshot> docs, String searchQuery) {
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

  List<QueryDocumentSnapshot<Object?>> _filterDocs(
      List<QueryDocumentSnapshot> docs, String searchQuery) {
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

/// Widget para especificar a quantidade e a especificação do material OPME selecionado
class _OpmeQuantityDialog extends StatefulWidget {
  final QueryDocumentSnapshot doc;

  const _OpmeQuantityDialog({required this.doc});

  @override
  State<_OpmeQuantityDialog> createState() => _OpmeQuantityDialogState();
}

class _OpmeQuantityDialogState extends State<_OpmeQuantityDialog> {
  final _quantityController = TextEditingController();
  final _specificationController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Especificar ${widget.doc['name']}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _quantityController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Quantidade',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _specificationController,
            decoration: const InputDecoration(
              labelText: 'Especificação (opcional)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_quantityController.text.isEmpty) return;
            Navigator.pop(context, {
              'materialId': widget.doc.id,
              'quantity': int.parse(_quantityController.text),
              'specification': _specificationController.text,
            });
          },
          child: const Text('Adicionar'),
        ),
      ],
    );
  }
}
