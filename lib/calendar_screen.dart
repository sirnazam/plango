import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Event Model with AI suggestions
class CalendarEvent {
  final String id;
  final String title;
  final String description;
  final Color color;
  final String type; // 'travel', 'task', 'meeting', 'personal'
  final DateTime date;
  final DateTime? startTime;
  final DateTime? endTime;
  final bool isAiSuggested;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.color,
    required this.type,
    required this.date,
    this.startTime,
    this.endTime,
    this.isAiSuggested = false,
  });

  factory CalendarEvent.fromMap(Map<String, dynamic> map) {
    final type = map['event_type'] ?? 'personal';
    return CalendarEvent(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      color: type == 'travel'
          ? const Color(0xFFEC4899)
          : type == 'task'
              ? const Color(0xFF6366F1)
              : type == 'meeting'
                  ? const Color(0xFF10B981)
                  : const Color(0xFFF59E0B),
      type: type,
      date: DateTime.tryParse(map['event_date'] ?? '') ?? DateTime.now(),
      startTime: map['start_time'] != null 
          ? DateTime.tryParse(map['start_time']) 
          : null,
      endTime: map['end_time'] != null 
          ? DateTime.tryParse(map['end_time']) 
          : null,
      isAiSuggested: map['is_ai_suggested'] ?? false,
    );
  }
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> with TickerProviderStateMixin {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<CalendarEvent> _selectedEvents = [];
  List<CalendarEvent> _allEvents = [];
  bool _isLoading = true;
  
  // AI Suggestions
  List<Map<String, dynamic>> _aiSuggestions = [];
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _loadEvents();
    _generateAiSuggestions();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // Generate fake AI suggestions for demo
  void _generateAiSuggestions() {
    final now = DateTime.now();
    _aiSuggestions = [
      {
        'time': '2:00 PM - 4:00 PM',
        'reason': 'Best focus time based on your patterns',
        'color': const Color(0xFF6366F1),
      },
      {
        'time': '6:00 PM - 7:00 PM',
        'reason': 'Free slot for exercise',
        'color': const Color(0xFF10B981),
      },
    ];
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }
      
      final response = await Supabase.instance.client
          .from('events')
          .select()
          .eq('user_id', user.id)
          .order('event_date', ascending: true);
      
      setState(() {
        _allEvents = (response as List).map((e) => CalendarEvent.fromMap(e)).toList();
        if (_selectedDay != null) {
          _selectedEvents = _getEventsForDay(_selectedDay!);
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Load demo data if error
      _loadDemoEvents();
    }
  }

  void _loadDemoEvents() {
    final now = DateTime.now();
    _allEvents = [
      CalendarEvent(
        id: '1',
        title: 'Team Standup',
        description: 'Daily team sync',
        color: const Color(0xFF10B981),
        type: 'meeting',
        date: now,
        startTime: now.copyWith(hour: 9, minute: 0),
        endTime: now.copyWith(hour: 9, minute: 30),
      ),
      CalendarEvent(
        id: '2',
        title: 'Deep Work: Project',
        description: 'Focus time',
        color: const Color(0xFF6366F1),
        type: 'task',
        date: now,
        startTime: now.copyWith(hour: 10, minute: 0),
        endTime: now.copyWith(hour: 12, minute: 0),
        isAiSuggested: true,
      ),
      CalendarEvent(
        id: '3',
        title: 'Flight to Paris',
        description: 'Travel booking',
        color: const Color(0xFFEC4899),
        type: 'travel',
        date: now.add(const Duration(days: 2)),
      ),
    ];
    if (_selectedDay != null) {
      _selectedEvents = _getEventsForDay(_selectedDay!);
    }
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    return _allEvents.where((e) => 
      e.date.year == day.year && 
      e.date.month == day.month && 
      e.date.day == day.day
    ).toList();
  }

  // AI Auto-Schedule Feature
  void _showAiScheduleDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00BCD4), Color(0xFF26C6DA)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'AI Auto-Schedule',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Plango analyzed your day and found optimal time slots:',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            ..._aiSuggestions.map((suggestion) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    suggestion['color'].withOpacity(0.1),
                    suggestion['color'].withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: suggestion['color'].withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: suggestion['color'],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.schedule,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          suggestion['time'],
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          suggestion['reason'],
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showAddEventDialog(suggestedTime: suggestion['time']);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: suggestion['color'],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Book',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            )).toList(),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade100,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Maybe Later',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEventDialog({String? suggestedTime}) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedType = 'task';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            suggestedTime != null ? 'Add to $suggestedTime' : 'Add Event',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    hintText: 'Event title',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    hintText: 'Description',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Event Type',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    {'label': 'Task', 'color': const Color(0xFF6366F1)},
                    {'label': 'Meeting', 'color': const Color(0xFF10B981)},
                    {'label': 'Travel', 'color': const Color(0xFFEC4899)},
                    {'label': 'Personal', 'color': const Color(0xFFF59E0B)},
                  ].map((type) {
                    final isSelected = selectedType == (type['label'] as String).toLowerCase();
                    return ChoiceChip(
                      label: Text(type['label'] as String),
                      selected: isSelected,
                      selectedColor: type['color'] as Color,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                      onSelected: (_) => setDialogState(() => 
                        selectedType = (type['label'] as String).toLowerCase()),
                    );
                  }).toList(),
                ),
                if (suggestedTime != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00BCD4).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome, 
                          color: Color(0xFF00BCD4), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '✨ AI suggested this time slot',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF00BCD4),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.inter()),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BCD4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                if (titleController.text.isNotEmpty) {
                  await _saveEvent(
                    title: titleController.text,
                    description: descController.text,
                    type: selectedType,
                    date: _selectedDay ?? DateTime.now(),
                  );
                  Navigator.pop(context);
                }
              },
              child: Text(
                'Add',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveEvent({
    required String title,
    required String description,
    required String type,
    required DateTime date,
  }) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      
      await Supabase.instance.client.from('events').insert({
        'user_id': user.id,
        'title': title,
        'description': description,
        'event_type': type,
        'event_date': date.toIso8601String().split('T')[0],
      });
      
      await _loadEvents();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✨ Event added! AI will optimize your schedule.'),
          backgroundColor: const Color(0xFF00BCD4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      // Add locally if error
      setState(() {
        _allEvents.add(CalendarEvent(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          description: description,
          color: type == 'travel'
              ? const Color(0xFFEC4899)
              : type == 'task'
                  ? const Color(0xFF6366F1)
                  : type == 'meeting'
                      ? const Color(0xFF10B981)
                      : const Color(0xFFF59E0B),
          type: type,
          date: date,
        ));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: SafeArea(
        child: Column(
          children: [
            // Header matching AI Home Screen style
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF00BCD4), Color(0xFF26C6DA)],
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Calendar',
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'AI-optimized scheduling',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                        ],
                      ),
                      // AI Button with pulse animation
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(
                                    0.3 + (_pulseController.value * 0.2)),
                                  blurRadius: 15 + (_pulseController.value * 10),
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: GestureDetector(
                              onTap: _showAiScheduleDialog,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.4),
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.auto_awesome,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildHeaderStat(
                        _allEvents.where((e) => e.type == 'task').length.toString(),
                        'Tasks',
                        Icons.task_alt,
                      ),
                      _buildHeaderStat(
                        _allEvents.where((e) => e.type == 'meeting').length.toString(),
                        'Meetings',
                        Icons.people,
                      ),
                      _buildHeaderStat(
                        _allEvents.where((e) => e.type == 'travel').length.toString(),
                        'Trips',
                        Icons.flight,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // AI Suggestion Banner
            if (_aiSuggestions.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6366F1).withOpacity(0.1),
                      const Color(0xFF8B5CF6).withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF6366F1).withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.lightbulb,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Suggestion',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF6366F1),
                            ),
                          ),
                          Text(
                            'Best focus time: ${_aiSuggestions[0]['time']}',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _showAiScheduleDialog,
                      child: Text(
                        'View',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF6366F1),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 8),

            // Calendar
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF00BCD4),
                          ),
                        )
                      : TableCalendar(
                          firstDay: DateTime.utc(2024, 1, 1),
                          lastDay: DateTime.utc(2028, 12, 31),
                          focusedDay: _focusedDay,
                          calendarFormat: _calendarFormat,
                          selectedDayPredicate: (day) =>
                              isSameDay(_selectedDay, day),
                          eventLoader: _getEventsForDay,
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                              _selectedEvents = _getEventsForDay(selectedDay);
                            });
                          },
                          onFormatChanged: (format) {
                            setState(() => _calendarFormat = format);
                          },
                          calendarStyle: CalendarStyle(
                            selectedDecoration: const BoxDecoration(
                              color: Color(0xFF00BCD4),
                              shape: BoxShape.circle,
                            ),
                            todayDecoration: BoxDecoration(
                              color: const Color(0xFF00BCD4).withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            markerDecoration: const BoxDecoration(
                              color: Color(0xFF00BCD4),
                              shape: BoxShape.circle,
                            ),
                            markersMaxCount: 3,
                            markerSize: 6,
                          ),
                          headerStyle: HeaderStyle(
                            titleCentered: true,
                            formatButtonDecoration: BoxDecoration(
                              color: const Color(0xFF00BCD4),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            formatButtonTextStyle: const TextStyle(
                              color: Colors.white,
                            ),
                            leftChevronIcon: const Icon(
                              Icons.chevron_left,
                              color: Color(0xFF00BCD4),
                            ),
                            rightChevronIcon: const Icon(
                              Icons.chevron_right,
                              color: Color(0xFF00BCD4),
                            ),
                          ),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Selected Day Events
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDay != null
                            ? 'Events for ${_selectedDay!.day}/${_selectedDay!.month}'
                            : 'Select a day',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_selectedDay != null)
                        GestureDetector(
                          onTap: () => _showAddEventDialog(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00BCD4), Color(0xFF26C6DA)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 100,
                    child: _selectedEvents.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.event_available,
                                  size: 40,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No events\nTap + to add',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    color: Colors.grey.shade500,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _selectedEvents.length,
                            itemBuilder: (context, index) {
                              final event = _selectedEvents[index];
                              return Container(
                                width: 200,
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      event.color.withOpacity(0.1),
                                      event.color.withOpacity(0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: event.color.withOpacity(0.3),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: event.color,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            event.type == 'travel'
                                                ? Icons.flight
                                                : event.type == 'task'
                                                    ? Icons.task_alt
                                                    : event.type == 'meeting'
                                                        ? Icons.people
                                                        : Icons.event,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                        ),
                                        if (event.isAiSuggested) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF00BCD4),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'AI',
                                              style: GoogleFonts.inter(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      event.title,
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      event.description,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStat(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
          Icon(
            icon,
            color: Colors.white.withOpacity(0.9),
            size: 18,
          ),
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
}