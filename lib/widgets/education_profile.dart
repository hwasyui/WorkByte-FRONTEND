import 'package:flutter/material.dart';

class EducationProfile extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;

  const EducationProfile({super.key, required this.onSave});

  @override
  State<EducationProfile> createState() => _EducationProfileState();
}

class _EducationProfileState extends State<EducationProfile> {
  final _formKey = GlobalKey<FormState>();

  final schoolCtrl = TextEditingController();
  final degreeCtrl = TextEditingController();
  final fieldCtrl = TextEditingController();
  final gradeCtrl = TextEditingController();
  final descCtrl = TextEditingController();

  DateTime? startDate;
  DateTime? endDate;

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
      widget.onSave({
        "school": schoolCtrl.text,
        "degree": degreeCtrl.text,
        "field": fieldCtrl.text,
        "grade": gradeCtrl.text,
        "description": descCtrl.text,
        "startDate": startDate,
        "endDate": endDate,
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
          date == null
              ? label
              : "${date.month}/${date.year}",
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
                _input(schoolCtrl, "School"),
                _input(degreeCtrl, "Degree"),
                _input(fieldCtrl, "Field of Study"),

                Row(
                  children: [
                    _dateField("Start Date", startDate, () => _pickDate(true)),
                    const SizedBox(width: 8),
                    _dateField("End Date", endDate, () => _pickDate(false)),
                  ],
                ),

                const SizedBox(height: 12),

                _input(gradeCtrl, "Grade"),
                _input(descCtrl, "Description", maxLines: 3),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    child: const Text("Save"),
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