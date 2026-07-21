import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';

class EditProfileForm extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onSave;
  final bool showJobTitle;

  const EditProfileForm({
    super.key,
    required this.initialData,
    required this.onSave,
    this.showJobTitle = true,
  });

  @override
  State<EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends State<EditProfileForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameCtrl;
  late TextEditingController jobTitleCtrl;

  String? imagePath;
  String? imageUrl;
  bool? imageDeleted;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.initialData['name'] ?? '');
    final rawJob = widget.initialData['job'] as String?;
    jobTitleCtrl = TextEditingController(
      text: (rawJob == null || rawJob == '-') ? '' : rawJob,
    );
    imageUrl = widget.initialData['image'];
    imagePath = imageUrl;
    imageDeleted = false;
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    jobTitleCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromCamera() async {
    final XFile? image = await ImagePicker().pickImage(
      source: ImageSource.camera,
    );
    if (image != null) {
      setState(() {
        imagePath = image.path;
        imageUrl = image.name;
        imageDeleted = false;
      });
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _pickImageFromGallery() async {
    final XFile? image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (image != null) {
      setState(() {
        imagePath = image.path;
        imageUrl = image.name;
        imageDeleted = false;
      });
    }
    if (mounted) Navigator.pop(context);
  }

  void _deleteImage() {
    setState(() {
      imagePath = null;
      imageUrl = null;
      imageDeleted = true;
    });
    Navigator.pop(context);
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              title: Text(
                'Camera',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              onTap: _pickImageFromCamera,
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.photo_library_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              title: Text(
                'Gallery',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              onTap: _pickImageFromGallery,
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.delete_rounded,
                  color: Colors.red.shade400,
                  size: 20,
                ),
              ),
              title: Text(
                'Remove Photo',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  color: Colors.red.shade400,
                ),
              ),
              onTap: _deleteImage,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSave({
        "name": nameCtrl.text,
        "job": jobTitleCtrl.text,
        "image": imagePath,
        "imageUrl": imageUrl,
        "imageDeleted": imageDeleted ?? false,
      });
      Navigator.pop(context);
    }
  }

  Widget _buildAvatar() {
    final hasImage = imagePath != null && imageDeleted == false;
    final isNetwork = hasImage && imagePath!.startsWith('http');
    final isLocal =
        hasImage && !isNetwork && File(imagePath!).existsSync();
    final showImage = isNetwork || isLocal;

    return GestureDetector(
      onTap: _showImageOptions,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Decorative dots
          Positioned(
            top: -8,
            left: -20,
            child: _dot(8, const Color(0xFFB8B0F0)),
          ),
          Positioned(
            top: 16,
            left: -36,
            child: _dot(5, const Color(0xFFD4D0F8)),
          ),
          Positioned(
            top: -8,
            right: -20,
            child: _dot(8, const Color(0xFFB8B0F0)),
          ),
          Positioned(
            top: 16,
            right: -36,
            child: _dot(5, const Color(0xFFD4D0F8)),
          ),
          Positioned(
            bottom: 10,
            left: -28,
            child: _dot(5, const Color(0xFFD4D0F8)),
          ),
          Positioned(
            bottom: 10,
            right: -28,
            child: _dot(5, const Color(0xFFD4D0F8)),
          ),
          // Sparkle icons
          const Positioned(
            top: -4,
            left: 2,
            child: Icon(Icons.add, size: 14, color: Color(0xFFB8B0F0)),
          ),
          const Positioned(
            top: -4,
            right: 2,
            child: Icon(Icons.add, size: 14, color: Color(0xFFB8B0F0)),
          ),

          // Avatar circle
          Container(
            width: 110,
            height: 110,
            decoration: const BoxDecoration(
              color: Color(0xFFE0DCFA),
              shape: BoxShape.circle,
            ),
            child: showImage
                ? ClipOval(
                    child: isNetwork
                        ? Image.network(imagePath!, fit: BoxFit.cover)
                        : Image.file(File(imagePath!), fit: BoxFit.cover),
                  )
                : const Icon(
                    Icons.person_rounded,
                    size: 58,
                    color: AppColors.primary,
                  ),
          ),

          // Camera badge
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                size: 17,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );

  Widget _fieldLabel(String label, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF374151),
          ),
        ),
      ],
    ),
  );

  Widget _textField(
    TextEditingController ctrl, {
    String hintText = '',
    bool required = true,
  }) => TextFormField(
    controller: ctrl,
    validator: required
        ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
        : null,
    style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF1A1A2E)),
    decoration: InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.poppins(
        fontSize: 14,
        color: const Color(0xFF9CA3AF),
      ),
      filled: true,
      fillColor: const Color(0xFFEEECFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDDD8FA), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Close button row
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEECFB),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),

                // Avatar section
                const SizedBox(height: 8),
                Center(child: _buildAvatar()),
                const SizedBox(height: 16),

                // Title
                Center(
                  child: Text(
                    'Change Photo',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    'Upload a clear photo to help others\nrecognize you easily.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF9CA3AF),
                      height: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Display Name
                _fieldLabel('Display Name', Icons.person_outline_rounded),
                _textField(nameCtrl, hintText: 'Your name'),

                if (widget.showJobTitle) ...[
                  const SizedBox(height: 16),

                  // Job Title
                  _fieldLabel('Job Title', Icons.work_outline_rounded),
                  _textField(
                    jobTitleCtrl,
                    hintText: 'e.g. UI Designer',
                    required: false,
                  ),
                ],

                const SizedBox(height: 28),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: Text(
                      'Save',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
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
