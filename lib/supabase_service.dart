import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final _client = Supabase.instance.client;

  // Get current user ID
  static String? get currentUserId => _client.auth.currentUser?.id;

  // ==================== TASKS ====================

  // Load all tasks for current user
  static Future<List<Map<String, dynamic>>> getTasks() async {
    try {
      final response = await _client
          .from('tasks')
          .select()
          .eq('user_id', currentUserId!)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting tasks: $e');
      return [];
    }
  }

  // Add a new task
  static Future<bool> addTask({
    required String title,
    required String priority,
  }) async {
    try {
      await _client.from('tasks').insert({
        'user_id': currentUserId,
        'title': title,
        'priority': priority,
        'done': false,
      });
      return true;
    } catch (e) {
      print('Error adding task: $e');
      return false;
    }
  }

  // Update task (mark done/undone)
  static Future<bool> updateTask({
    required String id,
    required bool done,
    required String priority,
  }) async {
    try {
      await _client.from('tasks').update({
        'done': done,
        'priority': priority,
      }).eq('id', id);
      return true;
    } catch (e) {
      print('Error updating task: $e');
      return false;
    }
  }

  // Delete a task
  static Future<bool> deleteTask(String id) async {
    try {
      await _client.from('tasks').delete().eq('id', id);
      return true;
    } catch (e) {
      print('Error deleting task: $e');
      return false;
    }
  }

  // ==================== NOTES ====================

  // Load all notes for current user
  static Future<List<Map<String, dynamic>>> getNotes() async {
    try {
      final response = await _client
          .from('notes')
          .select()
          .eq('user_id', currentUserId!)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting notes: $e');
      return [];
    }
  }

  // Add a new note
  static Future<bool> addNote({
    required String title,
    required String content,
    String type = 'note',
    String? meetingLink,
    String? meetingPlatform,
  }) async {
    try {
      await _client.from('notes').insert({
        'user_id': currentUserId,
        'title': title,
        'content': {
          'text': content,
          'type': type,
          'meeting_link': meetingLink,
          'meeting_platform': meetingPlatform,
        },
        'tags': [type],
      });
      return true;
    } catch (e) {
      print('Error adding note: $e');
      return false;
    }
  }

  // Delete a note
  static Future<bool> deleteNote(String id) async {
    try {
      await _client.from('notes').delete().eq('id', id);
      return true;
    } catch (e) {
      print('Error deleting note: $e');
      return false;
    }
  }

  // ==================== EVENTS ====================

  // Load all events for current user
  static Future<List<Map<String, dynamic>>> getEvents() async {
    try {
      final response = await _client
          .from('events')
          .select()
          .eq('user_id', currentUserId!)
          .order('event_date', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting events: $e');
      return [];
    }
  }

  // Add a new event
  static Future<bool> addEvent({
    required String title,
    required String description,
    required DateTime eventDate,
    required String eventType,
  }) async {
    try {
      await _client.from('events').insert({
        'user_id': currentUserId,
        'title': title,
        'description': description,
        'event_date':
            '${eventDate.year}-${eventDate.month.toString().padLeft(2, '0')}-${eventDate.day.toString().padLeft(2, '0')}',
        'event_type': eventType,
      });
      return true;
    } catch (e) {
      print('Error adding event: $e');
      return false;
    }
  }

  // Delete an event
  static Future<bool> deleteEvent(String id) async {
    try {
      await _client.from('events').delete().eq('id', id);
      return true;
    } catch (e) {
      print('Error deleting event: $e');
      return false;
    }
  }

  // ==================== PROFILE ====================

  // Get user profile
  static Future<Map<String, dynamic>?> getProfile() async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', currentUserId!)
          .single();
      return response;
    } catch (e) {
      print('Error getting profile: $e');
      return null;
    }
  }

  // Create or update profile
  static Future<bool> upsertProfile({
    required String fullName,
  }) async {
    try {
      await _client.from('profiles').upsert({
        'id': currentUserId,
        'full_name': fullName,
        'updated_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('Error upserting profile: $e');
      return false;
    }
  }

  // ==================== AUTH ====================

  // Sign out
  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Get current user
  static User? get currentUser => _client.auth.currentUser;

  // Get current user name
  static String get currentUserName {
    final user = _client.auth.currentUser;
    return user?.userMetadata?['full_name'] ?? 'User';
  }

  // Get current user email
  static String get currentUserEmail {
    return _client.auth.currentUser?.email ?? '';
  }
}