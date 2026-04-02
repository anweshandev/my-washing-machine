import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../models/maintenance_task.dart';
import '../providers/maintenance_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final mp = context.watch<MaintenanceProvider>();
    final cs = Theme.of(context).colorScheme;

    if (!auth.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Maintenance')),
        body: Center(
          child: Text(
            'Sign in to manage reminders',
            style: TextStyle(color: AppTheme.subtextColor(context)),
          ),
        ),
      );
    }

    final pending = mp.pendingTasks;
    final completed = mp.completedTasks;
    final overdue = mp.overdueTasks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance'),
        actions: [
          if (mp.tasks.isEmpty)
            TextButton.icon(
              onPressed: () => mp.seedPresets(),
              icon: const Icon(Icons.add_task, size: 18),
              label: const Text('Add Presets'),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Upcoming'),
                  if (overdue.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: cs.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${overdue.length}',
                        style: TextStyle(
                          color: cs.onError,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(text: 'Done (${completed.length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskSheet(context),
        child: const Icon(Icons.add),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Upcoming
          pending.isEmpty
              ? _EmptyTab(
                  icon: Icons.check_circle_outline,
                  message: 'No upcoming tasks',
                  subtitle: mp.tasks.isEmpty
                      ? 'Tap "Add Presets" to get started with recommended tasks'
                      : 'All caught up!',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: pending.length,
                  itemBuilder: (context, i) => _TaskCard(task: pending[i]),
                ),
          // Completed
          completed.isEmpty
              ? const _EmptyTab(
                  icon: Icons.history,
                  message: 'No completed tasks yet',
                  subtitle: 'Tasks you finish will show here',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: completed.length,
                  itemBuilder: (context, i) =>
                      _CompletedTaskTile(task: completed[i]),
                ),
        ],
      ),
    );
  }

  void _showAddTaskSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<MaintenanceProvider>(),
        child: const _AddTaskSheet(),
      ),
    );
  }
}

// ─── Empty Tab ───
class _EmptyTab extends StatelessWidget {
  final IconData icon;
  final String message;
  final String subtitle;
  const _EmptyTab({
    required this.icon,
    required this.message,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: cs.primary.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.subtextColor(context)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Task Card (pending) ───
class _TaskCard extends StatelessWidget {
  final MaintenanceTask task;
  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isOverdue = task.isOverdue;
    final isDueToday = task.isDueToday;
    final dueDateStr = DateFormat('d MMM yyyy').format(task.dueDate);
    final daysLeft = task.daysUntilDue;

    Color statusColor;
    String statusText;
    if (isOverdue) {
      statusColor = cs.error;
      statusText = '${-daysLeft} day${-daysLeft == 1 ? '' : 's'} overdue';
    } else if (isDueToday) {
      statusColor = Colors.orange;
      statusText = 'Due today';
    } else if (daysLeft <= 3) {
      statusColor = Colors.orange;
      statusText = 'In $daysLeft day${daysLeft == 1 ? '' : 's'}';
    } else {
      statusColor = AppTheme.subtextColor(context);
      statusText = 'Due $dueDateStr';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: isOverdue
            ? BorderSide(color: cs.error.withValues(alpha: 0.4))
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showTaskDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isOverdue
                        ? Icons.warning_amber_rounded
                        : Icons.build_circle_outlined,
                    size: 22,
                    color: isOverdue ? cs.error : cs.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  if (task.recurrence != TaskRecurrence.none)
                    Tooltip(
                      message: task.recurrence.label,
                      child: Icon(
                        Icons.repeat,
                        size: 16,
                        color: cs.primary.withValues(alpha: 0.6),
                      ),
                    ),
                ],
              ),
              if (task.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  task.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.subtextColor(context),
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.schedule, size: 14, color: statusColor),
                  const SizedBox(width: 4),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                  const Spacer(),
                  if (task.photoRequired)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.camera_alt_outlined,
                        size: 16,
                        color: cs.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  _ActionChip(
                    label: 'Done',
                    icon: Icons.check,
                    onTap: () => _markDone(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _markDone(BuildContext context) {
    final mp = context.read<MaintenanceProvider>();
    if (task.photoRequired) {
      _showPhotoCaptureDialog(context, mp);
    } else {
      mp.completeTask(task);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            task.recurrence != TaskRecurrence.none
                ? '${task.title} done! Next reminder scheduled.'
                : '${task.title} done!',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showPhotoCaptureDialog(BuildContext context, MaintenanceProvider mp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Attach a photo?'),
        content: Text(
          'This task suggests taking a photo for your records. '
          'You can take a photo now or skip.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              mp.completeTask(task);
            },
            child: const Text('Skip'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              mp.takePhoto(task.id, source: ImageSource.gallery);
              mp.completeTask(task);
            },
            child: const Text('Gallery'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              mp.takePhoto(task.id, source: ImageSource.camera);
              mp.completeTask(task);
            },
            icon: const Icon(Icons.camera_alt, size: 18),
            label: const Text('Camera'),
          ),
        ],
      ),
    );
  }

  void _showTaskDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<MaintenanceProvider>(),
        child: _TaskDetailSheet(task: task),
      ),
    );
  }
}

// ─── Small Action Chip ───
class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: cs.primary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Completed Task Tile ───
class _CompletedTaskTile extends StatelessWidget {
  final MaintenanceTask task;
  const _CompletedTaskTile({required this.task});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final completedStr = task.completedAt != null
        ? DateFormat('d MMM yyyy').format(task.completedAt!)
        : 'Unknown';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          Icons.check_circle,
          color: Colors.green.withValues(alpha: 0.7),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            color: cs.onSurface.withValues(alpha: 0.6),
            decoration: TextDecoration.lineThrough,
          ),
        ),
        subtitle: Text(
          'Done on $completedStr',
          style: TextStyle(fontSize: 12, color: AppTheme.subtextColor(context)),
        ),
        trailing: task.photoUrls.isNotEmpty
            ? Icon(
                Icons.photo_library,
                size: 18,
                color: cs.primary.withValues(alpha: 0.5),
              )
            : null,
        onTap: task.photoUrls.isNotEmpty ? () => _showPhotos(context) : null,
      ),
    );
  }

  void _showPhotos(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Photos - ${task.title}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: task.photoUrls.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  task.photoUrls[i],
                  width: 250,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : const Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// ─── Task Detail Bottom Sheet ───
class _TaskDetailSheet extends StatelessWidget {
  final MaintenanceTask task;
  const _TaskDetailSheet({required this.task});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mp = context.watch<MaintenanceProvider>();

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            task.title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: 16,
                color: AppTheme.subtextColor(context),
              ),
              const SizedBox(width: 4),
              Text(
                'Due ${DateFormat('d MMMM yyyy').format(task.dueDate)}',
                style: TextStyle(
                  color: task.isOverdue
                      ? cs.error
                      : AppTheme.subtextColor(context),
                  fontWeight: task.isOverdue
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
          if (task.recurrence != TaskRecurrence.none) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.repeat,
                  size: 16,
                  color: AppTheme.subtextColor(context),
                ),
                const SizedBox(width: 4),
                Text(
                  'Repeats ${task.recurrence.label.toLowerCase()}',
                  style: TextStyle(color: AppTheme.subtextColor(context)),
                ),
              ],
            ),
          ],
          if (task.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              task.description,
              style: TextStyle(color: cs.onSurface, height: 1.5),
            ),
          ],
          // Photos section
          if (task.photoUrls.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Photos',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: task.photoUrls.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      task.photoUrls[i],
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    mp.takePhoto(task.id, source: ImageSource.camera);
                  },
                  icon: mp.isUploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.camera_alt, size: 18),
                  label: Text(mp.isUploading ? 'Uploading...' : 'Take Photo'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    mp.completeTask(task);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          task.recurrence != TaskRecurrence.none
                              ? '${task.title} done! Next reminder scheduled.'
                              : '${task.title} done!',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Mark Done'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                _confirmDelete(context, mp);
              },
              child: Text(
                'Delete Task',
                style: TextStyle(color: cs.error, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, MaintenanceProvider mp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('Delete "${task.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              mp.deleteTask(task.id);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ─── Add Task Bottom Sheet ───
class _AddTaskSheet extends StatefulWidget {
  const _AddTaskSheet();

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  TaskRecurrence _recurrence = TaskRecurrence.none;
  bool _photoRequired = false;
  bool _showPresets = true;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'New Maintenance Task',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 16),

          // Quick presets
          if (_showPresets) ...[
            Text(
              'Quick Add',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.subtextColor(context),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: MaintenancePresets.all.map((p) {
                return ActionChip(
                  label: Text(p.title, style: const TextStyle(fontSize: 12)),
                  avatar: Icon(Icons.add, size: 16, color: cs.primary),
                  onPressed: () {
                    setState(() {
                      _titleController.text = p.title;
                      _descController.text = p.description;
                      _recurrence = p.recurrence;
                      _dueDate = DateTime.now().add(
                        Duration(days: p.daysFromNow),
                      );
                      _photoRequired = p.photoRequired;
                      _showPresets = false;
                    });
                  },
                );
              }).toList(),
            ),
            const Divider(height: 32),
            Text(
              'Or create custom',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.subtextColor(context),
              ),
            ),
            const SizedBox(height: 8),
          ],

          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Task name',
              hintText: 'e.g. Clean lint filter',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            maxLines: 3,
            minLines: 1,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Due date
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today),
            title: const Text('Due date'),
            subtitle: Text(
              DateFormat('d MMMM yyyy').format(_dueDate),
              style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600),
            ),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _dueDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 730)),
              );
              if (picked != null) {
                setState(() => _dueDate = picked);
              }
            },
          ),

          // Recurrence
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.repeat),
            title: const Text('Repeat'),
            subtitle: Text(
              _recurrence.label,
              style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600),
            ),
            onTap: () async {
              final result = await showDialog<TaskRecurrence>(
                context: context,
                builder: (ctx) => SimpleDialog(
                  title: const Text('Repeat interval'),
                  children: TaskRecurrence.values.map((r) {
                    return SimpleDialogOption(
                      onPressed: () => Navigator.pop(ctx, r),
                      child: Text(r.label),
                    );
                  }).toList(),
                ),
              );
              if (result != null) {
                setState(() => _recurrence = result);
              }
            },
          ),

          // Photo toggle
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Require photo on completion'),
            subtitle: const Text('Prompt to take a photo when marking done'),
            value: _photoRequired,
            onChanged: (v) => setState(() => _photoRequired = v),
          ),

          const SizedBox(height: 24),
          FilledButton(
            onPressed: _titleController.text.trim().isEmpty ? null : _save,
            child: const Text('Add Task'),
          ),
        ],
      ),
    );
  }

  void _save() {
    final mp = context.read<MaintenanceProvider>();
    final task = MaintenanceTask(
      id: '',
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      dueDate: _dueDate,
      recurrence: _recurrence,
      photoRequired: _photoRequired,
    );
    mp.addTask(task);
    Navigator.pop(context);
  }
}
