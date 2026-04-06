import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/job_model.dart';
import '../../providers/job_provider.dart';

class PostNewJobAddTeam extends StatefulWidget {
  final int? editIndex;
  final TeamRole? initialRole;

  const PostNewJobAddTeam({
    super.key,
    this.editIndex,
    this.initialRole,
  });

  @override
  State<PostNewJobAddTeam> createState() => _PostNewJobAddTeamState();
}

class _PostNewJobAddTeamState extends State<PostNewJobAddTeam> {
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool get isEditMode => widget.editIndex != null;

  @override
  void initState() {
    super.initState();

    if (isEditMode && widget.initialRole != null) {
      _roleController.text = widget.initialRole!.roleName;
      _budgetController.text = widget.initialRole!.budget;
      _descriptionController.text = widget.initialRole!.description ?? '';
    }
  }

  @override
  void dispose() {
    _roleController.dispose();
    _budgetController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00AAA8),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Post new job",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    isEditMode ? "Edit Team Role" : "Add Team Role",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(25),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      
                      // drag indicator
                      Center(
                        child: Container(
                          width: 100,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      const Text(
                        "Role",
                        style: TextStyle(
                          color: Color(0xFF7D7D7D),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildTextField(
                        hint: "Ex: UI Designer",
                        controller: _roleController,
                      ),

                      const SizedBox(height: 15),

                      const Text(
                        "Budget",
                        style: TextStyle(
                          color: Color(0xFF7D7D7D),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildTextField(
                        hint: "Ex: Rp. 1.000.000",
                        controller: _budgetController,
                      ),

                      const SizedBox(height: 15),

                      const Text(
                        "Description",
                        style: TextStyle(
                          color: Color(0xFF7D7D7D),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildTextField(
                        hint:
                            "Ex: We need UI Designer who can work with team",
                        maxLines: 5,
                        controller: _descriptionController,
                      ),

                      const SizedBox(height: 25),

                      SizedBox(
                        width: double.infinity,
                        child: GestureDetector(
                          onTap: () {
                            if (_roleController.text.isNotEmpty &&
                                _budgetController.text.isNotEmpty) {
                              
                              if (isEditMode) {
                                final updatedRole = TeamRole(
                                  id: widget.initialRole!.id,
                                  roleName: _roleController.text,
                                  budget: _budgetController.text,
                                  description: _descriptionController.text,
                                );

                                context
                                    .read<JobProvider>()
                                    .updateTeamRole(widget.editIndex!, updatedRole);

                                Navigator.pop(context);
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Role berhasil diupdate'),
                                    backgroundColor: Color(0xFF00AAA8),
                                  ),
                                );
                              } else {
                                final newRole = TeamRole(
                                  id: DateTime.now().toString(),
                                  roleName: _roleController.text,
                                  budget: _budgetController.text,
                                  description: _descriptionController.text,
                                );

                                context
                                    .read<JobProvider>()
                                    .addTeamRole(newRole);

                                Navigator.pop(context);
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Silakan isi Role dan Budget'),
                                ),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00AAA8),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              isEditMode ? "Update" : "Add",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),

                      if (isEditMode) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    title: const Text(
                                      'Delete Role',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    content: const Text(
                                      'Are you sure you want to delete this role?',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text(
                                          'Cancel',
                                          style: TextStyle(
                                            color: Color(0xFF7D7D7D),
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          context
                                              .read<JobProvider>()
                                              .removeTeamRole(widget.editIndex!);
                                          
                                          Navigator.pop(context); 
                                          Navigator.pop(context); 
                                          
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Role successfully deleted'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        },
                                        child: const Text(
                                          'Delete',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: Colors.red,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                "Delete",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    int maxLines = 1,
    required TextEditingController controller,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFF0F0F1)),
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Color(0xFFB5B4B4),
            fontSize: 12,
          ),
          contentPadding: const EdgeInsets.all(15),
          border: InputBorder.none,
        ),
      ),
    );
  }
}