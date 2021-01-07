import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:loja_virtual/models/section_item.dart';
import 'dart:io';

import 'package:uuid/uuid.dart';

class Section extends ChangeNotifier {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;
  DocumentReference get firestoreRef => firestore.doc('home/$id');
  Reference get storageRef => storage.ref().child('home/$id');
  String id;
  String name;
  String type;
  List<SectionItem> items;
  List<SectionItem> originalItems;
  String _error;

  Section.fromDocument(DocumentSnapshot document) {
    id = document.id;
    name = document.data()['name'] as String;
    type = document.data()['type'] as String;
    items = (document.data()['items'] as List)
        .map((i) => SectionItem.fromMap(i as Map<String, dynamic>))
        .toList();
  }
  Section({this.id, this.name, this.type, this.items}) {
    items = items ?? [];
    originalItems = List.from(items);
  }
  void addItem(SectionItem item) {
    items.add(item);
    notifyListeners();
  }

  String get error => _error;
  set error(String value) {
    _error = value;
    notifyListeners();
  }

  void removeItem(SectionItem item) {
    items.remove(item);
    notifyListeners();
  }

  Future<void> delete() async {
    await firestoreRef.delete();
    for (final item in items) {
      if ((item.image as String).contains('firebase')) {
        try {
          final ref = storage.refFromURL(item.image as String);
          await ref.delete();
          // ignore: empty_catches
        } catch (e) {}
      }
    }
  }

  Future<void> save(int pos) async {
    final Map<String, dynamic> data = {
      'name': name,
      'type': type,
      'pos': pos,
    };

    if (id == null) {
      final doc = await firestore.collection('home').add(data);
      id = doc.id;
    } else {
      await firestoreRef.update(data);
    }
    for (final item in items) {
      if (item.image is File) {
        final UploadTask task =
            storageRef.child(Uuid().v1()).putFile(item.image as File);
        final TaskSnapshot snapshot = task.snapshot;
        final String url = await snapshot.ref.getDownloadURL();
        item.image = url;
      }
    }

    for (final original in originalItems) {
      if (!items.contains(original) &&
          (original.image as String).contains('firebase')) {
        try {
          final ref = storage.refFromURL(original.image as String);
          await ref.delete();
          // ignore: empty_catches
        } catch (e) {}
      }
    }

    final Map<String, dynamic> itemsData = {
      'items': items.map((e) => e.toMap()).toList()
    };

    await firestoreRef.update(itemsData);
  }

  bool valid() {
    if (name == null || name.isEmpty) {
      error = 'Título inválido';
    } else if (items.isEmpty) {
      error = 'Insira ao menos uma imagem';
    } else {
      error = null;
    }
    return error == null;
  }

  Section clone() {
    return Section(
      id: id,
      name: name,
      type: type,
      items: items.map((e) => e.clone()).toList(),
    );
  }
}
