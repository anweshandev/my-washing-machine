import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── User Document ───

  Future<void> ensureUserDocument(
    String uid,
    String? email,
    String? displayName,
  ) async {
    final doc = _db.collection('users').doc(uid);
    final snap = await doc.get();
    if (!snap.exists) {
      await doc.set({
        'email': email ?? '',
        'displayName': displayName ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // ─── Device Management ───

  Future<void> saveDevice({
    required String uid,
    required String mac,
    required String name,
    String? model,
  }) async {
    await _db.collection('users').doc(uid).collection('devices').doc(mac).set({
      'mac': mac,
      'name': name,
      'model': model,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<Map<String, dynamic>>> streamUserDevices(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('devices')
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
        );
  }

  Future<void> removeDevice(String uid, String mac) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('devices')
        .doc(mac)
        .delete();
  }

  // ─── Wash History ───

  Future<void> saveWashRecord({
    required String uid,
    required String programName,
    required int programId,
    required int temperature,
    required int spinSpeed,
    required Map<String, dynamic> options,
    required int durationMinutes,
    String? deviceName,
    String? deviceMac,
  }) async {
    await _db.collection('users').doc(uid).collection('wash_history').add({
      'programName': programName,
      'programId': programId,
      'temperature': temperature,
      'spinSpeed': spinSpeed,
      'options': options,
      'durationMinutes': durationMinutes,
      'deviceName': deviceName,
      'deviceMac': deviceMac,
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> streamWashHistory(
    String uid, {
    int limit = 50,
  }) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('wash_history')
        .orderBy('completedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
        );
  }
}
