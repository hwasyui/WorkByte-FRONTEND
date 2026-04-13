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
  bool isCurrent = false;
  bool _isSubmitting = false;

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

  void _submit() async {
    if (_formKey.currentState!.validate() && !_isSubmitting) {
      if (!isCurrent && endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End date is required if not currently studying')),
        );
        return;
      }

      setState(() => _isSubmitting = true);

      try {
        await widget.onSave({
          "school": schoolCtrl.text,
          "degree": degreeCtrl.text,
          "field": fieldCtrl.text,
          "grade": gradeCtrl.text,
          "description": descCtrl.text,
          "startDate": startDate,
          "endDate": endDate,
          "isCurrent": isCurrent,
        });

        Navigator.pop(context);
      } finally {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
      }
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

  Widget _dateField(String label, DateTime? date, VoidCallback onTap, {bool isRequired = true}) {
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
                    _dateField("End Date (leave empty if current)", endDate, () => _pickDate(false), isRequired: false),
                  ],
                ),

                const SizedBox(height: 12),

                _input(gradeCtrl, "Grade"),

                CheckboxListTile(
                  title: const Text("Currently studying here"),
                  value: isCurrent,
                  onChanged: (value) {
                    setState(() {
                      isCurrent = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),

                _input(descCtrl, "Description", maxLines: 3),

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
        ),
      ),
    );
  }
}