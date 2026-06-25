class ContractSubmissionFileModel {
  final String fileId;
  final String submissionId;
  final String fileUrl;
  final String fileName;
  final int? fileSizeBytes;
  final String? mimeType;
  final DateTime? uploadedAt;

  ContractSubmissionFileModel({
    required this.fileId,
    required this.submissionId,
    required this.fileUrl,
    required this.fileName,
    this.fileSizeBytes,
    this.mimeType,
    this.uploadedAt,
  });

  factory ContractSubmissionFileModel.fromJson(Map<String, dynamic> json) {
    return ContractSubmissionFileModel(
      fileId: json['file_id']?.toString() ?? '',
      submissionId: json['submission_id']?.toString() ?? '',
      fileUrl: json['file_url']?.toString() ?? '',
      fileName: json['file_name']?.toString() ?? '',
      fileSizeBytes: json['file_size_bytes'] is int
          ? json['file_size_bytes']
          : int.tryParse(json['file_size_bytes']?.toString() ?? ''),
      mimeType: json['mime_type']?.toString(),
      uploadedAt: json['uploaded_at'] != null
          ? DateTime.tryParse(json['uploaded_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'file_id': fileId,
      'submission_id': submissionId,
      'file_url': fileUrl,
      'file_name': fileName,
      'file_size_bytes': fileSizeBytes,
      'mime_type': mimeType,
      'uploaded_at': uploadedAt?.toIso8601String(),
    };
  }
}

class ContractSubmissionModel {
  final String submissionId;
  final String contractId;
  final String submittedBy;
  final String? note;
  final String status;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? revisionNote;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<ContractSubmissionFileModel> files;

  ContractSubmissionModel({
    required this.submissionId,
    required this.contractId,
    required this.submittedBy,
    this.note,
    required this.status,
    this.submittedAt,
    this.reviewedAt,
    this.revisionNote,
    this.createdAt,
    this.updatedAt,
    required this.files,
  });

  factory ContractSubmissionModel.fromJson(Map<String, dynamic> json) {
    return ContractSubmissionModel(
      submissionId: json['submission_id']?.toString() ?? '',
      contractId: json['contract_id']?.toString() ?? '',
      submittedBy: json['submitted_by']?.toString() ?? '',
      note: json['note']?.toString(),
      status: json['status']?.toString() ?? 'submitted',
      submittedAt: json['submitted_at'] != null
          ? DateTime.tryParse(json['submitted_at'].toString())
          : null,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.tryParse(json['reviewed_at'].toString())
          : null,
      revisionNote: json['revision_note']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      files: (json['files'] as List<dynamic>? ?? [])
          .map(
            (e) =>
                ContractSubmissionFileModel.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'submission_id': submissionId,
      'contract_id': contractId,
      'submitted_by': submittedBy,
      'note': note,
      'status': status,
      'submitted_at': submittedAt?.toIso8601String(),
      'reviewed_at': reviewedAt?.toIso8601String(),
      'revision_note': revisionNote,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'files': files.map((e) => e.toJson()).toList(),
    };
  }
}
