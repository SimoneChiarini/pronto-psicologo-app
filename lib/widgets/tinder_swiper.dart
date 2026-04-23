import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class TinderSwiper extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final void Function(Map<String, dynamic> item, Map<String, dynamic> conversation) onAccepted;
  final void Function(Map<String, dynamic> item)? onRejected;

  const TinderSwiper({
    super.key,
    required this.items,
    required this.onAccepted,
    this.onRejected,
  });

  @override
  State<TinderSwiper> createState() => _TinderSwiperState();
}

class _TinderSwiperState extends State<TinderSwiper>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  Offset _dragOffset = Offset.zero;
  bool _isProcessing = false;

  late AnimationController _snapController;
  late Animation<Offset> _snapAnimation;

  static const double _swipeThreshold = 100.0;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _snapAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _snapController, curve: Curves.elasticOut));
    _snapController.addListener(() {
      setState(() => _dragOffset = _snapAnimation.value);
    });
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails _) => _snapController.stop();

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() => _dragOffset += details.delta);
  }

  Future<void> _onPanEnd(DragEndDetails _) async {
    if (_dragOffset.dx > _swipeThreshold) {
      await _swipe(right: true);
    } else if (_dragOffset.dx < -_swipeThreshold) {
      await _swipe(right: false);
    } else {
      _snapBack();
    }
  }

  void _snapBack() {
    _snapAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _snapController, curve: Curves.elasticOut));
    _snapController.forward(from: 0);
  }

  Future<void> _swipe({required bool right}) async {
    if (_isProcessing) return;
    final item = widget.items[_index];

    final targetX = right ? 600.0 : -600.0;
    _snapAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset(targetX, _dragOffset.dy + 100),
    ).animate(CurvedAnimation(parent: _snapController, curve: Curves.easeIn));
    await _snapController.forward(from: 0);

    if (right) {
      setState(() => _isProcessing = true);
      try {
        final conversation = await ApiService().createConversation(
          psychologistId: item['psychologistId'] as String,
          firstQuestionId: item['questionId'] as String,
          firstAnswerId: item['id'] as String,
        );
        setState(() {
          _index++;
          _dragOffset = Offset.zero;
          _isProcessing = false;
        });
        widget.onAccepted(item, conversation);
        return;
      } catch (e) {
        setState(() => _isProcessing = false);
      }
    }

    widget.onRejected?.call(item);
    setState(() {
      _index++;
      _dragOffset = Offset.zero;
    });
  }

  double get _rotation => (_dragOffset.dx / 300) * 0.25;
  double get _overlayOpacity => (_dragOffset.dx.abs() / _swipeThreshold).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final remaining = widget.items.length - _index;

    if (remaining <= 0) return const _EmptyState();

    return SizedBox.expand(
      child: Stack(
      alignment: Alignment.center,
      children: [
        if (remaining > 1)
          _buildCard(widget.items[_index + 1], scale: 0.94, offsetY: 16),
        if (remaining > 2)
          _buildCard(widget.items[_index + 2], scale: 0.88, offsetY: 32),

        GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: Transform.translate(
            offset: _dragOffset,
            child: Transform.rotate(
              angle: _rotation,
              child: Stack(
                children: [
                  _AnswerCard(item: widget.items[_index]),
                  if (_dragOffset.dx > 0)
                    _SwipeOverlay(
                      label: 'CONTATTA',
                      color: AppColors.success,
                      icon: Icons.favorite_rounded,
                      opacity: _overlayOpacity,
                      alignment: Alignment.topLeft,
                    ),
                  if (_dragOffset.dx < 0)
                    _SwipeOverlay(
                      label: 'PASSA',
                      color: AppColors.error,
                      icon: Icons.close_rounded,
                      opacity: _overlayOpacity,
                      alignment: Alignment.topRight,
                    ),
                ],
              ),
            ),
          ),
        ),

        Positioned(
          bottom: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ActionButton(
                icon: Icons.close_rounded,
                color: AppColors.error,
                onTap: () => _swipe(right: false),
              ),
              const SizedBox(width: 40),
              _ActionButton(
                icon: Icons.favorite_rounded,
                color: AppColors.success,
                onTap: () => _swipe(right: true),
              ),
            ],
          ),
        ),
      ],
    ));
  }

  Widget _buildCard(Map<String, dynamic> item, {double scale = 1.0, double offsetY = 0}) {
    return Transform.translate(
      offset: Offset(0, offsetY),
      child: Transform.scale(
        scale: scale,
        child: _AnswerCard(item: item, dimmed: true),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Card risposta / psicologo
// ─────────────────────────────────────────────────────────────

class _AnswerCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool dimmed;

  const _AnswerCard({required this.item, this.dimmed = false});

  @override
  Widget build(BuildContext context) {
    final psych = item['psychologist'] as Map<String, dynamic>? ?? {};
    final psychUser = psych['user'] as Map<String, dynamic>? ?? {};
    final question = item['question'] as Map<String, dynamic>? ?? {};
    final imageUrl = psych['profileImage'] as String?;

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
          width: MediaQuery.of(context).size.width - 32,
          height: double.infinity,
          decoration: BoxDecoration(
            color: dimmed ? AppColors.surface : AppColors.bg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.glassBorder),
            boxShadow: dimmed
                ? []
                : [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header psicologo
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                  border: Border(bottom: BorderSide(color: AppColors.glassBorder)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
                          ? NetworkImage(imageUrl)
                          : null,
                      backgroundColor: AppColors.glassBg,
                      child: (imageUrl == null || imageUrl.isEmpty)
                          ? const Icon(Icons.person_rounded, size: 30, color: AppColors.textSecondary)
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  () {
                                    final fn = (psychUser['firstName'] as String? ?? '').trim();
                                    final ln = (psychUser['lastName'] as String? ?? '').trim();
                                    final full = '$fn $ln'.trim();
                                    return full.isNotEmpty ? full : 'Psicologo';
                                  }(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (psych['verified'] == true)
                                const Tooltip(
                                  message: 'Verificato',
                                  child: Icon(Icons.verified_rounded, color: Colors.lightBlueAccent, size: 16),
                                ),
                            ],
                          ),
                          if (psych['alboCode'] != null && (psych['alboCode'] as String).isNotEmpty)
                            Text(
                              'Albo: ${psych['alboCode']}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          if (psych['address'] != null && (psych['address'] as String).isNotEmpty)
                            Text(
                              psych['address'] as String,
                              style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (item['distanceKm'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Row(children: [
                                const Icon(Icons.location_on_rounded, size: 12, color: AppColors.textSecondary),
                                const SizedBox(width: 2),
                                Text(
                                  '${item['distanceKm']} km da te',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                ),
                              ]),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Bio
              if (psych['bio'] != null && (psych['bio'] as String).isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Text(
                    psych['bio'] as String,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Divider(color: AppColors.glassBorder, height: 1),
              ),

              // Domanda originale
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'In risposta a: ${question['title'] ?? ''}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textTertiary, fontStyle: FontStyle.italic),
                ),
              ),

              const SizedBox(height: 8),

              // Risposta
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 84),
                  child: Text(
                    item['content'] as String? ?? '',
                    style: const TextStyle(fontSize: 15, height: 1.5, color: AppColors.textPrimary),
                    overflow: TextOverflow.fade,
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Overlay swipe LIKE / NOPE
// ─────────────────────────────────────────────────────────────

class _SwipeOverlay extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final double opacity;
  final Alignment alignment;

  const _SwipeOverlay({
    required this.label,
    required this.color,
    required this.icon,
    required this.opacity,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Align(
        alignment: alignment,
        child: Opacity(
          opacity: opacity,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                border: Border.all(color: color, width: 2.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: color, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Bottoni azione
// ─────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Icon(icon, color: AppColors.bgInverse, size: 20),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Stato vuoto
// ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.hourglass_top_rounded, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 20),
          const Text(
            'In attesa di altre risposte',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          const Text(
            'Gli psicologi stanno leggendo\nla tua domanda. Torna presto!',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }
}
