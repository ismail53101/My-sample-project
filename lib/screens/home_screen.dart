import 'dart:math';
import 'package:flutter/material.dart';
import '../models/task.dart';
import '../widgets/task_tile.dart';

enum TaskFilter { all, active, completed }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final List<Task> _tasks = [];
  final TextEditingController _controller = TextEditingController();
  TaskPriority _selectedPriority = TaskPriority.medium;
  TaskFilter _currentFilter = TaskFilter.all;
  bool _showCelebration = false;
  late AnimationController _celebrationController;

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _celebrationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _showCelebration = false);
        _celebrationController.reset();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  void _addTask() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _tasks.add(Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: text,
        priority: _selectedPriority,
      ));
    });
    _controller.clear();
    _checkCelebration();
  }

  void _toggleTask(Task task, bool? value) {
    setState(() {
      task.isCompleted = value ?? false;
    });
    _checkCelebration();
  }

  void _deleteTask(Task task) {
    setState(() {
      _tasks.remove(task);
    });
  }

  void _editTask(Task task) {
    final editController = TextEditingController(text: task.title);
    TaskPriority editPriority = task.priority;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Task'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: editController,
                    decoration: InputDecoration(
                      hintText: 'Task title',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<TaskPriority>(
                    segments: TaskPriority.values.map((p) {
                      return ButtonSegment(
                        value: p,
                        label: Text(p.label),
                        icon: Icon(
                          p.level == 0
                              ? Icons.arrow_downward
                              : p.level == 1
                                  ? Icons.remove
                                  : Icons.arrow_upward,
                          size: 16,
                        ),
                      );
                    }).toList(),
                    selected: {editPriority},
                    onSelectionChanged: (Set<TaskPriority> newSelection) {
                      setDialogState(() {
                        editPriority = newSelection.first;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final newText = editController.text.trim();
                    if (newText.isNotEmpty) {
                      setState(() {
                        // Create a new task to replace the old one since fields are final
                        final index = _tasks.indexOf(task);
                        if (index != -1) {
                          _tasks[index] = Task(
                            id: task.id,
                            title: newText,
                            isCompleted: task.isCompleted,
                            priority: editPriority,
                            createdAt: task.createdAt,
                          );
                        }
                      });
                    }
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _checkCelebration() {
    if (_tasks.isNotEmpty && _tasks.every((t) => t.isCompleted)) {
      setState(() => _showCelebration = true);
      _celebrationController.forward();
    }
  }

  double get _completionRatio {
    if (_tasks.isEmpty) return 0.0;
    return _tasks.where((t) => t.isCompleted).length / _tasks.length;
  }

  List<Task> get _filteredTasks {
    switch (_currentFilter) {
      case TaskFilter.active:
        return _tasks.where((t) => !t.isCompleted).toList();
      case TaskFilter.completed:
        return _tasks.where((t) => t.isCompleted).toList();
      case TaskFilter.all:
        return _tasks;
    }
  }

  Color _priorityColor(TaskPriority p) {
    switch (p.level) {
      case 0:
        return Colors.green;
      case 1:
        return Colors.orange;
      case 2:
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTasks;
    final ratio = _completionRatio;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TaskFlow'),
        centerTitle: true,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 4,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              ratio == 1.0 ? Colors.green : Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: 'Enter a task...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        onSubmitted: (_) => _addTask(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<TaskPriority>(
                      initialValue: _selectedPriority,
                      onSelected: (TaskPriority p) {
                        setState(() => _selectedPriority = p);
                      },
                      itemBuilder: (context) => TaskPriority.values.map((p) {
                        return PopupMenuItem<TaskPriority>(
                          value: p,
                          child: Row(
                            children: [
                              Icon(
                                p.level == 0
                                    ? Icons.arrow_downward
                                    : p.level == 1
                                        ? Icons.remove
                                        : Icons.arrow_upward,
                                size: 18,
                                color: _priorityColor(p),
                              ),
                              const SizedBox(width: 8),
                              Text(p.label),
                            ],
                          ),
                        );
                      }).toList(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: _priorityColor(_selectedPriority)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _selectedPriority.level == 0
                                  ? Icons.arrow_downward
                                  : _selectedPriority.level == 1
                                      ? Icons.remove
                                      : Icons.arrow_upward,
                              size: 18,
                              color: _priorityColor(_selectedPriority),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _selectedPriority.label,
                              style: TextStyle(color: _priorityColor(_selectedPriority)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _addTask,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Add'),
                    ),
                  ],
                ),
              ),
              if (_tasks.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: _currentFilter == TaskFilter.all,
                        onSelected: (_) => setState(() => _currentFilter = TaskFilter.all),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: Text('Active (${_tasks.where((t) => !t.isCompleted).length})'),
                        selected: _currentFilter == TaskFilter.active,
                        onSelected: (_) => setState(() => _currentFilter = TaskFilter.active),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: Text('Done (${_tasks.where((t) => t.isCompleted).length})'),
                        selected: _currentFilter == TaskFilter.completed,
                        onSelected: (_) => setState(() => _currentFilter = TaskFilter.completed),
                      ),
                    ],
                  ),
                ),
              if (_tasks.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        '${(ratio * 100).toInt()}% complete',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _tasks.isEmpty ? Icons.task_alt : Icons.filter_list_off,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _tasks.isEmpty
                                  ? 'No tasks yet.\nAdd one above to get started!'
                                  : 'No tasks match this filter.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final task = filtered[index];
                          return TaskTile(
                            task: task,
                            onToggle: (value) => _toggleTask(task, value),
                            onDelete: () => _deleteTask(task),
                            onEdit: () => _editTask(task),
                          );
                        },
                      ),
              ),
            ],
          ),
          if (_showCelebration)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _celebrationController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _CelebrationPainter(_celebrationController.value),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CelebrationPainter extends CustomPainter {
  final double progress;
  final Random random = Random(42);

  _CelebrationPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final colors = [
      Colors.red, Colors.blue, Colors.green, Colors.yellow,
      Colors.purple, Colors.orange, Colors.pink, Colors.teal,
    ];

    for (int i = 0; i < 60; i++) {
      final x = random.nextDouble() * size.width;
      final startY = -20.0;
      final endY = size.height + 20;
      final y = startY + (endY - startY) * progress + random.nextDouble() * 100;
      final radius = 3.0 + random.nextDouble() * 5.0;
      final opacity = max(0.0, 1.0 - progress * 1.2);
      final color = colors[i % colors.length].withOpacity(opacity);

      final paint = Paint()..color = color;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CelebrationPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
