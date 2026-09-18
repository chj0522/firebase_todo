import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DeletePage extends StatelessWidget {
  const DeletePage({super.key});

  CollectionReference<Map<String, dynamic>> get _todos =>
      FirebaseFirestore.instance.collection('firetodo');

  CollectionReference<Map<String, dynamic>> get _deletedTodos =>
      FirebaseFirestore.instance.collection('deletefiretodo');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Delete Lists')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _deletedTodos.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('삭제한 일정을 불러오지 못했습니다.\n${snapshot.error}'),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          return docs.isEmpty
              ? Center(child: Text('삭제한 일정이 없습니다.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_month_outlined),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(data['todo'] as String? ?? ''),
                            ),
                            Text(' / '),
                            Text(data['dodate'] as String? ?? ''),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'restore') {
                                  restoreTodo(context, doc.id);
                                } else {
                                  deleteForever(context, doc.id);
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'restore',
                                  child: Text('복원'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('영구 삭제'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
        },
      ),
    );
  }

  Future<void> restoreTodo(BuildContext context, String id) async {
    final deletedDocument = await _deletedTodos.doc(id).get();
    final todoData = deletedDocument.data();
    if (todoData == null) return;

    final deleteCheck = todoData['deletecheck'];
    final deleteCount = deleteCheck is num
        ? deleteCheck
        : num.tryParse(deleteCheck.toString()) ?? 0;
    todoData['deletecheck'] = deleteCount - 1;
    final batch = FirebaseFirestore.instance.batch();
    batch.set(_todos.doc(id), todoData);
    batch.delete(_deletedTodos.doc(id));
    await batch.commit();
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('일정을 복원했습니다.')));
    }
  }

  Future<void> deleteForever(BuildContext context, String id) async {
    await _deletedTodos.doc(id).delete();
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('일정을 영구 삭제했습니다.')));
    }
  }
}
