import 'package:flutter/material.dart';
import '../core/constants/colors.dart';

class ExperienceProfile extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;

  const ExperienceProfile({super.key, required this.onSave});

  @override
  State<ExperienceProfile> createState() => _ExperienceProfileState();
}

class _ExperienceProfileState extends State<ExperienceProfile> {
  final _formKey = GlobalKey<FormState>();

  final titleCtrl = TextEditingController();
  final companyCtrl = TextEditingController();
  final locationCtrl = TextEditingController();
  final descCtrl = TextEditingController();

  DateTime? startDate;
  DateTime? endDate;
  bool isPresent = false;

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (startDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Start date is required')),
        );
        return;
      }

      if (!isPresent && endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End date is required unless currently working here')),
        );
        return;
      }

      widget.onSave({
        "title": titleCtrl.text,
        "company": companyCtrl.text,
        "location": locationCtrl.text,
        "description": descCtrl.text,
        "startDate": startDate,
        "endDate": endDate,
        "isPresent": isPresent,
      });

      Navigator.pop(context);
    }
  }

  Widget _input(TextEditingController c, String label,
      {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        maxLines: maxLines,
        validator: (v) => v!.isEmpty ? "Required" : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _dateField(String label, DateTime? date, VoidCallback onTap) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onTap,
        child: Text(
          date == null ? label : "${date.month}/${date.year}",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _input(titleCtrl, "Job Title"),
                _input(companyCtrl, "Company"),

                Row(
                  children: [
                    _dateField("Start Date", startDate, () => _pickDate(true)),
                    const SizedBox(width: 8),
                    _dateField("End Date", endDate, () => _pickDate(false)),
                  ],
                ),

                CheckboxListTile(
                  value: isPresent,
                  onChanged: (v) => setState(() => isPresent = v!),
                  title: const Text("Currently working here"),
                ),
                _input(locationCtrl, "Location"),
                _input(descCtrl, "Description", maxLines: 3),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Save",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}