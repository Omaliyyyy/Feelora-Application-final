import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../constants.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  DocumentReference? get _userRef =>
      _uid != null ? _db.collection('users').doc(_uid) : null;

  // ── Create doc on first signup ────────────────────────────────────────────
  Future<void> createUserDoc(String email) async {
    if (_uid == null) return;
    await _userRef!.set({
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
      'currentDay': 1,
      'days': {},
    });
    debugPrint('[Firestore] createUserDoc: done for $_uid');
  }

  // ── Real-time stream ──────────────────────────────────────────────────────
  Stream<DocumentSnapshot> userStream() {
    if (_uid == null) return const Stream.empty();
    return _userRef!.snapshots();
  }

  // ── Set mood + initialize tasks for a day ─────────────────────────────────
  Future<void> setDayMood(int day, MoodData mood) async {
    if (_uid == null) return;
    final tasks = {for (var t in mood.tasks) t.title: false};
    await _userRef!.update({
      'days.$day.mood': mood.label,
      'days.$day.tasks': tasks,
      'days.$day.date': DateTime.now().toIso8601String().split('T')[0],
    });
    debugPrint('[Firestore] setDayMood: day=$day mood=${mood.label}');
  }

  // ── Toggle individual task ────────────────────────────────────────────────
  Future<void> toggleTask(int day, String taskTitle, bool done) async {
    if (_uid == null) return;
    await _userRef!.update({'days.$day.tasks.$taskTitle': done});
    debugPrint('[Firestore] toggleTask: day=$day "$taskTitle" → $done');
  }

  // ── Advance to next day (loops after 21) ──────────────────────────────────
  Future<void> advanceDay(int currentDay) async {
    if (_uid == null) return;
    final next = currentDay < 21 ? currentDay + 1 : 1;
    await _userRef!.update({'currentDay': next});
    debugPrint('[Firestore] advanceDay: $currentDay → $next');
  }
}
