import 'package:plango/calendar_screen.dart' as cal;
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'profile_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart' as home;
import 'notes_screen.dart';
import 'supabase_service.dart';

class AIHomeScreen extends StatefulWidget {
  const AIHomeScreen({super.key});

  @override
  State<AIHomeScreen> createState() => _AIHomeScreenState();
}

class _AIHomeScreenState extends State<AIHomeScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;

  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  String? _userName;
  late AnimationController _headerAnimationController;
  late AnimationController _floatingAnimationController;
  late AnimationController _fabPulseController;

  // Key to force NotesScreen rebuild after FAB save
  Key _notesKey = UniqueKey();

  final List<Map<String, dynamic>> _quickActions = [
    {'icon': Icons.calendar_today_rounded, 'label': 'Plan Day', 'color': 0xFF6366F1, 'gradient': [0xFF6366F1, 0xFF8B5CF6]},
    {'icon': Icons.check_circle_outline_rounded, 'label': 'Add Task', 'color': 0xFF10B981, 'gradient': [0xFF10B981, 0xFF34D399]},
    {'icon': Icons.schedule_rounded, 'label': 'Schedule', 'color': 0xFFF59E0B, 'gradient': [0xFFF59E0B, 0xFFFB923C]},
    {'icon': Icons.flight_takeoff_rounded, 'label': 'Plan Trip', 'color': 0xFFEC4899, 'gradient': [0xFFEC4899, 0xFFF472B6]},
  ];

  final List<Map<String, dynamic>> _navItems = [
    {'icon': Icons.home_rounded, 'label': 'Home', 'color': 0xFF00BCD4},
    {'icon': Icons.task_alt_rounded, 'label': 'Tasks', 'color': 0xFF6366F1},
    {'icon': Icons.note_alt_rounded, 'label': 'Notes', 'color': 0xFF9C27B0},
    {'icon': Icons.calendar_today_rounded, 'label': 'Calendar', 'color': 0xFFF59E0B},
    {'icon': Icons.flight_takeoff_rounded, 'label': 'Travel', 'color': 0xFFEC4899},
  ];

  @override
  void initState() {
    super.initState();

    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..forward();

    _floatingAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _fabPulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _loadUserProfile();
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    _headerAnimationController.dispose();
    _floatingAnimationController.dispose();
    _fabPulseController.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    Future.delayed(const Duration(milliseconds: 500), () {
      _messages.add({
        'role': 'assistant',
        'content':
            '👋 Welcome back! I\'m Plango, your AI companion.\n\nI can help you:\n• Plan your day intelligently\n• Add and manage tasks\n• Schedule meetings\n• Plan your next adventure\n\nWhat would you like to do today? ✨',
      });
      if (mounted) setState(() {});
    });
  }

  // ===================== FIX #2: NAME NOT SHOWING =====================
  // Reads from profiles table first, then falls back to auth metadata,
  // then falls back to email prefix — so name always shows.
  Future<void> _loadUserProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // 1. Try profiles table
      try {
        final response = await Supabase.instance.client
            .from('profiles')
            .select('full_name')
            .eq('id', user.id)
            .maybeSingle(); // maybeSingle won't throw if row doesn't exist

        final fullName = response?['full_name'] as String?;
        if (fullName != null && fullName.trim().isNotEmpty) {
          setState(() {
            _userName = fullName.split(' ').first.trim();
          });
          return;
        }
      } catch (_) {}

      // 2. Try auth user_metadata (set during sign-up form)
      final meta = user.userMetadata;
      if (meta != null) {
        final metaName = (meta['full_name'] ?? meta['name'] ?? meta['display_name']) as String?;
        if (metaName != null && metaName.trim().isNotEmpty) {
          setState(() {
            _userName = metaName.split(' ').first.trim();
          });
          // Also write it back to profiles so future loads are faster
          try {
            await Supabase.instance.client.from('profiles').upsert({
              'id': user.id,
              'full_name': metaName,
            });
          } catch (_) {}
          return;
        }
      }

      // 3. Fallback: use email prefix
      final email = user.email ?? '';
      setState(() {
        _userName = email.isNotEmpty ? email.split('@').first : 'Friend';
      });
    } catch (e) {
      setState(() => _userName = 'Friend');
    }
  }
  // ====================================================================

  Future<void> _sendMessage() async {
    if (_chatController.text.trim().isEmpty) return;

    final userMessage = _chatController.text.trim();
    setState(() {
      _messages.add({'role': 'user', 'content': userMessage});
      _chatController.clear();
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final parsed = _parseLocally(userMessage);
      await _executeAction(parsed);
      final displayMessage = _getDisplayMessage(parsed);

      setState(() {
        _messages.add({'role': 'assistant', 'content': displayMessage});
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': '⚠️ I had trouble processing that. Could you try rephrasing?'
        });
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _parseLocally(String message) {
    final lowerMsg = message.toLowerCase();

    if (lowerMsg.contains('add task') || lowerMsg.contains('task')) {
      String taskTitle =
          message.replaceAll(RegExp(r'(?i)add task|task'), '').trim();
      if (taskTitle.isEmpty) taskTitle = 'New task';

      String date = DateTime.now().toIso8601String().split('T')[0];
      if (lowerMsg.contains('tomorrow')) {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        date = tomorrow.toIso8601String().split('T')[0];
      }

      return {
        'intent': 'ADD_TASK',
        'title': taskTitle,
        'date': date,
        'priority': 'Medium'
      };
    }

    if (lowerMsg.contains('plan my day') || lowerMsg.contains('plan day')) {
      return {'intent': 'PLAN_DAY'};
    }

    if (lowerMsg.contains('schedule') || lowerMsg.contains('meeting')) {
      return {
        'intent': 'SCHEDULE_EVENT',
        'title': 'Meeting',
        'date': null,
        'time': '14:00'
      };
    }

    if (lowerMsg.contains('trip') || lowerMsg.contains('travel')) {
      return {
        'intent': 'PLAN_TRIP',
        'destination': 'Paris',
        'duration_days': 3
      };
    }

    return {'intent': 'unknown'};
  }

  Future<void> _executeAction(Map<String, dynamic> parsed) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    switch (parsed['intent']) {
      case 'ADD_TASK':
        await Supabase.instance.client.from('tasks').insert({
          'user_id': user.id,
          'title': parsed['title'],
          'priority': parsed['priority'] ?? 'Medium',
          'done': false,
          'deadline':
              parsed['date'] != null ? '${parsed['date']}T09:00:00' : null,
        });
        break;
      case 'SCHEDULE_EVENT':
        await Supabase.instance.client.from('events').insert({
          'user_id': user.id,
          'title': parsed['title'],
          'date': parsed['date'],
          'time': parsed['time'],
        });
        break;
    }
  }

  String _getDisplayMessage(Map<String, dynamic> parsed) {
    switch (parsed['intent']) {
      case 'ADD_TASK':
        return '✅ Perfect! I\'ve added "${parsed['title']}" as ${parsed['priority']} priority${parsed['date'] != null ? ' for ${parsed['date']}' : ''}. You\'re making great progress!';
      case 'SCHEDULE_EVENT':
        return '📅 Excellent! I\'ve scheduled "${parsed['title']}"${parsed['time'] != null ? ' at ${parsed['time']}' : ''}. I\'ll remind you when it\'s time!';
      case 'PLAN_DAY':
        return '🧠 I\'m analyzing your schedule and creating an optimal plan for today. I\'ve prioritized your most important tasks. Check your task list!';
      case 'PLAN_TRIP':
        return '✈️ Exciting! I\'m planning your trip to ${parsed['destination']} for ${parsed['duration_days']} days. I\'ll find the best flights and accommodations for you!';
      default:
        return '💫 I\'m here to help! Try saying:\n• "Add task buy milk tomorrow"\n• "Plan my day"\n• "Schedule meeting at 3pm"\n• "Plan trip to Tokyo"';
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleQuickAction(String label) {
    switch (label) {
      case 'Plan Day':
        _chatController.text = 'Plan my day';
        break;
      case 'Add Task':
        _chatController.text = 'Add task ';
        break;
      case 'Schedule':
        _chatController.text = 'Schedule meeting ';
        break;
      case 'Plan Trip':
        _chatController.text = 'Plan trip to ';
        break;
    }
    _sendMessage();
  }

  void _onNavItemTap(int index) {
    setState(() => _selectedIndex = index);
  }

  // ===================== FIX #1: FAB → DIRECT ADD NOTE =====================
  // Tapping + switches to Notes tab and immediately opens the Add Note dialog.
  // No more bottom sheet menu. Notes nav tab still works for just navigating.
  void _onCenterButtonTap() {
    // Switch to Notes tab
    setState(() => _selectedIndex = 2);

    // Small delay so the Notes tab is rendered before dialog opens
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;

      final TextEditingController titleController = TextEditingController();
      final TextEditingController contentController = TextEditingController();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.note_add, color: Color(0xFF00BCD4)),
              SizedBox(width: 8),
              Text('New Note'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Note title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF00BCD4)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentController,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText: 'Write your note here...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF00BCD4)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.black54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BCD4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                if (titleController.text.trim().isNotEmpty) {
                  final title = titleController.text.trim();
                  final content = contentController.text.trim();
                  Navigator.pop(context);
                  await SupabaseService.addNote(
                    title: title,
                    content: content,
                    type: 'note',
                  );
                  // Refresh NotesScreen by replacing its key
                  setState(() => _notesKey = UniqueKey());
                }
              },
              child: const Text('Save',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    });
  }
  // =========================================================================

  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  @override
  Widget build(BuildContext context) {
    // ===================== FIX #3: CALENDAR OVERFLOW =====================
    // Screens are built here inside build() so _notesKey refresh works,
    // and the CalendarScreen is wrapped in a clipped Expanded to prevent overflow.
    final List<Widget> screens = [
      _buildHomeTab(),        // 0: Home
      const TasksScreen(),    // 1: Tasks
      NotesScreen(key: _notesKey), // 2: Notes — refreshes after FAB save
      // Wrap calendar in LayoutBuilder + ClipRect to contain its overflow
      ClipRect(
        child: cal.CalendarScreen(),
      ),                      // 3: Calendar
      const TravelScreen(),   // 4: Travel
    ];
    // =====================================================================

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: screens,
              ),
            ),
            _buildStunningFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    return Column(
      children: [
        // Animated Gradient Header
        AnimatedBuilder(
          animation: _headerAnimationController,
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(const Color(0xFF00BCD4), const Color(0xFF0097A7),
                            _headerAnimationController.value) ??
                        const Color(0xFF00BCD4),
                    Color.lerp(const Color(0xFF26C6DA), const Color(0xFF4DD0E1),
                            _headerAnimationController.value) ??
                        const Color(0xFF26C6DA),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00BCD4).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.wb_sunny_rounded,
                                          size: 14,
                                          color:
                                              Colors.white.withOpacity(0.9)),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Good ${_getTimeOfDay()}',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // ---- NAME DISPLAY (reactive to _userName) ----
                            Text(
                              _userName ?? '...',
                              style: GoogleFonts.inter(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ready to make today productive?',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Animated AI Avatar
                      AnimatedBuilder(
                        animation: _floatingAnimationController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(
                                0,
                                math.sin(_floatingAnimationController.value *
                                        2 *
                                        math.pi) *
                                    3),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ProfileScreen(),
                                  ),
                                );
                              },
                              child: Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.4),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.auto_awesome_rounded,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildHeaderStat(
                          '3', 'Tasks Today', Icons.check_circle_outline),
                      _buildHeaderStat('1', 'Meetings', Icons.schedule),
                      _buildHeaderStat('2', 'Trips', Icons.flight),
                    ],
                  ),
                ],
              ),
            );
          },
        ),

        // Quick Actions
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: _quickActions.map((action) {
              return Expanded(
                child: GestureDetector(
                  onTap: () => _handleQuickAction(action['label']),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(action['gradient'][0]).withOpacity(0.1),
                          Color(action['gradient'][1]).withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Color(action['color']).withOpacity(0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(action['color']).withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(action['gradient'][0]),
                                Color(action['gradient'][1]),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(action['icon'],
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          action['label'],
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(action['color']),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 8),

        // Chat Messages
        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00BCD4), Color(0xFF26C6DA)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00BCD4).withOpacity(0.3),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.auto_awesome_rounded,
                            color: Colors.white, size: 48),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'How can I help you today?',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap a quick action or type your request',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final isUser = msg['role'] == 'user';
                    return Align(
                      alignment: isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 14),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.78,
                        ),
                        decoration: BoxDecoration(
                          gradient: isUser
                              ? const LinearGradient(colors: [
                                  Color(0xFF00BCD4),
                                  Color(0xFF26C6DA)
                                ])
                              : null,
                          color: isUser ? null : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20),
                            topRight: const Radius.circular(20),
                            bottomLeft: Radius.circular(isUser ? 20 : 4),
                            bottomRight: Radius.circular(isUser ? 4 : 20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isUser
                                  ? const Color(0xFF00BCD4).withOpacity(0.3)
                                  : Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          msg['content']!,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            height: 1.4,
                            color:
                                isUser ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Loading Indicator
        if (_isLoading)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF00BCD4)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Plango is thinking...',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Input Bar
        Container(
          margin: const EdgeInsets.only(
              left: 16, right: 16, top: 8, bottom: 8),
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  style: GoogleFonts.inter(
                      color: Colors.black87, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Ask Plango anything...',
                    hintStyle: GoogleFonts.inter(
                        color: Colors.grey.shade400, fontSize: 15),
                    prefixIcon: Icon(
                      Icons.auto_awesome_rounded,
                      color: const Color(0xFF00BCD4).withOpacity(0.5),
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  margin: const EdgeInsets.only(right: 4),
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF00BCD4), Color(0xFF26C6DA)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF00BCD4),
                        blurRadius: 10,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderStat(String value, String label, IconData icon) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.9), size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStunningFooter() {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
      height: 75,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Curved Glassmorphic Background
          ClipPath(
            clipper: CurvedFooterClipper(),
            child: Container(
              height: 65,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.95),
                    Colors.white.withOpacity(0.75),
                  ],
                ),
                borderRadius: const BorderRadius.all(Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius:
                        const BorderRadius.all(Radius.circular(30)),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Nav Items Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildNavItem(0), // Home
                _buildNavItem(1), // Tasks
                _buildNavItem(2), // Notes
                const SizedBox(width: 50), // FAB space
                _buildNavItem(3), // Calendar
                _buildNavItem(4), // Travel
              ],
            ),
          ),

          // Pulsing Glow Behind FAB
          Positioned(
            top: -30,
            child: AnimatedBuilder(
              animation: _fabPulseController,
              builder: (context, child) {
                return Container(
                  width: 70 + (_fabPulseController.value * 10),
                  height: 70 + (_fabPulseController.value * 10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF00BCD4).withOpacity(
                            0.3 - (_fabPulseController.value * 0.1)),
                        const Color(0xFF00BCD4).withOpacity(0.0),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Central FAB
          Positioned(
            top: -25,
            child: GestureDetector(
              onTap: _onCenterButtonTap,
              child: AnimatedBuilder(
                animation: _fabPulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_fabPulseController.value * 0.05),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF00BCD4),
                            Color(0xFF26C6DA),
                            Color(0xFF4DD0E1),
                          ],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00BCD4).withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 5,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: Colors.white.withOpacity(0.8),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.add_rounded,
                          color: Colors.white, size: 28),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final bool isSelected = _selectedIndex == index;
    final item = _navItems[index];
    final color = Color(item['color']);

    return GestureDetector(
      onTap: () => _onNavItemTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color:
              isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.transparent,
                shape: BoxShape.circle,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                item['icon'],
                color: isSelected ? Colors.white : Colors.grey.shade400,
                size: 18,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item['label'],
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? color : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom clipper for curved footer
class CurvedFooterClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final width = size.width;
    final height = size.height;
    const centerCutoutWidth = 85.0;
    const centerCutoutHeight = 32.0;
    final centerX = width / 2;

    path.moveTo(0, 0);
    path.lineTo(centerX - centerCutoutWidth / 2 - 20, 0);
    path.quadraticBezierTo(
      centerX - centerCutoutWidth / 2, 0,
      centerX - centerCutoutWidth / 2, centerCutoutHeight,
    );
    path.cubicTo(
      centerX - centerCutoutWidth / 2 + 20, centerCutoutHeight + 15,
      centerX - 20, centerCutoutHeight + 25,
      centerX, centerCutoutHeight + 25,
    );
    path.cubicTo(
      centerX + 20, centerCutoutHeight + 25,
      centerX + centerCutoutWidth / 2 - 20, centerCutoutHeight + 15,
      centerX + centerCutoutWidth / 2, centerCutoutHeight,
    );
    path.quadraticBezierTo(
      centerX + centerCutoutWidth / 2, 0,
      centerX + centerCutoutWidth / 2 + 20, 0,
    );
    path.lineTo(width, 0);
    path.lineTo(width, height - 20);
    path.quadraticBezierTo(width, height, width - 20, height);
    path.lineTo(20, height);
    path.quadraticBezierTo(0, height, 0, height - 20);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// ======================== TASKS SCREEN ========================
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<home.Task> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
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
        _tasks =
            (response as List).map((json) => home.Task.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (error) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addTask(String title, String priority) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final response = await Supabase.instance.client
          .from('tasks')
          .insert({
            'user_id': user.id,
            'title': title,
            'priority': priority,
            'done': false,
          })
          .select()
          .single();
      setState(() => _tasks.insert(0, home.Task.fromJson(response)));
    } catch (_) {}
  }

  Future<void> _toggleTask(home.Task task) async {
    try {
      final newDone = !task.done;
      final newTag =
          newDone ? 'Done' : (task.tag == 'Done' ? 'High' : task.tag);
      await Supabase.instance.client
          .from('tasks')
          .update({'done': newDone, 'priority': newTag}).eq('id', task.id!);
      setState(() {
        task.done = newDone;
        task.tag = newTag;
      });
    } catch (_) {}
  }

  Future<void> _deleteTask(home.Task task) async {
    try {
      await Supabase.instance.client
          .from('tasks')
          .delete()
          .eq('id', task.id!);
      setState(() => _tasks.remove(task));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF0F4F8),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text('My Tasks',
                      style: TextStyle(
                          fontSize: 28, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _showAddTaskDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Task'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00BCD4),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _tasks.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox_outlined,
                                  size: 60, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text(
                                'No tasks yet!\nTap + Add Task to create one',
                                textAlign: TextAlign.center,
                                style:
                                    TextStyle(color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _tasks.length,
                          itemBuilder: (context, index) {
                            final task = _tasks[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: Checkbox(
                                  value: task.done,
                                  onChanged: (_) => _toggleTask(task),
                                ),
                                title: Text(
                                  task.title,
                                  style: TextStyle(
                                    decoration: task.done
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                                subtitle: Text(task.tag),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => _deleteTask(task),
                                ),
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

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Task'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(hintText: 'Task title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                _addTask(titleController.text, 'Medium');
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

// ======================== TRAVEL SCREEN ========================
class TravelScreen extends StatelessWidget {
  const TravelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF0F4F8),
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Travel Plans',
                  style: TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.flight_takeoff,
                        size: 60, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text('No trips planned yet!',
                        style: TextStyle(color: Colors.grey.shade500)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}