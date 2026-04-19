import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../models/client_model.dart';
import '../../models/freelancer_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class PeopleListScreen extends StatefulWidget {
  final bool showClients;

  const PeopleListScreen({super.key, required this.showClients});

  @override
  State<PeopleListScreen> createState() => _PeopleListScreenState();
}

class _PeopleListScreenState extends State<PeopleListScreen> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _people = [];

  @override
  void initState() {
    super.initState();
    _loadPeople();
  }

  Future<void> _loadPeople() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) {
      setState(() {
        _isLoading = false;
        _error = 'Authentication required.';
      });
      return;
    }

    try {
      final rawItems = widget.showClients
          ? await ApiService.getAllClients(auth.token!)
          : await ApiService.getAllFreelancers(auth.token!);

      setState(() {
        _people = widget.showClients
            ? rawItems.map((e) => ClientModel.fromJson(e)).toList()
            : rawItems.map((e) => FreelancerModel.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load data.';
        _isLoading = false;
      });
      debugPrint('PeopleListScreen error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.showClients ? 'Clients' : 'Freelancers';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));
    }
    if (_people.isEmpty) {
      return const Center(child: Text('No profiles available yet.'));
    }

    return ListView.separated(
      itemCount: _people.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final person = _people[index];
        final displayName = widget.showClients
            ? (person as ClientModel).displayName
            : (person as FreelancerModel).displayName;
        final subtitle = widget.showClients
            ? (person as ClientModel).jobTitle
            : (person as FreelancerModel).jobTitle;
        final avatarUrl = widget.showClients
            ? (person as ClientModel).profilePictureUrl
            : (person as FreelancerModel).profilePictureUrl;
        final additionalText = widget.showClients
            ? (person as ClientModel).averageRatingGiven != null
                ? 'Rating ${(person as ClientModel).averageRatingGiven!.toStringAsFixed(1)}'
                : 'No rating yet'
            : (person as FreelancerModel).estimatedRate != null
                ? (person as FreelancerModel).formattedRate
                : 'Rate not set';

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PeopleProfileScreen(
                  isClient: widget.showClients,
                  client: widget.showClients ? person as ClientModel : null,
                  freelancer: widget.showClients ? null : person as FreelancerModel,
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary.withOpacity(0.15),
                  backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                      ? (avatarUrl.startsWith('http')
                          ? NetworkImage(avatarUrl) as ImageProvider
                          : (File(avatarUrl).existsSync()
                              ? FileImage(File(avatarUrl))
                              : null))
                      : null,
                  child: avatarUrl == null || avatarUrl.isEmpty
                      ? Text(
                          displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                          style: const TextStyle(color: AppColors.primary, fontSize: 20),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displayName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(subtitle.isNotEmpty ? subtitle : 'No title',
                          style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 10),
                      Text(additionalText,
                          style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }
}

class PeopleProfileScreen extends StatelessWidget {
  final bool isClient;
  final ClientModel? client;
  final FreelancerModel? freelancer;

  const PeopleProfileScreen({
    super.key,
    required this.isClient,
    this.client,
    this.freelancer,
  });

  @override
  Widget build(BuildContext context) {
    final name = isClient ? client?.displayName ?? 'Client' : freelancer?.displayName ?? 'Freelancer';
    final title = isClient ? client?.jobTitle ?? 'Client' : freelancer?.jobTitle ?? 'Freelancer';
    final avatarUrl = isClient ? client?.profilePictureUrl : freelancer?.profilePictureUrl;
    final description = isClient
        ? client?.bio ?? 'No description available.'
        : freelancer?.bio ?? 'No description available.';
    final badge = isClient
        ? client?.averageRatingGiven != null
            ? 'Rating ${client!.averageRatingGiven!.toStringAsFixed(1)}'
            : 'No rating yet'
        : freelancer?.estimatedRate != null
            ? freelancer!.formattedRate
            : 'Rate not set';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(isClient ? 'Client Profile' : 'Freelancer Profile'),
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, Color(0xFF008C8A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.white,
                    backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                        ? (avatarUrl.startsWith('http')
                            ? NetworkImage(avatarUrl) as ImageProvider
                            : (File(avatarUrl).existsSync() ? FileImage(File(avatarUrl)) : null))
                        : null,
                    child: avatarUrl == null || avatarUrl.isEmpty
                        ? const Icon(Icons.person, size: 48, color: AppColors.primary)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(name,
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.message, size: 18),
                        label: const Text('Message'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.work_outline, size: 18),
                        label: Text(isClient ? 'View Jobs' : 'Invite'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white70),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('About', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(description, style: const TextStyle(fontSize: 14, height: 1.6)),
                  const SizedBox(height: 20),
                  const Text('Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildDetailRow('Name', name),
                  _buildDetailRow(isClient ? 'Rating' : 'Rate', badge),
                  if (!isClient) _buildDetailRow('Experience', freelancer?.bio ?? 'Not available'),
                  if (isClient) _buildDetailRow('Website', client?.websiteUrl ?? 'Not available'),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text('$title:', style: const TextStyle(color: Colors.grey, fontSize: 14))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
