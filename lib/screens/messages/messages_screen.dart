import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../models/dm_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dm_provider.dart';
import '../../../core/utils/app_snackbar.dart';
import 'dm_chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadThreads());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadThreads() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    await context.read<DmProvider>().fetchThreads(token);
  }

  List<DmThread> _filtered(List<DmThread> threads) {
    if (_searchQuery.isEmpty) return threads;
    final q = _searchQuery.toLowerCase();
    return threads.where((t) {
      final name = t.otherUser?.displayName.toLowerCase() ?? '';
      final last = t.lastMessage?.messageText.toLowerCase() ?? '';
      return name.contains(q) || last.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
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
        title: Text(
          'Messages',
          style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF333333)),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49),
          child: Consumer<DmProvider>(
            builder: (context, dm, _) {
              final requestCount = dm.requestThreads.length;
              return TabBar(
                controller: _tabController,
                labelStyle: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w600),
                unselectedLabelStyle:
                    GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w400),
                labelColor: AppColors.primary,
                unselectedLabelColor: const Color(0xFF9CA3AF),
                indicatorColor: AppColors.primary,
                indicatorWeight: 2,
                tabs: [
                  const Tab(text: 'Chats'),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Requests'),
                        if (requestCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$requestCount',
                              style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: GoogleFonts.poppins(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search conversations...',
                  hintStyle: GoogleFonts.poppins(
                      fontSize: 13, color: const Color(0xFF9CA3AF)),
                  prefixIcon: const Icon(Icons.search_rounded,
                      size: 18, color: Color(0xFF9CA3AF)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ThreadList(
                  filter: (dm) => _filtered(dm.activeThreads),
                  emptyTitle: 'No active chats',
                  emptySubtitle:
                      'Your conversations will appear here\nonce a request is accepted',
                  onRefresh: _loadThreads,
                ),
                _ThreadList(
                  filter: (dm) => _filtered(dm.requestThreads),
                  emptyTitle: 'No message requests',
                  emptySubtitle: 'New message requests\nwill appear here',
                  onRefresh: _loadThreads,
                  showRequestActions: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThreadList extends StatelessWidget {
  final List<DmThread> Function(DmProvider) filter;
  final String emptyTitle;
  final String emptySubtitle;
  final Future<void> Function() onRefresh;
  final bool showRequestActions;

  const _ThreadList({
    required this.filter,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.onRefresh,
    this.showRequestActions = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<DmProvider>(
      builder: (context, dm, _) {
        if (dm.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
                color: AppColors.primary, strokeWidth: 2),
          );
        }

        final threads = filter(dm);

        if (threads.isEmpty) {
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: onRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.55,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 36,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          emptyTitle,
                          style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF374151)),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          emptySubtitle,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                              fontSize: 13, color: const Color(0xFF9CA3AF)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: onRefresh,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: threads.length,
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              indent: 72,
              color: Color(0xFFF0F0F0),
            ),
            itemBuilder: (context, index) =>
                _ThreadTile(
                  thread: threads[index],
                  showRequestActions: showRequestActions,
                ),
          ),
        );
      },
    );
  }
}

class _ThreadTile extends StatelessWidget {
  final DmThread thread;
  final bool showRequestActions;

  const _ThreadTile({
    required this.thread,
    this.showRequestActions = false,
  });

  String _formatTime(BuildContext context, DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      return TimeOfDay.fromDateTime(dt).format(context);
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dt.weekday - 1];
    }
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final other = thread.otherUser;
    final displayName = other?.displayName ?? 'Unknown';
    final initials = other?.initials ?? '?';
    final lastMsg = thread.lastMessage;
    final unread = thread.unreadCount;
    final token = context.read<AuthProvider>().token ?? '';
    final currentUserId = context.read<AuthProvider>().userId ?? '';

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DmChatScreen(
            thread: thread,
            currentUserId: currentUserId,
          ),
        ),
      ).then((_) {
        // Refresh threads list when returning from chat
        final t = context.read<AuthProvider>().token;
        if (t != null) context.read<DmProvider>().fetchThreads(t);
      }),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              displayName,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: unread > 0
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: const Color(0xFF111827),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (lastMsg?.sentAt != null)
                            Text(
                              _formatTime(context, lastMsg!.sentAt),
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: unread > 0
                                    ? AppColors.primary
                                    : const Color(0xFF9CA3AF),
                                fontWeight: unread > 0
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              lastMsg?.messageText.isNotEmpty == true
                                  ? lastMsg!.messageText
                                  : 'No messages yet',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: unread > 0
                                    ? const Color(0xFF374151)
                                    : const Color(0xFF6B7280),
                                fontWeight: unread > 0
                                    ? FontWeight.w500
                                    : FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (unread > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$unread',
                                style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Accept/Decline actions shown in Requests tab
            if (showRequestActions) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        final dmProvider = context.read<DmProvider>();
                        final messenger = ScaffoldMessenger.of(context);
                        dmProvider
                            .declineThread(token, thread.threadId)
                            .then((ok) {
                          if (!ok) {
                            AppSnackBar.show(context, dmProvider.error ?? 'Failed', type: SnackBarType.error);
                          }
                        });
                      },
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
                      onPressed: () {
                        final dmProvider = context.read<DmProvider>();
                        final messenger = ScaffoldMessenger.of(context);
                        dmProvider
                            .acceptThread(token, thread.threadId)
                            .then((ok) {
                          if (ok) {
                            AppSnackBar.show(context, 'Request accepted!', type: SnackBarType.success);
                          }
                        });
                      },
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
          ],
        ),
      ),
    );
  }
}
