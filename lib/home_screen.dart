import 'notes_screen.dart';
import 'calendar_screen.dart';
import 'profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'travel_screen.dart';

class Task {
  String? id;
  String title;
  String tag;
  bool done;
  String? userId;
  DateTime? createdAt;

  Task({
    this.id,
    required this.title,
    required this.tag,
    this.done = false,
    this.userId,
    this.createdAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      tag: json['priority'] ?? 'Medium',
      done: json['done'] ?? false,
      userId: json['user_id'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'priority': tag,
      'done': done,
    };
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  List<Task> _tasks = [];
  bool _isLoading = true;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _loadUserProfile();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final response = await Supabase.instance.client
          .from('tasks')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      setState(() {
        _tasks = (response as List).map((json) => Task.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (error) {
      setState(() => _isLoading = false);
      _showError('Failed to load tasks: $error');
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final response = await Supabase.instance.client
          .from('profiles')
          .select('full_name')
          .eq('id', user.id)
          .single();
      setState(() {
        _userName = response['full_name'] ?? 'User';
      });
    } catch (error) {
      // Use default name
    }
  }

  Future<void> _addTask(String title, String priority) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final newTask = {
        'user_id': user.id,
        'title': title,
        'priority': priority,
        'done': false,
      };
      final response = await Supabase.instance.client
          .from('tasks')
          .insert(newTask)
          .select()
          .single();
      setState(() {
        _tasks.insert(0, Task.fromJson(response));
      });
    } catch (error) {
      _showError('Failed to add task: $error');
    }
  }

  Future<void> _toggleTask(Task task) async {
    try {
      final newDone = !task.done;
      final newTag = newDone ? 'Done' : (task.tag == 'Done' ? 'High' : task.tag);
      await Supabase.instance.client
          .from('tasks')
          .update({'done': newDone, 'priority': newTag})
          .eq('id', task.id!);
      setState(() {
        task.done = newDone;
        task.tag = newTag;
      });
    } catch (error) {
      _showError('Failed to update task: $error');
    }
  }

  Future<void> _deleteTask(Task task) async {
    try {
      await Supabase.instance.client
          .from('tasks')
          .delete()
          .eq('id', task.id!);
      setState(() {
        _tasks.remove(task);
      });
    } catch (error) {
      _showError('Failed to delete task: $error');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF4FB),
      body: _getScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF00BCD4),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        iconSize: 22,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task_outlined),
            activeIcon: Icon(Icons.task),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flight_outlined),
            activeIcon: Icon(Icons.flight),
            label: 'Travel',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mic_outlined),
            activeIcon: Icon(Icons.mic),
            label: 'Notes',
          ),
        ],
      ),
    );
  }

  Widget _getScreen() {
    switch (_currentIndex) {
      case 0:
        return HomeTab(
          tasks: _tasks,
          userName: _userName,
          isLoading: _isLoading,
          onToggleTask: _toggleTask,
          onDeleteTask: _deleteTask,
          onAddTask: _addTask,
          onRefresh: _loadTasks,
        );
      case 1:
        return TasksTab(
          tasks: _tasks,
          isLoading: _isLoading,
          onToggleTask: _toggleTask,
          onDeleteTask: _deleteTask,
          onAddTask: _addTask,
          onRefresh: _loadTasks,
        );
      case 2:
        return const CalendarScreen();
      case 3:
        return const TravelTab();
      case 4:
        return const NotesTab();
      default:
        return HomeTab(
          tasks: _tasks,
          userName: _userName,
          isLoading: _isLoading,
          onToggleTask: _toggleTask,
          onDeleteTask: _deleteTask,
          onAddTask: _addTask,
          onRefresh: _loadTasks,
        );
    }
  }
}

// HOME TAB
class HomeTab extends StatelessWidget {
  final List<Task> tasks;
  final String? userName;
  final bool isLoading;
  final Function(Task) onToggleTask;
  final Function(Task) onDeleteTask;
  final Function(String, String) onAddTask;
  final VoidCallback onRefresh;

  const HomeTab({
    super.key,
    required this.tasks,
    this.userName,
    required this.isLoading,
    required this.onToggleTask,
    required this.onDeleteTask,
    required this.onAddTask,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final pendingTasks = tasks.where((t) => !t.done).length;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Text(
                        'Good Morning! ',
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                      Icon(Icons.waving_hand,
                          size: 16, color: Colors.amber.shade600),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          userName ?? 'User',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00BCD4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // AI Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00BCD4), Color(0xFF0097A7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'AI Summary',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'You have $pendingTasks tasks pending and a flight to Paris in 2 days. Stay on track!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _QuickAction(
                  icon: Icons.add_task,
                  label: 'Add Task',
                  color: Colors.blue,
                  onTap: () => _showAddTaskDialog(context),
                ),
                _QuickAction(
                  icon: Icons.flight_takeoff,
                  label: 'Book Flight',
                  color: Colors.orange,
                  onTap: () {},
                ),
                _QuickAction(
                  icon: Icons.mic,
                  label: 'Add Note',
                  color: Colors.purple,
                  onTap: () {},
                ),
                _QuickAction(
                  icon: Icons.hotel,
                  label: 'Book Hotel',
                  color: Colors.green,
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Today's Tasks
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Today's Tasks",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                TextButton(
                  onPressed: onRefresh,
                  child: const Text(
                    'Refresh',
                    style: TextStyle(color: Color(0xFF00BCD4)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (tasks.isEmpty)
              const Center(
                child: Text(
                  'No tasks yet!\nTap Add Task to get started.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
              )
            else
              ...tasks.take(3).map((task) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _HomeTaskItem(
                      task: task,
                      onToggle: () => onToggleTask(task),
                      onDelete: () => onDeleteTask(task),
                    ),
                  )),

            const SizedBox(height: 24),

            // Upcoming Travel
            const Text(
              'Upcoming Travel',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 8),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF4FB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                        const Icon(Icons.flight, color: Color(0xFF00BCD4)),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lagos → Paris',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Direct · 6h 50m · In 2 days',
                          style:
                              TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF4FB),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'View',
                      style: TextStyle(
                        color: Color(0xFF00BCD4),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    String selectedTag = 'High';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New Task'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: 'Task title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Priority:',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['High', 'Medium', 'Low'].map((tag) {
                    return ChoiceChip(
                      label: Text(tag),
                      selected: selectedTag == tag,
                      selectedColor: const Color(0xFF00BCD4),
                      labelStyle: TextStyle(
                        color: selectedTag == tag
                            ? Colors.white
                            : Colors.black87,
                      ),
                      onSelected: (_) =>
                          setDialogState(() => selectedTag = tag),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BCD4),
              ),
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  onAddTask(controller.text, selectedTag);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// TASKS TAB
class TasksTab extends StatelessWidget {
  final List<Task> tasks;
  final bool isLoading;
  final Function(Task) onToggleTask;
  final Function(Task) onDeleteTask;
  final Function(String, String) onAddTask;
  final VoidCallback onRefresh;

  const TasksTab({
    super.key,
    required this.tasks,
    required this.isLoading,
    required this.onToggleTask,
    required this.onDeleteTask,
    required this.onAddTask,
    required this.onRefresh,
  });

  void _showAddTaskDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    String selectedTag = 'High';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New Task'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: 'Task title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Priority:',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['High', 'Medium', 'Low'].map((tag) {
                    return ChoiceChip(
                      label: Text(tag),
                      selected: selectedTag == tag,
                      selectedColor: const Color(0xFF00BCD4),
                      labelStyle: TextStyle(
                        color: selectedTag == tag
                            ? Colors.white
                            : Colors.black87,
                      ),
                      onSelected: (_) =>
                          setDialogState(() => selectedTag = tag),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BCD4),
              ),
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  onAddTask(controller.text, selectedTag);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My Tasks',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BCD4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _showAddTaskDialog(context),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Add Task',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : tasks.isEmpty
                      ? const Center(
                          child: Text(
                            'No tasks yet!\nTap Add Task to get started.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black54),
                          ),
                        )
                      : ListView.builder(
                          itemCount: tasks.length,
                          itemBuilder: (context, index) {
                            final task = tasks[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _HomeTaskItem(
                                task: task,
                                onToggle: () => onToggleTask(task),
                                onDelete: () => onDeleteTask(task),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// TRAVEL TAB - LOADS THE REAL TravelScreen with MAP
class TravelTab extends StatelessWidget {
  const TravelTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const TravelScreen();
  }
}

// NOTES TAB
class NotesTab extends StatelessWidget {
  const NotesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const NotesScreen();
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _HomeTaskItem extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _HomeTaskItem({
    required this.task,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Icon(
              task.done
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: task.done ? Colors.green : Colors.grey,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              task.title,
              style: TextStyle(
                decoration:
                    task.done ? TextDecoration.lineThrough : null,
                color: task.done ? Colors.grey : Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: task.tag == 'Done'
                  ? Colors.green.shade100
                  : task.tag == 'High'
                      ? Colors.orange.shade100
                      : task.tag == 'Medium'
                          ? Colors.yellow.shade100
                          : Colors.blue.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              task.tag,
              style: TextStyle(
                color: task.tag == 'Done'
                    ? Colors.green
                    : task.tag == 'High'
                        ? Colors.orange
                        : task.tag == 'Medium'
                            ? Colors.orange.shade700
                            : Colors.blue,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: Colors.red, size: 20),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}