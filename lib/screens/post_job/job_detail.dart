import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/job_post_provider.dart';
import '../dashboard/dashboard.dart';
import 'job_roles.dart';

class PostNewJobJobDetail extends StatefulWidget {
  const PostNewJobJobDetail({super.key});

  @override
  PostNewJobJobDetailState createState() => PostNewJobJobDetailState();
}

class PostNewJobJobDetailState extends State<PostNewJobJobDetail> {
  static const Color _primary = Color(0xFF00AAA8);

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _daysController = TextEditingController(text: '7');

  String _projectType = 'individual';
  String _projectScope = 'small';
  String _experienceLevel = 'entry';
  DateTime? _deadline;
  bool _submitted = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) => Theme(
        data: Theme.of(
          context,
        ).copyWith(colorScheme: ColorScheme.light(primary: _primary)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  String get _deadlineDisplay {
    if (_deadline == null) return 'Select deadline';
    return '${_deadline!.day.toString().padLeft(2, '0')}/'
        '${_deadline!.month.toString().padLeft(2, '0')}/'
        '${_deadline!.year}';
  }

  String? _validate() {
    if (_titleController.text.trim().isEmpty) return 'Title is required';
    if (_descController.text.trim().isEmpty) return 'Description is required';
    if (_daysController.text.trim().isEmpty) return 'Working days is required';
    if (int.tryParse(_daysController.text.trim()) == null) {
      return 'Working days must be a number';
    }
    if (_deadline == null) return 'Deadline is required';
    return null;
  }

  void _onNext() {
    setState(() => _submitted = true);
    final error = _validate();
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    context.read<JobPostProvider>().setDraftJobData({
      'job_title': _titleController.text.trim(),
      'job_description': _descController.text.trim(),
      'project_type': _projectType,
      'project_scope': _projectScope,
      'working_days': int.parse(_daysController.text.trim()),
      'experience_level': _experienceLevel,
      'deadline':
          '${_deadline!.year}-${_deadline!.month.toString().padLeft(2, '0')}-${_deadline!.day.toString().padLeft(2, '0')}',
      'status': 'draft',
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostNewJobRoles(projectType: _projectType),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProjectTypeToggle(),
                    _buildHint(
                      _projectType == 'individual'
                          ? 'Individual: completed by 1 freelancer'
                          : 'Team: completed by 2 or more freelancers',
                    ),
                    _buildLabel('Title'),
                    _buildTextField(
                      controller: _titleController,
                      hint: 'e.g. Create a logo for my company',
                    ),
                    _buildLabel('Description'),
                    _buildTextField(
                      controller: _descController,
                      hint: 'Describe what you need...',
                      maxLines: 5,
                    ),
                    _buildLabel('Project Scope'),
                    _buildDropdown<String>(
                      value: _projectScope,
                      items: const ['small', 'medium', 'large'],
                      labels: const ['Small', 'Medium', 'Large'],
                      onChanged: (v) => setState(() => _projectScope = v!),
                    ),
                    _buildLabel('Experience Level'),
                    _buildDropdown<String>(
                      value: _experienceLevel,
                      items: const ['entry', 'intermediate', 'expert'],
                      labels: const ['Entry', 'Intermediate', 'Expert'],
                      onChanged: (v) => setState(() => _experienceLevel = v!),
                    ),
                    _buildLabel('Working Days'),
                    _buildWorkingDaysField(),
                    _buildHint(
                      'Working days start when a freelancer is chosen',
                    ),
                    _buildLabel('Deadline'),
                    _buildDeadlinePicker(),
                    _buildHint(
                      'Date by which freelancers must submit proposals',
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 29),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _onNext,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            'Next',
                            style: TextStyle(
                              fontSize: 12,
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
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() => Container(
    color: _primary,
    padding: const EdgeInsets.only(top: 23, bottom: 29),
    width: double.infinity,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white, size: 24),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(left: 29),
          child: Text(
            'Post new job',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Padding(
          padding: EdgeInsets.only(left: 29),
          child: Text(
            'Job Detail',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
      ],
    ),
  );

  Widget _buildProjectTypeToggle() => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      color: Colors.white,
      border: Border.all(color: const Color(0xFFF0F0F1)),
    ),
    padding: const EdgeInsets.symmetric(vertical: 3),
    margin: const EdgeInsets.only(top: 20, bottom: 12, left: 28, right: 28),
    child: Row(
      children: [
        _typeOption('Individual', 'individual'),
        _typeOption('Team', 'team'),
      ],
    ),
  );

  Widget _typeOption(String label, String value) {
    final selected = _projectType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _projectType = value),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: selected ? _primary : Colors.transparent,
          ),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF333333),
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Container(
    margin: const EdgeInsets.only(bottom: 8, left: 32),
    child: Text(
      text,
      style: const TextStyle(
        color: Color(0xFF7D7D7D),
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  Widget _buildHint(String text) => Container(
    margin: const EdgeInsets.only(bottom: 20, left: 29, right: 29, top: 4),
    child: Text(
      text,
      style: const TextStyle(color: Color(0xFFB5B4B4), fontSize: 10),
    ),
  );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) => Container(
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFFF0F0F1)),
      borderRadius: BorderRadius.circular(10),
      color: Colors.white,
    ),
    margin: const EdgeInsets.only(bottom: 16, left: 29, right: 29),
    child: TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Color(0xFF333333), fontSize: 12),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFB5B4B4)),
        contentPadding: const EdgeInsets.all(19),
        border: InputBorder.none,
      ),
    ),
  );

  Widget _buildDropdown<T>({
    required T value,
    required List<T> items,
    required List<String> labels,
    required void Function(T?) onChanged,
  }) => Container(
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFFF0F0F1)),
      borderRadius: BorderRadius.circular(10),
      color: Colors.white,
    ),
    margin: const EdgeInsets.only(bottom: 16, left: 29, right: 29),
    padding: const EdgeInsets.symmetric(horizontal: 19),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        style: const TextStyle(color: Color(0xFF333333), fontSize: 12),
        items: items
            .asMap()
            .entries
            .map(
              (e) => DropdownMenuItem<T>(
                value: e.value,
                child: Text(labels[e.key]),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    ),
  );

  Widget _buildWorkingDaysField() => Container(
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFFF0F0F1)),
      borderRadius: BorderRadius.circular(10),
      color: Colors.white,
    ),
    padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 5),
    margin: const EdgeInsets.only(bottom: 4, left: 29, right: 29),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: _daysController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Color(0xFF333333), fontSize: 12),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: '0',
            ),
          ),
        ),
        const Text(
          'days',
          style: TextStyle(
            color: Color(0xFF333333),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );

  Widget _buildDeadlinePicker() => GestureDetector(
    onTap: _selectDate,
    child: Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: _submitted && _deadline == null
              ? const Color(0xFFFF5C5C)
              : const Color(0xFFF0F0F1),
        ),
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 17),
      margin: const EdgeInsets.only(bottom: 4, left: 29, right: 29),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _deadlineDisplay,
            style: TextStyle(
              color: _deadline == null
                  ? const Color(0xFFB5B4B4)
                  : const Color(0xFF333333),
              fontSize: 12,
            ),
          ),
          const Icon(
            Icons.calendar_today_outlined,
            size: 18,
            color: Color(0xFFB5B4B4),
          ),
        ],
      ),
    ),
  );
}
