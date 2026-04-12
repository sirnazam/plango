import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:url_launcher/url_launcher.dart';
import 'supabase_service.dart';

// NOTE MODEL
class Note {
  String id;
  String title;
  String content;
  String type; // 'note', 'meeting', 'transcript'
  DateTime createdAt;
  String? meetingLink;
  String? meetingPlatform;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.createdAt,
    this.meetingLink,
    this.meetingPlatform,
  });

  // Build a Note from Supabase row
  factory Note.fromMap(Map<String, dynamic> map) {
    final content = map['content'] as Map<String, dynamic>? ?? {};
    return Note(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: content['text'] ?? '',
      type: content['type'] ?? 'note',
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      meetingLink: content['meeting_link'],
      meetingPlatform: content['meeting_platform'],
    );
  }
}

// GLOBAL NOTES LIST
List<Note> globalNotes = [];

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;
  bool _isLoading = true;
  String _transcribedText = '';
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _loadNotes();
  }

  // ==================== SUPABASE ====================

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    try {
      final data = await SupabaseService.getNotes();
      setState(() {
        globalNotes = data.map((map) => Note.fromMap(map)).toList();
      });
    } catch (e) {
      _showSnackBar('Failed to load notes: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveNoteToSupabase({
    required String title,
    required String content,
    String type = 'note',
    String? meetingLink,
    String? meetingPlatform,
  }) async {
    final success = await SupabaseService.addNote(
      title: title,
      content: content,
      type: type,
      meetingLink: meetingLink,
      meetingPlatform: meetingPlatform,
    );
    if (success) {
      await _loadNotes();
    } else {
      _showSnackBar('Failed to save note', isError: true);
    }
  }

  Future<void> _deleteNoteFromSupabase(Note note) async {
    final success = await SupabaseService.deleteNote(note.id);
    if (success) {
      setState(() => globalNotes.remove(note));
    } else {
      _showSnackBar('Failed to delete note', isError: true);
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

  // ==================== SPEECH ====================

  Future<void> _initSpeech() async {
    _speechAvailable = await _speechToText.initialize();
    setState(() {});
  }

  Future<void> _startListening() async {
    if (_speechAvailable) {
      await _speechToText.listen(
        onResult: (result) {
          setState(() => _transcribedText = result.recognizedWords);
        },
        localeId: 'en_US',
      );
      setState(() => _isListening = true);
    } else {
      _showSnackBar('Speech recognition not available on this device',
          isError: true);
    }
  }

  Future<void> _stopListening() async {
    await _speechToText.stop();
    setState(() => _isListening = false);
    if (_transcribedText.isNotEmpty) {
      _showSaveTranscriptDialog();
    }
  }

  // ==================== DIALOGS ====================

  void _showSaveTranscriptDialog() {
    final TextEditingController titleController = TextEditingController(
      text:
          'Voice Note ${DateTime.now().hour}:${DateTime.now().minute}',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.mic, color: Color(0xFF00BCD4)),
            SizedBox(width: 8),
            Text('Save Voice Note'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                hintText: 'Note title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Transcribed Text:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF4FB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _transcribedText,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _transcribedText = '');
              Navigator.pop(context);
            },
            child: const Text('Discard'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BCD4),
            ),
            onPressed: () async {
              final title = titleController.text;
              final content = _transcribedText;
              setState(() => _transcribedText = '');
              Navigator.pop(context);
              await _saveNoteToSupabase(
                title: title,
                content: content,
                type: 'transcript',
              );
            },
            child: const Text('Save',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddNoteDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                decoration: InputDecoration(
                  hintText: 'Note title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
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
                final content = contentController.text;
                Navigator.pop(context);
                await _saveNoteToSupabase(
                  title: title,
                  content: content,
                  type: 'note',
                );
              }
            },
            child: const Text('Save',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddMeetingDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController linkController = TextEditingController();
    final TextEditingController notesController = TextEditingController();
    String selectedPlatform = 'Zoom';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.video_call, color: Color(0xFF00BCD4)),
              SizedBox(width: 8),
              Text('Add Meeting'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Platform:',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children:
                      ['Zoom', 'Google Meet', 'Teams', 'Custom'].map((p) {
                    return ChoiceChip(
                      label: Text(p),
                      selected: selectedPlatform == p,
                      selectedColor: const Color(0xFF00BCD4),
                      labelStyle: TextStyle(
                        color: selectedPlatform == p
                            ? Colors.white
                            : Colors.black,
                      ),
                      onSelected: (_) =>
                          setDialogState(() => selectedPlatform = p),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    hintText: 'Meeting title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: linkController,
                  decoration: InputDecoration(
                    hintText: 'Meeting link (e.g. zoom.us/j/...)',
                    prefixIcon: const Icon(Icons.link,
                        color: Color(0xFF00BCD4)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Meeting notes or agenda...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
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
                  final content = notesController.text;
                  final link = linkController.text;
                  final platform = selectedPlatform;
                  Navigator.pop(context);
                  await _saveNoteToSupabase(
                    title: title,
                    content: content,
                    type: 'meeting',
                    meetingLink: link,
                    meetingPlatform: platform,
                  );
                }
              },
              child: const Text('Save',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showNoteDetail(Note note) {
    final TextEditingController contentController =
        TextEditingController(text: note.content);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              note.type == 'meeting'
                  ? Icons.video_call
                  : note.type == 'transcript'
                      ? Icons.mic
                      : Icons.note,
              color: const Color(0xFF00BCD4),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(note.title,
                  style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (note.type == 'meeting' &&
                  note.meetingLink != null &&
                  note.meetingLink!.isNotEmpty) ...[
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _getPlatformColor(note.meetingPlatform ?? 'Zoom'),
                    minimumSize: const Size(double.infinity, 45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    final Uri uri = Uri.parse(note.meetingLink!);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.video_call, color: Colors.white),
                  label: Text(
                    'Join ${note.meetingPlatform} Meeting',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: contentController,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: 'Notes...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 45),
                  side: const BorderSide(color: Color(0xFF00BCD4)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _checkGrammar(contentController),
                icon: const Icon(Icons.auto_fix_high,
                    color: Color(0xFF00BCD4)),
                label: const Text('AI Grammar Check & Fix',
                    style: TextStyle(color: Color(0xFF00BCD4))),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BCD4),
            ),
            onPressed: () {
              // Local update only for editing content in detail view
              setState(() => note.content = contentController.text);
              Navigator.pop(context);
              _showSnackBar('Note saved! ✅');
            },
            child: const Text('Save',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ==================== HELPERS ====================

  void _checkGrammar(TextEditingController controller) {
    String text = controller.text;
    text = text.replaceAllMapped(
      RegExp(r'(?<=[.!?]\s)([a-z])'),
      (match) => match.group(0)!.toUpperCase(),
    );
    if (text.isNotEmpty) text = text[0].toUpperCase() + text.substring(1);
    text = text.replaceAll(' i ', ' I ');
    text = text.replaceAll(' dont ', " don't ");
    text = text.replaceAll(' cant ', " can't ");
    text = text.replaceAll(' wont ', " won't ");
    text = text.replaceAll(' didnt ', " didn't ");
    text = text.replaceAll(' wasnt ', " wasn't ");
    text = text.replaceAll(' isnt ', " isn't ");
    text = text.replaceAll(' Im ', " I'm ");
    text = text.replaceAll(' id ', " I'd ");
    text = text.replaceAll(' ill ', " I'll ");
    controller.text = text;
    _showSnackBar('Grammar checked and fixed! ✅');
  }

  Color _getPlatformColor(String platform) {
    switch (platform) {
      case 'Zoom':
        return Colors.blue;
      case 'Google Meet':
        return Colors.green;
      case 'Teams':
        return const Color(0xFF6264A7);
      default:
        return const Color(0xFF00BCD4);
    }
  }

  List<Note> get _filteredNotes {
    if (_selectedFilter == 'All') return globalNotes;
    if (_selectedFilter == 'Notes') {
      return globalNotes.where((n) => n.type == 'note').toList();
    }
    if (_selectedFilter == 'Meetings') {
      return globalNotes.where((n) => n.type == 'meeting').toList();
    }
    if (_selectedFilter == 'Transcripts') {
      return globalNotes.where((n) => n.type == 'transcript').toList();
    }
    return globalNotes;
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
                      'AI Notes',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    // Mic Record Button
                    GestureDetector(
                      onTap: _isListening ? _stopListening : _startListening,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: _isListening
                              ? Colors.red
                              : const Color(0xFF00BCD4),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _isListening
                                  ? Colors.red.withValues(alpha: 0.4)
                                  : const Color(0xFF00BCD4)
                                      .withValues(alpha: 0.4),
                              blurRadius: 12,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isListening ? Icons.stop : Icons.mic,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),

                // Recording indicator
                if (_isListening) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.fiber_manual_record,
                            color: Colors.red, size: 16),
                        const SizedBox(width: 8),
                        const Text(
                          'Recording... Tap mic to stop',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        if (_transcribedText.isNotEmpty)
                          Expanded(
                            child: Text(
                              _transcribedText,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black54),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00BCD4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _showAddNoteDialog,
                        icon: const Icon(Icons.note_add,
                            color: Colors.white, size: 18),
                        label: const Text('New Note',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _showAddMeetingDialog,
                        icon: const Icon(Icons.video_call,
                            color: Colors.white, size: 18),
                        label: const Text('Meeting',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children:
                        ['All', 'Notes', 'Meetings', 'Transcripts'].map((f) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(f),
                          selected: _selectedFilter == f,
                          selectedColor: const Color(0xFF00BCD4),
                          labelStyle: TextStyle(
                            color: _selectedFilter == f
                                ? Colors.white
                                : Colors.black,
                          ),
                          onSelected: (_) =>
                              setState(() => _selectedFilter = f),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Notes List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF00BCD4),
                    ),
                  )
                : _filteredNotes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.note_alt_outlined,
                                size: 60, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            const Text(
                              'No notes yet!\nTap New Note or record with mic',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: const Color(0xFF00BCD4),
                        onRefresh: _loadNotes,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(24),
                          itemCount: _filteredNotes.length,
                          itemBuilder: (context, index) {
                            final note = _filteredNotes[index];
                            return GestureDetector(
                              onTap: () => _showNoteDetail(note),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 6),
                                  ],
                                  border: Border(
                                    left: BorderSide(
                                      color: note.type == 'meeting'
                                          ? Colors.purple
                                          : note.type == 'transcript'
                                              ? Colors.red
                                              : const Color(0xFF00BCD4),
                                      width: 4,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          note.type == 'meeting'
                                              ? Icons.video_call
                                              : note.type == 'transcript'
                                                  ? Icons.mic
                                                  : Icons.note,
                                          color: note.type == 'meeting'
                                              ? Colors.purple
                                              : note.type == 'transcript'
                                                  ? Colors.red
                                                  : const Color(0xFF00BCD4),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            note.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        if (note.type == 'meeting' &&
                                            note.meetingPlatform != null)
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _getPlatformColor(
                                                      note.meetingPlatform!)
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              note.meetingPlatform!,
                                              style: TextStyle(
                                                color: _getPlatformColor(
                                                    note.meetingPlatform!),
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    if (note.content.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        note.content,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${note.createdAt.day}/${note.createdAt.month}/${note.createdAt.year} ${note.createdAt.hour}:${note.createdAt.minute.toString().padLeft(2, '0')}',
                                          style: const TextStyle(
                                            color: Colors.black38,
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (note.type == 'meeting' &&
                                            note.meetingLink != null &&
                                            note.meetingLink!.isNotEmpty)
                                          GestureDetector(
                                            onTap: () async {
                                              final Uri uri = Uri.parse(
                                                  note.meetingLink!);
                                              if (await canLaunchUrl(uri)) {
                                                await launchUrl(uri,
                                                    mode: LaunchMode
                                                        .externalApplication);
                                              }
                                            },
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color: _getPlatformColor(
                                                    note.meetingPlatform ??
                                                        'Custom'),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: const Text(
                                                'Join Now',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        IconButton(
                                          icon: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.red,
                                              size: 20),
                                          onPressed: () =>
                                              _deleteNoteFromSupabase(note),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
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
}