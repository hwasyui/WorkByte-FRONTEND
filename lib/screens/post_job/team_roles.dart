import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'add_team.dart';
import 'payment_detail.dart';
import '../../providers/job_post_provider.dart';
import '../../models/job_role_model.dart';

class PostNewJobTeamRoles extends StatefulWidget {
  const PostNewJobTeamRoles({super.key});

  @override
  PostNewJobTeamRolesState createState() => PostNewJobTeamRolesState();
}

class PostNewJobTeamRolesState extends State<PostNewJobTeamRoles> {
  // Draft roles held locally until "Next" is tapped
  final List<JobRoleModel> _draftRoles = [];

  // ─── Add or edit a role via modal ─────────────────────────────────────────
  Future<void> _openAddTeamModal({
    JobRoleModel? editRole,
    int? editIndex,
  }) async {
    final result = await showAddTeamModal(context, editRole: editRole);
    if (result == null) return;

    setState(() {
      if (result.jobRoleId == '__delete__' && editIndex != null) {
        _draftRoles.removeAt(editIndex);
      } else if (editIndex != null) {
        _draftRoles[editIndex] = result;
      } else {
        _draftRoles.add(result);
      }
    });
  }

  // ─── Validation ───────────────────────────────────────────────────────────
  String? _validate() {
    if (_draftRoles.isEmpty) return 'Add at least one role before continuing';
    return null;
  }

  void _onNext() {
    final error = _validate();
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    // Convert draft roles to plain maps for the provider
    final roleMaps = _draftRoles.asMap().entries.map((e) {
      final role = e.value;
      return <String, dynamic>{
        'role_title': role.roleTitle,
        if (role.roleBudget != null) 'role_budget': role.roleBudget,
        'budget_currency': role.budgetCurrency,
        'budget_type': role.budgetType,
        if (role.roleDescription != null)
          'role_description': role.roleDescription,
        'positions_available': role.positionsAvailable,
        'is_required': role.isRequired,
        'display_order': e.key,
      };
    }).toList();

    // Save draft — no API call yet
    context.read<JobPostProvider>().setDraftRoles(roleMaps);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PostPaymentDetail()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          constraints: const BoxConstraints.expand(),
          color: const Color(0xFFFFFFFF),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  color: const Color(0xFFF9F9F9),
                  width: double.infinity,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Header ──────────────────────────────────────────
                        Container(
                          color: const Color(0xFF00AAA8),
                          padding: const EdgeInsets.only(top: 23, bottom: 40),
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InkWell(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  margin: const EdgeInsets.only(
                                    bottom: 15,
                                    left: 18,
                                  ),
                                  child: const Icon(
                                    Icons.chevron_left,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(
                                  bottom: 9,
                                  left: 29,
                                ),
                                child: const Text(
                                  'Post new job',
                                  style: TextStyle(
                                    color: Color(0xFFFFFFFF),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(left: 29),
                                child: const Text(
                                  'Team Roles',
                                  style: TextStyle(
                                    color: Color(0xFFFFFFFF),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // ── Role list ────────────────────────────────────────
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 26),
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_draftRoles.isEmpty)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.only(top: 50),
                                    child: Text(
                                      'Add team roles',
                                      style: TextStyle(
                                        color: Color(0xFFB5B4B4),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ...List.generate(_draftRoles.length, (
                                      index,
                                    ) {
                                      final actualIndex =
                                          _draftRoles.length - 1 - index;
                                      final role = _draftRoles[actualIndex];
                                      return Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 16,
                                        ),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          color: Colors.white,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.05,
                                              ),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          children: [
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  width: 35,
                                                  height: 35,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: const Color(
                                                        0xFF00AAA8,
                                                      ),
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      '${actualIndex + 1}',
                                                      style: const TextStyle(
                                                        color: Color(
                                                          0xFF00AAA8,
                                                        ),
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        role.roleTitle,
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        role.roleDescription ??
                                                            'No description',
                                                        style: const TextStyle(
                                                          color: Colors.grey,
                                                          fontSize: 11,
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Text(
                                                  role.roleBudget != null
                                                      ? '${role.budgetCurrency} ${role.roleBudget!.toStringAsFixed(0)}'
                                                      : 'No budget',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 16),
                                            SizedBox(
                                              width: double.infinity,
                                              height: 45,
                                              child: ElevatedButton(
                                                onPressed: () =>
                                                    _openAddTeamModal(
                                                      editRole: role,
                                                      editIndex: actualIndex,
                                                    ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(
                                                    0xFF00AAA8,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          25,
                                                        ),
                                                  ),
                                                  elevation: 0,
                                                ),
                                                child: const Text(
                                                  'Edit',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                    const SizedBox(height: 10),
                                    Text(
                                      'You have ${_draftRoles.length} role${_draftRoles.length == 1 ? '' : 's'} for this job',
                                      style: const TextStyle(
                                        color: Color(0xFF7D7D7D),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Next button ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00AAA8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      'Next',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // ── FAB: add role → opens modal ──────────────────────────────────
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton(
          backgroundColor: const Color(0xFF00AAA8),
          onPressed: () => _openAddTeamModal(),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}
