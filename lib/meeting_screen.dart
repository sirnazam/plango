import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MeetingScreen extends StatefulWidget {
  const MeetingScreen({super.key});

  @override
  State<MeetingScreen> createState() => _MeetingScreenState();
}

class _MeetingScreenState extends State<MeetingScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _attendeeEmailController =
      TextEditingController();
  final TextEditingController _attendeeNameController =
      TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedTimezone = 'Africa/Lagos';
  List<Map<String, String>> _attendees = [];

  final List<String> _timezones = [
    'Africa/Lagos',
    'Europe/London',
    'America/New_York',
    'America/Los_Angeles',
    'Europe/Paris',
    'Asia/Dubai',
    'Asia/Tokyo',
    'Australia/Sydney',
    'America/Chicago',
    'Europe/Berlin',
  ];

  final Map<String, String> _timezoneOffsets = {
    'Africa/Lagos': 'WAT (UTC+1)',
    'Europe/London': 'GMT (UTC+0)',
    'America/New_York': 'EST (UTC-5)',
    'America/Los_Angeles': 'PST (UTC-8)',
    'Europe/Paris': 'CET (UTC+1)',
    'Asia/Dubai': 'GST (UTC+4)',
    'Asia/Tokyo': 'JST (UTC+9)',
    'Australia/Sydney': 'AEDT (UTC+11)',
    'America/Chicago': 'CST (UTC-6)',
    'Europe/Berlin': 'CET (UTC+1)',
  };

  final Map<String, int> _timezoneHours = {
    'Africa/Lagos': 1,
    'Europe/London': 0,
    'America/New_York': -5,
    'America/Los_Angeles': -8,
    'Europe/Paris': 1,
    'Asia/Dubai': 4,
    'Asia/Tokyo': 9,
    'Australia/Sydney': 11,
    'America/Chicago': -6,
    'Europe/Berlin': 1,
  };

  String _convertTime(TimeOfDay time, String fromTz, String toTz) {
    int fromOffset = _timezoneHours[fromTz] ?? 0;
    int toOffset = _timezoneHours[toTz] ?? 0;
    int diff = toOffset - fromOffset;
    int newHour = (time.hour + diff) % 24;
    if (newHour < 0) newHour += 24;
    final period = newHour >= 12 ? 'PM' : 'AM';
    final displayHour = newHour > 12 ? newHour - 12 : (newHour == 0 ? 12 : newHour);
    final minutes = time.minute.toString().padLeft(2, '0');
    return '$displayHour:$minutes $period';
  }

  void _addAttendee() {
    showDialog(
      context: context,
      builder: (context) {
        String selectedTz = 'Europe/London';
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Add Attendee'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _attendeeNameController,
                    decoration: InputDecoration(
                      hintText: 'Name (e.g. John Boss)',
                      prefixIcon: const Icon(Icons.person,
                          color: Color(0xFF00BCD4)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _attendeeEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Email address',
                      prefixIcon: const Icon(Icons.email,
                          color: Color(0xFF00BCD4)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Their Timezone:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedTz,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: _timezones.map((tz) {
                      return DropdownMenuItem(
                        value: tz,
                        child: Text(
                          '${tz.split('/').last} ${_timezoneOffsets[tz] ?? ''}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) =>
                        setDialogState(() => selectedTz = val!),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _attendeeNameController.clear();
                  _attendeeEmailController.clear();
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00BCD4),
                ),
                onPressed: () {
                  if (_attendeeEmailController.text.isNotEmpty &&
                      _attendeeNameController.text.isNotEmpty) {
                    setState(() {
                      _attendees.add({
                        'name': _attendeeNameController.text,
                        'email': _attendeeEmailController.text,
                        'timezone': selectedTz,
                      });
                    });
                    _attendeeNameController.clear();
                    _attendeeEmailController.clear();
                    Navigator.pop(context);
                  }
                },
                child: const Text(
                  'Add',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendViaGmail() async {
    if (_titleController.text.isEmpty || _attendees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add meeting title and attendees!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final emails = _attendees.map((a) => a['email']).join(',');
    final subject = Uri.encodeComponent(
        '📅 Meeting Invite: ${_titleController.text}');

    // Build time for each attendee
    String attendeesTimes = _attendees.map((a) {
      final convertedTime =
          _convertTime(_selectedTime, _selectedTimezone, a['timezone']!);
      final tzLabel = _timezoneOffsets[a['timezone']] ?? '';
      return '• ${a['name']}: $convertedTime $tzLabel';
    }).join('\n');

    final body = Uri.encodeComponent('''
Hi,

You are invited to the following meeting:

📌 Title: ${_titleController.text}
📅 Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}
🕐 Time (${_timezoneOffsets[_selectedTimezone]}): ${_selectedTime.format(context)}
📍 Location: ${_locationController.text.isEmpty ? 'To be confirmed' : _locationController.text}
📝 Description: ${_descController.text.isEmpty ? 'N/A' : _descController.text}

⏰ Your Local Time:
$attendeesTimes

Please confirm your attendance.

Sent via PLANGO - AI Workspace
    ''');

    final Uri emailUri = Uri.parse(
        'https://mail.google.com/mail/?view=cm&fs=1&to=$emails&su=$subject&body=$body');

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open Gmail!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendViaOutlook() async {
    if (_titleController.text.isEmpty || _attendees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add meeting title and attendees!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final emails = _attendees.map((a) => a['email']).join(';');
    final subject = Uri.encodeComponent(
        '📅 Meeting Invite: ${_titleController.text}');

    String attendeesTimes = _attendees.map((a) {
      final convertedTime =
          _convertTime(_selectedTime, _selectedTimezone, a['timezone']!);
      final tzLabel = _timezoneOffsets[a['timezone']] ?? '';
      return '• ${a['name']}: $convertedTime $tzLabel';
    }).join('\n');

    final body = Uri.encodeComponent('''
Hi,

You are invited to the following meeting:

📌 Title: ${_titleController.text}
📅 Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}
🕐 Time (${_timezoneOffsets[_selectedTimezone]}): ${_selectedTime.format(context)}
📍 Location: ${_locationController.text.isEmpty ? 'To be confirmed' : _locationController.text}
📝 Description: ${_descController.text.isEmpty ? 'N/A' : _descController.text}

⏰ Your Local Time:
$attendeesTimes

Please confirm your attendance.

Sent via PLANGO - AI Workspace
    ''');

    final Uri emailUri = Uri.parse(
        'https://outlook.live.com/mail/0/deeplink/compose?to=$emails&subject=$subject&body=$body');

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open Outlook!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendViaYahoo() async {
    if (_titleController.text.isEmpty || _attendees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add meeting title and attendees!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final emails = _attendees.map((a) => a['email']).join(',');
    final subject = Uri.encodeComponent(
        '📅 Meeting Invite: ${_titleController.text}');

    String attendeesTimes = _attendees.map((a) {
      final convertedTime =
          _convertTime(_selectedTime, _selectedTimezone, a['timezone']!);
      final tzLabel = _timezoneOffsets[a['timezone']] ?? '';
      return '• ${a['name']}: $convertedTime $tzLabel';
    }).join('\n');

    final body = Uri.encodeComponent('''
Hi,

You are invited to the following meeting:

📌 Title: ${_titleController.text}
📅 Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}
🕐 Time (${_timezoneOffsets[_selectedTimezone]}): ${_selectedTime.format(context)}
📍 Location: ${_locationController.text.isEmpty ? 'To be confirmed' : _locationController.text}
📝 Description: ${_descController.text.isEmpty ? 'N/A' : _descController.text}

⏰ Your Local Time:
$attendeesTimes

Please confirm your attendance.

Sent via PLANGO - AI Workspace
    ''');

    final Uri emailUri = Uri.parse(
        'https://compose.mail.yahoo.com/?to=$emails&subject=$subject&body=$body');

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open Yahoo Mail!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF4FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEAF4FB),
        elevation: 0,
        title: const Text(
          'Schedule Meeting',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Meeting Title
            const Text(
              'Meeting Title',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'e.g. Project Review with Client',
                prefixIcon: const Icon(Icons.title,
                    color: Color(0xFF00BCD4)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Date & Time Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Date',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2028),
                          );
                          if (picked != null) {
                            setState(() => _selectedDate = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today,
                                  color: Color(0xFF00BCD4), size: 18),
                              const SizedBox(width: 8),
                              Text(
                                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Time',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _selectedTime,
                          );
                          if (picked != null) {
                            setState(() => _selectedTime = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time,
                                  color: Color(0xFF00BCD4), size: 18),
                              const SizedBox(width: 8),
                              Text(
                                _selectedTime.format(context),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Your Timezone
            const Text(
              'Your Timezone',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedTimezone,
                  isExpanded: true,
                  items: _timezones.map((tz) {
                    return DropdownMenuItem(
                      value: tz,
                      child: Text(
                        '${tz.split('/').last} - ${_timezoneOffsets[tz] ?? ''}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) =>
                      setState(() => _selectedTimezone = val!),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Location
            const Text(
              'Location / Meeting Link',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                hintText: 'e.g. Zoom link or Office address',
                prefixIcon: const Icon(Icons.location_on,
                    color: Color(0xFF00BCD4)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Description
            const Text(
              'Description',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Meeting agenda or notes...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Attendees Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Attendees',
                  style: TextStyle(
                    fontSize: 18,
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
                  onPressed: _addAttendee,
                  icon: const Icon(Icons.person_add,
                      color: Colors.white, size: 18),
                  label: const Text(
                    'Add',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Attendees List with time conversion
            if (_attendees.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.people_outline, color: Colors.grey),
                    SizedBox(width: 12),
                    Text(
                      'No attendees yet. Tap Add!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            else
              ..._attendees.asMap().entries.map((entry) {
                final i = entry.key;
                final attendee = entry.value;
                final convertedTime = _convertTime(
                    _selectedTime,
                    _selectedTimezone,
                    attendee['timezone']!);
                final tzLabel =
                    _timezoneOffsets[attendee['timezone']] ?? '';
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 6),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF4FB),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.person,
                            color: Color(0xFF00BCD4)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              attendee['name']!,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              attendee['email']!,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '🕐 $convertedTime $tzLabel',
                              style: const TextStyle(
                                color: Color(0xFF00BCD4),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red, size: 20),
                        onPressed: () {
                          setState(() => _attendees.removeAt(i));
                        },
                      ),
                    ],
                  ),
                );
              }),

            const SizedBox(height: 24),

            // Send Via Section
            const Text(
              'Send Invite Via',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // Gmail Button
            _SendButton(
              icon: Icons.mail,
              label: 'Send via Gmail',
              color: Colors.red,
              onTap: _sendViaGmail,
            ),
            const SizedBox(height: 10),

            // Outlook Button
            _SendButton(
              icon: Icons.email,
              label: 'Send via Outlook',
              color: Colors.blue,
              onTap: _sendViaOutlook,
            ),
            const SizedBox(height: 10),

            // Yahoo Button
            _SendButton(
              icon: Icons.alternate_email,
              label: 'Send via Yahoo Mail',
              color: Colors.purple,
              onTap: _sendViaYahoo,
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SendButton({
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 6),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
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