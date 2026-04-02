import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/maintenance_task.dart';

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

  // ─── Maintenance Tasks ───

  CollectionReference<Map<String, dynamic>> _tasksCol(String uid) =>
      _db.collection('users').doc(uid).collection('maintenance_tasks');

  Future<String> addTask(String uid, MaintenanceTask task) async {
    final doc = await _tasksCol(uid).add(task.toMap());
    return doc.id;
  }

  Future<void> updateTask(String uid, MaintenanceTask task) async {
    await _tasksCol(uid).doc(task.id).update(task.toMap());
  }

  Future<void> deleteTask(String uid, String taskId) async {
    await _tasksCol(uid).doc(taskId).delete();
  }

  Stream<List<MaintenanceTask>> streamMaintenanceTasks(String uid) {
    return _tasksCol(uid)
        .orderBy('dueDate')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => MaintenanceTask.fromMap(d.id, d.data()))
            .toList());
  }

  Future<void> completeTask(String uid, MaintenanceTask task) async {
    final now = DateTime.now();
    // Mark current as done
    await _tasksCol(uid).doc(task.id).update({
      'completed': true,
      'completedAt': Timestamp.fromDate(now),
    });

    // If recurring, create next occurrence
    if (task.recurrence != TaskRecurrence.none) {
      final nextDue = task.recurrence.nextDate(now);
      if (nextDue != null) {
        final next = MaintenanceTask(
          id: '',
          title: task.title,
          description: task.description,
          dueDate: nextDue,
          recurrence: task.recurrence,
          photoRequired: task.photoRequired,
        );
        await _tasksCol(uid).add(next.toMap());
      }
    }
  }

  Future<void> addPhotoUrl(String uid, String taskId, String url) async {
    await _tasksCol(uid).doc(taskId).update({
      'photoUrls': FieldValue.arrayUnion([url]),
    });
  }

  // ─── Favourite Wash Configs ───

  Future<void> saveFavouriteWash({
    required String uid,
    required String name,
    required Map<String, dynamic> config,
  }) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('favourite_washes')
        .add({
      'name': name,
      'config': config,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> streamFavouriteWashes(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('favourite_washes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
        );
  }

  Future<void> deleteFavouriteWash(String uid, String docId) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('favourite_washes')
        .doc(docId)
        .delete();
  }
}
