import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class AddSkillWidget extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;

  const AddSkillWidget({Key? key, required this.onSave}) : super(key: key);

  @override
  State<AddSkillWidget> createState() => _AddSkillWidgetState();
}

class _AddSkillWidgetState extends State<AddSkillWidget> {
  String? selectedSkillId;
  String? selectedProficiency;
  bool _isSubmitting = false;
  bool _isLoading = true;

  List<Map<String, dynamic>> skills = [];

  List<String> proficiencyLevels = [
    'Beginner',
    'Intermediate',
    'Advanced',
  ];

  @override
  void initState() {
    super.initState();
    _loadSkills();
  }

  Future<void> _loadSkills() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final skillList = await ApiService.getSkills(auth.token!);
    if (mounted) {
      setState(() {
        skills = skillList;
        _isLoading = false;
      });
    }
  }

  void _submit() async {
    if (selectedSkillId != null && selectedProficiency != null && !_isSubmitting) {
      setState(() => _isSubmitting = true);

      try {
        await widget.onSave({
          "skill_id": selectedSkillId,
          "proficiency_level": selectedProficiency!.toLowerCase(),
        });

        if (mounted) Navigator.pop(context);
      } finally {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add Skill',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Skill",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 6),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<String>(
                        value: selectedSkillId,
                        hint: const Text("Select Skill"),
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down),
                        items: skills.map((skill) {
                          final id = skill["skill_id"]?.toString();
                          return DropdownMenuItem<String>(
                            value: id,
                            child: Text(skill["skill_name"] ?? "Unknown Skill"),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedSkillId = value;
                          });
                        },
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFF6C63FF)),
                          ),
                        ),
                      ),
              ],
            ),

            const SizedBox(height: 12),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Proficiency",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedProficiency,
                  hint: const Text("Select Proficiency"),
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  items: proficiencyLevels.map((level) {
                    return DropdownMenuItem(
                      value: level,
                      child: Text(level.toLowerCase()), 
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedProficiency = value;
                    });
                  },
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Color(0xFF6C63FF)),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00AAA8),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        "Save",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}