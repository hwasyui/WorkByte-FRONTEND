import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
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

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.initialData['name']);
    usernameCtrl =
        TextEditingController(text: widget.initialData['username']);
    jobCtrl = TextEditingController(text: widget.initialData['job']);
    imagePath = widget.initialData['image'];
  }

  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null) {
      setState(() {
        imagePath = result.files.single.path;
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSave({
        "name": nameCtrl.text,
        "username": usernameCtrl.text,
        "job": jobCtrl.text,
        "image": imagePath,
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
          backgroundImage: imagePath != null
              ? (imagePath!.startsWith('http')
                  ? NetworkImage(imagePath!)
                  : FileImage(
                      // ignore: unnecessary_cast
                      File(imagePath!),
                    ) as ImageProvider)
              : null,
          child: imagePath == null
              ? const Icon(Icons.person, size: 40)
              : null,
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _pickImage,
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