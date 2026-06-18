import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dm_provider.dart';
import '../../models/dm_model.dart';
import '../../core/utils/helpers.dart';
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
  bool _isPickingFile = false;

  PlatformFile? _selectedFile;
  String? _selectedFilePath;
  bool _isSendingFile = false;

  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _recordingPath;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;
  String? _playingMessageId;
  bool _isAudioPlaying = false;
  StreamSubscription<void>? _playerCompleteSub;

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
    _playerCompleteSub?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _recordingTimer?.cancel();
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
    final text = _messageController.text.trim();
    final hasText = text.isNotEmpty;
    final hasFile = _selectedFile != null && _selectedFilePath != null;

    if (!hasText && !hasFile) return;

    final token = context.read<AuthProvider>().token;
    final currentUserId = context.read<AuthProvider>().userId;

    if (token == null || currentUserId == null) return;

    _focusNode.unfocus();
    _sendButtonController.forward();

    final pickedFile = _selectedFile;
    final pickedFilePath = _selectedFilePath;

    _messageController.clear();

    if (hasFile) {
      setState(() {
        _selectedFile = null;
        _selectedFilePath = null;
        _isSendingFile = true;
      });
    }

    try {
      if (hasFile && pickedFile != null && pickedFilePath != null) {
        await context.read<DMProvider>().sendFileMessage(
          token: token,
          threadId: widget.thread.threadId,
          filePath: pickedFilePath,
          fileName: pickedFile.name,
          fileSizeBytes: pickedFile.size,
          senderId: currentUserId,
          messageText: hasText ? text : null,
        );
      } else {
        await context.read<DMProvider>().sendMessage(
          token: token,
          threadId: widget.thread.threadId,
          messageText: text,
          senderId: currentUserId,
        );
      }

      _scrollToBottom();
    } finally {
      if (mounted) {
        setState(() => _isSendingFile = false);
      }
      _sendButtonController.reverse();
    }
  }

  void _toggleVoiceNote() {
    setState(() => _showVoiceNote = !_showVoiceNote);
  }

  Future<void> _pickFile() async {
    if (_isPickingFile) return;

    setState(() => _isPickingFile = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.any,
      );

      if (result == null || result.files.isEmpty) return;

      final picked = result.files.first;
      if (picked.path == null) {
        throw Exception('Selected file path is unavailable');
      }

      setState(() {
        _selectedFile = picked;
        _selectedFilePath = picked.path!;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isPickingFile = false);
    }
  }

  void _showFailedMessageReason(DMMessageModel message) {
    final reason =
        message.failureReason ??
        'This message failed to send. Please check the content and try again.';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Message failed',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: Text(reason, style: GoogleFonts.poppins(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fileExtension(String name) {
    final parts = name.split('.');
    return parts.length > 1 ? parts.last.toUpperCase() : 'FILE';
  }

  String _fileTypeLabel(String? fileType, String name) {
    if (fileType == null || fileType.isEmpty) {
      return _fileExtension(name);
    }
    return fileType.replaceAll('_', ' ').toUpperCase();
  }

  Widget _buildVoiceMessageBubble(
    DMAttachmentModel attachment,
    bool isOwn,
    String messageId,
  ) {
    const barHeights = [
      8.0,
      14.0,
      20.0,
      12.0,
      18.0,
      10.0,
      22.0,
      16.0,
      8.0,
      14.0,
      20.0,
      10.0,
      18.0,
      12.0,
      22.0,
      8.0,
      16.0,
      14.0,
    ];
    final isThisPlaying = _playingMessageId == messageId && _isAudioPlaying;
    final durSec = attachment.durationSeconds?.round() ?? 0;
    final durLabel =
        '${(durSec ~/ 60)}:${(durSec % 60).toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: () => _togglePlayback(attachment.fileUrl, messageId),
      child: SizedBox(
        width: 210,
        child: Row(
          children: [
            Icon(
              isThisPlaying
                  ? Icons.pause_circle_filled_rounded
                  : Icons.play_circle_filled_rounded,
              size: 38,
              color: isOwn ? Colors.white : AppColors.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: List.generate(barHeights.length, (i) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: Container(
                          width: 3,
                          height: barHeights[i],
                          decoration: BoxDecoration(
                            color: isOwn
                                ? Colors.white.withValues(
                                    alpha: isThisPlaying ? 1.0 : 0.55,
                                  )
                                : AppColors.primary.withValues(
                                    alpha: isThisPlaying ? 1.0 : 0.45,
                                  ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    durSec > 0 ? durLabel : 'Voice message',
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      color: isOwn
                          ? Colors.white.withValues(alpha: 0.75)
                          : const Color(0xFF9A9AA3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startRecording() async {
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Microphone permission denied',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _audioRecorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );

    setState(() {
      _isRecording = true;
      _recordingPath = path;
      _recordingSeconds = 0;
    });

    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _recordingSeconds++);
    });
  }

  Future<void> _stopAndSendRecording() async {
    _recordingTimer?.cancel();
    final path = await _audioRecorder.stop();

    setState(() {
      _isRecording = false;
      _recordingSeconds = 0;
      _recordingPath = null;
    });

    if (path == null) return;

    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    try {
      final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final currentUserId = context.read<AuthProvider>().userId;
      if (currentUserId == null) return;

      await context.read<DMProvider>().sendFileMessage(
        token: token,
        threadId: widget.thread.threadId,
        filePath: path,
        fileName: fileName,
        senderId: currentUserId,
      );

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
  }

  Future<void> _cancelRecording() async {
    _recordingTimer?.cancel();
    await _audioRecorder.stop();
    final savedPath = _recordingPath;

    setState(() {
      _isRecording = false;
      _recordingSeconds = 0;
      _recordingPath = null;
    });

    if (savedPath != null) {
      final file = File(savedPath);
      if (await file.exists()) await file.delete();
    }
  }

  Future<void> _togglePlayback(String url, String messageId) async {
    if (_playingMessageId == messageId && _isAudioPlaying) {
      await _audioPlayer.pause();
      setState(() => _isAudioPlaying = false);
      return;
    }

    if (_playingMessageId == messageId && !_isAudioPlaying) {
      await _audioPlayer.resume();
      setState(() => _isAudioPlaying = true);
      return;
    }

    await _audioPlayer.stop();

    _playerCompleteSub?.cancel();
    _playerCompleteSub = _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isAudioPlaying = false;
          _playingMessageId = null;
        });
      }
    });

    setState(() {
      _playingMessageId = messageId;
      _isAudioPlaying = true;
    });

    try {
      await _audioPlayer.setVolume(1.0);
      // UrlSource doesn't support custom headers, so download with auth first
      final token = context.read<AuthProvider>().token;
      final tempFile = await downloadToTempFile(url, token: token);
      if (tempFile == null) throw Exception('Failed to download audio');
      await _audioPlayer.play(DeviceFileSource(tempFile.path));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAudioPlaying = false;
        _playingMessageId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal memutar audio: ${e.toString().replaceFirst('Exception: ', '')}',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _openAttachment(String url) async {
    final token = context.read<AuthProvider>().token;
    await openDocumentFromUrl(
      context,
      url,
      token: token,
      onRefreshToken: () async {
        final ok = await context.read<AuthProvider>().tryRefresh();
        return ok ? context.read<AuthProvider>().token : null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthProvider>().userId ?? '';
    final messages = context.select<DMProvider, List<DMMessageModel>>(
      (dm) => dm.messagesFor(widget.thread.threadId),
    );

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF2F2FA),
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
            if (_selectedFile != null) _buildPendingAttachmentPreview(),
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
                      ? LinearGradient(
                          colors: [AppColors.primary, const Color(0xFF4338CA)],
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
                      _buildAttachmentPreview(
                        message.attachments.first,
                        isOwn,
                        message.dmMessageId,
                      ),
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
                            if (message.isSending)
                              Icon(
                                Icons.access_time_rounded,
                                size: 14,
                                color: Colors.white.withValues(alpha: 0.85),
                              )
                            else if (message.isFailed)
                              GestureDetector(
                                onTap: () => _showFailedMessageReason(message),
                                child: const Icon(
                                  Icons.error_outline_rounded,
                                  size: 15,
                                  color: Colors.amberAccent,
                                ),
                              )
                            else
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

  bool _isVoiceAttachment(DMAttachmentModel att) {
    if (att.fileType == 'voice_note' || att.fileType == 'audio') return true;
    if (att.mimeType.startsWith('audio/')) return true;
    final name = att.fileName.toLowerCase();
    return name.endsWith('.m4a') ||
        name.endsWith('.mp3') ||
        name.endsWith('.wav') ||
        name.endsWith('.ogg') ||
        name.endsWith('.aac');
  }

  Widget _buildAttachmentPreview(
    DMAttachmentModel attachment,
    bool isOwn,
    String messageId,
  ) {
    final fileName = attachment.fileName?.trim().isNotEmpty == true
        ? attachment.fileName!.trim()
        : 'Attachment';

    if (_isVoiceAttachment(attachment)) {
      return _buildVoiceMessageBubble(attachment, isOwn, messageId);
    }

    if (attachment.fileType == 'image') {
      final token = context.read<AuthProvider>().token;
      final isBackend = isOurBackendUrl(attachment.fileUrl);
      return GestureDetector(
        onTap: () => _openAttachment(attachment.fileUrl),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            attachment.fileUrl,
            headers: (token != null && isBackend)
                ? {'Authorization': 'Bearer $token'}
                : {},
            width: 190,
            height: 190,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildFileAttachmentCard(
              fileName: fileName,
              fileUrl: attachment.fileUrl,
              fileType: attachment.fileType,
              fileSize: attachment.fileSizeBytes,
              isOwn: isOwn,
            ),
          ),
        ),
      );
    }

    return _buildFileAttachmentCard(
      fileName: fileName,
      fileUrl: attachment.fileUrl,
      fileType: attachment.fileType,
      fileSize: attachment.fileSizeBytes,
      isOwn: isOwn,
    );
  }

  Widget _documentPreview(DMAttachmentModel attachment) {
    final ext = attachment.fileName?.contains('.') == true
        ? attachment.fileName!.split('.').last.toUpperCase()
        : 'FILE';

    final Color extColor;
    final IconData extIcon;
    if (ext == 'PDF') {
      extColor = const Color(0xFFE53E3E);
      extIcon = Icons.picture_as_pdf_rounded;
    } else if (['DOC', 'DOCX'].contains(ext)) {
      extColor = const Color(0xFF2B6CB0);
      extIcon = Icons.description_rounded;
    } else if (['XLS', 'XLSX'].contains(ext)) {
      extColor = const Color(0xFF276749);
      extIcon = Icons.table_chart_rounded;
    } else if (['PPT', 'PPTX'].contains(ext)) {
      extColor = const Color(0xFFDD6B20);
      extIcon = Icons.slideshow_rounded;
    } else if (['ZIP', 'RAR', '7Z'].contains(ext)) {
      extColor = const Color(0xFF744210);
      extIcon = Icons.folder_zip_rounded;
    } else {
      extColor = const Color(0xFF4A5568);
      extIcon = Icons.insert_drive_file_rounded;
    }

    final sizeLabel = attachment.fileSizeBytes != null
        ? _formatFileSize(attachment.fileSizeBytes!)
        : ext;

    return Container(
      width: 220,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBEBF0)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: extColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(extIcon, size: 22, color: extColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.fileName,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A2E),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  sizeLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xFF8D8D98),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Widget _buildMessageInput() {
    if (_isRecording) return _buildRecordingBar();

    final hasText = _messageController.text.trim().isNotEmpty;
    final hasAttachment = _selectedFile != null && _selectedFilePath != null;
    final canSend = hasText || hasAttachment;
    final isBusy = _isPickingFile || _isSendingFile;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE9ECEF))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            onPressed: isBusy ? null : _pickFile,
            icon: Icon(
              Icons.attach_file_rounded,
              color: canSend ? AppColors.primary : const Color(0xFF9A9AA3),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _focusNode,
              minLines: 1,
              maxLines: 5,
              textInputAction: TextInputAction.newline,
              style: GoogleFonts.poppins(fontSize: 14),
              decoration: InputDecoration(
                hintText: hasAttachment
                    ? 'Add a caption...'
                    : 'Type a message...',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFFAAAAAA),
                ),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: _startRecording,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mic_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            decoration: BoxDecoration(
              color: canSend ? AppColors.primary : const Color(0xFFCCCCDD),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: (!canSend || isBusy) ? null : _sendMessage,
              icon: isBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingBar() {
    final minutes = (_recordingSeconds ~/ 60).toString();
    final seconds = (_recordingSeconds % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE9ECEF))),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _cancelRecording,
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.redAccent,
              size: 24,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Colors.redAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Recording  $minutes:$seconds',
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1A1A2E),
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _stopAndSendRecording,
              icon: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
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

  Widget _buildPendingAttachmentPreview() {
    if (_selectedFile == null || _selectedFilePath == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Stack(
        children: [
          _buildFileAttachmentCard(
            fileName: _selectedFile!.name,
            fileUrl: _selectedFilePath!,
            fileType: _selectedFile!.extension,
            fileSize: _selectedFile!.size,
            extension: _selectedFile!.extension,
          ),
          Positioned(
            top: 6,
            right: 6,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedFile = null;
                    _selectedFilePath = null;
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: Ink(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, size: 16),
                ),
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

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _prettyFileType({
    String? fileType,
    String? fileName,
    String? extension,
  }) {
    final ext =
        (extension ??
                (fileName != null && fileName.contains('.')
                    ? fileName.split('.').last
                    : 'file'))
            .toUpperCase();

    if (fileType == null || fileType.trim().isEmpty) return ext;

    switch (fileType.toLowerCase()) {
      case 'image':
        return 'IMAGE • $ext';
      case 'video':
        return 'VIDEO • $ext';
      case 'audio':
      case 'voice_note':
        return 'AUDIO • $ext';
      case 'document':
        return 'DOCUMENT • $ext';
      default:
        return fileType.replaceAll('_', ' ').toUpperCase();
    }
  }

  IconData _fileIcon(String? fileName, String? fileType, String? extension) {
    final ext =
        (extension ??
                (fileName != null && fileName.contains('.')
                    ? fileName.split('.').last
                    : ''))
            .toLowerCase();

    if (fileType == 'image') return Icons.image_rounded;
    if (fileType == 'video') return Icons.videocam_rounded;
    if (fileType == 'audio' || fileType == 'voice_note') {
      return Icons.audio_file_rounded;
    }

    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'xls':
      case 'xlsx':
      case 'csv':
        return Icons.table_chart_rounded;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow_rounded;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.folder_zip_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Color _fileAccent(String? extension) {
    switch ((extension ?? '').toLowerCase()) {
      case 'pdf':
        return const Color(0xFFE74C3C);
      case 'doc':
      case 'docx':
        return const Color(0xFF2F80ED);
      case 'xls':
      case 'xlsx':
      case 'csv':
        return const Color(0xFF27AE60);
      case 'ppt':
      case 'pptx':
        return const Color(0xFFF2994A);
      case 'zip':
      case 'rar':
      case '7z':
        return const Color(0xFF9B51E0);
      default:
        return AppColors.primary;
    }
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

  Widget _buildFileAttachmentCard({
    required String fileName,
    required String fileUrl,
    required String? fileType,
    required int? fileSize,
    bool isOwn = false,
    String? extension,
  }) {
    final ext =
        extension ?? (fileName.contains('.') ? fileName.split('.').last : null);
    final accent = _fileAccent(ext);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openAttachment(fileUrl),
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: 255,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isOwn
                ? Colors.white.withValues(alpha: 0.16)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isOwn
                  ? Colors.white.withValues(alpha: 0.18)
                  : const Color(0xFFE6EBF2),
            ),
            boxShadow: isOwn
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isOwn
                      ? Colors.white.withValues(alpha: 0.95)
                      : accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _fileIcon(fileName, fileType, ext),
                  color: accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13.2,
                        fontWeight: FontWeight.w600,
                        color: isOwn ? Colors.white : const Color(0xFF1A1A2E),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _prettyFileType(
                        fileType: fileType,
                        fileName: fileName,
                        extension: ext,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 11.2,
                        fontWeight: FontWeight.w500,
                        color: isOwn
                            ? Colors.white.withValues(alpha: 0.86)
                            : const Color(0xFF7B8794),
                      ),
                    ),
                    if (fileSize != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _formatBytes(fileSize),
                        style: GoogleFonts.poppins(
                          fontSize: 10.8,
                          color: isOwn
                              ? Colors.white.withValues(alpha: 0.72)
                              : const Color(0xFF98A2B3),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isOwn
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.open_in_new_rounded,
                  size: 18,
                  color: isOwn ? Colors.white : const Color(0xFF667085),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
