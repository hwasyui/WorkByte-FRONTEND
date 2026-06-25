import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../models/contract_model.dart';
import '../../models/freelancer_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../services/contract_service.dart';

class ClientHistoryScreen extends StatefulWidget {
  const ClientHistoryScreen({Key? key}) : super(key: key);

  @override
  State<ClientHistoryScreen> createState() => _ClientHistoryScreenState();
}

class _ClientHistoryScreenState extends State<ClientHistoryScreen> {
  bool _isLoading = true;
  String? _error;
  final Map<String, List<ContractModel>> _historyByFreelancer = {};
  final Map<String, FreelancerModel?> _freelancers = {};

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _historyByFreelancer.clear();
      _freelancers.clear();
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final profile = Provider.of<ProfileProvider>(context, listen: false);
    final token = auth.token;
    final clientId = profile.clientProfile?.clientId;

    if (token == null || clientId == null || clientId.isEmpty) {
      setState(() {
        _error = 'Client not authenticated.';
        _isLoading = false;
      });
      return;
    }

    try {
      final contractService = ContractService();
      final contracts = await contractService.getContractsByClient(token, clientId);

      final groups = <String, List<ContractModel>>{};
      for (final contract in contracts) {
        groups.putIfAbsent(contract.freelancerId, () => []).add(contract);
      }

      final List<Future<MapEntry<String, FreelancerModel?>>> fetches = groups.keys
          .map((freelancerId) async {
            final freelancer = await profile.fetchFreelancerById(
              token: token,
              freelancerId: freelancerId,
            );
            return MapEntry(freelancerId, freelancer);
          })
          .toList();
      final entries = await Future.wait(fetches);

      if (!mounted) return;
      setState(() {
        _historyByFreelancer.addAll(groups);
        _freelancers.addEntries(entries);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load freelancer history.';
        _isLoading = false;
      });
      debugPrint('ClientHistoryScreen error: $e');
    }
  }

  String _formatDate(String? value) {
    if (value == null || value.isEmpty) return 'No date available';
    return value.split('T').first;
  }

  Widget _buildHistoryAvatar(String? imageUrl, String name) {
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    final imageProvider = hasImage ? NetworkImage(imageUrl) : null;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        image: imageProvider != null ? DecorationImage(image: imageProvider, fit: BoxFit.cover) : null,
      ),
      child: imageProvider == null
          ? Center(
              child: Text(
                name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildHistoryStatusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 16,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'History Freelancer',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'View freelancers who have completed projects with you.',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF7D7D7D),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_historyByFreelancer.length} Freelancer',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: const Color(0xFF7D7D7D),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${_historyByFreelancer.values.fold<int>(0, (sum, list) => sum + list.length)} projects',
                                style: GoogleFonts.poppins(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1A1A2E),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            'Summary',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2,
                      ),
                    )
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline_rounded,
                                  size: 48, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              Text(
                                _error!,
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF7D7D7D),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        )
                      : _historyByFreelancer.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.history_rounded,
                                      size: 56, color: Colors.grey.shade300),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No work history yet',
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFF7D7D7D),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Freelancers will appear after working with you.',
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFFB5B4B4),
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              color: AppColors.primary,
                              onRefresh: _loadHistory,
                              child: ListView.separated(
                                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                itemCount: _historyByFreelancer.keys.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final freelancerId = _historyByFreelancer.keys.elementAt(index);
                                  final contracts = _historyByFreelancer[freelancerId]!;
                                  final freelancer = _freelancers[freelancerId];

                                  return Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ExpansionTile(
                                      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                      collapsedShape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      title: Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          _buildHistoryAvatar(
                                            freelancer?.profilePictureUrl,
                                            freelancer?.displayName ?? 'F',
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  freelancer?.displayName ?? 'Freelancer',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w700,
                                                    color: const Color(0xFF1A1A2E),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${contracts.length} projects',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 12,
                                                    color: const Color(0xFF7D7D7D),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                      children: contracts.map((contract) {
                                        return Container(
                                          margin: const EdgeInsets.only(top: 12),
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color: AppColors.background,
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                contract.contractTitle.isNotEmpty
                                                    ? contract.contractTitle
                                                    : contract.roleTitle.isNotEmpty
                                                        ? contract.roleTitle
                                                        : 'Project title not available',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: const Color(0xFF1A1A2E),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: [
                                                  _buildHistoryStatusChip(contract.status),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    _formatDate(contract.actualCompletionDate ?? contract.endDate),
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                      color: const Color(0xFF7D7D7D),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if ((contract.roleTitle).isNotEmpty) ...[
                                                const SizedBox(height: 8),
                                                Text(
                                                  contract.roleTitle,
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 12,
                                                    color: const Color(0xFF7D7D7D),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
