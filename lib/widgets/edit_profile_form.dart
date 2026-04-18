import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditProfileForm extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onSave;

  const EditProfileForm({
    super.key,
    required this.initialData,
    required this.onSave,
  });

  @override
  State<EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends State<EditProfileForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameCtrl;
  late TextEditingController usernameCtrl;
  late TextEditingController jobCtrl;

  String? imagePath; 
  String? imageUrl;
  bool? imageDeleted;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.initialData['name']);
    usernameCtrl =
        TextEditingController(text: widget.initialData['username']);
    jobCtrl = TextEditingController(text: widget.initialData['job']);
    imageUrl = widget.initialData['image'];
    imagePath = imageUrl;
    imageDeleted = false;
  }

  Future<void> _pickImageFromCamera() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

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
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

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
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF00AAA8)),
              title: const Text('Camera'),
              onTap: _pickImageFromCamera,
            ),
            ListTile(
              leading: const Icon(Icons.image, color: Color(0xFF00AAA8)),
              title: const Text('Gallery'),
              onTap: _pickImageFromGallery,
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Photo', style: TextStyle(color: Colors.red)),
              onTap: _deleteImage,
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSave({
        "name": nameCtrl.text,
        "username": usernameCtrl.text,
        "job": jobCtrl.text,
        "image": imagePath, 
        "imageUrl": imageUrl,
        "imageDeleted": imageDeleted ?? false,
      });

      Navigator.pop(context);
    }
  }

  Widget _input(TextEditingController c, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
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

  Widget _profileImage() {
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundImage: imagePath != null && !imageDeleted!
              ? (imagePath!.startsWith('http')
                  ? NetworkImage(imagePath!)
                  : (File(imagePath!).existsSync()
                      ? FileImage(File(imagePath!))
                      : null))
              : null,
          child: (imagePath == null || imageDeleted!) || (!imagePath!.startsWith('http') && !File(imagePath!).existsSync())
              ? const Icon(Icons.person, size: 40)
              : null,
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _showImageOptions,
          child: const Text("Change Photo"),
        )
      ],
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
                _profileImage(),
                const SizedBox(height: 16),

                _input(nameCtrl, "Display Name"),
                _input(usernameCtrl, "Username"),
                _input(jobCtrl, "Job Title"),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00AAA8),
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