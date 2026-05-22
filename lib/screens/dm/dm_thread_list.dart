import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dm_provider.dart';
import '../../models/dm_model.dart';
import '../../../core/utils/app_snackbar.dart';
import 'dm_chat_screen.dart';

class DMThreadListScreen extends StatefulWidget {
  const DMThreadListScreen({super.key});

  @override
  State<DMThreadListScreen> createState() => _DMThreadListScreenState();
}

class _DMThreadListScreenState extends State<DMThreadListScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();

  late TabController _tabController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadThreads();
      _loadRequests();
    });
  }

  Future<void> _loadThreads() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    await context.read<DMProvider>().fetchThreads(token);
  }

  Future<void> _loadRequests() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    await context.read<DMProvider>().fetchRequests(token);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  List<DMThreadModel> _filterThreads(List<DMThreadModel> threads) {
    if (_query.isEmpty) return threads;

    return threads.where((thread) {
      final name = (thread.otherUser?.fullName ?? '').toLowerCase();
      final jobTitle = (thread.jobPost?.jobTitle ?? '').toLowerCase();
      final lastMessage = (thread.lastMessage?.messageText ?? '').toLowerCase();

      return name.contains(_query) ||
          jobTitle.contains(_query) ||
          lastMessage.contains(_query);
    }).toList();
  }

  List<DMThreadModel> _threadsForTab(
    List<DMThreadModel> all,
    int tabIndex,
    String currentUserId,
    List<DMThreadModel> requestThreads,
  ) {
    switch (tabIndex) {
      case 0:
        return all.where((t) => t.status != 'declined').toList();
      case 1:
        return requestThreads;
      case 2:
        return all.where((t) => t.status == 'active').toList();
      default:
        return all;
    }
  }

  Future<void> _handleAccept(DMThreadModel thread) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    try {
      await context.read<DMProvider>().acceptThread(
        token: token,
        threadId: thread.threadId,
      );

      if (!mounted) return;

      AppSnackBar.show(context, 'Message request accepted.', type: SnackBarType.error);

      await _loadThreads();
      await _loadRequests();
    } catch (_) {
      if (!mounted) return;

      AppSnackBar.show(context, 'Failed to accept request.', type: SnackBarType.error);
    }
  }

  Future<void> _handleDecline(DMThreadModel thread) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    try {
      await context.read<DMProvider>().declineThread(
        token: token,
        threadId: thread.threadId,
      );

      if (!mounted) return;

      AppSnackBar.show(context, 'Message request declined.', type: SnackBarType.error);

      await _loadThreads();
      await _loadRequests();
    } catch (_) {
      if (!mounted) return;

      AppSnackBar.show(context, 'Failed to decline request.', type: SnackBarType.error);
    }
  }

  Future<void> _openThread(DMThreadModel thread) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DMChatScreen(thread: thread)),
    );

    if (!mounted) return;
    await _loadThreads();
    await _loadRequests();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthProvider>().userId ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<DMProvider>(
          builder: (context, dm, _) {
            final allThreads = _filterThreads(dm.threads);
            final requestThreads = _filterThreads(dm.requests);
            final inboxThreads = _threadsForTab(
              allThreads,
              0,
              currentUserId,
              requestThreads,
            );
            final requestsTabThreads = _threadsForTab(
              allThreads,
              1,
              currentUserId,
              requestThreads,
            );
            final activeThreads = _threadsForTab(
              allThreads,
              2,
              currentUserId,
              requestThreads,
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(dm.pendingRequestCount),
                const SizedBox(height: 14),
                _buildSearchBar(),
                const SizedBox(height: 14),
                _buildTabs(dm.pendingRequestCount),
                const SizedBox(height: 14),
                Expanded(
                  child: dm.isLoadingThreads
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        )
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildThreadList(
                              threads: inboxThreads,
                              currentUserId: currentUserId,
                            ),
                            _buildThreadList(
                              threads: requestsTabThreads,
                              currentUserId: currentUserId,
                              isRequestTab: true,
                            ),
                            _buildThreadList(
                              threads: activeThreads,
                              currentUserId: currentUserId,
                            ),
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(int pendingCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEDEDED)),
            ),
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Color(0xFF1A1A2E),
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Messages',
                  style: GoogleFonts.poppins(
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                Text(
                  pendingCount > 0
                      ? '$pendingCount pending request${pendingCount == 1 ? '' : 's'}'
                      : 'Your conversations and requests',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF7D7D7D),
                  ),
                ),
              ],
            ),
          ),
          if (pendingCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Text(
                '$pendingCount new',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF0F0F1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Icon(
              Icons.search_rounded,
              color: Color(0xFF8D8D98),
              size: 21,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF1A1A2E),
                ),
                decoration: InputDecoration(
                  hintText: 'Search people, jobs, or messages...',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFFB5B4B4),
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            if (_query.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                },
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F2F6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: Color(0xFF7D7D7D),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs(int requestCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        height: 52,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF0F0F1)),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(13),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: AppColors.primary,
          unselectedLabelColor: const Color(0xFF8B8B95),
          labelStyle: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          tabs: [
            const Tab(text: 'Inbox'),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Requests'),
                  if (requestCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$requestCount',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Active'),
          ],
        ),
      ),
    );
  }

  Widget _buildThreadList({
    required List<DMThreadModel> threads,
    required String currentUserId,
    bool isRequestTab = false,
  }) {
    if (threads.isEmpty) {
      return _buildEmptyState(isRequestTab: isRequestTab);
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        await _loadThreads();
        await _loadRequests();
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
        itemCount: threads.length,
        itemBuilder: (context, index) {
          final thread = threads[index];
          return _buildThreadCard(
            thread,
            currentUserId: currentUserId,
            isRequestTab: isRequestTab,
          );
        },
      ),
    );
  }

  Widget _buildThreadCard(
    DMThreadModel thread, {
    required String currentUserId,
    bool isRequestTab = false,
  }) {
    final isIncomingRequest =
        thread.status == 'request' && thread.initiatorId != currentUserId;

    final name = (thread.otherUser?.fullName?.trim().isNotEmpty ?? false)
        ? (thread.otherUser?.fullName?.trim() ?? 'Unknown User')
        : 'Unknown User';

    final role = thread.otherUser?.role ?? 'user';
    final avatarUrl = thread.otherUser?.profilePictureUrl;
    final jobTitle = thread.jobPost?.jobTitle;

    final lastMessageText =
        (thread.lastMessage?.messageText?.trim().isNotEmpty ?? false)
        ? (thread.lastMessage?.messageText?.trim() ?? '')
        : (thread.status == 'request'
              ? 'Sent you a message request'
              : 'No messages yet');

    final subtitle = (jobTitle?.trim().isNotEmpty ?? false)
        ? jobTitle!.trim()
        : _roleLabel(role);

    final timeText = _formatTimestamp(thread.lastMessage?.sentAt);

    return GestureDetector(
      onTap: isIncomingRequest ? null : () => _openThread(thread),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isIncomingRequest
                ? AppColors.primary.withValues(alpha: 0.22)
                : const Color(0xFFF0F0F2),
          ),
          boxShadow: [
            BoxShadow(
              color: isIncomingRequest
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.035),
              blurRadius: isIncomingRequest ? 18 : 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatar(avatarUrl, name),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1A1A2E),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (timeText.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              timeText,
                              style: GoogleFonts.poppins(
                                fontSize: 10.5,
                                color: const Color(0xFF9A9AA3),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              subtitle,
                              style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _statusPill(thread.status, isIncomingRequest),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Text(
                        lastMessageText,
                        style: GoogleFonts.poppins(
                          fontSize: 12.2,
                          color: const Color(0xFF6F6F78),
                          fontWeight: thread.unreadCount > 0
                              ? FontWeight.w600
                              : FontWeight.w400,
                          height: 1.45,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 11),
                      Row(
                        children: [
                          if (thread.jobPost != null)
                            _contextChip(
                              icon: Icons.work_outline_rounded,
                              label: 'Job context',
                            ),
                          if (thread.jobPost != null) const SizedBox(width: 8),
                          if (thread.unreadCount > 0 && !isIncomingRequest)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(
                                '${thread.unreadCount} unread',
                                style: GoogleFonts.poppins(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isIncomingRequest) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _handleDecline(thread),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF7A7A85),
                          side: const BorderSide(color: Color(0xFFD8D8DE)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'Decline',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _handleAccept(thread),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'Accept',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String? avatarUrl, String name) {
    final initials = _initials(name);

    Widget child;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      if (avatarUrl.startsWith('http')) {
        child = Image.network(
          '$avatarUrl?t=${DateTime.now().millisecondsSinceEpoch}',
          fit: BoxFit.cover,
          width: 56,
          height: 56,
          errorBuilder: (_, __, ___) => _fallbackAvatar(initials),
        );
      } else if (File(avatarUrl).existsSync()) {
        child = Image.file(
          File(avatarUrl),
          fit: BoxFit.cover,
          width: 56,
          height: 56,
          errorBuilder: (_, __, ___) => _fallbackAvatar(initials),
        );
      } else {
        child = _fallbackAvatar(initials);
      }
    } else {
      child = _fallbackAvatar(initials);
    }

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F7F5), Color(0xFFD7F0EC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  Widget _fallbackAvatar(String initials) {
    return Container(
      color: AppColors.secondary,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _statusPill(String status, bool isIncomingRequest) {
    Color textColor;
    Color bgColor;
    String label;

    switch (status) {
      case 'request':
        label = isIncomingRequest ? 'Request' : 'Pending';
        textColor = const Color(0xFF9C6A00);
        bgColor = const Color(0xFFFFF4D6);
        break;
      case 'active':
        label = 'Active';
        textColor = AppColors.primary;
        bgColor = AppColors.secondary;
        break;
      case 'declined':
        label = 'Declined';
        textColor = const Color(0xFFB23A3A);
        bgColor = const Color(0xFFFFECEC);
        break;
      default:
        label = status;
        textColor = const Color(0xFF7D7D7D);
        bgColor = const Color(0xFFF0F0F1);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _contextChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6C6C76),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({bool isRequestTab = false}) {
    final title = isRequestTab ? 'No pending requests' : 'No conversations yet';
    final subtitle = isRequestTab
        ? 'New message requests will appear here.'
        : 'Start connecting with clients and freelancers to see your chats here.';

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.12),
        Center(
          child: Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEAF8F6), Color(0xFFDDF3EF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(
              Icons.forum_rounded,
              size: 38,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A2E),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 42),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF8D8D98),
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'freelancer':
        return 'Freelancer';
      case 'client':
        return 'Client';
      case 'dual':
        return 'Client • Freelancer';
      default:
        return 'WorkByte user';
    }
  }

  String _initials(String name) {
    final safe = name.trim();
    if (safe.isEmpty) return '?';

    final parts = safe.split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();

    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  String _formatTimestamp(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final local = dateTime.toLocal();
    final diff = now.difference(local);

    if (diff.inMinutes < 1) return 'Now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';

    if (diff.inHours < 24 &&
        now.day == local.day &&
        now.month == local.month &&
        now.year == local.year) {
      final hour = local.hour > 12
          ? local.hour - 12
          : (local.hour == 0 ? 12 : local.hour);
      final minute = local.minute.toString().padLeft(2, '0');
      final suffix = local.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $suffix';
    }

    if (diff.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[local.weekday - 1];
    }

    return '${local.day}/${local.month}';
  }
}
