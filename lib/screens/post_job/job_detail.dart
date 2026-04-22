import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
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
  static const Color _primary = AppColors.primary;

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
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _primary),
        ),
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
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
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProjectTypeToggle(),
                  _buildInfoBanner(
                    _projectType == 'individual'
                        ? 'Individual: completed by 1 freelancer'
                        : 'Team: completed by 2 or more freelancers',
                  ),
                  const SizedBox(height: 4),
                  _buildLabel('Title'),
                  _buildTextField(
                    controller: _titleController,
                    hint: 'e.g. Create a logo for my company',
                    prefixIcon: Icons.work_outline,
                  ),
                  _buildLabel('Description'),
                  _buildTextField(
                    controller: _descController,
                    hint: 'Describe what you need...',
                    maxLines: 5,
                    prefixIcon: Icons.description_outlined,
                  ),
                  _buildLabel('Project Scope'),
                  _buildDropdown<String>(
                    value: _projectScope,
                    items: const ['small', 'medium', 'large'],
                    labels: const ['Small', 'Medium', 'Large'],
                    prefixIcon: Icons.gps_fixed,
                    onChanged: (v) => setState(() => _projectScope = v!),
                  ),
                  _buildLabel('Experience Level'),
                  _buildDropdown<String>(
                    value: _experienceLevel,
                    items: const ['entry', 'intermediate', 'expert'],
                    labels: const ['Entry', 'Intermediate', 'Expert'],
                    prefixIcon: Icons.bar_chart_outlined,
                    onChanged: (v) => setState(() => _experienceLevel = v!),
                  ),
                  _buildLabel('Working Days'),
                  _buildWorkingDaysField(),
                  _buildInfoBanner('Working days start when a freelancer is chosen'),
                  const SizedBox(height: 4),
                  _buildLabel('Deadline'),
                  _buildDeadlinePicker(),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _onNext,
                        icon: const Icon(Icons.send_outlined, size: 18),
                        label: const Text(
                          'Next',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
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
    );
  }

  Widget _buildHeader() {
    return Container(
      color: _primary,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -40,
            top: -20,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            right: 24,
            top: 52,
            child: _buildDotGrid(),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 20),
                    child: Text(
                      'Post new job',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Padding(
                    padding: EdgeInsets.only(left: 20),
                    child: Text(
                      'Job Detail',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDotGrid() {
    return Column(
      children: List.generate(
        4,
        (row) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: List.generate(
              3,
              (col) => Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProjectTypeToggle() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(4),
      margin: const EdgeInsets.only(top: 20, bottom: 12, left: 20, right: 20),
      child: Row(
        children: [
          _typeOption('Individual', 'individual', Icons.person_outline),
          _typeOption('Team', 'team', Icons.people_outline),
        ],
      ),
    );
  }

  Widget _typeOption(String label, String value, IconData icon) {
    final selected = _projectType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _projectType = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(36),
            color: selected ? _primary : Colors.transparent,
          ),
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? Colors.white : _primary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF333333),
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBanner(String text) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: _primary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: _primary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 8, top: 12),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    IconData? prefixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      margin: const EdgeInsets.only(bottom: 4, left: 20, right: 20),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(color: Color(0xFF333333), fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFB5B4B4), fontSize: 13),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: _primary, size: 20)
              : null,
          contentPadding: prefixIcon != null
              ? const EdgeInsets.symmetric(vertical: 16)
              : const EdgeInsets.all(16),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<T> items,
    required List<String> labels,
    required void Function(T?) onChanged,
    IconData? prefixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      margin: const EdgeInsets.only(bottom: 4, left: 20, right: 20),
      child: Row(
        children: [
          if (prefixIcon != null)
            Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Icon(prefixIcon, color: _primary, size: 20),
            ),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _primary),
                style: const TextStyle(color: Color(0xFF333333), fontSize: 13),
                padding: EdgeInsets.only(
                  left: prefixIcon != null ? 10 : 16,
                  right: 4,
                ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildWorkingDaysField() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      margin: const EdgeInsets.only(bottom: 8, left: 20, right: 20),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Icon(Icons.calendar_today_outlined, color: _primary, size: 20),
          ),
          Expanded(
            child: TextField(
              controller: _daysController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Color(0xFF333333), fontSize: 13),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
                hintText: '0',
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'days',
              style: TextStyle(
                color: _primary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlinePicker() {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: _submitted && _deadline == null
                ? const Color(0xFFFF5C5C)
                : const Color(0xFFE5E7EB),
          ),
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
        ),
        margin: const EdgeInsets.only(bottom: 4, left: 20, right: 20),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              child: Icon(Icons.calendar_today_outlined, color: _primary, size: 20),
            ),
            Expanded(
              child: Text(
                _deadlineDisplay,
                style: TextStyle(
                  color: _deadline == null
                      ? const Color(0xFFB5B4B4)
                      : const Color(0xFF333333),
                  fontSize: 13,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              child: Icon(Icons.calendar_today_outlined, color: _primary, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
