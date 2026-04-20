import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/notification_item.dart';
import '../../widgets/load_more_button.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── App bar ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  // Back button (not in Figma design, added per request)
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF333333),
                      size: 22,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),

                  // Title
                  Text(
                    'Notifications',
                    style: GoogleFonts.figtree(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF333333),
                      height: 19 / 16,
                    ),
                  ),

                  const Spacer(),

                  // "Latest" label + filter icon
                  Text(
                    'Latest',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF7D7D7D),
                      height: 18 / 12,
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      // TODO: open filter bottom sheet
                    },
                    child: const Icon(
                      Icons.filter_list,
                      size: 20,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),

            // ── Notifications list ─────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(13, 20, 16, 16),
                children: [
                  NotificationItem(
                    boldPrefix: 'Congratulation! Dennis',
                    message:
                        'accept your bid. Please wait until they pay first deposit.',
                    timestamp: '2 minutes ago',
                    isUnread: true,
                    avatar: Image.network(
                      'https://i.pravatar.cc/50?img=11',
                      width: 25,
                      height: 25,
                      fit: BoxFit.cover,
                    ),
                  ),

                  const SizedBox(height: 24),

                  NotificationItem(
                    boldPrefix: 'Ais',
                    message:
                        'sent you bid on job "I need logo designer to make our company logo"',
                    timestamp: '12 Jan 2023 01:00 WIB',
                    isUnread: true,
                    avatar: Image.network(
                      'https://i.pravatar.cc/50?img=5',
                      width: 25,
                      height: 25,
                      fit: BoxFit.cover,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Load more
                  Center(child: LoadMoreButton(onTap: () {})),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
