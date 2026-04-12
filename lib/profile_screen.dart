import 'supabase_service.dart';
import 'signin_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notifications = true;
  bool _darkMode = false;
  bool _aiSuggestions = true;
  String _userName = '';
  String _userEmail = '';
  int _tasksDone = 0;
  int _tripsPlanned = 0;
  int _aiNotes = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final user = SupabaseService.currentUser;
      if (user == null) return;

      // Load profile, tasks and notes in parallel
      final results = await Future.wait([
        SupabaseService.getProfile(),
        SupabaseService.getTasks(),
        SupabaseService.getNotes(),
      ]);

      final profile = results[0] as Map<String, dynamic>?;
      final tasks = results[1] as List<Map<String, dynamic>>;
      final notes = results[2] as List<Map<String, dynamic>>;

      setState(() {
        _userName = profile?['full_name'] ?? user.email ?? 'User';
        _userEmail = user.email ?? '';
        _tasksDone = tasks.where((t) => t['done'] == true).length;
        _aiNotes = notes.length;
        _tripsPlanned = 3; // static for now
      });
    } catch (e) {
      // use defaults silently
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    // Show confirmation dialog first
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await SupabaseService.signOut();
      if (mounted) {
        // Clear entire navigation stack and go to SignIn
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SignInScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign out failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _darkMode ? ThemeData.dark() : ThemeData.light(),
      home: Scaffold(
        backgroundColor:
            _darkMode ? const Color(0xFF121212) : const Color(0xFFEAF4FB),
        appBar: AppBar(
          backgroundColor:
              _darkMode ? const Color(0xFF121212) : const Color(0xFFEAF4FB),
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back,
                color: _darkMode ? Colors.white : Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Profile',
            style: TextStyle(
              color: _darkMode ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF00BCD4)),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00BCD4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.person,
                          color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 12),

                    // Name & Email
                    Text(
                      _userName,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _darkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _userEmail,
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            _darkMode ? Colors.white54 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Edit Profile Button
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF00BCD4)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProfileScreen(
                              currentName: _userName,
                              currentEmail: _userEmail,
                              onSave: (name, email) {
                                setState(() {
                                  _userName = name;
                                  _userEmail = email;
                                });
                              },
                            ),
                          ),
                        );
                        // Reload in case name was changed
                        _loadStats();
                      },
                      child: const Text(
                        'Edit Profile',
                        style: TextStyle(color: Color(0xFF00BCD4)),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Stats Row
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.check_circle,
                            iconColor: Colors.green,
                            value: '$_tasksDone',
                            label: 'Tasks Done',
                            darkMode: _darkMode,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.flight,
                            iconColor: Colors.orange,
                            value: '$_tripsPlanned',
                            label: 'Trips Planned',
                            darkMode: _darkMode,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.mic,
                            iconColor: Colors.purple,
                            value: '$_aiNotes',
                            label: 'AI Notes',
                            darkMode: _darkMode,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Preferences
                    _SectionHeader(
                        title: 'Preferences', darkMode: _darkMode),
                    const SizedBox(height: 10),

                    _ToggleRow(
                      icon: Icons.notifications_outlined,
                      label: 'Notifications',
                      value: _notifications,
                      darkMode: _darkMode,
                      onChanged: (val) =>
                          setState(() => _notifications = val),
                    ),
                    const SizedBox(height: 8),
                    _ToggleRow(
                      icon: Icons.dark_mode_outlined,
                      label: 'Dark Mode',
                      value: _darkMode,
                      darkMode: _darkMode,
                      onChanged: (val) =>
                          setState(() => _darkMode = val),
                    ),
                    const SizedBox(height: 8),
                    _ToggleRow(
                      icon: Icons.auto_awesome_outlined,
                      label: 'AI Suggestions',
                      value: _aiSuggestions,
                      darkMode: _darkMode,
                      onChanged: (val) =>
                          setState(() => _aiSuggestions = val),
                    ),

                    const SizedBox(height: 24),

                    // Account
                    _SectionHeader(title: 'Account', darkMode: _darkMode),
                    const SizedBox(height: 10),

                    _ArrowRow(
                      icon: Icons.lock_outline,
                      label: 'Change Password',
                      darkMode: _darkMode,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const ChangePasswordScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    _ArrowRow(
                      icon: Icons.help_outline,
                      label: 'Help & Support',
                      darkMode: _darkMode,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HelpScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    _ArrowRow(
                      icon: Icons.privacy_tip_outlined,
                      label: 'Privacy Policy',
                      darkMode: _darkMode,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PrivacyScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // Sign Out
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _signOut,
                        icon: const Icon(Icons.logout, color: Colors.white),
                        label: const Text(
                          'Sign Out',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }
}

// ── EDIT PROFILE SCREEN ──
class EditProfileScreen extends StatefulWidget {
  final String currentName;
  final String currentEmail;
  final Function(String, String) onSave;

  const EditProfileScreen({
    super.key,
    required this.currentName,
    required this.currentEmail,
    required this.onSave,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _emailController = TextEditingController(text: widget.currentEmail);
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final success = await SupabaseService.upsertProfile(
        fullName: _nameController.text,
      );
      if (success) {
        widget.onSave(_nameController.text, _emailController.text);
        if (context.mounted) Navigator.pop(context);
      } else {
        throw Exception('Failed to save profile');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF4FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEAF4FB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Edit Profile',
            style: TextStyle(
                color: Colors.black87, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: const Text('Save',
                style: TextStyle(
                    color: Color(0xFF00BCD4),
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF00BCD4),
                borderRadius: BorderRadius.circular(20),
              ),
              child:
                  const Icon(Icons.person, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {},
              child: const Text('Change Photo',
                  style: TextStyle(color: Color(0xFF00BCD4))),
            ),
            const SizedBox(height: 24),
            _InputField(
                label: 'Full Name', controller: _nameController),
            const SizedBox(height: 16),
            _InputField(
                label: 'Email',
                controller: _emailController,
                enabled: false),
            const SizedBox(height: 32),
            if (_isSaving)
              const CircularProgressIndicator(color: Color(0xFF00BCD4))
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BCD4),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _save,
                  child: const Text('Save Changes',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── CHANGE PASSWORD SCREEN ──
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;

  Future<void> _changePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Passwords do not match'),
            backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      await Supabase.instance.client.auth
          .updateUser(UserAttributes(
              password: _newPasswordController.text));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Password updated successfully!'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF4FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEAF4FB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Change Password',
            style: TextStyle(
                color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.lock_outline,
                size: 60, color: Color(0xFF00BCD4)),
            const SizedBox(height: 24),
            TextField(
              controller: _newPasswordController,
              obscureText: _obscureNew,
              decoration: InputDecoration(
                labelText: 'New Password',
                prefixIcon: const Icon(Icons.lock_outline,
                    color: Color(0xFF00BCD4)),
                suffixIcon: IconButton(
                  icon: Icon(_obscureNew
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () =>
                      setState(() => _obscureNew = !_obscureNew),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                prefixIcon: const Icon(Icons.lock_outline,
                    color: Color(0xFF00BCD4)),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () => setState(
                      () => _obscureConfirm = !_obscureConfirm),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 32),
            if (_isSaving)
              const CircularProgressIndicator(color: Color(0xFF00BCD4))
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BCD4),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _changePassword,
                  child: const Text('Update Password',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── HELP SCREEN ──
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF4FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEAF4FB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Help & Support',
            style: TextStyle(
                color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.help_outline,
              size: 60, color: Color(0xFF00BCD4)),
          const SizedBox(height: 16),
          const Text('Frequently Asked Questions',
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          _FaqItem(
            question: 'How do I add a task?',
            answer:
                'Go to the Tasks tab and tap the Add Task button. Fill in the title and priority then tap Add.',
          ),
          _FaqItem(
            question: 'How does AI Notes work?',
            answer:
                'Go to the Notes tab and tap the mic button. Speak your note — PLANGO will transcribe and summarize it automatically.',
          ),
          _FaqItem(
            question: 'How do I book a flight?',
            answer:
                'Go to the Travel tab, tap Book Flight, enter your route and dates then browse results.',
          ),
          _FaqItem(
            question: 'How do I reset my password?',
            answer:
                'Go to Profile → Change Password. Enter your new password and confirm it.',
          ),
          const SizedBox(height: 24),
          const Text('Still need help?',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BCD4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {},
            icon: const Icon(Icons.email_outlined, color: Colors.white),
            label: const Text('Contact Support',
                style: TextStyle(color: Colors.white, fontSize: 15)),
          ),
        ],
      ),
    );
  }
}

// ── PRIVACY SCREEN ──
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF4FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEAF4FB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Privacy Policy',
            style: TextStyle(
                color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          Icon(Icons.privacy_tip_outlined,
              size: 60, color: Color(0xFF00BCD4)),
          SizedBox(height: 16),
          Text('Privacy Policy',
              style:
                  TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          SizedBox(height: 8),
          Text('Last updated: April 2026',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center),
          SizedBox(height: 24),
          _PrivacySection(
            title: '1. Data We Collect',
            body:
                'PLANGO collects your name, email, tasks, notes, and travel plans to provide our service. We do not sell your data to third parties.',
          ),
          _PrivacySection(
            title: '2. How We Use Your Data',
            body:
                'Your data is used to power AI features, sync your tasks and notes, and personalize your travel recommendations.',
          ),
          _PrivacySection(
            title: '3. Data Storage',
            body:
                'Your data is securely stored using Supabase with industry-standard encryption. All data is backed up regularly.',
          ),
          _PrivacySection(
            title: '4. Your Rights',
            body:
                'You can request deletion of your account and all associated data at any time by contacting our support team.',
          ),
          _PrivacySection(
            title: '5. Contact',
            body: 'For privacy concerns, contact us at privacy@plango.app',
          ),
        ],
      ),
    );
  }
}

// ── HELPER WIDGETS ──

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final bool darkMode;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.darkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: darkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: darkMode ? Colors.white : Colors.black87)),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: darkMode ? Colors.white54 : Colors.black54),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool darkMode;

  const _SectionHeader({required this.title, required this.darkMode});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: darkMode ? Colors.white : Colors.black87,
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final bool darkMode;
  final Function(bool) onChanged;

  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.darkMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: darkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00BCD4), size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 15,
                    color: darkMode ? Colors.white : Colors.black87)),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF00BCD4),
          ),
        ],
      ),
    );
  }
}

class _ArrowRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool darkMode;
  final VoidCallback onTap;

  const _ArrowRow({
    required this.icon,
    required this.label,
    required this.darkMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: darkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF00BCD4), size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 15,
                      color:
                          darkMode ? Colors.white : Colors.black87)),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;

  const _InputField({
    required this.label,
    required this.controller,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade100,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: Color(0xFF00BCD4), width: 2),
        ),
      ),
    );
  }
}

class _FaqItem extends StatefulWidget {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: ExpansionTile(
        title: Text(widget.question,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(widget.answer,
                style: const TextStyle(
                    color: Colors.black54, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _PrivacySection extends StatelessWidget {
  final String title;
  final String body;

  const _PrivacySection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(body,
              style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  height: 1.6)),
        ],
      ),
    );
  }
}