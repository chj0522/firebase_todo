import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';

import 'delete_page.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _todoController = TextEditingController();

  CollectionReference<Map<String, dynamic>> get _todos =>
      _firestore.collection('firetodo');

  CollectionReference<Map<String, dynamic>> get _deletedTodos =>
      _firestore.collection('deletefiretodo');

  @override
  void dispose() {
    _todoController.dispose();
    super.dispose();
  }

  String _today() => DateTime.now().toIso8601String().split('T').first;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Todo Lists'),
        actions: [
          IconButton(
            onPressed: () => Get.to(() => DeletePage()),
            icon: Icon(Icons.delete_outlined),
            tooltip: '삭제한 일정',
          ),
          IconButton(
            onPressed: _showDialog,
            icon: Icon(Icons.add),
            tooltip: '할 일 추가',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _todos.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('일정을 불러오지 못했습니다.\n${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final docs = (snapshot.data?.docs ?? [])
              .where((doc) => doc.data()['deletecheck'].toString() == '0')
              .toList();
          return docs.isEmpty
              ? Center(child: Text('등록된 일정이 없습니다.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    return Slidable(
                      key: ValueKey(doc.id),
                      endActionPane: ActionPane(
                        motion: const DrawerMotion(),
                        extentRatio: 0.25,
                        children: [
                          SlidableAction(
                            onPressed: (_) => deleteToDo(doc.id),
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            icon: Icons.delete,
                            label: '삭제',
                          ),
                        ],
                      ),
                      child: SizedBox(
                        height: 70,
                        child: Card(
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(15.0),
                                child: Icon(Icons.calendar_month_outlined),
                              ),
                              Text(data['todo']),
                              Text(' / '),
                              Text(data['dodate']),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
        },
      ),
    );
  }

  void _showDialog() {
    _todoController.clear();
    Get.defaultDialog(
      title: 'Todo List',
      middleText: '',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '추가할 내용',
            textAlign: TextAlign.start,
            style: TextStyle(fontSize: 16, color: Colors.black87),
          ),
          TextField(
            controller: _todoController,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(hintText: '할 일을 입력하세요'),
            onSubmitted: (_) => _addTodo(),
          ),
        ],
      ),
      actions: [TextButton(onPressed: _addTodo, child: Text('추가하기'))],
    );
  }

  Future<void> _addTodo() async {
    final todo = _todoController.text.trim();
    if (todo.isEmpty) {
      Get.back();
      Get.snackbar(
        '입력 필요',
        '할 일을 입력해 주세요.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
      return;
    }

    await _todos.add({'todo': todo, 'dodate': _today(), 'deletecheck': 0});
    Get.back();
  }

  Future<void> deleteToDo(String id) async {
    final todoDocument = await _todos.doc(id).get();
    final todoData = todoDocument.data();
    if (todoData == null) return;

    final deleteCheck = todoData['deletecheck'];
    final deleteCount = deleteCheck is num
        ? deleteCheck
        : num.tryParse(deleteCheck.toString()) ?? 0;
    todoData['deletecheck'] = deleteCount + 1;
    final batch = _firestore.batch();
    batch.set(_deletedTodos.doc(id), todoData);
    batch.delete(_todos.doc(id));
    await batch.commit();
  }
}
