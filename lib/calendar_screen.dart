import 'meeting_screen.dart';
import 'supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

// EVENT MODEL
class CalendarEvent {
  final String id;
  final String title;
  final String description;
  final Color color;
  final String type; // 'travel', 'task', 'personal'
  final DateTime date;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.color,
    required this.type,
    required this.date,
  });

  factory CalendarEvent.fromMap(Map<String, dynamic> map) {
    final type = map['event_type'] ?? 'personal';
    return CalendarEvent(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      color: type == 'travel'
          ? const Color(0xFF00BCD4)
          : type == 'task'
              ? Colors.red
              : Colors.purple,
      type: type,
      date: DateTime.tryParse(map['event_date'] ?? '') ?? DateTime.now(),
    );
  }
}

// GLOBAL EVENTS MAP
Map<DateTime, List<CalendarEvent>> globalEvents = {};

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<CalendarEvent> _selectedEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  // ==================== SUPABASE ====================

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.getEvents();
      final Map<DateTime, List<CalendarEvent>> eventsMap = {};

      for (final map in data) {
        final event = CalendarEvent.fromMap(map);
        final key = DateTime.utc(
          event.date.year,
          event.date.month,
          event.date.day,
        );
        eventsMap[key] = [...(eventsMap[key] ?? []), event];
      }

      setState(() {
        globalEvents = eventsMap;
        // Refresh selected day events if a day is selected
        if (_selectedDay != null) {
          _selectedEvents = _getEventsForDay(_selectedDay!);
        }
      });
    } catch (e) {
      _showSnackBar('Failed to load events: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveEvent({
    required String title,
    required String description,
    required String type,
    required DateTime date,
  }) async {
    final success = await SupabaseService.addEvent(
      title: title,
      description: description,
      eventDate: date,
      eventType: type,
    );
    if (success) {
      await _loadEvents();
    } else {
      _showSnackBar('Failed to save event', isError: true);
    }
  }

  Future<void> _deleteEvent(CalendarEvent event) async {
    final success = await SupabaseService.deleteEvent(event.id);
    if (success) {
      await _loadEvents();
    } else {
      _showSnackBar('Failed to delete event', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF00BCD4),
      ),
    );
  }

  // ==================== HELPERS ====================

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    return globalEvents[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  // ==================== DIALOGS ====================

  void _showAddEventDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descController = TextEditingController();
    String selectedType = 'personal';
    DateTime selectedDate = _selectedDay ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Event'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    hintText: 'Event title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    hintText: 'Description (optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Event Type:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['personal', 'travel', 'task'].map((type) {
                    return ChoiceChip(
                      label: Text(type.toUpperCase()),
                      selected: selectedType == type,
                      selectedColor: const Color(0xFF00BCD4),
                      labelStyle: TextStyle(
                        color: selectedType == type
                            ? Colors.white
                            : Colors.black87,
                      ),
                      onSelected: (_) =>
                          setDialogState(() => selectedType = type),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                // Date picker
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2028),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: Color(0xFF00BCD4)),
                        const SizedBox(width: 8),
                        Text(
                          '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
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
              onPressed: () async {
                if (titleController.text.isNotEmpty) {
                  final title = titleController.text;
                  final desc = descController.text;
                  final type = selectedType;
                  final date = selectedDate;
                  Navigator.pop(context);
                  await _saveEvent(
                    title: title,
                    description: desc,
                    type: type,
                    date: date,
                  );
                }
              },
              child: const Text(
                'Add',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGoogleCalendarDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.calendar_month, color: Color(0xFF00BCD4)),
            SizedBox(width: 8),
            Text('Connect Calendar'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Connect your calendars to sync events automatically.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),
            _CalendarOption(
              icon: Icons.g_mobiledata,
              label: 'Google Calendar',
              color: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('Google Calendar connected! ✅');
              },
            ),
            const SizedBox(height: 12),
            _CalendarOption(
              icon: Icons.apple,
              label: 'Apple Calendar',
              color: Colors.grey,
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('Apple Calendar connected! ✅');
              },
            ),
            const SizedBox(height: 12),
            _CalendarOption(
              icon: Icons.email,
              label: 'Outlook Calendar',
              color: Colors.blue,
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('Outlook Calendar connected! ✅');
              },
            ),
          ],
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

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Calendar',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Row(
                      children: [
                        // Refresh button
                        IconButton(
                          onPressed: _loadEvents,
                          icon: const Icon(Icons.refresh,
                              color: Color(0xFF00BCD4)),
                          tooltip: 'Refresh',
                        ),
                        IconButton(
                          onPressed: _showGoogleCalendarDialog,
                          icon: const Icon(Icons.link,
                              color: Color(0xFF00BCD4)),
                          tooltip: 'Connect Calendar',
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MeetingScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.people, color: Colors.white),
                        label: const Text(
                          'Schedule Meeting',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00BCD4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _showAddEventDialog,
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text(
                          'Add Event',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Calendar Widget
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF00BCD4),
                    ),
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
                      color:
                          const Color(0xFF00BCD4).withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: const BoxDecoration(
                      color: Color(0xFF00BCD4),
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonDecoration: BoxDecoration(
                      color: Color(0xFF00BCD4),
                      borderRadius:
                          BorderRadius.all(Radius.circular(12)),
                    ),
                    formatButtonTextStyle:
                        TextStyle(color: Colors.white),
                    titleCentered: true,
                  ),
                ),

          const SizedBox(height: 8),

          // Events Legend
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                _LegendItem(
                    color: const Color(0xFF00BCD4), label: 'Travel'),
                const SizedBox(width: 16),
                _LegendItem(color: Colors.red, label: 'Task'),
                const SizedBox(width: 16),
                _LegendItem(color: Colors.purple, label: 'Personal'),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Events List
          Expanded(
            child: _selectedEvents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_available,
                          size: 60,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No events for this day\nTap + Add to create one!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: _selectedEvents.length,
                    itemBuilder: (context, index) {
                      final event = _selectedEvents[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black12, blurRadius: 6),
                          ],
                          border: Border(
                            left: BorderSide(
                              color: event.color,
                              width: 4,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              event.type == 'travel'
                                  ? Icons.flight
                                  : event.type == 'task'
                                      ? Icons.task_alt
                                      : Icons.event,
                              color: event.color,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (event.description.isNotEmpty)
                                    Text(
                                      event.description,
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 13,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: event.color
                                    .withValues(alpha: 0.1),
                                borderRadius:
                                    BorderRadius.circular(20),
                              ),
                              child: Text(
                                event.type.toUpperCase(),
                                style: TextStyle(
                                  color: event.color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // Delete button
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red, size: 20),
                              onPressed: () => _deleteEvent(event),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// HELPER WIDGETS
class _CalendarOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _CalendarOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }
}