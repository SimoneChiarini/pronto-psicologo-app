import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────
// ENTRY POINT
// ─────────────────────────────────────────────────────────────

class PsychologistProfilePage extends StatefulWidget {
  final String psychologistId;
  final String role; // 'USER', 'PSYCHOLOGIST', 'ADMIN'
  final bool isOwnProfile;
  /// Quando true non avvolge in Scaffold (usato come tab embeddato nel nav rail)
  final bool asEmbedded;
  /// Se fornito e asEmbedded==true, mostra un tasto indietro nella AppBar
  final VoidCallback? onBack;

  const PsychologistProfilePage({
    super.key,
    required this.psychologistId,
    required this.role,
    required this.isOwnProfile,
    this.asEmbedded = false,
    this.onBack,
  });

  @override
  State<PsychologistProfilePage> createState() => _PsychologistProfilePageState();
}

class _PsychologistProfilePageState extends State<PsychologistProfilePage>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  late TabController _tabController;

  Map<String, dynamic>? _psych;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await _api.getPsychologists();
      final found = list.cast<Map<String, dynamic>>()
          .where((p) => p['id'] == widget.psychologistId)
          .toList();
      if (found.isEmpty) throw Exception('Psicologo non trovato');
      setState(() { _psych = found.first; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _pickAndUploadCover() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
    if (file == null || !mounted) return;
    try {
      final url = await _api.uploadImage(file);
      await _api.updatePsychologist(widget.psychologistId, {'coverImage': url});
      await _load();
    } catch (e) {
      if (mounted) _showError('Errore upload copertina: $e');
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, maxWidth: 400, imageQuality: 90);
    if (file == null || !mounted) return;
    try {
      final url = await _api.uploadImage(file);
      await _api.updatePsychologist(widget.psychologistId, {'profileImage': url});
      await _load();
    } catch (e) {
      if (mounted) _showError('Errore upload foto profilo: $e');
    }
  }

  void _openEdit() {
    if (_psych == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PsychEditSheet(psych: _psych!, onSaved: _load),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.error,
    ));
  }

  String _fullName() {
    final u = _psych?['user'] as Map<String, dynamic>? ?? {};
    final fn = (u['firstName'] as String? ?? '').trim();
    final ln = (u['lastName'] as String? ?? '').trim();
    final full = '$fn $ln'.trim();
    return full.isNotEmpty ? full : _psych?['alboCode'] as String? ?? 'Psicologo';
  }

  @override
  Widget build(BuildContext context) {
    // ── Loading / Error ──────────────────────────────────────
    if (_loading) {
      const body = Center(child: CircularProgressIndicator());
      return widget.asEmbedded ? body : const Scaffold(backgroundColor: AppColors.bg, body: body);
    }
    if (_error != null || _psych == null) {
      final body = Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(_error ?? 'Errore', style: const TextStyle(color: AppColors.error)),
          if (!widget.asEmbedded) ...[
            const SizedBox(height: 12),
            OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Torna indietro')),
          ],
        ]),
      );
      return widget.asEmbedded ? body : Scaffold(backgroundColor: AppColors.bg, appBar: AppBar(), body: body);
    }

    final p = _psych!;
    final coverImage  = ApiService.resolveUrl(p['coverImage'] as String?);
    final profileImage = ApiService.resolveUrl(p['profileImage'] as String?);
    final verified    = p['verified'] == true;

    // ── Content ──────────────────────────────────────────────
    final scrollBody = NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverAppBar(
          automaticallyImplyLeading: !widget.asEmbedded,
          leading: (widget.asEmbedded && widget.onBack != null)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: widget.onBack,
                )
              : null,
          expandedHeight: 220,
          pinned: true,
          backgroundColor: AppColors.bg,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.pin,
            background: _ProfileHeader(
              coverImage: coverImage,
              profileImage: profileImage,
              isOwnProfile: widget.isOwnProfile,
              onPickCover: _pickAndUploadCover,
              onPickAvatar: _pickAndUploadAvatar,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _ProfileInfo(
            psych: p,
            name: _fullName(),
            verified: verified,
            isOwnProfile: widget.isOwnProfile,
            onEditTap: widget.isOwnProfile ? _openEdit : null,
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _StickyTabBarDelegate(
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Post'),
                Tab(text: 'Agenda'),
                Tab(text: 'Recensioni'),
              ],
            ),
          ),
        ),
      ],
      body: TabBarView(
        controller: _tabController,
        children: [
          _PostsTab(
            psychologistId: widget.psychologistId,
            isOwnProfile: widget.isOwnProfile,
          ),
          _AgendaPublicTab(
            psychologistId: widget.psychologistId,
            role: widget.role,
            isOwnProfile: widget.isOwnProfile,
          ),
          _ReviewsTab(psychologistId: widget.psychologistId),
        ],
      ),
    );

    if (widget.asEmbedded) return scrollBody;
    return Scaffold(backgroundColor: AppColors.bg, body: scrollBody);
  }
}

// ─────────────────────────────────────────────────────────────
// HEADER (cover + avatar)
// ─────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final String? coverImage;
  final String? profileImage;
  final bool isOwnProfile;
  final VoidCallback onPickCover;
  final VoidCallback onPickAvatar;

  const _ProfileHeader({
    required this.coverImage,
    required this.profileImage,
    required this.isOwnProfile,
    required this.onPickCover,
    required this.onPickAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Cover image
        GestureDetector(
          onTap: isOwnProfile ? onPickCover : null,
          child: SizedBox(
            width: double.infinity,
            height: 180,
            child: (coverImage != null)
                ? Image.network(
                    coverImage!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _CoverPlaceholder(isOwnProfile: isOwnProfile),
                  )
                : _CoverPlaceholder(isOwnProfile: isOwnProfile),
          ),
        ),
        // Edit cover icon
        if (isOwnProfile)
          Positioned(
            top: 8, right: 8,
            child: GestureDetector(
              onTap: onPickCover,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
              ),
            ),
          ),
        // Avatar
        Positioned(
          bottom: -20, left: 20,
          child: GestureDetector(
            onTap: isOwnProfile ? onPickAvatar : null,
            child: Stack(
              children: [
                Container(
                  width: 84, height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.bg, width: 3),
                  ),
                  child: ClipOval(
                    child: (profileImage != null)
                        ? Image.network(profileImage!, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _AvatarPlaceholder())
                        : _AvatarPlaceholder(),
                  ),
                ),
                if (isOwnProfile)
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.bgInverse,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.bg, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt_rounded, size: 12, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  final bool isOwnProfile;
  const _CoverPlaceholder({required this.isOwnProfile});
  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.bgPanel,
    child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.image_outlined, size: 32, color: AppColors.textTertiary),
      if (isOwnProfile) ...[
        const SizedBox(height: 6),
        const Text('Aggiungi copertina', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
      ],
    ])),
  );
}

class _AvatarPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.bgPanel,
    child: const Icon(Icons.person_rounded, size: 40, color: AppColors.textTertiary),
  );
}

// ─────────────────────────────────────────────────────────────
// INFO NOME / BIO / SPECIALIZZAZIONI
// ─────────────────────────────────────────────────────────────

class _ProfileInfo extends StatelessWidget {
  final Map<String, dynamic> psych;
  final String name;
  final bool verified;
  final bool isOwnProfile;
  final VoidCallback? onEditTap;

  const _ProfileInfo({
    required this.psych,
    required this.name,
    required this.verified,
    required this.isOwnProfile,
    this.onEditTap,
  });

  static Map<String, String> get _specLabels => {
    for (final cat in kSpecCategories)
      for (final e in cat.specs.entries) e.key: e.value,
  };

  @override
  Widget build(BuildContext context) {
    final albo = psych['alboCode'] as String? ?? '';
    final bio  = psych['bio'] as String?;
    final specs = _specLabels.entries
        .where((e) => psych[e.key] == true)
        .map((e) => e.value)
        .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 36, 20, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textStrong)),
          ),
          if (verified) const Icon(Icons.verified_rounded, color: Colors.lightBlueAccent, size: 20),
          if (isOwnProfile && onEditTap != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onEditTap,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.glassBorder),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.edit_rounded, size: 14, color: AppColors.textSecondary),
              ),
            ),
          ],
        ]),
        const SizedBox(height: 2),
        Text('Albo: $albo', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        if (bio != null && bio.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(bio, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.5)),
        ],
        if (specs.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 6, children: specs.map((s) => Chip(
            label: Text(s, style: const TextStyle(fontSize: 11)),
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          )).toList()),
        ],
        const SizedBox(height: 8),
        const Divider(),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STICKY TAB BAR
// ─────────────────────────────────────────────────────────────

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _StickyTabBarDelegate(this.tabBar);

  @override double get minExtent => tabBar.preferredSize.height;
  @override double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      Container(color: AppColors.bg, child: tabBar);

  @override
  bool shouldRebuild(_StickyTabBarDelegate o) => tabBar != o.tabBar;
}

// ─────────────────────────────────────────────────────────────
// TAB: POST
// ─────────────────────────────────────────────────────────────

class _PostsTab extends StatefulWidget {
  final String psychologistId;
  final bool isOwnProfile;
  const _PostsTab({required this.psychologistId, required this.isOwnProfile});
  @override
  State<_PostsTab> createState() => _PostsTabState();
}

class _PostsTabState extends State<_PostsTab> with AutomaticKeepAliveClientMixin {
  final _api = ApiService();
  List<Map<String, dynamic>>? _posts;
  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final posts = await _api.getPostsByPsychologist(widget.psychologistId);
      setState(() { _posts = posts; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _showCreatePost() async {
    final ctrl = TextEditingController();
    String? imageUrl;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Nuovo post', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            TextField(controller: ctrl, maxLines: 5,
                decoration: const InputDecoration(hintText: 'Scrivi qualcosa...')),
            const SizedBox(height: 8),
            if (imageUrl != null)
              Row(children: [
                const Icon(Icons.image_rounded, size: 14, color: AppColors.success),
                const SizedBox(width: 4),
                const Expanded(child: Text('Immagine allegata',
                    style: TextStyle(fontSize: 12, color: AppColors.success))),
                IconButton(icon: const Icon(Icons.close_rounded, size: 14),
                    onPressed: () => setModal(() => imageUrl = null)),
              ]),
            Row(children: [
              OutlinedButton.icon(
                onPressed: () async {
                  final f = await ImagePicker().pickImage(
                      source: ImageSource.gallery, maxWidth: 800, imageQuality: 85);
                  if (f == null) return;
                  try {
                    final url = await _api.uploadImage(f);
                    setModal(() => imageUrl = url);
                  } catch (_) {}
                },
                icon: const Icon(Icons.photo_outlined, size: 14),
                label: const Text('Foto'),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () async {
                  if (ctrl.text.trim().isEmpty) return;
                  try {
                    await _api.createPost(content: ctrl.text.trim(), imageUrl: imageUrl);
                    if (ctx.mounted) Navigator.pop(ctx);
                    _load();
                  } catch (e) {
                    if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text('Errore: $e'), backgroundColor: AppColors.error));
                  }
                },
                child: const Text('Pubblica'),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  Future<void> _deletePost(String id) async {
    try {
      await _api.deletePost(id);
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e'), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(_error!, style: const TextStyle(color: AppColors.error)),
        const SizedBox(height: 8),
        OutlinedButton(onPressed: _load, child: const Text('Riprova')),
      ]));
    }
    final posts = _posts ?? [];
    return CustomScrollView(slivers: [
      if (widget.isOwnProfile)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: OutlinedButton.icon(
              onPressed: _showCreatePost,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Nuovo post'),
            ),
          ),
        ),
      if (posts.isEmpty)
        const SliverFillRemaining(
          child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.article_outlined, size: 48, color: AppColors.textTertiary),
            SizedBox(height: 12),
            Text('Nessun post ancora', style: TextStyle(color: AppColors.textSecondary)),
          ])),
        )
      else
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (ctx, i) => _PostCard(
                post: posts[i], isOwnProfile: widget.isOwnProfile, onDelete: _deletePost),
            childCount: posts.length,
          ),
        ),
    ]);
  }
}

class _PostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final bool isOwnProfile;
  final void Function(String id) onDelete;
  const _PostCard({required this.post, required this.isOwnProfile, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final content  = post['content'] as String? ?? '';
    final rawImg   = post['imageUrl'] as String?;
    final imageUrl = ApiService.resolveUrl(rawImg);
    final createdAt = post['createdAt'] != null
        ? DateTime.tryParse(post['createdAt'] as String)?.toLocal()
        : null;

    String dateLabel = '';
    if (createdAt != null) {
      final diff = DateTime.now().difference(createdAt);
      if (diff.inDays == 0) {
        dateLabel = 'oggi ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
      } else if (diff.inDays == 1) {
        dateLabel = 'ieri';
      } else {
        dateLabel = '${createdAt.day}/${createdAt.month}/${createdAt.year}';
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
          child: Row(children: [
            Expanded(child: Text(dateLabel,
                style: const TextStyle(fontSize: 11, color: AppColors.textTertiary))),
            if (isOwnProfile)
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.textTertiary),
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Elimina post'),
                      content: const Text('Vuoi eliminare questo post?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Elimina')),
                      ],
                    ),
                  );
                  if (ok == true) onDelete(post['id'] as String);
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: Text(content,
              style: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.textPrimary)),
        ),
        if (imageUrl != null)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
            child: Image.network(imageUrl, width: double.infinity, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink()),
          ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TAB: AGENDA (Giorno / Settimana / Mese)
// ─────────────────────────────────────────────────────────────

enum _AgendaView { day, week, month }

class _AgendaPublicTab extends StatefulWidget {
  final String psychologistId;
  final String role;
  final bool isOwnProfile;
  const _AgendaPublicTab({
    required this.psychologistId,
    required this.role,
    required this.isOwnProfile,
  });
  @override
  State<_AgendaPublicTab> createState() => _AgendaPublicTabState();
}

class _AgendaPublicTabState extends State<_AgendaPublicTab>
    with AutomaticKeepAliveClientMixin {
  final _api = ApiService();

  _AgendaView _view = _AgendaView.day;
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _slots = [];       // slot giorno corrente
  List<Map<String, dynamic>> _rangeSlots = [];  // slot settimana/mese
  // per isOwnProfile: lista completa caricata una volta sola
  List<Map<String, dynamic>> _fullAgenda = [];
  bool _loading = false;
  String? _error;

  static const _hours = [8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19];
  static const _dayNames    = ['', 'Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];
  static const _dayNamesFull = ['', 'Lunedì', 'Martedì', 'Mercoledì', 'Giovedì', 'Venerdì', 'Sabato', 'Domenica'];
  static const _monthNames  = ['', 'Gen', 'Feb', 'Mar', 'Apr', 'Mag', 'Giu', 'Lug', 'Ago', 'Set', 'Ott', 'Nov', 'Dic'];
  static const _monthNamesFull = ['', 'Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno',
      'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre'];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    widget.isOwnProfile ? _loadOwnAgenda() : _loadDay();
  }

  // ── Loaders ───────────────────────────────────────────────

  Future<void> _loadDay() async {
    setState(() { _loading = true; _error = null; });
    try {
      final s = await _api.getPublicSlots(widget.psychologistId, _selectedDate);
      setState(() { _slots = s; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _loadRange(DateTime start, DateTime end) async {
    setState(() { _loading = true; _error = null; });
    try {
      final s = await _api.getPublicSlots(widget.psychologistId, start, endDate: end);
      setState(() { _rangeSlots = s; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _loadOwnAgenda() async {
    setState(() { _loading = true; _error = null; });
    try {
      final all = await _api.getAgenda();
      if (!mounted) return;
      setState(() { _fullAgenda = all; _loading = false; });
      _applyOwnFilter();
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _applyOwnFilter() {
    setState(() {
      switch (_view) {
        case _AgendaView.day:
          _slots = _fullAgenda.where((s) {
            final dt = DateTime.tryParse(s['startTime'] as String)?.toLocal();
            return dt != null && _isSameDay(dt, _selectedDate);
          }).toList();
        case _AgendaView.week:
          final ws = _weekStart(_selectedDate);
          final we = ws.add(const Duration(days: 7));
          _rangeSlots = _fullAgenda.where((s) {
            final dt = DateTime.tryParse(s['startTime'] as String)?.toLocal();
            return dt != null && !dt.isBefore(ws) && dt.isBefore(we);
          }).toList();
        case _AgendaView.month:
          final ms = DateTime(_selectedDate.year, _selectedDate.month, 1);
          final me = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
          _rangeSlots = _fullAgenda.where((s) {
            final dt = DateTime.tryParse(s['startTime'] as String)?.toLocal();
            return dt != null && !dt.isBefore(ms) && dt.isBefore(me);
          }).toList();
      }
    });
  }

  void _loadForView() {
    if (widget.isOwnProfile) { _applyOwnFilter(); return; }
    switch (_view) {
      case _AgendaView.day:
        _loadDay();
      case _AgendaView.week:
        final ws = _weekStart(_selectedDate);
        _loadRange(ws, ws.add(const Duration(days: 6)));
      case _AgendaView.month:
        final ms = DateTime(_selectedDate.year, _selectedDate.month, 1);
        final me = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
        _loadRange(ms, me);
    }
  }

  // ── Helpers ───────────────────────────────────────────────

  DateTime _weekStart(DateTime d) => d.subtract(Duration(days: d.weekday - 1));

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Map<String, List<Map<String, dynamic>>> _groupByDay(List<Map<String, dynamic>> slots) {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final s in slots) {
      final dt = DateTime.tryParse(s['startTime'] as String)?.toLocal();
      if (dt == null) continue;
      final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      map.putIfAbsent(key, () => []).add(s);
    }
    return map;
  }

  String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Map<String, dynamic>? _slotForHour(int hour) {
    for (final s in _slots) {
      final dt = DateTime.tryParse(s['startTime'] as String)?.toLocal();
      if (dt != null && dt.hour == hour) return s;
    }
    return null;
  }

  // ── Actions (slot) ────────────────────────────────────────

  Future<void> _requestSlot(int hour) async {
    final dt = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, hour);
    try {
      await _api.requestSlot(psychologistId: widget.psychologistId, startTime: dt);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Richiesta inviata allo psicologo')));
      _loadDay();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e'), backgroundColor: AppColors.error));
    }
  }

  Future<void> _acceptSlot(String id) async {
    try {
      await _api.acceptAppointment(id);
      widget.isOwnProfile ? _loadOwnAgenda() : _loadDay();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e'), backgroundColor: AppColors.error));
    }
  }

  Future<void> _rejectSlot(String id) async {
    try {
      await _api.rejectAppointment(id);
      widget.isOwnProfile ? _loadOwnAgenda() : _loadDay();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e'), backgroundColor: AppColors.error));
    }
  }

  Future<void> _deleteSlot(String id) async {
    try {
      await _api.deleteAppointment(id);
      widget.isOwnProfile ? _loadOwnAgenda() : _loadForView();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e'), backgroundColor: AppColors.error));
    }
  }

  void _showCreateDialog({int? hour}) {
    showDialog(
      context: context,
      builder: (_) => _NewEventDialog(
        initialDate: _selectedDate,
        initialHour: hour,
        psychologistId: widget.psychologistId,
        onCreated: widget.isOwnProfile ? _loadOwnAgenda : _loadForView,
      ),
    );
  }

  // ── Navigation ────────────────────────────────────────────

  void _prev() {
    setState(() {
      switch (_view) {
        case _AgendaView.day:
          _selectedDate = _selectedDate.subtract(const Duration(days: 1));
        case _AgendaView.week:
          _selectedDate = _selectedDate.subtract(const Duration(days: 7));
        case _AgendaView.month:
          _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
      }
    });
    _loadForView();
  }

  void _next() {
    setState(() {
      switch (_view) {
        case _AgendaView.day:
          _selectedDate = _selectedDate.add(const Duration(days: 1));
        case _AgendaView.week:
          _selectedDate = _selectedDate.add(const Duration(days: 7));
        case _AgendaView.month:
          _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
      }
    });
    _loadForView();
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _loadForView();
    }
  }

  // ── Period label ──────────────────────────────────────────

  String _periodLabel() {
    switch (_view) {
      case _AgendaView.day:
        return '${_dayNamesFull[_selectedDate.weekday]} ${_selectedDate.day} ${_monthNames[_selectedDate.month]} ${_selectedDate.year}';
      case _AgendaView.week:
        final ws = _weekStart(_selectedDate);
        final we = ws.add(const Duration(days: 6));
        if (ws.month == we.month) {
          return '${ws.day}–${we.day} ${_monthNamesFull[ws.month]} ${ws.year}';
        }
        return '${ws.day} ${_monthNames[ws.month]} – ${we.day} ${_monthNames[we.month]} ${we.year}';
      case _AgendaView.month:
        return '${_monthNamesFull[_selectedDate.month]} ${_selectedDate.year}';
    }
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final column = Column(children: [
      // View switcher
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
        child: SegmentedButton<_AgendaView>(
          segments: const [
            ButtonSegment(value: _AgendaView.day,   label: Text('Giorno'),    icon: Icon(Icons.view_day_rounded,    size: 14)),
            ButtonSegment(value: _AgendaView.week,  label: Text('Settimana'), icon: Icon(Icons.view_week_rounded,   size: 14)),
            ButtonSegment(value: _AgendaView.month, label: Text('Mese'),      icon: Icon(Icons.calendar_month_rounded, size: 14)),
          ],
          selected: {_view},
          onSelectionChanged: (sel) {
            setState(() => _view = sel.first);
            _loadForView();
          },
          style: const ButtonStyle(
            visualDensity: VisualDensity(horizontal: -2, vertical: -2),
          ),
        ),
      ),
      // Period navigator
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Row(children: [
          IconButton(icon: const Icon(Icons.chevron_left_rounded), onPressed: _prev,
              padding: EdgeInsets.zero, constraints: const BoxConstraints()),
          Expanded(
            child: GestureDetector(
              onTap: _pickDate,
              child: Text(_periodLabel(),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textStrong),
                textAlign: TextAlign.center),
            ),
          ),
          IconButton(icon: const Icon(Icons.chevron_right_rounded), onPressed: _next,
              padding: EdgeInsets.zero, constraints: const BoxConstraints()),
        ]),
      ),
      const Divider(height: 1),
      // Content
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
                    const SizedBox(height: 8),
                    OutlinedButton(onPressed: _loadForView, child: const Text('Riprova')),
                  ]))
                : _buildViewContent(),
      ),
    ]);
    if (!widget.isOwnProfile) return column;
    return Stack(children: [
      Positioned.fill(child: column),
      Positioned(
        bottom: 16, right: 16,
        child: FloatingActionButton(
          mini: true,
          onPressed: _showCreateDialog,
          backgroundColor: AppColors.bgInverse,
          child: const Icon(Icons.add_rounded, color: AppColors.textInverse),
        ),
      ),
    ]);
  }

  Widget _buildViewContent() {
    switch (_view) {
      case _AgendaView.day:   return _buildDayContent();
      case _AgendaView.week:  return _buildWeekContent();
      case _AgendaView.month: return _buildMonthContent();
    }
  }

  // ── DAY VIEW ──────────────────────────────────────────────

  Widget _buildDayContent() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _hours.length,
      itemBuilder: (ctx, i) {
        final hour = _hours[i];
        final slot = _slotForHour(hour);
        final status = slot?['status'] as String?;
        return _SlotRow(
          hour: hour,
          slot: slot,
          role: widget.role,
          isOwnProfile: widget.isOwnProfile,
          selectedDate: _selectedDate,
          onRequest: () => _requestSlot(hour),
          onCreateAtHour: widget.isOwnProfile && slot == null
              ? () => _showCreateDialog(hour: hour)
              : null,
          onAccept: slot != null ? () => _acceptSlot(slot['id'] as String) : null,
          onReject: slot != null ? () => _rejectSlot(slot['id'] as String) : null,
          onCancel: widget.isOwnProfile && status == 'CONFIRMED'
              ? () => _deleteSlot(slot!['id'] as String)
              : null,
        );
      },
    );
  }

  // ── WEEK VIEW ─────────────────────────────────────────────

  Widget _buildWeekContent() {
    final ws      = _weekStart(_selectedDate);
    final byDay   = _groupByDay(_rangeSlots);
    final today   = DateTime.now();

    return Column(children: [
      // 7-day grid
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 4),
        child: Row(
          children: List.generate(7, (i) {
            final day  = ws.add(Duration(days: i));
            final key  = _dayKey(day);
            final slotsForDay = byDay[key] ?? [];
            final isToday    = _isSameDay(day, today);
            final isSelected = _isSameDay(day, _selectedDate);
            final confirmedCount = slotsForDay.where((s) => s['status'] == 'CONFIRMED').length;
            final pendingCount   = slotsForDay.where((s) => s['status'] == 'PENDING').length;

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() { _selectedDate = day; _view = _AgendaView.day; });
                  _loadDay();
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.bgInverse
                        : isToday
                            ? AppColors.bgPanel
                            : AppColors.bg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? AppColors.bgInverse : AppColors.glassBorder,
                    ),
                  ),
                  child: Column(children: [
                    Text(_dayNames[day.weekday],
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected ? AppColors.textInverse : AppColors.textTertiary,
                      )),
                    const SizedBox(height: 4),
                    Text('${day.day}',
                      style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700,
                        color: isSelected ? AppColors.textInverse : AppColors.textStrong,
                      )),
                    const SizedBox(height: 6),
                    // Dots
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      if (confirmedCount > 0)
                        ...List.generate(confirmedCount.clamp(0, 3), (_) => Container(
                          width: 5, height: 5, margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.success),
                        )),
                      if (pendingCount > 0)
                        ...List.generate(pendingCount.clamp(0, 2), (_) => Container(
                          width: 5, height: 5, margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.star),
                        )),
                    ]),
                    if (slotsForDay.isEmpty)
                      Container(
                        width: 5, height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? AppColors.textInverse.withAlpha(80)
                              : AppColors.borderSubtle,
                        ),
                      ),
                  ]),
                ),
              ),
            );
          }),
        ),
      ),
      const Divider(height: 1),
      // Legenda
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          _LegendDot(color: AppColors.success, label: 'Confermato'),
          const SizedBox(width: 12),
          _LegendDot(color: AppColors.star, label: 'In attesa'),
          const SizedBox(width: 12),
          const Text('• Tocca un giorno per i dettagli',
              style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
        ]),
      ),
      // Riepilogo slot settimana (scrollabile)
      Expanded(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 4),
          children: List.generate(7, (i) {
            final day     = ws.add(Duration(days: i));
            final key     = _dayKey(day);
            final daySlots = byDay[key] ?? [];
            if (daySlots.isEmpty) return const SizedBox.shrink();
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: Text(
                  '${_dayNamesFull[day.weekday]} ${day.day}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary),
                ),
              ),
              ...daySlots.map((s) {
                final dt = DateTime.tryParse(s['startTime'] as String)?.toLocal();
                final status = s['status'] as String? ?? '';
                return ListTile(
                  dense: true,
                  leading: Container(
                    width: 8, height: 8,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: status == 'CONFIRMED' ? AppColors.success : AppColors.star,
                    ),
                  ),
                  title: Text(
                    dt != null ? '${dt.hour.toString().padLeft(2, '0')}:00 – ${(dt.hour + 1).toString().padLeft(2, '0')}:00' : '—',
                    style: const TextStyle(fontSize: 13),
                  ),
                  subtitle: Text(
                    status == 'CONFIRMED' ? 'Confermato' : 'In attesa di conferma',
                    style: const TextStyle(fontSize: 11),
                  ),
                );
              }),
            ]);
          }),
        ),
      ),
    ]);
  }

  // ── MONTH VIEW ────────────────────────────────────────────

  Widget _buildMonthContent() {
    final byDay   = _groupByDay(_rangeSlots);
    final today   = DateTime.now();
    final firstDay = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final daysInMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
    // Offset per iniziare dal lunedì (weekday 1=Mon)
    final startOffset = firstDay.weekday - 1;

    return Column(children: [
      // Header giorni settimana
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
        child: Row(
          children: _dayNames.skip(1).map((name) => Expanded(
            child: Text(name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textTertiary)),
          )).toList(),
        ),
      ),
      const Divider(height: 1),
      // Griglia giorni
      Expanded(
        child: GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 0.85,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: startOffset + daysInMonth,
          itemBuilder: (ctx, idx) {
            if (idx < startOffset) return const SizedBox.shrink();
            final dayNum = idx - startOffset + 1;
            final day = DateTime(_selectedDate.year, _selectedDate.month, dayNum);
            final key = _dayKey(day);
            final daySlots = byDay[key] ?? [];
            final isToday    = _isSameDay(day, today);
            final isSelected = _isSameDay(day, _selectedDate);
            final confirmedCount = daySlots.where((s) => s['status'] == 'CONFIRMED').length;
            final pendingCount   = daySlots.where((s) => s['status'] == 'PENDING').length;

            return GestureDetector(
              onTap: () {
                setState(() { _selectedDate = day; _view = _AgendaView.day; });
                _loadDay();
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.bgInverse
                      : isToday
                          ? AppColors.bgPanel
                          : AppColors.bg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected ? AppColors.bgInverse : AppColors.borderFaint,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$dayNum',
                      style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: isSelected ? AppColors.textInverse : AppColors.textStrong,
                      )),
                    if (confirmedCount > 0 || pendingCount > 0) ...[
                      const SizedBox(height: 3),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        if (confirmedCount > 0) Container(
                          width: 5, height: 5, margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.success),
                        ),
                        if (pendingCount > 0) Container(
                          width: 5, height: 5, margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.star),
                        ),
                      ]),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
      // Legenda
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          _LegendDot(color: AppColors.success, label: 'Confermato'),
          const SizedBox(width: 12),
          _LegendDot(color: AppColors.star, label: 'In attesa'),
        ]),
      ),
    ]);
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
  ]);
}

// ─────────────────────────────────────────────────────────────
// SLOT ROW (day view)
// ─────────────────────────────────────────────────────────────

class _SlotRow extends StatelessWidget {
  final int hour;
  final Map<String, dynamic>? slot;
  final String role;
  final bool isOwnProfile;
  final DateTime selectedDate;
  final VoidCallback onRequest;
  final VoidCallback? onCreateAtHour; // psicologo: crea evento su slot vuoto
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onCancel; // psicologo: cancella appuntamento confermato

  const _SlotRow({
    required this.hour, required this.slot, required this.role,
    required this.isOwnProfile, required this.selectedDate,
    required this.onRequest, this.onCreateAtHour,
    this.onAccept, this.onReject, this.onCancel,
  });

  bool get _isPast => DateTime(selectedDate.year, selectedDate.month, selectedDate.day, hour + 1)
      .isBefore(DateTime.now());

  bool _isTappable(String? status) {
    if (_isPast) return false;
    if (status == null && onCreateAtHour != null) return true; // slot vuoto psicologo
    if (status == null && role == 'USER') return true;
    if (status == 'PENDING' && isOwnProfile) return true;
    if (status == 'CONFIRMED' || status == 'PENDING') return true;
    return false;
  }

  void _openDialog(BuildContext context, String? status) {
    // Slot vuoto + psicologo → apre direttamente il dialog di creazione
    if (status == null && onCreateAtHour != null) {
      onCreateAtHour!();
      return;
    }
    showDialog(
      context: context,
      builder: (dialogCtx) => _SlotDialog(
        hour: hour,
        slot: slot,
        selectedDate: selectedDate,
        status: status,
        role: role,
        isOwnProfile: isOwnProfile,
        onRequest: () { Navigator.pop(dialogCtx); onRequest(); },
        onAccept:  onAccept  != null ? () { Navigator.pop(dialogCtx); onAccept!();  } : null,
        onReject:  onReject  != null ? () { Navigator.pop(dialogCtx); onReject!();  } : null,
        onCancel:  onCancel  != null ? () { Navigator.pop(dialogCtx); onCancel!();  } : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status  = slot?['status'] as String?;
    final isPast  = _isPast;
    final tappable = _isTappable(status);

    Color borderColor;
    Color bgColor;
    String statusLabel;
    IconData statusIcon;

    if (status == 'CONFIRMED') {
      borderColor = AppColors.success;
      bgColor     = AppColors.success.withAlpha(15);
      statusLabel = 'Confermato';
      statusIcon  = Icons.check_circle_outline_rounded;
    } else if (status == 'PENDING') {
      borderColor = AppColors.star;
      bgColor     = AppColors.star.withAlpha(15);
      statusLabel = 'In attesa';
      statusIcon  = Icons.hourglass_empty_rounded;
    } else {
      borderColor = isPast ? AppColors.borderSubtle : AppColors.glassBorder;
      bgColor     = AppColors.bg;
      statusLabel = isPast ? 'Passato' : 'Disponibile';
      statusIcon  = isPast ? Icons.remove_circle_outline_rounded : Icons.circle_outlined;
    }

    return GestureDetector(
      onTap: tappable ? () => _openDialog(context, status) : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Row(children: [
          SizedBox(width: 52, child: Text(
            '${hour.toString().padLeft(2, '0')}:00',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textStrong),
          )),
          Icon(statusIcon, size: 14,
            color: status == 'CONFIRMED' ? AppColors.success
                : status == 'PENDING' ? AppColors.star
                : AppColors.textTertiary),
          const SizedBox(width: 6),
          Expanded(child: Text(statusLabel, style: TextStyle(
            fontSize: 13,
            color: status == 'CONFIRMED' ? AppColors.success
                : status == 'PENDING' ? AppColors.star
                : isPast ? AppColors.textTertiary : AppColors.textSecondary,
          ))),
          if (status == null && onCreateAtHour != null && !isPast)
            const Icon(Icons.add_circle_outline_rounded, size: 18, color: AppColors.textTertiary)
          else if (tappable)
            const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textTertiary),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SLOT DIALOG
// ─────────────────────────────────────────────────────────────

class _SlotDialog extends StatelessWidget {
  final int hour;
  final Map<String, dynamic>? slot;
  final DateTime selectedDate;
  final String? status;
  final String role;
  final bool isOwnProfile;
  final VoidCallback onRequest;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onCancel;

  static const _months = ['', 'Gen', 'Feb', 'Mar', 'Apr', 'Mag', 'Giu',
      'Lug', 'Ago', 'Set', 'Ott', 'Nov', 'Dic'];

  const _SlotDialog({
    required this.hour, this.slot, required this.selectedDate, required this.status,
    required this.role, required this.isOwnProfile,
    required this.onRequest, this.onAccept, this.onReject, this.onCancel,
  });

  String get _timeStr =>
      '${hour.toString().padLeft(2, '0')}:00 – ${(hour + 1).toString().padLeft(2, '0')}:00';
  String get _dateStr =>
      '${selectedDate.day} ${_months[selectedDate.month]} ${selectedDate.year}';

  String _clientLabel() {
    if (slot == null) return 'Privato';
    if (slot!['isExternal'] == true) {
      final name = slot!['externalClientName'] as String? ?? 'Cliente esterno';
      return 'Esterno: $name';
    }
    final user = slot!['user'] as Map<String, dynamic>?;
    if (user != null) {
      final fn = (user['firstName'] as String? ?? '').trim();
      final ln = (user['lastName'] as String? ?? '').trim();
      final name = '$fn $ln'.trim();
      return 'Cliente app: ${name.isNotEmpty ? name : 'N/D'}';
    }
    return 'Privato';
  }

  @override
  Widget build(BuildContext context) {
    final String title;
    final IconData titleIcon;
    final Color iconColor;
    final String subtitle;
    final List<Widget> actions;

    if (status == 'CONFIRMED' && isOwnProfile) {
      title     = slot?['title'] as String? ?? 'Appuntamento confermato';
      titleIcon = Icons.check_circle_rounded;
      iconColor = AppColors.success;
      subtitle  = '';
      actions   = [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Chiudi')),
        if (onCancel != null)
          TextButton(
            onPressed: onCancel,
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Cancella'),
          ),
      ];
    } else if (status == 'CONFIRMED') {
      title     = 'Orario non disponibile';
      titleIcon = Icons.block_rounded;
      iconColor = AppColors.textTertiary;
      subtitle  = 'Questo orario è già occupato.';
      actions   = [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Chiudi'))];
    } else if (status == 'PENDING' && isOwnProfile) {
      title     = 'Richiesta in attesa';
      titleIcon = Icons.hourglass_empty_rounded;
      iconColor = AppColors.star;
      subtitle  = 'Un cliente ha richiesto questo orario. Accetta o rifiuta.';
      actions   = [
        TextButton(
          onPressed: onReject,
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: const Text('Rifiuta'),
        ),
        ElevatedButton(
          onPressed: onAccept,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
          child: const Text('Accetta'),
        ),
      ];
    } else if (status == 'PENDING') {
      title     = 'Orario non disponibile';
      titleIcon = Icons.hourglass_empty_rounded;
      iconColor = AppColors.star;
      subtitle  = 'Questo orario è in attesa di conferma da parte dello psicologo.';
      actions   = [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Chiudi'))];
    } else {
      // available slot, role == USER
      title     = 'Prenota questo orario';
      titleIcon = Icons.event_available_rounded;
      iconColor = AppColors.primary;
      subtitle  = 'Vuoi richiedere un appuntamento in questo orario?';
      actions   = [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
        ElevatedButton(onPressed: onRequest, child: const Text('Richiedi')),
      ];
    }

    final notes = slot?['notes'] as String?;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(titleIcon, color: iconColor, size: 22),
            const SizedBox(width: 10),
            Expanded(child: Text(title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textTertiary),
            const SizedBox(width: 6),
            Text(_dateStr, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textTertiary),
            const SizedBox(width: 6),
            Text(_timeStr, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ]),
          if (status == 'CONFIRMED' && isOwnProfile) ...[
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.person_outline_rounded, size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 6),
              Expanded(child: Text(_clientLabel(),
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
            ]),
            if (notes != null && notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Text(notes, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4)),
            ],
          ],
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
          ],
          const SizedBox(height: 4),
        ],
      ),
      actions: actions,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// DIALOG: NUOVO IMPEGNO (psicologo)
// ─────────────────────────────────────────────────────────────

class _NewEventDialog extends StatefulWidget {
  final DateTime initialDate;
  final int? initialHour;
  final String psychologistId;
  final VoidCallback onCreated;
  const _NewEventDialog({
    required this.initialDate,
    this.initialHour,
    required this.psychologistId,
    required this.onCreated,
  });
  @override
  State<_NewEventDialog> createState() => _NewEventDialogState();
}

class _NewEventDialogState extends State<_NewEventDialog> {
  final _titleCtrl       = TextEditingController();
  final _notesCtrl       = TextEditingController();
  final _extNameCtrl     = TextEditingController();

  late DateTime  _date;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  bool   _isExternal = false;
  bool   _saving     = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate;
    if (widget.initialHour != null) {
      _startTime = TimeOfDay(hour: widget.initialHour!, minute: 0);
      _endTime   = TimeOfDay(hour: (widget.initialHour! + 1) % 24, minute: 0);
    } else {
      final now = TimeOfDay.now();
      _startTime = now;
      _endTime   = TimeOfDay(hour: (now.hour + 1) % 24, minute: now.minute);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    _extNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime(bool isStart) async {
    final t = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (t != null) setState(() { if (isStart) _startTime = t; else _endTime = t; });
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Il titolo è obbligatorio');
      return;
    }
    if (_isExternal && _extNameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Inserisci il nome del contatto');
      return;
    }
    final start = DateTime(_date.year, _date.month, _date.day, _startTime.hour, _startTime.minute);
    final end   = DateTime(_date.year, _date.month, _date.day, _endTime.hour,   _endTime.minute);
    setState(() { _saving = true; _error = null; });
    try {
      await ApiService().createAppointment(
        title:              _titleCtrl.text.trim(),
        notes:              _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        startTime:          start,
        endTime:            end,
        isExternal:         _isExternal,
        externalClientName: _isExternal ? _extNameCtrl.text.trim() : null,
      );
      if (mounted) { Navigator.pop(context); widget.onCreated(); }
    } catch (e) {
      setState(() { _saving = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr  = '${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}';
    final startStr = '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}';
    final endStr   = '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}';

    return AlertDialog(
      title: const Text('Nuovo impegno'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Titolo *',
                hintText: 'es. Consulenza, Visita, Riunione…',
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today_rounded, size: 16),
              label: Text(dateStr),
              onPressed: _pickDate,
            )),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                icon: const Icon(Icons.access_time_rounded, size: 16),
                label: Text('Inizio  $startStr'),
                onPressed: () => _pickTime(true),
              )),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton.icon(
                icon: const Icon(Icons.access_time_rounded, size: 16),
                label: Text('Fine  $endStr'),
                onPressed: () => _pickTime(false),
              )),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              const Text('Tipo:', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Privato'),
                selected: !_isExternal,
                onSelected: (_) => setState(() => _isExternal = false),
              ),
              const SizedBox(width: 4),
              ChoiceChip(
                label: const Text('Esterno'),
                selected: _isExternal,
                onSelected: (_) => setState(() => _isExternal = true),
              ),
            ]),
            if (_isExternal) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _extNameCtrl,
                decoration: const InputDecoration(labelText: 'Nome contatto *'),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Note (opzionale)'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Salva'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TAB: RECENSIONI
// ─────────────────────────────────────────────────────────────

class _ReviewsTab extends StatefulWidget {
  final String psychologistId;
  const _ReviewsTab({required this.psychologistId});
  @override
  State<_ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends State<_ReviewsTab> with AutomaticKeepAliveClientMixin {
  final _api = ApiService();
  List<Map<String, dynamic>>? _reviews;
  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r = await _api.getReviewsByPsychologist(widget.psychologistId);
      setState(() { _reviews = r; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  double _avg(List<Map<String, dynamic>> reviews) {
    if (reviews.isEmpty) return 0;
    return reviews.fold<double>(0, (a, r) => a + ((r['rating'] as num?)?.toDouble() ?? 0)) /
        reviews.length;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
        OutlinedButton(onPressed: _load, child: const Text('Riprova')),
      ]));
    }
    final reviews = _reviews ?? [];
    if (reviews.isEmpty) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.star_border_rounded, size: 48, color: AppColors.textTertiary),
        SizedBox(height: 12),
        Text('Nessuna recensione ancora', style: TextStyle(color: AppColors.textSecondary)),
      ]));
    }
    final avg = _avg(reviews);
    return CustomScrollView(slivers: [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(children: [
            Text(avg.toStringAsFixed(1),
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.textStrong)),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _StarRow(rating: avg.round()),
              Text('${reviews.length} recension${reviews.length == 1 ? 'e' : 'i'}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ]),
          ]),
        ),
      ),
      const SliverToBoxAdapter(child: Divider()),
      SliverList(delegate: SliverChildBuilderDelegate(
        (ctx, i) => _ReviewCard(review: reviews[i]),
        childCount: reviews.length,
      )),
      const SliverToBoxAdapter(child: SizedBox(height: 16)),
    ]);
  }
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final rating  = (review['rating'] as num?)?.toInt() ?? 0;
    final comment = review['comment'] as String?;
    final user = review['User'] as Map<String, dynamic>?
        ?? review['user'] as Map<String, dynamic>? ?? {};
    final name = '${(user['firstName'] as String? ?? '').trim()} ${(user['lastName'] as String? ?? '').trim()}'.trim();
    final createdAt = review['createdAt'] != null
        ? DateTime.tryParse(review['createdAt'] as String)?.toLocal()
        : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.bgPanel,
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name.isNotEmpty ? name : 'Utente',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            if (createdAt != null)
              Text('${createdAt.day}/${createdAt.month}/${createdAt.year}',
                style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
          ])),
          _StarRow(rating: rating),
        ]),
        if (comment != null && comment.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(comment,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.5)),
        ],
      ]),
    );
  }
}

class _StarRow extends StatelessWidget {
  final int rating;
  const _StarRow({required this.rating});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(5, (i) => Icon(
      i < rating ? Icons.star_rounded : Icons.star_border_rounded,
      size: 14, color: AppColors.star,
    )),
  );
}

// ─────────────────────────────────────────────────────────────
// EDIT SHEET (bio, indirizzo, telefono, specializzazioni)
// ─────────────────────────────────────────────────────────────

class _PsychEditSheet extends StatefulWidget {
  final Map<String, dynamic> psych;
  final VoidCallback onSaved;
  const _PsychEditSheet({required this.psych, required this.onSaved});
  @override
  State<_PsychEditSheet> createState() => _PsychEditSheetState();
}

class _PsychEditSheetState extends State<_PsychEditSheet> {
  late final TextEditingController _bioCtrl;
  late final TextEditingController _phoneCtrl;
  final List<TextEditingController> _addrCtrls = [];
  final Map<String, bool> _specs = {};
  bool _isOnlineOnly      = false;
  bool _isPsychotherapist = false;
  bool _loading = false;

  static Map<String, String> get _specLabels => {
    for (final cat in kSpecCategories)
      for (final e in cat.specs.entries) e.key: e.value,
  };

  @override
  void initState() {
    super.initState();
    _bioCtrl   = TextEditingController(text: widget.psych['bio'] as String? ?? '');
    _phoneCtrl = TextEditingController(text: widget.psych['phone'] as String? ?? '');
    _isOnlineOnly      = widget.psych['isOnlineOnly'] == true;
    _isPsychotherapist = widget.psych['isPsychotherapist'] == true;

    final rawAddresses = widget.psych['addresses'] as List? ?? [];
    if (rawAddresses.isEmpty) {
      _addrCtrls.add(TextEditingController());
    } else {
      for (final a in rawAddresses) {
        _addrCtrls.add(TextEditingController(text: (a as Map)['address'] as String? ?? ''));
      }
    }

    for (final k in _specLabels.keys) _specs[k] = widget.psych[k] == true;
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    _phoneCtrl.dispose();
    for (final c in _addrCtrls) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      final addresses = _isOnlineOnly
          ? <String>[]
          : _addrCtrls.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();

      await ApiService().updatePsychologist(widget.psych['id'] as String, {
        'bio': _bioCtrl.text.trim(),
        'isOnlineOnly': _isOnlineOnly,
        'isPsychotherapist': _isPsychotherapist,
        'addresses': addresses,
        if (_phoneCtrl.text.trim().isNotEmpty) 'phone': _phoneCtrl.text.trim(),
        ..._specs,
      });
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSaved();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
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
          const Text('Modifica profilo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),

          TextField(
            controller: _bioCtrl,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Bio', alignLabelWithHint: true),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Telefono', prefixIcon: Icon(Icons.phone_outlined)),
          ),
          const SizedBox(height: 16),

          // Psicoterapeuta
          Row(children: [
            Switch(value: _isPsychotherapist, onChanged: (v) => setState(() => _isPsychotherapist = v)),
            const SizedBox(width: 8),
            const Text('Psicoterapeuta', style: TextStyle(fontSize: 14)),
          ]),
          const SizedBox(height: 4),

          // Solo online
          Row(children: [
            Switch(value: _isOnlineOnly, onChanged: (v) => setState(() => _isOnlineOnly = v)),
            const SizedBox(width: 8),
            const Text('Solo online', style: TextStyle(fontSize: 14)),
          ]),
          const SizedBox(height: 12),

          // Indirizzi
          if (!_isOnlineOnly) ...[
            const Text('Indirizzi studio', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
            const SizedBox(height: 8),
            for (int i = 0; i < _addrCtrls.length; i++) Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _addrCtrls[i],
                    decoration: InputDecoration(
                      labelText: _addrCtrls.length > 1 ? 'Indirizzo ${i + 1}' : 'Indirizzo',
                      hintText: 'Es. Via Roma 1, 59100 Prato',
                      prefixIcon: const Icon(Icons.location_on_outlined),
                    ),
                  ),
                ),
                if (_addrCtrls.length > 1) ...[
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: AppColors.error),
                    onPressed: () => setState(() {
                      _addrCtrls[i].dispose();
                      _addrCtrls.removeAt(i);
                    }),
                  ),
                ],
              ]),
            ),
            TextButton.icon(
              onPressed: () => setState(() => _addrCtrls.add(TextEditingController())),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Aggiungi indirizzo', style: TextStyle(fontSize: 13)),
            ),
            const SizedBox(height: 8),
          ],

          const Text('Specializzazioni', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
          const SizedBox(height: 10),
          ...kSpecCategories.map((cat) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(cat.icon, size: 12, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(cat.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              ]),
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 6, children: cat.specs.entries.map((e) {
                final selected = _specs[e.key] ?? false;
                return FilterChip(
                  label: Text(e.value, style: TextStyle(
                    fontSize: 12,
                    color: selected ? AppColors.textInverse : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  )),
                  selected: selected,
                  onSelected: (v) => setState(() => _specs[e.key] = v),
                  selectedColor: AppColors.bgInverse,
                  checkmarkColor: AppColors.textInverse,
                  backgroundColor: AppColors.bg,
                  side: BorderSide(color: selected ? AppColors.bgInverse : AppColors.glassBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                );
              }).toList()),
            ]),
          )),
          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _loading ? null : _save,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            child: _loading
                ? const SizedBox(height: 20, width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.bg))
                : const Text('Salva'),
          ),
        ]),
      ),
    );
  }
}
