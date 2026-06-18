import 'package:flutter/material.dart';
import 'job_post_service.dart';
import 'profile_service.dart';
import '../screens/people_list/people_list_screen.dart';
import '../screens/job_freelancer_view/job_detail.dart' as freelancer_view;
import '../screens/job_client_view/job_detail.dart' as client_view;

const _shareBase = 'https://workbyte.angelica-whiharto.com/share';

String jobShareUrl(String jobPostId) => '$_shareBase/job/$jobPostId';
String profileShareUrl(String userId) => '$_shareBase/profile/$userId';

class DeepLinkService {
  static Uri? _pendingLink;
  static GlobalKey<NavigatorState>? _navigatorKey;

  static void init(GlobalKey<NavigatorState> key) => _navigatorKey = key;

  static void setPendingLink(Uri? uri) => _pendingLink = uri;

  static Uri? consumePendingLink() {
    final link = _pendingLink;
    _pendingLink = null;
    return link;
  }

  // Returns (type, id) — e.g. ('job', '123') or ('profile', '456').
  static (String?, String?) parseLink(Uri uri) {
    if (uri.scheme == 'workbyte') {
      // workbyte://job/123  or  workbyte://profile/123
      final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
      return (uri.host, id);
    }
    if (uri.scheme == 'https') {
      // https://workbyte.angelica-whiharto.com/share/job/123
      final segs = uri.pathSegments;
      if (segs.length >= 3 && segs[0] == 'share') {
        return (segs[1], segs[2]);
      }
    }
    return (null, null);
  }

  static Future<void> handleLink({
    required Uri uri,
    required String token,
    required bool isClient,
  }) async {
    final (type, id) = parseLink(uri);
    if (type == null || id == null) return;

    final navigator = _navigatorKey?.currentState;
    if (navigator == null) return;

    if (type == 'job') {
      try {
        final job = await JobPostService().getJobPost(token, id);
        if (isClient) {
          navigator.push(MaterialPageRoute(
            builder: (_) => client_view.ClientJobDetailScreen(job: job),
          ));
        } else {
          navigator.push(MaterialPageRoute(
            builder: (_) => freelancer_view.JobDetailScreen(job: job),
          ));
        }
      } catch (_) {}
    } else if (type == 'profile') {
      final profileService = ProfileService();
      try {
        final freelancer = await profileService.fetchFreelancerById(token, id);
        if (freelancer != null) {
          navigator.push(MaterialPageRoute(
            builder: (_) =>
                PeopleProfileScreen(isClient: false, freelancer: freelancer),
          ));
          return;
        }
      } catch (_) {}
      try {
        final client = await profileService.fetchClientById(token, id);
        if (client != null) {
          navigator.push(MaterialPageRoute(
            builder: (_) =>
                PeopleProfileScreen(isClient: true, client: client),
          ));
        }
      } catch (_) {}
    }
  }
}
