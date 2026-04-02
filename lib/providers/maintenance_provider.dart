import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/maintenance_task.dart';
import '../services/firestore_service.dart';

class MaintenanceProvider extends ChangeNotifier {
  final FirestoreService _db = FirestoreService();
  final ImagePicker _picker = ImagePicker();

  String? _uid;
  List<MaintenanceTask> _tasks = [];
  List<MaintenanceTask> get tasks => _tasks;

  List<MaintenanceTask> get pendingTasks =>
      _tasks.where((t) => !t.completed).toList();

  List<MaintenanceTask> get completedTasks =>
      _tasks.where((t) => t.completed).toList();

  List<MaintenanceTask> get overdueTasks =>
      _tasks.where((t) => t.isOverdue).toList();

  List<MaintenanceTask> get dueTodayTasks =>
      _tasks.where((t) => t.isDueToday).toList();

  int get overdueCount => overdueTasks.length;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isUploading = false;
  bool get isUploading => _isUploading;

  StreamSubscription? _sub;

  void init(String uid) {
    if (_uid == uid) return;
    _uid = uid;
    _sub?.cancel();
    _sub = _db.streamMaintenanceTasks(uid).listen((list) {
      _tasks = list;
      notifyListeners();
    });
  }

  void clear() {
    _sub?.cancel();
    _uid = null;
    _tasks = [];
    notifyListeners();
  }

  Future<void> addTask(MaintenanceTask task) async {
    if (_uid == null) return;
    _isLoading = true;
    notifyListeners();
    await _db.addTask(_uid!, task);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateTask(MaintenanceTask task) async {
    if (_uid == null) return;
    await _db.updateTask(_uid!, task);
  }

  Future<void> deleteTask(String taskId) async {
    if (_uid == null) return;
    await _db.deleteTask(_uid!, taskId);
  }

  /// Mark a task as done. If recurring, creates the next occurrence automatically.
  Future<void> completeTask(MaintenanceTask task) async {
    if (_uid == null) return;
    await _db.completeTask(_uid!, task);
  }

  /// Pick a photo from camera or gallery and upload to Firebase Storage.
  Future<String?> takePhoto(String taskId, {ImageSource source = ImageSource.camera}) async {
    if (_uid == null) return null;
    final xFile = await _picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 80,
    );
    if (xFile == null) return null;

    _isUploading = true;
    notifyListeners();

    try {
      final file = File(xFile.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref = FirebaseStorage.instance
          .ref()
          .child('users/$_uid/maintenance/$taskId/$timestamp.jpg');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      // Save URL to Firestore
      await _db.addPhotoUrl(_uid!, taskId, url);

      _isUploading = false;
      notifyListeners();
      return url;
    } catch (e) {
      _isUploading = false;
      notifyListeners();
      debugPrint('Photo upload error: $e');
      return null;
    }
  }

  /// Seed default maintenance presets for a new user.
  Future<void> seedPresets() async {
    if (_uid == null) return;
    // Only seed if no tasks exist yet
    if (_tasks.isNotEmpty) return;
    _isLoading = true;
    notifyListeners();

    for (final preset in MaintenancePresets.all) {
      final task = MaintenanceTask(
        id: '',
        title: preset.title,
        description: preset.description,
        dueDate: DateTime.now().add(Duration(days: preset.daysFromNow)),
        recurrence: preset.recurrence,
        photoRequired: preset.photoRequired,
      );
      await _db.addTask(_uid!, task);
    }
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
