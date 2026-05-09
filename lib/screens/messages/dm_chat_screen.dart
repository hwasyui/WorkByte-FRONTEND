import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../models/dm_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dm_provider.dart';
import '../../services/dm_service.dart';

class DmChatScreen extends StatefulWidget {
  final DmThread thread;
  final String currentUserId;

  const DmChatScreen({
    super.key,
    required this.thread,
    required this.currentUserId,
  });

  @override
  State<DmChatScreen> createState() => _DmChatScreenState();
}

class _DmChatScreenState extends State<DmChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late DmThread _thread;
  List<DmMessage> _messages = [];
  bool _loadingMessages = true;
  bool _isSending = false;
  bool _hasMore = false;
  String? _nextCursor;
  bool _loadingMore = false;

  // Poll interval for real-time feel without WebSocket package
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _thread = widget.thread;
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Load older messages when scrolled to top
    if (_scrollController.position.pixels <= 80 &&
        _hasMore &&
        !_loadingMore) {
      _loadOlderMessages();
    }
  }

  Future<void> _init() async {
    await _loadMessages();
    await _markRead();
    _startPolling();
  }

  Future<void> _loadMessages() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    setState(() => _loadingMessages = true);
    try {
      final result =
          await DmService.getMessages(token, _thread.threadId, limit: 50);
      final list = (result['messages'] as List? ?? [])
          .map((e) => DmMessage.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() {
        _messages = list;
        _hasMore = result['has_more'] as bool? ?? false;
        _nextCursor = result['next_cursor'] as String?;
        _loadingMessages = false;
      });
      _scrollToBottom();
    } catch (_) {
      setState(() => _loadingMessages = false);
    }
  }

  Future<void> _loadOlderMessages() async {
    if (_loadingMore || !_hasMore || _nextCursor == null) return;
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    setState(() => _loadingMore = true);
    try {
      final result = await DmService.getMessages(
        token,
        _thread.threadId,
        limit: 50,
        before: _nextCursor,
      );
      final older = (result['messages'] as List? ?? [])
          .map((e) => DmMessage.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() {
        _messages = [...older, ..._messages];
        _hasMore = result['has_more'] as bool? ?? false;
        _nextCursor = result['next_cursor'] as String?;
        _loadingMore = false;
      });
    } catch (_) {
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _markRead() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      await DmService.markRead(token, _thread.threadId);
    } catch (_) {}
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted) return;
      final token = context.read<AuthProvider>().token;
      if (token == null) return;
      try {
        final result = await DmService.getMessages(
            token, _thread.threadId,
            limit: 50);
        final list = (result['messages'] as List? ?? [])
            .map((e) => DmMessage.fromJson(e as Map<String, dynamic>))
            .toList();
        if (!mounted) return;
        final lastKnown =
            _messages.isNotEmpty ? _messages.last.dmMessageId : null;
        final hasNew = list.isNotEmpty &&
            list.last.dmMessageId != lastKnown;
        if (hasNew) {
          setState(() {
            _messages = list;
            _hasMore = result['has_more'] as bool? ?? false;
            _nextCursor = result['next_cursor'] as String?;
          });
          _scrollToBottom();
          await _markRead();
        }
      } catch (_) {}
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;
    if (_thread.isDeclined) return;

    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      final msg =
          await DmService.sendMessage(token, _thread.threadId, text);
      setState(() {
        _messages.add(msg);
        _isSending = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', ''),
              style: GoogleFonts.poppins()),
          backgroundColor: Colors.redAccent,
        ),
      );
      setState(() => _isSending = false);
    }
  }

  Future<void> _acceptThread() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    final dmProvider = context.read<DmProvider>();
    final ok = await dmProvider.acceptThread(token, _thread.threadId);
    if (!mounted) return;
    if (ok) {
      setState(() =>
          _thread = dmProvider.threads.firstWhere(
              (t) => t.threadId == _thread.threadId,
              orElse: () => _thread.copyWithStatus('active')));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Request accepted!', style: GoogleFonts.poppins()),
        backgroundColor: Colors.green,
      ));
    }
  }

  Future<void> _declineThread() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    final dmProvider = context.read<DmProvider>();
    final ok = await dmProvider.declineThread(token, _thread.threadId);
    if (!mounted) return;
    if (ok) {
      setState(() =>
          _thread = dmProvider.threads.firstWhere(
              (t) => t.threadId == _thread.threadId,
              orElse: () => _thread.copyWithStatus('declined')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final otherName = _thread.otherUser?.displayName ?? 'User';
    final isReceiver =
        widget.currentUserId != _thread.initiatorId;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: Color(0xFF333333)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  _thread.otherUser?.initials ?? '?',
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  otherName,
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827)),
                ),
                Text(
                  _threadStatusLabel(_thread.status),
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: _statusColor(_thread.status)),
                ),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFF0F0F0)),
        ),
      ),
      body: Column(
        children: [
          // Request banner (shown to receiver when thread is in 'request' status)
          if (_thread.isRequest && isReceiver)
            _RequestBanner(
              onAccept: _acceptThread,
              onDecline: _declineThread,
            ),

          // Declined banner
          if (_thread.isDeclined)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              color: Colors.red.shade50,
              child: Text(
                'This conversation has been declined.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w500),
              ),
            ),

          // Messages list
          Expanded(
            child: _loadingMessages
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary, strokeWidth: 2))
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        itemCount:
                            _messages.length + (_loadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (_loadingMore && index == 0) {
                            return const Padding(
                              padding: EdgeInsets.all(12),
                              child: Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary),
                                ),
                              ),
                            );
                          }
                          final msgIndex =
                              _loadingMore ? index - 1 : index;
                          return _buildMessage(_messages[msgIndex]);
                        },
                      ),
          ),

          // Input bar
          if (!_thread.isDeclined)
            _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded,
              size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('No messages yet',
              style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500)),
          const SizedBox(height: 6),
          Text('Start the conversation below.',
              style: GoogleFonts.poppins(
                  fontSize: 13, color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  Widget _buildMessage(DmMessage msg) {
    final isOwn = msg.senderId == widget.currentUserId;

    // System / metadata card messages
    if (msg.isContractAccepted) {
      return _ContractAcceptedCard(metadata: msg.metadata ?? {});
    }
    if (msg.isJobPitch) {
      return _JobPitchCard(
          metadata: msg.metadata ?? {}, isOwn: isOwn, message: msg);
    }
    if (msg.isContractPdfShared) {
      return _PdfSharedCard(
          metadata: msg.metadata ?? {}, isOwn: isOwn, message: msg);
    }

    // Regular bubble
    return _MessageBubble(msg: msg, isOwn: isOwn);
  }

  Widget _buildInputBar() {
    final canSend = _thread.isActive ||
        (_thread.isRequest &&
            widget.currentUserId == _thread.initiatorId &&
            _messages.isEmpty);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.04),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                enabled: canSend,
                minLines: 1,
                maxLines: 4,
                style: GoogleFonts.poppins(fontSize: 13),
                decoration: InputDecoration(
                  hintText: canSend
                      ? 'Type a message...'
                      : 'Waiting for request to be accepted...',
                  hintStyle: GoogleFonts.poppins(
                      fontSize: 13, color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide:
                        BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide:
                        BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide:
                        const BorderSide(color: AppColors.primary),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide:
                        BorderSide(color: Colors.grey.shade100),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 48,
              height: 48,
              child: Material(
                color: (canSend && !_isSending)
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha:0.4),
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: (canSend && !_isSending)
                      ? _sendMessage
                      : null,
                  child: _isSending
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white)),
                        )
                      : const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _threadStatusLabel(String status) {
    switch (status) {
      case 'active':
        return 'Active';
      case 'request':
        return 'Request pending';
      case 'declined':
        return 'Declined';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return const Color(0xFF059669);
      case 'request':
        return const Color(0xFFD97706);
      case 'declined':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

// ── Extension to create a copy with updated status ───────────────────────────

extension _DmThreadCopy on DmThread {
  DmThread copyWithStatus(String newStatus) => DmThread(
        threadId: threadId,
        userAId: userAId,
        userBId: userBId,
        initiatorId: initiatorId,
        status: newStatus,
        jobPostId: jobPostId,
        contractId: contractId,
        createdAt: createdAt,
        updatedAt: updatedAt,
        otherUser: otherUser,
        jobPost: jobPost,
        lastMessage: lastMessage,
        unreadCount: unreadCount,
      );
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _RequestBanner extends StatelessWidget {
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _RequestBanner({required this.onAccept, required this.onDecline});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: const Color(0xFFFFFBEB),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Message Request',
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF92400E)),
          ),
          const SizedBox(height: 4),
          Text(
            'This person sent you a message request. Accept to chat freely.',
            style: GoogleFonts.poppins(
                fontSize: 12, color: const Color(0xFF78350F)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDecline,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text('Decline',
                      style: GoogleFonts.poppins(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text('Accept',
                      style: GoogleFonts.poppins(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final DmMessage msg;
  final bool isOwn;

  const _MessageBubble({required this.msg, required this.isOwn});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.72),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isOwn ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isOwn ? 18 : 4),
                  bottomRight: Radius.circular(isOwn ? 4 : 18),
                ),
                border: isOwn
                    ? null
                    : Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.messageText,
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: isOwn
                            ? Colors.white
                            : const Color(0xFF111827),
                        height: 1.4),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(context, msg.sentAt),
                        style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: isOwn
                                ? Colors.white.withValues(alpha:0.75)
                                : Colors.grey.shade400),
                      ),
                      if (isOwn) ...[
                        const SizedBox(width: 4),
                        Icon(
                          msg.isRead
                              ? Icons.done_all_rounded
                              : Icons.done_rounded,
                          size: 13,
                          color: msg.isRead
                              ? Colors.lightBlueAccent
                              : Colors.white.withValues(alpha:0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(BuildContext context, DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final tod = TimeOfDay.fromDateTime(dt);
    if (dt.year == now.year &&
        dt.month == now.month &&
        dt.day == now.day) {
      return tod.format(context);
    }
    return '${dt.day}/${dt.month} ${tod.format(context)}';
  }
}

// ── Metadata cards ────────────────────────────────────────────────────────────

class _ContractAcceptedCard extends StatelessWidget {
  final Map<String, dynamic> metadata;

  const _ContractAcceptedCard({required this.metadata});

  @override
  Widget build(BuildContext context) {
    final contractTitle =
        metadata['contract_title'] as String? ?? 'Contract';
    final roleTitle = metadata['role_title'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha:0.07),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppColors.primary.withValues(alpha:0.25)),
          ),
          child: Column(
            children: [
              const Icon(Icons.handshake_outlined,
                  color: AppColors.primary, size: 28),
              const SizedBox(height: 6),
              Text(
                'Contract Accepted',
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary),
              ),
              const SizedBox(height: 2),
              Text(
                contractTitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 12, color: const Color(0xFF374151)),
              ),
              if (roleTitle.isNotEmpty)
                Text(
                  roleTitle,
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: const Color(0xFF6B7280)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JobPitchCard extends StatelessWidget {
  final Map<String, dynamic> metadata;
  final bool isOwn;
  final DmMessage message;

  const _JobPitchCard({
    required this.metadata,
    required this.isOwn,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final jobTitle =
        metadata['job_title'] as String? ?? 'Job Opportunity';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha:0.04),
                    blurRadius: 8),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.work_outline_rounded,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Job Pitch',
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  jobTitle,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827)),
                ),
                const SizedBox(height: 6),
                Text(
                  message.messageText,
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: const Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PdfSharedCard extends StatelessWidget {
  final Map<String, dynamic> metadata;
  final bool isOwn;
  final DmMessage message;

  const _PdfSharedCard({
    required this.metadata,
    required this.isOwn,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final pdfUrl = metadata['pdf_url'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha:0.04),
                    blurRadius: 8),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.picture_as_pdf_outlined,
                        color: Colors.redAccent, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Contract PDF Shared',
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.redAccent),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  message.messageText,
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: const Color(0xFF374151)),
                ),
                if (pdfUrl.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      // URL launch handled by url_launcher if available
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('PDF URL: $pdfUrl',
                            style: GoogleFonts.poppins(fontSize: 12)),
                      ));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.open_in_new,
                              color: Colors.white, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            'View PDF',
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
