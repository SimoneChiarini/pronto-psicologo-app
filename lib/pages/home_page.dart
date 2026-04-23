import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/image_picker_field.dart';
import '../widgets/tinder_swiper.dart';

String _psychName(Map<String, dynamic> psych) {
  final u = psych['user'] as Map<String, dynamic>? ?? {};
  final fn = (u['firstName'] as String? ?? '').trim();
  final ln = (u['lastName'] as String? ?? '').trim();
  final full = '$fn $ln'.trim();
  return full.isNotEmpty ? full : psych['alboCode'] as String? ?? 'Psicologo';
}

// ─────────────────────────────────────────────────────────────
// ROOT
// ─────────────────────────────────────────────────────────────

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _authService = AuthService();
  Map<String, dynamic>? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _loadProfile(); }

  Future<void> _loadProfile() async {
    try {
      final p = await _authService.getProfile();
      setState(() { _profile = p; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(backgroundColor: AppColors.bg, body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(_error!, style: const TextStyle(color: AppColors.error)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            child: const Text('Torna al login'),
          ),
        ])),
      );
    }
    final role = _profile?['role'] ?? '';
    if (role == 'ADMIN') return _AdminHome(onLogout: _logout);
    if (role == 'PSYCHOLOGIST') return _PsychologistHome(profile: _profile!, onLogout: _logout);
    return _UserHome(profile: _profile!, onLogout: _logout);
  }
}

// ─────────────────────────────────────────────────────────────
// GLASS NAVIGATION RAIL
// ─────────────────────────────────────────────────────────────

class _GlassNavRail extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationRailDestination> destinations;
  final Widget? leading;
  final Widget? trailing;

  const _GlassNavRail({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 700;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.glassBg,
            border: Border(right: BorderSide(color: AppColors.glassBorder)),
          ),
          child: NavigationRail(
            backgroundColor: Colors.transparent,
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            useIndicator: true,
            indicatorColor: Colors.white.withOpacity(0.18),
            selectedIconTheme: const IconThemeData(color: AppColors.textPrimary, size: 22),
            unselectedIconTheme: const IconThemeData(color: AppColors.textTertiary, size: 22),
            selectedLabelTextStyle: const TextStyle(
              color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600,
            ),
            unselectedLabelTextStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
            labelType: isWide ? NavigationRailLabelType.all : NavigationRailLabelType.none,
            minWidth: isWide ? 130 : 64,
            leading: leading,
            trailing: trailing,
            destinations: destinations,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SHARED HELPERS
// ─────────────────────────────────────────────────────────────

Widget _emptyState({required IconData icon, required String title, String? subtitle}) {
  return Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 72, color: AppColors.textTertiary),
      const SizedBox(height: 16),
      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
      if (subtitle != null) ...[
        const SizedBox(height: 8),
        Text(subtitle, textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textTertiary, fontSize: 14, height: 1.5)),
      ],
    ]),
  );
}

Widget _errorState(String error, VoidCallback onRetry) {
  return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
    const SizedBox(height: 12),
    Text(error, style: const TextStyle(color: AppColors.error, fontSize: 13), textAlign: TextAlign.center),
    const SizedBox(height: 16),
    OutlinedButton(onPressed: onRetry, child: const Text('Riprova')),
  ]));
}

Widget _searchBar(TextEditingController ctrl, String hint) {
  return TextField(
    controller: ctrl,
    decoration: InputDecoration(
      hintText: hint,
      prefixIcon: const Icon(Icons.search_rounded),
      suffixIcon: ctrl.text.isNotEmpty
          ? IconButton(icon: const Icon(Icons.clear_rounded), onPressed: ctrl.clear)
          : null,
      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
// VISTA UTENTE
// ─────────────────────────────────────────────────────────────

class _UserHome extends StatefulWidget {
  final Map<String, dynamic> profile;
  final VoidCallback onLogout;
  const _UserHome({required this.profile, required this.onLogout});

  @override
  State<_UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<_UserHome> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final firstName = widget.profile['firstName'] as String? ?? '';
    final userId    = widget.profile['userId'] as String;
    final isWide    = MediaQuery.of(context).size.width >= 700;

    final pages = [
      const _AskQuestionTab(),
      _MyAnswersTab(userId: userId),
      _ConversationsTab(userId: userId, role: 'USER'),
      const _PsychologistsListTab(),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: AppBackground(
        child: SafeArea(
          child: Row(
            children: [
              _GlassNavRail(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (i) => setState(() => _selectedIndex = i),
                leading: _NavHeader(name: firstName.isNotEmpty ? firstName : 'ProntoPsicologo', isWide: isWide),
                trailing: _NavTrailing(onLogout: widget.onLogout),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.help_outline_rounded),
                    selectedIcon: Icon(Icons.help_rounded),
                    label: Text('Domanda'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.style_outlined),
                    selectedIcon: Icon(Icons.style_rounded),
                    label: Text('Risposte'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.chat_bubble_outline_rounded),
                    selectedIcon: Icon(Icons.chat_bubble_rounded),
                    label: Text('Chat'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.people_outline_rounded),
                    selectedIcon: Icon(Icons.people_rounded),
                    label: Text('Psicologi'),
                  ),
                ],
              ),
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: pages,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// VISTA PSICOLOGO
// ─────────────────────────────────────────────────────────────

class _PsychologistHome extends StatefulWidget {
  final Map<String, dynamic> profile;
  final VoidCallback onLogout;
  const _PsychologistHome({required this.profile, required this.onLogout});

  @override
  State<_PsychologistHome> createState() => _PsychologistHomeState();
}

class _PsychologistHomeState extends State<_PsychologistHome> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final userId = widget.profile['userId'] as String;
    final isWide = MediaQuery.of(context).size.width >= 700;

    final pages = [
      _MyProfileTab(userId: userId),
      const _QuestionsForPsychTab(),
      _ConversationsTab(userId: userId, role: 'PSYCHOLOGIST'),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: AppBackground(
        child: SafeArea(
          child: Row(
            children: [
              _GlassNavRail(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (i) => setState(() => _selectedIndex = i),
                leading: _NavHeader(name: 'Psicologo', isWide: isWide),
                trailing: _NavTrailing(onLogout: widget.onLogout),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.person_outline_rounded),
                    selectedIcon: Icon(Icons.person_rounded),
                    label: Text('Profilo'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.question_answer_outlined),
                    selectedIcon: Icon(Icons.question_answer_rounded),
                    label: Text('Domande'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.chat_bubble_outline_rounded),
                    selectedIcon: Icon(Icons.chat_bubble_rounded),
                    label: Text('Chat'),
                  ),
                ],
              ),
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: pages,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// VISTA ADMIN
// ─────────────────────────────────────────────────────────────

class _AdminHome extends StatefulWidget {
  final VoidCallback onLogout;
  const _AdminHome({required this.onLogout});

  @override
  State<_AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<_AdminHome> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 700;

    const pages = [
      _AdminQuestionsTab(),
      _AdminConversationsTab(),
      _AdminAnswersTab(),
      _AdminPsychologistsTab(),
      _AdminUsersTab(),
      _AdminSettingsTab(),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: AppBackground(
        child: SafeArea(
          child: Row(
            children: [
              SingleChildScrollView(
                child: IntrinsicHeight(
                  child: _GlassNavRail(
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: (i) => setState(() => _selectedIndex = i),
                    leading: _NavHeader(name: 'Admin', isWide: isWide),
                    trailing: _NavTrailing(onLogout: widget.onLogout),
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.help_outline_rounded),
                        selectedIcon: Icon(Icons.help_rounded),
                        label: Text('Domande'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.chat_bubble_outline_rounded),
                        selectedIcon: Icon(Icons.chat_bubble_rounded),
                        label: Text('Conv.'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.question_answer_outlined),
                        selectedIcon: Icon(Icons.question_answer_rounded),
                        label: Text('Risposte'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.psychology_outlined),
                        selectedIcon: Icon(Icons.psychology_rounded),
                        label: Text('Psicologi'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.people_outline_rounded),
                        selectedIcon: Icon(Icons.people_rounded),
                        label: Text('Utenti'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.settings_outlined),
                        selectedIcon: Icon(Icons.settings_rounded),
                        label: Text('Settings'),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: pages,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// NAV RAIL HELPERS
// ─────────────────────────────────────────────────────────────

class _NavHeader extends StatelessWidget {
  final String name;
  final bool isWide;
  const _NavHeader({required this.name, required this.isWide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: AppColors.glassBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: const Icon(Icons.psychology_rounded, color: AppColors.textPrimary, size: 22),
        ),
        if (isWide) ...[
          const SizedBox(height: 6),
          Text(name,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ]),
    );
  }
}

class _NavTrailing extends StatelessWidget {
  final VoidCallback onLogout;
  const _NavTrailing({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: IconButton(
        icon: const Icon(Icons.logout_rounded, color: AppColors.textTertiary, size: 20),
        tooltip: 'Esci',
        onPressed: onLogout,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TAB: RISPOSTE TINDER
// ─────────────────────────────────────────────────────────────

class _MyAnswersTab extends StatefulWidget {
  final String userId;
  const _MyAnswersTab({required this.userId});
  @override
  State<_MyAnswersTab> createState() => _MyAnswersTabState();
}

class _MyAnswersTabState extends State<_MyAnswersTab> with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>>? _answers;
  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  String get _seenKey => 'seen_answers_${widget.userId}';

  Future<Set<String>> _getSeenIds() async {
    final prefs = await SharedPreferences.getInstance();
    return Set.from(prefs.getStringList(_seenKey) ?? []);
  }

  Future<void> _markSeen(String answerId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_seenKey) ?? [];
    if (!list.contains(answerId)) { list.add(answerId); await prefs.setStringList(_seenKey, list); }
  }

  @override
  void initState() { super.initState(); _load(); }

  Future<Position?> _getLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return null;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return null;
      return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low, timeLimit: const Duration(seconds: 5));
    } catch (_) { return null; }
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final pos = await _getLocation();
      if (pos != null) ApiService().updateMyLocation(pos.latitude, pos.longitude).catchError((_) {});
      final answers = await ApiService().getAnswersForMyQuestions(lat: pos?.latitude, lng: pos?.longitude);
      final seenIds = await _getSeenIds();
      setState(() {
        _answers = answers.where((a) => !seenIds.contains(a['id'] as String)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _onAccepted(Map<String, dynamic> item, Map<String, dynamic> conversation) {
    _markSeen(item['id'] as String);
    final psych    = item['psychologist'] as Map<String, dynamic>? ?? {};
    final question = item['question']    as Map<String, dynamic>? ?? {};
    Navigator.of(context).pushNamed('/conversation', arguments: {
      'conversationId':    conversation['id'] as String,
      'psychologistId':    item['psychologistId'] as String,
      'psychologistLabel': _psychName(psych),
      'userId':            widget.userId,
      'role':              'USER',
      'questionTitle':     question['title'] as String?,
      'answerContent':     item['content'] as String?,
    });
  }

  void _onRejected(Map<String, dynamic> item) => _markSeen(item['id'] as String);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _errorState(_error!, _load);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TinderSwiper(items: _answers ?? [], onAccepted: _onAccepted, onRejected: _onRejected),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TAB: CONVERSAZIONI
// ─────────────────────────────────────────────────────────────

class _ConversationsTab extends StatefulWidget {
  final String userId;
  final String role;
  const _ConversationsTab({required this.userId, required this.role});
  @override
  State<_ConversationsTab> createState() => _ConversationsTabState();
}

class _ConversationsTabState extends State<_ConversationsTab> with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>>? _conversations;
  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await ApiService().getMyConversations();
      setState(() { _conversations = list; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _openConversation(Map<String, dynamic> conv) {
    String psychologistId, psychologistLabel;
    if (widget.role == 'USER') {
      final psych = conv['Psychologist'] as Map<String, dynamic>? ?? {};
      psychologistId = conv['psychologistId'] as String;
      psychologistLabel = _psychName(psych);
    } else {
      final user = conv['User'] as Map<String, dynamic>? ?? {};
      psychologistId = conv['psychologistId'] as String;
      final fn = user['firstName'] as String? ?? '';
      final ln = user['lastName'] as String? ?? '';
      psychologistLabel = fn.isEmpty && ln.isEmpty ? user['email'] ?? 'Utente' : '$fn $ln'.trim();
    }
    Navigator.of(context).pushNamed('/conversation', arguments: {
      'conversationId':    conv['id'] as String,
      'psychologistId':    psychologistId,
      'psychologistLabel': psychologistLabel,
      'userId':            widget.userId,
      'role':              widget.role,
      'questionTitle':     null,
      'answerContent':     null,
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _errorState(_error!, _load);
    if (_conversations == null || _conversations!.isEmpty) {
      return _emptyState(icon: Icons.chat_bubble_outline_rounded, title: 'Nessuna conversazione');
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _conversations!.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final conv = _conversations![i];
          String title;
          String? subtitle;
          String? imageUrl;
          if (widget.role == 'USER') {
            final psych = conv['Psychologist'] as Map<String, dynamic>? ?? {};
            title = _psychName(psych);
            imageUrl = psych['profileImage'] as String?;
            final albo = psych['alboCode'] as String?;
            if (psych['verified'] == true) {
              subtitle = albo != null && albo.isNotEmpty ? '✓ Verificato · Albo: $albo' : '✓ Verificato';
            } else if (albo != null && albo.isNotEmpty) {
              subtitle = 'Albo: $albo';
            }
          } else {
            final user = conv['User'] as Map<String, dynamic>? ?? {};
            final fn = user['firstName'] as String? ?? '';
            final ln = user['lastName'] as String? ?? '';
            title = fn.isEmpty && ln.isEmpty ? user['email'] as String? ?? 'Utente' : '$fn $ln'.trim();
          }
          final updatedAt = conv['updatedAt'] as String?;
          return GlassCard(
            noPadding: true,
            onTap: () => _openConversation(conv),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: CircleAvatar(
                radius: 22,
                backgroundImage: (imageUrl != null && imageUrl.isNotEmpty) ? NetworkImage(imageUrl) : null,
                backgroundColor: AppColors.glassBg,
                child: (imageUrl == null || imageUrl.isEmpty)
                    ? const Icon(Icons.chat_rounded, color: AppColors.textSecondary, size: 20)
                    : null,
              ),
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              subtitle: subtitle != null ? Text(subtitle) : null,
              trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (updatedAt != null)
                  Text(_formatDate(updatedAt), style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                const SizedBox(height: 4),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 18),
              ]),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
        return '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
      }
      return '${dt.day}/${dt.month}';
    } catch (_) { return ''; }
  }
}

// ─────────────────────────────────────────────────────────────
// TAB: FAI UNA DOMANDA
// ─────────────────────────────────────────────────────────────

class _AskQuestionTab extends StatefulWidget {
  const _AskQuestionTab();
  @override
  State<_AskQuestionTab> createState() => _AskQuestionTabState();
}

class _AskQuestionTabState extends State<_AskQuestionTab> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  bool _isAnonymous = false;
  bool _loading = false;

  @override
  void dispose() { _titleCtrl.dispose(); _contentCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ApiService().createQuestion(
        title: _titleCtrl.text.trim(),
        content: _contentCtrl.text.trim(),
        isAnonymous: _isAnonymous,
      );
      if (!mounted) return;
      _titleCtrl.clear(); _contentCtrl.clear();
      setState(() => _isAnonymous = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Domanda inviata con successo!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SizedBox(height: 8),
          const Text('Hai bisogno di supporto?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('Scrivi la tua domanda e uno psicologo vicino a te ti risponderà.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.4)),
          const SizedBox(height: 28),
          GlassCard(
            radius: 20,
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Titolo',
                  hintText: 'Es. Come gestire l\'ansia?',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.isEmpty) ? 'Inserisci un titolo' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _contentCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descrivi la tua situazione',
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                validator: (v) => (v == null || v.isEmpty) ? 'Inserisci il contenuto' : null,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Pubblica in modo anonimo'),
                subtitle: const Text('Il tuo nome non sarà visibile'),
                value: _isAnonymous,
                onChanged: (v) => setState(() => _isAnonymous = v),
                contentPadding: EdgeInsets.zero,
              ),
            ]),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loading ? null : _submit,
            icon: _loading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.bg))
                : const Icon(Icons.send_rounded),
            label: const Text('Invia domanda'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TAB: LISTA PSICOLOGI (GRID QUADRATA)
// ─────────────────────────────────────────────────────────────

class _PsychologistsListTab extends StatefulWidget {
  const _PsychologistsListTab();
  @override
  State<_PsychologistsListTab> createState() => _PsychologistsListTabState();
}

class _PsychologistsListTabState extends State<_PsychologistsListTab> {
  List<Map<String, dynamic>>? _psychologists;
  bool _loading = true;
  String? _error;
  final _searchCtrl = TextEditingController();
  String _query = '';

  // Filtri attivi
  bool? _filterGender;          // null=tutti, true=uomo, false=donna
  final Set<String> _filterSpecs = {};

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text.toLowerCase()));
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await ApiService().getPsychologists();
      setState(() { _psychologists = list; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  int get _activeFilterCount =>
      (_filterGender != null ? 1 : 0) + _filterSpecs.length;

  List<Map<String, dynamic>> get _filtered {
    var list = _psychologists ?? [];
    if (_query.isNotEmpty) {
      list = list.where((p) =>
        (p['alboCode'] as String? ?? '').toLowerCase().contains(_query) ||
        (p['bio'] as String? ?? '').toLowerCase().contains(_query) ||
        (p['address'] as String? ?? '').toLowerCase().contains(_query),
      ).toList();
    }
    if (_filterGender != null) {
      list = list.where((p) => p['isMale'] == _filterGender).toList();
    }
    if (_filterSpecs.isNotEmpty) {
      list = list.where((p) => _filterSpecs.every((s) => p[s] == true)).toList();
    }
    return list;
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<_FilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        initialGender: _filterGender,
        initialSpecs: Set.from(_filterSpecs),
      ),
    );
    if (result != null) {
      setState(() {
        _filterGender = result.gender;
        _filterSpecs..clear()..addAll(result.specs);
      });
    }
  }

  int _crossAxisCount(double width) {
    if (width >= 900) return 3;
    if (width >= 600) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _errorState(_error!, _load);
    final filtered = _filtered;
    final width = MediaQuery.of(context).size.width;
    final cols = _crossAxisCount(width);
    final activeCount = _activeFilterCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Row(children: [
            Expanded(child: _searchBar(_searchCtrl, 'Cerca per albo, bio, indirizzo...')),
            const SizedBox(width: 8),
            // Bottone Filtra con badge
            GestureDetector(
              onTap: _openFilters,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: activeCount > 0
                      ? AppColors.primary.withOpacity(0.2)
                      : AppColors.glassBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: activeCount > 0 ? AppColors.primary : AppColors.glassBorder,
                    width: activeCount > 0 ? 1.5 : 1,
                  ),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.tune_rounded,
                    size: 18,
                    color: activeCount > 0 ? AppColors.primary : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text('Filtra',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: activeCount > 0 ? FontWeight.w600 : FontWeight.normal,
                      color: activeCount > 0 ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                  if (activeCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('$activeCount',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  ],
                ]),
              ),
            ),
          ]),
        ),

        // Chips dei filtri attivi
        if (activeCount > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                if (_filterGender != null)
                  _ActiveChip(
                    label: _filterGender! ? 'Uomo' : 'Donna',
                    onRemove: () => setState(() => _filterGender = null),
                  ),
                ..._filterSpecs.map((s) => _ActiveChip(
                  label: _PsychFilter.specLabels[s] ?? s,
                  onRemove: () => setState(() => _filterSpecs.remove(s)),
                )),
                const SizedBox(width: 4),
                TextButton(
                  onPressed: () => setState(() { _filterGender = null; _filterSpecs.clear(); }),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Azzera tutto', style: TextStyle(fontSize: 12)),
                ),
              ]),
            ),
          ),

        Expanded(
          child: filtered.isEmpty
              ? _emptyState(icon: Icons.psychology_outlined, title: 'Nessuno psicologo trovato')
              : RefreshIndicator(
                  onRefresh: _load,
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: cols == 1 ? 0.85 : 0.75,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) => _PsychSquareCard(p: filtered[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

// Chip filtro attivo rimovibile
class _ActiveChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _ActiveChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.5)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500)),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: onRemove,
          child: const Icon(Icons.close_rounded, size: 14, color: AppColors.primary),
        ),
      ]),
    );
  }
}

// Dati condivisi filtri
class _PsychFilter {
  static const Map<String, String> specLabels = {
    'specAnsia': 'Ansia',
    'specUmore': 'Umore / depressione',
    'specStress': 'Stress / lavoro',
    'specRelazioni': 'Relazioni',
    'specCoppia': 'Coppia',
    'specGenitorialita': 'Genitorialità',
    'specInfanzia': 'Infanzia / adolescenza',
    'specAutostima': 'Autostima',
    'specTrauma': 'Trauma',
    'specLutto': 'Lutto',
    'specSessualita': 'Sessualità',
    'specDisturbiAlimentari': 'Disturbi alimentari',
    'specDipendenze': 'Dipendenze',
    'specNeurodivergenze': 'Neurodivergenze',
  };
}

class _FilterResult {
  final bool? gender;
  final Set<String> specs;
  const _FilterResult({required this.gender, required this.specs});
}

// ─────────────────────────────────────────────────────────────
// FILTER BOTTOM SHEET
// ─────────────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  final bool? initialGender;
  final Set<String> initialSpecs;
  const _FilterSheet({required this.initialGender, required this.initialSpecs});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  bool? _gender;
  late Set<String> _specs;

  @override
  void initState() {
    super.initState();
    _gender = widget.initialGender;
    _specs = Set.from(widget.initialSpecs);
  }

  int get _count => (_gender != null ? 1 : 0) + _specs.length;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomPad),
          decoration: const BoxDecoration(
            color: AppColors.glassBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: AppColors.glassBorder)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Titolo
              Row(children: [
                const Icon(Icons.tune_rounded, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                const Text('Filtra psicologi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const Spacer(),
                if (_count > 0)
                  TextButton(
                    onPressed: () => setState(() { _gender = null; _specs.clear(); }),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('Azzera', style: TextStyle(fontSize: 13)),
                  ),
              ]),
              const SizedBox(height: 16),

              // Sezione Sesso
              _SheetSection(
                icon: Icons.person_outline_rounded,
                label: 'Sesso',
                child: Wrap(spacing: 8, children: [
                  _ChoiceItem(label: 'Tutti', selected: _gender == null,
                    onTap: () => setState(() => _gender = null)),
                  _ChoiceItem(label: 'Uomo', icon: Icons.male_rounded,
                    selected: _gender == true,
                    onTap: () => setState(() => _gender = _gender == true ? null : true)),
                  _ChoiceItem(label: 'Donna', icon: Icons.female_rounded,
                    selected: _gender == false,
                    onTap: () => setState(() => _gender = _gender == false ? null : false)),
                ]),
              ),
              const SizedBox(height: 20),

              // Sezione Specializzazioni
              _SheetSection(
                icon: Icons.psychology_outlined,
                label: 'Aree di specializzazione',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _PsychFilter.specLabels.entries.map((e) {
                    final sel = _specs.contains(e.key);
                    return FilterChip(
                      label: Text(e.value),
                      selected: sel,
                      onSelected: (v) => setState(() {
                        if (v) _specs.add(e.key); else _specs.remove(e.key);
                      }),
                      selectedColor: AppColors.primary.withOpacity(0.22),
                      checkmarkColor: AppColors.primary,
                      labelStyle: TextStyle(
                        fontSize: 13,
                        color: sel ? AppColors.primary : AppColors.textSecondary,
                        fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: sel ? AppColors.primary : AppColors.textTertiary.withOpacity(0.4),
                      ),
                      backgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // Bottone Applica
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, _FilterResult(gender: _gender, specs: _specs)),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: Text(
                    _count == 0 ? 'Mostra tutti' : 'Applica $_count filtri',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetSection extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;
  const _SheetSection({required this.icon, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ]),
      const SizedBox(height: 10),
      child,
    ]);
  }
}

class _ChoiceItem extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;
  const _ChoiceItem({required this.label, this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.textTertiary.withOpacity(0.4),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: selected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 5),
          ],
          Text(label, style: TextStyle(
            fontSize: 13,
            color: selected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          )),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CARD PSICOLOGO QUADRATA
// ─────────────────────────────────────────────────────────────

class _PsychSquareCard extends StatelessWidget {
  final Map<String, dynamic> p;
  const _PsychSquareCard({required this.p});

  Future<void> _handleCall(BuildContext context, String phone) async {
    if (kIsWeb) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Numero di telefono'),
          content: SelectableText(phone, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Chiudi'))],
        ),
      );
    } else {
      final uri = Uri.parse('tel:$phone');
      if (await canLaunchUrl(uri)) await launchUrl(uri);
    }
  }

  void _showReviews(BuildContext context) {
    final psychId = p['id'] as String?;
    if (psychId == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ReviewsSheet(
        psychologistId: psychId,
        psychName: _psychName(p),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl    = p['profileImage'] as String?;
    final hasImage    = imageUrl != null && imageUrl.isNotEmpty;
    final avg         = p['avgRating'];
    final reviewCount = p['reviewCount'] as int? ?? 0;
    final phone       = p['phone'] as String?;

    return GlassCard(
      radius: 18,
      noPadding: true,
      onTap: () => _showReviews(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Immagine (60% card)
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: hasImage
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => _PlaceholderAvatar(),
                    )
                  : _PlaceholderAvatar(),
            ),
          ),
          // Info (40% card)
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(
                        _psychName(p),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (p['verified'] == true)
                      const Icon(Icons.verified_rounded, color: Colors.lightBlueAccent, size: 14),
                  ]),
                  if (p['alboCode'] != null && (p['alboCode'] as String).isNotEmpty)
                    Text(
                      'Albo: ${p['alboCode']}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (p['address'] != null && (p['address'] as String).isNotEmpty)
                    Text(
                      p['address'] as String,
                      style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const Spacer(),
                  Row(children: [
                    if (avg != null) ...[
                      const Icon(Icons.star_rounded, color: AppColors.star, size: 13),
                      const SizedBox(width: 3),
                      Text('$avg ($reviewCount)',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ] else
                      const Text('Nessuna rec.', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                    const Spacer(),
                    if (phone != null && phone.isNotEmpty)
                      GestureDetector(
                        onTap: () => _handleCall(context, phone),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                          child: const Icon(Icons.phone_rounded, size: 14, color: AppColors.textPrimary),
                        ),
                      ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.glassBg,
      child: const Center(
        child: Icon(Icons.person_rounded, size: 56, color: AppColors.textTertiary),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// REVIEWS BOTTOM SHEET
// ─────────────────────────────────────────────────────────────

class _ReviewsSheet extends StatefulWidget {
  final String psychologistId;
  final String psychName;
  const _ReviewsSheet({required this.psychologistId, required this.psychName});
  @override
  State<_ReviewsSheet> createState() => _ReviewsSheetState();
}

class _ReviewsSheetState extends State<_ReviewsSheet> {
  List<Map<String, dynamic>>? _reviews;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final list = await ApiService().getReviewsByPsychologist(widget.psychologistId);
      if (mounted) setState(() { _reviews = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _reviews = []; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, ctrl) => Column(children: [
        const SizedBox(height: 10),
        Container(width: 36, height: 4,
            decoration: BoxDecoration(color: AppColors.glassBorder, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            const Icon(Icons.star_rounded, color: AppColors.star, size: 20),
            const SizedBox(width: 8),
            Text('Recensioni — ${widget.psychName}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ]),
        ),
        const SizedBox(height: 12),
        const Divider(height: 1),
        if (_loading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_reviews == null || _reviews!.isEmpty)
          Expanded(child: _emptyState(icon: Icons.star_outline_rounded, title: 'Nessuna recensione ancora'))
        else
          Expanded(
            child: ListView.separated(
              controller: ctrl,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: _reviews!.length,
              separatorBuilder: (_, __) => const Divider(height: 24),
              itemBuilder: (_, i) {
                final r         = _reviews![i];
                final rating    = r['rating'] as int? ?? 0;
                final comment   = r['comment'] as String?;
                final user      = (r['User'] ?? r['user']) as Map<String, dynamic>? ?? {};
                final firstName = user['firstName'] as String? ?? '';
                final lastName  = user['lastName'] as String? ?? '';
                final date      = r['createdAt'] != null ? DateTime.tryParse(r['createdAt'] as String) : null;
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    ...List.generate(5, (s) => Icon(
                      s < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: AppColors.star, size: 17,
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: Text(
                      '$firstName $lastName'.trim().isEmpty ? 'Utente' : '$firstName $lastName',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    )),
                    if (date != null)
                      Text('${date.day}/${date.month}/${date.year}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                  ]),
                  if (comment != null && comment.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(comment, style: const TextStyle(fontSize: 14, height: 1.45, color: AppColors.textSecondary)),
                  ],
                ]);
              },
            ),
          ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TAB: PROFILO PSICOLOGO
// ─────────────────────────────────────────────────────────────

class _MyProfileTab extends StatefulWidget {
  final String userId;
  const _MyProfileTab({required this.userId});
  @override
  State<_MyProfileTab> createState() => _MyProfileTabState();
}

class _MyProfileTabState extends State<_MyProfileTab> {
  Map<String, dynamic>? _psychProfile;
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final p = await ApiService().getPsychologistByUserId(widget.userId);
      setState(() { _psychProfile = p; _loading = false; });
    } catch (e) { setState(() { _error = e.toString(); _loading = false; }); }
  }

  void _openEdit() {
    if (_psychProfile == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _EditProfileSheet(
        profile: _psychProfile!,
        onSaved: () { Navigator.pop(ctx); setState(() => _loading = true); _load(); },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null || _psychProfile == null) {
      return Center(child: Text(_error ?? 'Profilo non trovato',
          style: const TextStyle(color: AppColors.error)));
    }
    final p = _psychProfile!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        const SizedBox(height: 8),
        CircleAvatar(
          radius: 52,
          backgroundImage: (p['profileImage'] != null && (p['profileImage'] as String).isNotEmpty)
              ? NetworkImage(p['profileImage'] as String)
              : null,
          backgroundColor: AppColors.glassBg,
          child: (p['profileImage'] == null || (p['profileImage'] as String).isEmpty)
              ? const Icon(Icons.person_rounded, size: 52, color: AppColors.textSecondary)
              : null,
        ),
        const SizedBox(height: 8),
        if (p['verified'] == true)
          const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.verified_rounded, color: Colors.lightBlueAccent, size: 16),
            SizedBox(width: 4),
            Text('Verificato', style: TextStyle(color: Colors.lightBlueAccent, fontSize: 13)),
          ]),
        const SizedBox(height: 24),
        GlassCard(
          radius: 20,
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            _ProfileField(label: 'Codice Albo',  value: p['alboCode'] ?? '—'),
            const Divider(height: 24),
            _ProfileField(label: 'Bio',           value: p['bio'] ?? '—'),
            const Divider(height: 24),
            _ProfileField(label: 'Indirizzo',     value: p['address'] ?? '—'),
            const Divider(height: 24),
            _ProfileField(label: 'Telefono',      value: p['phone'] ?? '—'),
            const Divider(height: 24),
            _ProfileField(label: 'Stato',
                value: p['verified'] == true ? 'Verificato' : 'In attesa di verifica'),
          ]),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _openEdit,
          icon: const Icon(Icons.edit_rounded, size: 18),
          label: const Text('Modifica profilo'),
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
        ),
      ]),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String label;
  final String value;
  const _ProfileField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        width: 100,
        child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
      ),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 15))),
    ]);
  }
}

class _EditProfileSheet extends StatefulWidget {
  final Map<String, dynamic> profile;
  final VoidCallback onSaved;
  const _EditProfileSheet({required this.profile, required this.onSaved});
  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _bioController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  XFile? _selectedImage;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _bioController     = TextEditingController(text: widget.profile['bio'] ?? '');
    _addressController = TextEditingController(text: widget.profile['address'] ?? '');
    _phoneController   = TextEditingController(text: widget.profile['phone'] ?? '');
  }

  @override
  void dispose() { _bioController.dispose(); _addressController.dispose(); _phoneController.dispose(); super.dispose(); }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      String? imageUrl = widget.profile['profileImage'] as String?;
      if (_selectedImage != null) imageUrl = await ApiService().uploadImage(_selectedImage!);
      await ApiService().updatePsychologist(widget.profile['id'] as String, {
        'bio':     _bioController.text.trim(),
        'address': _addressController.text.trim(),
        if (_phoneController.text.trim().isNotEmpty) 'phone': _phoneController.text.trim(),
        if (imageUrl != null && imageUrl.isNotEmpty) 'profileImage': imageUrl,
      });
      if (!mounted) return;
      widget.onSaved();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Modifica profilo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          Center(child: ImagePickerField(
            selectedImage: _selectedImage,
            currentImageUrl: widget.profile['profileImage'] as String?,
            onImageSelected: (f) => setState(() => _selectedImage = f),
          )),
          const SizedBox(height: 20),
          TextField(controller: _bioController,
              decoration: const InputDecoration(labelText: 'Bio', alignLabelWithHint: true),
              maxLines: 3),
          const SizedBox(height: 14),
          TextField(controller: _addressController,
              decoration: const InputDecoration(labelText: 'Indirizzo', prefixIcon: Icon(Icons.location_on_outlined))),
          const SizedBox(height: 14),
          TextField(controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Telefono', prefixIcon: Icon(Icons.phone_outlined)),
              keyboardType: TextInputType.phone),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _save,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            child: _loading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.bg))
                : const Text('Salva'),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TAB: DOMANDE PER PSICOLOGO
// ─────────────────────────────────────────────────────────────

class _QuestionsForPsychTab extends StatefulWidget {
  const _QuestionsForPsychTab();
  @override
  State<_QuestionsForPsychTab> createState() => _QuestionsForPsychTabState();
}

class _QuestionsForPsychTabState extends State<_QuestionsForPsychTab> {
  List<Map<String, dynamic>>? _questions;
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await ApiService().getQuestionsForPsych();
      setState(() { _questions = list; _loading = false; });
    } catch (e) { setState(() { _error = e.toString(); _loading = false; }); }
  }

  void _openAnswer(Map<String, dynamic> question) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AnswerSheet(question: question, onAnswered: () { Navigator.pop(ctx); _load(); }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _errorState(_error!, _load);
    if (_questions == null || _questions!.isEmpty) {
      return _emptyState(
        icon: Icons.inbox_outlined,
        title: 'Nessuna domanda disponibile',
        subtitle: 'Non ci sono domande nella tua area.\nTorna più tardi!',
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _questions!.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final q = _questions![i];
          return GlassCard(
            radius: 16,
            noPadding: true,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: AppColors.glassBg,
                child: const Icon(Icons.help_outline_rounded, color: AppColors.textSecondary, size: 20),
              ),
              title: Text(q['title'] as String? ?? 'Senza titolo',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 4),
                Text(q['content'] as String? ?? '', maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary)),
                if (q['isAnonymous'] == true) ...[
                  const SizedBox(height: 4),
                  const Text('Anonimo', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                ],
              ]),
              trailing: IconButton(
                icon: const Icon(Icons.reply_rounded, color: AppColors.textPrimary),
                tooltip: 'Rispondi',
                onPressed: () => _openAnswer(q),
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}

class _AnswerSheet extends StatefulWidget {
  final Map<String, dynamic> question;
  final VoidCallback onAnswered;
  const _AnswerSheet({required this.question, required this.onAnswered});
  @override
  State<_AnswerSheet> createState() => _AnswerSheetState();
}

class _AnswerSheetState extends State<_AnswerSheet> {
  final _ctrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await ApiService().createAnswer(questionId: widget.question['id'] as String, content: _ctrl.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Risposta inviata!')));
      widget.onAnswered();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Rispondi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(widget.question['title'] as String? ?? '',
            style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text(widget.question['content'] as String? ?? '',
            style: const TextStyle(color: AppColors.textSecondary), maxLines: 3, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 16),
        TextField(
          controller: _ctrl,
          decoration: const InputDecoration(labelText: 'La tua risposta', alignLabelWithHint: true),
          maxLines: 4,
          autofocus: true,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
          child: _loading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.bg))
              : const Text('Invia risposta'),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ADMIN HELPERS
// ─────────────────────────────────────────────────────────────

String _adminUserName(Map<String, dynamic> user) {
  final fn   = user['firstName'] as String? ?? '';
  final ln   = user['lastName'] as String? ?? '';
  final full = '$fn $ln'.trim();
  return full.isEmpty ? user['email'] as String? ?? 'Utente' : full;
}

// ── Admin: Domande ────────────────────────────────────────────

class _AdminQuestionsTab extends StatefulWidget {
  const _AdminQuestionsTab();
  @override
  State<_AdminQuestionsTab> createState() => _AdminQuestionsTabState();
}

class _AdminQuestionsTabState extends State<_AdminQuestionsTab> {
  List<Map<String, dynamic>>? _items;
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text.toLowerCase()));
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService().getAdminQuestions();
      setState(() { _items = data; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_query.isEmpty) return _items ?? [];
    return (_items ?? []).where((q) {
      final user = q['user'] as Map<String, dynamic>? ?? {};
      return (q['title'] as String? ?? '').toLowerCase().contains(_query) ||
          (q['content'] as String? ?? '').toLowerCase().contains(_query) ||
          _adminUserName(user).toLowerCase().contains(_query) ||
          (user['email'] as String? ?? '').toLowerCase().contains(_query);
    }).toList();
  }

  void _openDetail(Map<String, dynamic> q) {
    final user    = q['user'] as Map<String, dynamic>? ?? {};
    final answers = (q['answers'] as List? ?? []).cast<Map<String, dynamic>>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (_, sc) => ListView(controller: sc, padding: const EdgeInsets.all(20), children: [
          Text(q['title'] as String? ?? '',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Utente: ${_adminUserName(user)}',
              style: const TextStyle(color: AppColors.textTertiary, fontSize: 13)),
          const SizedBox(height: 12),
          Text(q['content'] as String? ?? '',
              style: const TextStyle(fontSize: 15, height: 1.5, color: AppColors.textSecondary)),
          const Divider(height: 32),
          Text('Risposte (${answers.length})',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 12),
          if (answers.isEmpty)
            const Text('Nessuna risposta ancora', style: TextStyle(color: AppColors.textTertiary))
          else
            ...answers.map((a) {
              final psych = a['psychologist'] as Map<String, dynamic>? ?? {};
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.glassBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Albo: ${psych['alboCode'] ?? '—'}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(a['content'] as String? ?? '',
                      style: const TextStyle(fontSize: 14, height: 1.4, color: AppColors.textSecondary)),
                ]),
              );
            }),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final filtered = _filtered;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: _searchBar(_searchCtrl, 'Cerca per titolo, testo, utente...'),
      ),
      Expanded(
        child: RefreshIndicator(
          onRefresh: _load,
          child: filtered.isEmpty
              ? _emptyState(icon: Icons.inbox_outlined, title: 'Nessun risultato')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final q    = filtered[i];
                    final user  = q['user'] as Map<String, dynamic>? ?? {};
                    final count = (q['_count'] as Map<String, dynamic>?)?['answers'] ?? 0;
                    return GlassCard(
                      radius: 14,
                      noPadding: true,
                      onTap: () => _openDetail(q),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.glassBg,
                          child: Text('$count',
                              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
                        ),
                        title: Text(q['title'] as String? ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(_adminUserName(user)),
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
                      ),
                    );
                  },
                ),
        ),
      ),
    ]);
  }
}

// ── Admin: Conversazioni ──────────────────────────────────────

class _AdminConversationsTab extends StatefulWidget {
  const _AdminConversationsTab();
  @override
  State<_AdminConversationsTab> createState() => _AdminConversationsTabState();
}

class _AdminConversationsTabState extends State<_AdminConversationsTab> {
  List<Map<String, dynamic>>? _items;
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text.toLowerCase()));
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService().getAdminConversations();
      setState(() { _items = data; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_query.isEmpty) return _items ?? [];
    return (_items ?? []).where((c) {
      final user  = c['User']         as Map<String, dynamic>? ?? {};
      final psych = c['Psychologist'] as Map<String, dynamic>? ?? {};
      return _adminUserName(user).toLowerCase().contains(_query) ||
          (user['email'] as String? ?? '').toLowerCase().contains(_query) ||
          (psych['alboCode'] as String? ?? '').toLowerCase().contains(_query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final filtered = _filtered;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: _searchBar(_searchCtrl, 'Cerca per utente, albo psicologo...'),
      ),
      Expanded(
        child: RefreshIndicator(
          onRefresh: _load,
          child: filtered.isEmpty
              ? _emptyState(icon: Icons.chat_bubble_outline_rounded, title: 'Nessun risultato')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final conv  = filtered[i];
                    final user  = conv['User']         as Map<String, dynamic>? ?? {};
                    final psych = conv['Psychologist'] as Map<String, dynamic>? ?? {};
                    final msgCount = (conv['_count'] as Map<String, dynamic>?)?['messages'] ?? 0;
                    return GlassCard(
                      radius: 14,
                      noPadding: true,
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => _AdminConvDetail(conv: conv),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.glassBg,
                          child: Text('$msgCount',
                              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
                        ),
                        title: Text(_adminUserName(user),
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('Psicologo: ${psych['alboCode'] ?? '—'}'),
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
                      ),
                    );
                  },
                ),
        ),
      ),
    ]);
  }
}

class _AdminConvDetail extends StatefulWidget {
  final Map<String, dynamic> conv;
  const _AdminConvDetail({required this.conv});
  @override
  State<_AdminConvDetail> createState() => _AdminConvDetailState();
}

class _AdminConvDetailState extends State<_AdminConvDetail> {
  List<Map<String, dynamic>>? _messages;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    ApiService().getAdminConversationMessages(widget.conv['id'] as String).then((msgs) {
      if (mounted) setState(() { _messages = msgs; _loading = false; });
    }).catchError((_) { if (mounted) setState(() => _loading = false); });
  }

  @override
  Widget build(BuildContext context) {
    final user  = widget.conv['User']         as Map<String, dynamic>? ?? {};
    final psych = widget.conv['Psychologist'] as Map<String, dynamic>? ?? {};
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (_, sc) => Column(children: [
        const SizedBox(height: 10),
        Container(width: 36, height: 4,
            decoration: BoxDecoration(color: AppColors.glassBorder, borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_adminUserName(user),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Text('Psicologo: ${psych['alboCode'] ?? '—'}',
                style: const TextStyle(color: AppColors.textTertiary, fontSize: 13)),
            const SizedBox(height: 12),
            const Divider(height: 1),
          ]),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : (_messages == null || _messages!.isEmpty)
                  ? _emptyState(icon: Icons.chat_bubble_outline_rounded, title: 'Nessun messaggio')
                  : ListView.builder(
                      controller: sc,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _messages!.length,
                      itemBuilder: (_, i) {
                        final msg        = _messages![i];
                        final fromPsych  = msg['senderPsychId'] != null;
                        final senderPsych = msg['senderPsych'] as Map<String, dynamic>?;
                        final senderUser  = msg['senderUser']  as Map<String, dynamic>?;
                        final senderLabel = fromPsych
                            ? 'Psicologo (${senderPsych?['alboCode'] ?? '—'})'
                            : _adminUserName(senderUser ?? {});
                        return Align(
                          alignment: fromPsych ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: fromPsych ? AppColors.textPrimary : AppColors.glassBg,
                              border: fromPsych ? null : Border.all(color: AppColors.glassBorder),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: fromPsych ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                Text(senderLabel,
                                    style: TextStyle(fontSize: 10,
                                        color: fromPsych ? AppColors.bg.withOpacity(0.6) : AppColors.textTertiary)),
                                const SizedBox(height: 4),
                                Text(msg['content'] as String? ?? '',
                                    style: TextStyle(color: fromPsych ? AppColors.bg : AppColors.textPrimary)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ]),
    );
  }
}

// ── Admin: Risposte ───────────────────────────────────────────

class _AdminAnswersTab extends StatefulWidget {
  const _AdminAnswersTab();
  @override
  State<_AdminAnswersTab> createState() => _AdminAnswersTabState();
}

class _AdminAnswersTabState extends State<_AdminAnswersTab> {
  List<Map<String, dynamic>>? _items;
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text.toLowerCase()));
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService().getAdminAnswers();
      setState(() { _items = data; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_query.isEmpty) return _items ?? [];
    return (_items ?? []).where((a) {
      final psych    = a['psychologist'] as Map<String, dynamic>? ?? {};
      final question = a['question']    as Map<String, dynamic>? ?? {};
      return (a['content'] as String? ?? '').toLowerCase().contains(_query) ||
          (psych['alboCode'] as String? ?? '').toLowerCase().contains(_query) ||
          (question['title'] as String? ?? '').toLowerCase().contains(_query);
    }).toList();
  }

  void _openDetail(Map<String, dynamic> a) {
    final psych    = a['psychologist'] as Map<String, dynamic>? ?? {};
    final question = a['question']    as Map<String, dynamic>? ?? {};
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, sc) => ListView(controller: sc, padding: const EdgeInsets.all(20), children: [
          const Text('DOMANDA',
              style: TextStyle(fontSize: 11, color: AppColors.textTertiary, fontWeight: FontWeight.w700, letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(question['title'] as String? ?? '',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(question['content'] as String? ?? '',
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4)),
          const Divider(height: 32),
          const Text('RISPOSTA',
              style: TextStyle(fontSize: 11, color: AppColors.textTertiary, fontWeight: FontWeight.w700, letterSpacing: 1)),
          const SizedBox(height: 8),
          Text('Albo: ${psych['alboCode'] ?? '—'}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          if (psych['address'] != null && (psych['address'] as String).isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(psych['address'] as String,
                style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.glassBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Text(a['content'] as String? ?? '',
                style: const TextStyle(fontSize: 15, height: 1.5)),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final filtered = _filtered;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: _searchBar(_searchCtrl, 'Cerca per testo, albo, titolo domanda...'),
      ),
      Expanded(
        child: RefreshIndicator(
          onRefresh: _load,
          child: filtered.isEmpty
              ? _emptyState(icon: Icons.question_answer_outlined, title: 'Nessun risultato')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final a        = filtered[i];
                    final psych    = a['psychologist'] as Map<String, dynamic>? ?? {};
                    final question = a['question']    as Map<String, dynamic>? ?? {};
                    return GlassCard(
                      radius: 14,
                      noPadding: true,
                      onTap: () => _openDetail(a),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.glassBg,
                          child: Icon(Icons.question_answer_outlined, color: AppColors.textSecondary, size: 20),
                        ),
                        title: Text(question['title'] as String? ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('Psicologo: ${psych['alboCode'] ?? '—'}'),
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
                      ),
                    );
                  },
                ),
        ),
      ),
    ]);
  }
}

// ── Admin: Psicologi ─────────────────────────────────────────

class _AdminPsychologistsTab extends StatefulWidget {
  const _AdminPsychologistsTab();
  @override
  State<_AdminPsychologistsTab> createState() => _AdminPsychologistsTabState();
}

class _AdminPsychologistsTabState extends State<_AdminPsychologistsTab> {
  List<Map<String, dynamic>>? _items;
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text.toLowerCase()));
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService().getAdminPsychologists();
      setState(() { _items = data; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_query.isEmpty) return _items ?? [];
    return (_items ?? []).where((p) =>
      (p['alboCode'] as String? ?? '').toLowerCase().contains(_query) ||
      (p['bio'] as String? ?? '').toLowerCase().contains(_query) ||
      (p['address'] as String? ?? '').toLowerCase().contains(_query) ||
      _adminUserName(p['user'] as Map<String, dynamic>? ?? {}).toLowerCase().contains(_query),
    ).toList();
  }

  Future<void> _call(BuildContext context, String phone) async {
    if (kIsWeb) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Numero di telefono'),
          content: SelectableText(phone, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Chiudi'))],
        ),
      );
    } else {
      final uri = Uri.parse('tel:$phone');
      if (await canLaunchUrl(uri)) await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final filtered = _filtered;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: _searchBar(_searchCtrl, 'Cerca per albo, nome, bio, indirizzo...'),
      ),
      Expanded(
        child: RefreshIndicator(
          onRefresh: _load,
          child: filtered.isEmpty
              ? _emptyState(icon: Icons.psychology_outlined, title: 'Nessun risultato')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final p           = filtered[i];
                    final avg         = p['avgRating'];
                    final reviewCount = p['reviewCount'] as int? ?? 0;
                    final phone       = p['phone'] as String?;
                    final user        = p['user'] as Map<String, dynamic>? ?? {};
                    return GlassCard(
                      radius: 16,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Text('Albo: ${p['alboCode'] ?? '—'}',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                              const SizedBox(width: 6),
                              if (p['verified'] == true)
                                const Icon(Icons.verified_rounded, color: Colors.lightBlueAccent, size: 15),
                            ]),
                            Text(_adminUserName(user),
                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                            if (user['email'] != null)
                              Text(user['email'] as String,
                                  style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                          ])),
                        ]),
                        if (p['bio'] != null && (p['bio'] as String).isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(p['bio'] as String,
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                        if (p['address'] != null && (p['address'] as String).isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(p['address'] as String,
                              style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                        ],
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 10),
                        Row(children: [
                          if (avg != null) ...[
                            ...List.generate(5, (j) => Icon(
                              j < (avg as num).round() ? Icons.star_rounded : Icons.star_outline_rounded,
                              color: AppColors.star, size: 15,
                            )),
                            const SizedBox(width: 4),
                            Text('$avg ($reviewCount)',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ] else
                            const Text('Nessuna recensione',
                                style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                          const Spacer(),
                          if (phone != null && phone.isNotEmpty)
                            OutlinedButton.icon(
                              onPressed: () => _call(context, phone),
                              icon: const Icon(Icons.phone_rounded, size: 15),
                              label: Text(phone, style: const TextStyle(fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                            ),
                        ]),
                      ]),
                    );
                  },
                ),
        ),
      ),
    ]);
  }
}

// ── Admin: Utenti ─────────────────────────────────────────────

class _AdminUsersTab extends StatefulWidget {
  const _AdminUsersTab();
  @override
  State<_AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<_AdminUsersTab> {
  List<Map<String, dynamic>>? _items;
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text.toLowerCase()));
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService().getAdminUsers();
      setState(() { _items = data; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_query.isEmpty) return _items ?? [];
    return (_items ?? []).where((u) =>
      _adminUserName(u).toLowerCase().contains(_query) ||
      (u['email'] as String? ?? '').toLowerCase().contains(_query),
    ).toList();
  }

  String _formatDate(String? iso) {
    if (iso == null) return '—';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) { return '—'; }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final filtered = _filtered;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: _searchBar(_searchCtrl, 'Cerca per nome o email...'),
      ),
      Expanded(
        child: RefreshIndicator(
          onRefresh: _load,
          child: filtered.isEmpty
              ? _emptyState(icon: Icons.people_outline_rounded, title: 'Nessun risultato')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final u           = filtered[i];
                    final hasLocation = u['latitude'] != null && u['longitude'] != null;
                    final initials    = _adminUserName(u).isNotEmpty ? _adminUserName(u)[0].toUpperCase() : '?';
                    return GlassCard(
                      radius: 14,
                      noPadding: true,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.glassBg,
                          child: Text(initials,
                              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
                        ),
                        title: Text(_adminUserName(u),
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(u['email'] as String? ?? ''),
                        trailing: Column(mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text(_formatDate(u['createdAt'] as String?),
                              style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                          const SizedBox(height: 2),
                          Icon(hasLocation ? Icons.location_on_rounded : Icons.location_off_rounded,
                              size: 14,
                              color: hasLocation ? AppColors.success : AppColors.textTertiary),
                        ]),
                      ),
                    );
                  },
                ),
        ),
      ),
    ]);
  }
}

// ── Admin: Impostazioni ───────────────────────────────────────

class _AdminSettingsTab extends StatefulWidget {
  const _AdminSettingsTab();
  @override
  State<_AdminSettingsTab> createState() => _AdminSettingsTabState();
}

class _AdminSettingsTabState extends State<_AdminSettingsTab> {
  final _radiusCtrl     = TextEditingController();
  final _minutesCtrl    = TextEditingController();
  final _maxAnswersCtrl = TextEditingController();
  bool _loading = true;
  bool _saving  = false;

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _radiusCtrl.dispose(); _minutesCtrl.dispose(); _maxAnswersCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final s = await ApiService().getAdminSettings();
      _radiusCtrl.text     = (s['radiusKm']     ?? 50).toString();
      _minutesCtrl.text    = (s['expandMinutes'] ?? 60).toString();
      _maxAnswersCtrl.text = (s['maxAnswers']    ?? 5).toString();
      setState(() => _loading = false);
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ApiService().updateAdminSettings(
        radiusKm:      double.tryParse(_radiusCtrl.text),
        expandMinutes: int.tryParse(_minutesCtrl.text),
        maxAnswers:    int.tryParse(_maxAnswersCtrl.text),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impostazioni salvate')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: 8),
        const Text('Parametri visibilità', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        const Text('Configura raggio e limiti per la distribuzione delle domande.',
            style: TextStyle(color: AppColors.textSecondary, height: 1.4)),
        const SizedBox(height: 28),
        GlassCard(
          radius: 20,
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            _SettingField(
              controller: _radiusCtrl,
              label: 'Raggio iniziale (km)',
              hint: '50',
              helper: 'Solo gli psicologi entro questo raggio vedono la domanda.',
            ),
            const SizedBox(height: 20),
            _SettingField(
              controller: _minutesCtrl,
              label: 'Minuti per raddoppio raggio',
              hint: '60',
              helper: 'Ogni N minuti il raggio raddoppia, fino a 5000 km.',
            ),
            const SizedBox(height: 20),
            _SettingField(
              controller: _maxAnswersCtrl,
              label: 'Max risposte per domanda',
              hint: '5',
              helper: 'Dopo N risposte la domanda viene nascosta agli altri psicologi.',
            ),
          ]),
        ),
        const SizedBox(height: 28),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          child: _saving
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.bg))
              : const Text('Salva impostazioni'),
        ),
      ]),
    );
  }
}

class _SettingField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String helper;
  const _SettingField({required this.controller, required this.label, required this.hint, required this.helper});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helper,
        helperMaxLines: 2,
        helperStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    );
  }
}
