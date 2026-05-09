import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dm_provider.dart';
import '../../models/dm_model.dart';
import 'dm_thread_list.dart';

class DMChatScreen extends StatefulWidget {
  final DMThreadModel thread;

  const DMChatScreen({super.key, required this.thread});

  @override
  State<DMChatScreen> createState() => _DMChatScreenState();
}

class _DMChatScreenState extends State<DMChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  bool _showVoiceNote = false;
  bool _isRecording = false;
  bool _isLoadingMessages = true;

  late AnimationController _sendButtonController;
  late Animation<double> _sendButtonScale;
  late AnimationController _recordingController;
  late Animation<double> _recordingScale;

  @override
  void initState() {
    super.initState();

    _sendButtonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _sendButtonScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _sendButtonController, curve: Curves.easeInOut),
    );

    _messageController.addListener(() => setState(() {}));

    _recordingController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _recordingScale = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _recordingController, curve: Curves.elasticOut),
    );

    _loadMessages();
    _scrollToBottom();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _sendButtonController.dispose();
    _recordingController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    setState(() => _isLoadingMessages = true);

    await context.read<DMProvider>().fetchMessages(
      token,
      widget.thread.threadId,
    );

    await context.read<DMProvider>().markThreadAsRead(
      token: token,
      threadId: widget.thread.threadId,
    );

    setState(() => _isLoadingMessages = false);
    _scrollToBottom();
  }

  Future<void> _loadOlderMessages() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    await context.read<DMProvider>().fetchOlderMessages(
      token,
      widget.thread.threadId,
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    final text = _messageController.text.trim();
    _messageController.clear();
    _focusNode.unfocus();

    _sendButtonController.forward();
    await _sendMessageCore(token, text);
    _sendButtonController.reverse();
  }

  Future<void> _sendMessageCore(String token, String text) async {
    final message = await context.read<DMProvider>().sendMessage(
      token: token,
      threadId: widget.thread.threadId,
      messageText: text,
    );

    context.read<DMProvider>().insertIncomingMessage(
      widget.thread.threadId,
      message,
    );

    _scrollToBottom();
  }

  void _toggleVoiceNote() {
    setState(() => _showVoiceNote = !_showVoiceNote);
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthProvider>().userId ?? '';
    final messages = context.select<DMProvider, List<DMMessageModel>>(
      (dm) => dm.messagesFor(widget.thread.threadId),
    );

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(currentUserId),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildMessageList(messages, currentUserId)),
            if (_isLoadingMessages)
              const LinearProgressIndicator(
                backgroundColor: Color(0xFFF0F0F1),
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(String currentUserId) {
    final other = widget.thread.otherUser;
    final name = other?.fullName?.trim().isNotEmpty == true
        ? other!.fullName!.trim()
        : 'Unknown User';
    final role = other?.role ?? 'user';
    final avatarUrl = other?.profilePictureUrl;
    final isRequest = widget.thread.status == 'request';
    final isIncomingRequest =
        isRequest && widget.thread.initiatorId != currentUserId;

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leadingWidth: 54,
      leading: Container(
        margin: const EdgeInsets.only(left: 14),
        child: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1A1A2E),
            size: 18,
          ),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          Text(
            _roleLabel(role),
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: const Color(0xFF7D7D7D),
            ),
          ),
        ],
      ),
      actions: [
        if (isIncomingRequest)
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Accept Request',
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          )
        else
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: Color(0xFF7D7D7D),
              size: 20,
            ),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'block', child: Text('Block')),
              const PopupMenuItem(value: 'report', child: Text('Report')),
              const PopupMenuItem(
                value: 'mute',
                child: Text('Mute notifications'),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildMessageList(
    List<DMMessageModel> messages,
    String currentUserId,
  ) {
    final displayMessages = messages.reversed.toList();

    return Column(
      children: [
        if (displayMessages.isEmpty)
          Expanded(child: _buildEmptyChat())
        else
          Expanded(
            child: GestureDetector(
              onTap: () => _focusNode.unfocus(),
              child: ListView.builder(
                controller: _scrollController,
                reverse: true,
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 90),
                itemCount: displayMessages.length,
                itemBuilder: (context, index) {
                  final message = displayMessages[index];
                  final isOwn = message.senderId == currentUserId;
                  return _buildMessageBubble(message, isOwn);
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMessageBubble(DMMessageModel message, bool isOwn) {
    final isSystem = message.isSystemEvent;
    final timeText = _formatMessageTime(message.sentAt);

    if (isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE9ECEF)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: const Color(0xFF6C757D),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _systemMessageLabel(message.metadata?['type']),
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6C757D),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isOwn
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isOwn) ...[_buildAvatarForBubble(), const SizedBox(width: 9)],
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showMessageActions(message),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: message.attachments.isNotEmpty ? 12 : 14,
                ),
                decoration: BoxDecoration(
                  gradient: isOwn
                      ? const LinearGradient(
                          colors: [Color(0xFF0DB4A5), Color(0xFF00A89E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : LinearGradient(
                          colors: [
                            const Color(0xFFF8F9FA),
                            Colors.white.withValues(alpha: 0.9),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(22),
                    topRight: const Radius.circular(22),
                    bottomLeft: Radius.circular(isOwn ? 22 : 6),
                    bottomRight: Radius.circular(isOwn ? 6 : 22),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isOwn
                          ? AppColors.primary.withValues(alpha: 0.25)
                          : Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: isOwn
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (message.attachments.isNotEmpty)
                      _buildAttachmentPreview(message.attachments.first),
                    if (message.messageText.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          message.messageText.trim(),
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            color: isOwn
                                ? Colors.white
                                : const Color(0xFF1A1A2E),
                            height: 1.45,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            timeText,
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              color: isOwn
                                  ? Colors.white.withValues(alpha: 0.8)
                                  : const Color(0xFF9A9AA3),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (isOwn) ...[
                            const SizedBox(width: 6),
                            Icon(
                              message.isRead
                                  ? Icons.done_all_rounded
                                  : Icons.done_rounded,
                              size: 14,
                              color: message.isRead
                                  ? const Color(0xFFBDEBFF)
                                  : Colors.white.withValues(alpha: 0.85),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isOwn) const SizedBox(width: 9),
        ],
      ),
    );
  }

  Widget _buildAttachmentPreview(DMAttachmentModel attachment) {
    switch (attachment.fileType) {
      case 'image':
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            attachment.fileUrl,
            width: 180,
            height: 180,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _attachmentPlaceholder('Image'),
          ),
        );
      case 'video':
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 180,
                height: 180,
                color: const Color(0xFFF5F5F5),
                child: const Icon(
                  Icons.play_circle_outline_rounded,
                  size: 48,
                  color: Colors.grey,
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Video',
                  style: GoogleFonts.poppins(fontSize: 10, color: Colors.white),
                ),
              ),
            ),
          ],
        );
      case 'audio':
      case 'voice_note':
        return Container(
          width: 220,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEBEBF0)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0DB4A5), Color(0xFF00A89E)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.mic_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attachment.filename,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A2E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${attachment.durationSeconds?.toStringAsFixed(0) ?? '0'}s',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: const Color(0xFF7D7D7D),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.play_arrow_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        );
      default:
        return _attachmentPlaceholder(attachment.fileType);
    }
  }

  Widget _attachmentPlaceholder(String type) {
    return Container(
      width: 180,
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_attachmentIcon(type), size: 32, color: const Color(0xFFADB5BD)),
          const SizedBox(height: 8),
          Text(
            type.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: const Color(0xFFADB5BD),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _attachmentIcon(String type) {
    switch (type) {
      case 'image':
        return Icons.image_outlined;
      case 'video':
        return Icons.video_file_outlined;
      case 'audio':
      case 'voice_note':
        return Icons.audiotrack_outlined;
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  Widget _buildMessageInput() {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(18, 8, 18, 18),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFF0F0F1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: _toggleVoiceNote,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _showVoiceNote
                      ? AppColors.primary
                      : const Color(0xFFF7F7F8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _showVoiceNote ? Icons.keyboard_rounded : Icons.mic_rounded,
                  size: 20,
                  color: _showVoiceNote
                      ? Colors.white
                      : const Color(0xFF8D8D98),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 120),
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  minLines: 1,
                  textAlignVertical: TextAlignVertical.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF1A1A2E),
                  ),
                  decoration: InputDecoration(
                    hintText: _showVoiceNote
                        ? 'Hold to record'
                        : 'Type a message...',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFFB5B4B4),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF7F7F8),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedBuilder(
              animation: _sendButtonController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _sendButtonScale.value,
                  child: GestureDetector(
                    onTap: _messageController.text.trim().isEmpty
                        ? null
                        : _sendMessage,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0DB4A5), Color(0xFF00A89E)],
                        ),
                        borderRadius: BorderRadius.circular(23),
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEAF8F6), Color(0xFFDDF3EF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 32,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No messages yet',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Send a message to start the conversation.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF8D8D98),
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessageActions(DMMessageModel message) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.reply_rounded,
                  color: AppColors.primary,
                ),
                title: Text(
                  'Reply',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.copy_rounded,
                  color: AppColors.primary,
                ),
                title: Text(
                  'Copy',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              if (message.attachments.isNotEmpty)
                ListTile(
                  leading: const Icon(
                    Icons.download_rounded,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    'Download',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'freelancer':
        return 'Freelancer';
      case 'client':
        return 'Client';
      case 'dual':
        return 'Client & Freelancer';
      default:
        return 'WorkByte user';
    }
  }

  String _systemMessageLabel(String? type) {
    switch (type) {
      case 'contract_accepted':
        return 'Contract accepted';
      case 'proposal_accepted':
        return 'Proposal accepted';
      case 'milestone_approved':
        return 'Milestone approved';
      case 'revision_requested':
        return 'Revision requested';
      default:
        return 'System message';
    }
  }

  String _formatMessageTime(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now().toLocal();
    final dt = dateTime.toLocal();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';

    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final suffix = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }

  Widget _buildAvatarForBubble() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F7F5), Color(0xFFD7F0EC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Icon(
        Icons.person_rounded,
        size: 18,
        color: AppColors.primary,
      ),
    );
  }
}
