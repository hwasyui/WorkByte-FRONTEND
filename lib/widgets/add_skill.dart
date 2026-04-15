import 'package:flutter/material.dart';

class AddSkillWidget extends StatefulWidget {
  final Function(List<String>) onSave;

  const AddSkillWidget({Key? key, required this.onSave}) : super(key: key);

  @override
  State<AddSkillWidget> createState() => _AddSkillWidgetState();
}

class _AddSkillWidgetState extends State<AddSkillWidget> {
  final TextEditingController _controller = TextEditingController();
  List<String> tempSkills = [];

  void _addSkill() {
    if (_controller.text.trim().isNotEmpty) {
      setState(() {
        tempSkills.add(_controller.text.trim());
        _controller.clear();
      });
    }
  }

  void _removeSkill(String skill) {
    setState(() {
      tempSkills.remove(skill);
    });
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
              'Add Skills',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Enter skill (e.g. Flutter, UI/UX)',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addSkill,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onSubmitted: (_) => _addSkill(),
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              children: tempSkills.map((skill) {
                return Chip(
                  label: Text(skill),
                  onDeleted: () => _removeSkill(skill),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onSave(tempSkills);
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}