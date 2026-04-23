import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class ConversationPage extends StatefulWidget {
  final String conversationId;
  final String psychologistId;
  final String psychologistLabel;
  final String userId;
  final String role;
  final String? questionTitle;
  final String? answerContent;

  const ConversationPage({
    super.key,
    required this.conversationId,
    required this.psychologistId,
    required this.psychologistLabel,
    required this.userId,
    required this.role,
    this.questionTitle,
    this.answerContent,
  });

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  bool _sending = false;
  bool _alreadyReviewed = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final msgs = await ApiService().getMessages(widget.conversationId);
      setState(() {
        _messages = msgs;
        _loading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ApiService().sendMessage(widget.conversationId, text);
      _messageController.clear();
      await _loadMessages();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _openReviewDialog() {
    showDialog(
      context: context,
      builder: (_) => _ReviewDialog(
        psychologistLabel: widget.psychologistLabel,
        psychologistId: widget.psychologistId,
        onSubmitted: () {
          setState(() => _alreadyReviewed = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recensione inviata, grazie!')),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: _ConversationAppBar(
        psychologistLabel: widget.psychologistLabel,
        role: widget.role,
        alreadyReviewed: _alreadyReviewed,
        onReview: _openReviewDialog,
        onRefresh: _loadMessages,
      ),
      body: Column(
        children: [
          if (widget.questionTitle != null || widget.answerContent != null)
            _ContextBanner(
              questionTitle: widget.questionTitle,
              answerContent: widget.answerContent,
            ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.bgInverse))
                : _messages.isEmpty
                    ? _EmptyChat(psychologistLabel: widget.psychologistLabel)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: _messages.length,
                        itemBuilder: (ctx, i) {
                          final msg = _messages[i];
                          final isMine = widget.role == 'USER'
                              ? msg['senderUserId'] == widget.userId
                              : msg['senderPsychId'] != null;
                          return _MessageBubble(
                            content: msg['content'] as String,
                            isMine: isMine,
                            createdAt: msg['createdAt'] as String?,
                          );
                        },
                      ),
          ),

          _MessageInput(
            controller: _messageController,
            sending: _sending,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// AppBar
// ─────────────────────────────────────────────────────────────

class _ConversationAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String psychologistLabel;
  final String role;
  final bool alreadyReviewed;
  final VoidCallback onReview;
  final VoidCallback onRefresh;

  const _ConversationAppBar({
    required this.psychologistLabel,
    required this.role,
    required this.alreadyReviewed,
    required this.onReview,
    required this.onRefresh,
  });

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.glassBorder)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textSecondary, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  psychologistLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textStrong,
                    letterSpacing: -0.01,
                  ),
                ),
                const Text(
                  'Conversazione',
                  style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
          if (role == 'USER' && !alreadyReviewed)
            IconButton(
              icon: const Icon(Icons.star_outline_rounded, color: AppColors.textTertiary, size: 18),
              tooltip: 'Lascia una recensione',
              onPressed: onReview,
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textTertiary, size: 18),
            tooltip: 'Aggiorna',
            onPressed: onRefresh,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Banner contesto domanda/risposta
// ─────────────────────────────────────────────────────────────

class _ContextBanner extends StatefulWidget {
  final String? questionTitle;
  final String? answerContent;
  const _ContextBanner({this.questionTitle, this.answerContent});

  @override
  State<_ContextBanner> createState() => _ContextBannerState();
}

class _ContextBannerState extends State<_ContextBanner> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        width: double.infinity,
        color: AppColors.bgPanel,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 13, color: AppColors.textTertiary),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Tocca per vedere domanda e risposta iniziale',
                    style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                  ),
                ),
                Icon(
                  _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  color: AppColors.textTertiary,
                  size: 16,
                ),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 8),
              if (widget.questionTitle != null)
                _BannerRow(label: 'Domanda', text: widget.questionTitle!),
              if (widget.answerContent != null)
                _BannerRow(label: 'Risposta', text: widget.answerContent!),
            ],
          ],
        ),
      ),
    );
  }
}

class _BannerRow extends StatelessWidget {
  final String label;
  final String text;
  const _BannerRow({required this.label, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.textTertiary, fontWeight: FontWeight.w600, letterSpacing: 0.04)),
          Text(text, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary), maxLines: 3, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Stato vuoto chat
// ─────────────────────────────────────────────────────────────

class _EmptyChat extends StatelessWidget {
  final String psychologistLabel;
  const _EmptyChat({required this.psychologistLabel});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.chat_bubble_outline_rounded, size: 40, color: AppColors.borderSubtle),
          const SizedBox(height: 14),
          const Text('Nessun messaggio ancora',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(
            'Inizia la conversazione con $psychologistLabel',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Bubble messaggio
// ─────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final String content;
  final bool isMine;
  final String? createdAt;

  const _MessageBubble({required this.content, required this.isMine, this.createdAt});

  String _formatTime(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMine ? AppColors.bgInverse : AppColors.borderFaint,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isMine ? 12 : 3),
            bottomRight: Radius.circular(isMine ? 3 : 12),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              content,
              style: TextStyle(
                color: isMine ? AppColors.textInverse : AppColors.textStrong,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              _formatTime(createdAt),
              style: TextStyle(
                fontSize: 10.5,
                color: isMine ? Colors.white.withOpacity(0.5) : AppColors.textTertiary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Input messaggio
// ─────────────────────────────────────────────────────────────

class _MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  const _MessageInput({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 10,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 10,
      ),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(top: BorderSide(color: AppColors.glassBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Scrivi un messaggio…',
                hintStyle: const TextStyle(color: AppColors.textPlaceholder, fontSize: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: AppColors.glassBorder),
                ),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: AppColors.glassBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: AppColors.textPrimary, width: 1.5),
                ),
              ),
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: sending ? null : onSend,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: sending ? AppColors.borderSubtle : AppColors.bgInverse,
                borderRadius: BorderRadius.circular(5),
              ),
              child: sending
                  ? const Padding(
                      padding: EdgeInsets.all(9),
                      child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.textInverse),
                    )
                  : const Icon(Icons.arrow_upward_rounded, color: AppColors.textInverse, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Dialog recensione
// ─────────────────────────────────────────────────────────────

class _ReviewDialog extends StatefulWidget {
  final String psychologistLabel;
  final String psychologistId;
  final VoidCallback onSubmitted;

  const _ReviewDialog({
    required this.psychologistLabel,
    required this.psychologistId,
    required this.onSubmitted,
  });

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleziona almeno una stella')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await ApiService().createReview(
        psychologistId: widget.psychologistId,
        rating: _rating,
        comment: _commentController.text.trim().isNotEmpty
            ? _commentController.text.trim()
            : null,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onSubmitted();
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
    return AlertDialog(
      title: const Text('Lascia una recensione'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.psychologistLabel,
              style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
          const SizedBox(height: 16),
          const Text('Valutazione',
              style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              return GestureDetector(
                onTap: () => setState(() => _rating = i + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    i < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: AppColors.star,
                    size: 34,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentController,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            decoration: const InputDecoration(
              labelText: 'Commento (facoltativo)',
              alignLabelWithHint: true,
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.textInverse))
              : const Text('Invia'),
        ),
      ],
    );
  }
}
