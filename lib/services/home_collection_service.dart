import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/home_collection.dart';

class HomeCollectionService {
  static const _collection = 'home_collections';
  FirebaseFirestore? _firestore;

  HomeCollectionService() {
    try {
      _firestore = FirebaseFirestore.instance;
    } catch (_) {
      _firestore = null;
    }
  }

  Stream<List<HomeCollection>> streamCollections() {
    final fs = _firestore;
    if (fs == null) return Stream.value(const []);
    return fs.collection(_collection).snapshots().handleError((e) {
      debugPrint('Home collection stream notice: $e');
    }).map((snap) {
      final list = snap.docs.map((d) => HomeCollection.fromMap(d.data(), d.id)).toList();
      list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return list;
    });
  }

  Future<void> saveCollection(HomeCollection c) async {
    await _firestore?.collection(_collection).doc(c.id).set(c.toMap());
  }

  Future<void> deleteCollection(String id) async {
    await _firestore?.collection(_collection).doc(id).delete();
  }
}
