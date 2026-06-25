class JobFileModel {
  final String jobFileId;
  final String jobPostId;
  final String fileUrl;
  final String fileType;
  final String fileName;
  final int? fileSize;
  final String? createdAt;

  const JobFileModel({
    required this.jobFileId,
    required this.jobPostId,
    required this.fileUrl,
    required this.fileType,
    required this.fileName,
    this.fileSize,
    this.createdAt,
  });

  factory JobFileModel.fromJson(Map<String, dynamic> json) {
    return JobFileModel(
      jobFileId: (json['job_file_id'] ?? json['jobFileId'] ?? json['id'] ?? '')
          .toString(),
      jobPostId: (json['job_post_id'] ?? json['jobPostId'] ?? '').toString(),
      fileUrl: (json['file_url'] ?? json['fileUrl'] ?? json['url'] ?? '')
          .toString(),
      fileType: (json['file_type'] ?? json['fileType'] ?? '').toString(),
      fileName: (json['file_name'] ?? json['fileName'] ?? '').toString(),
      fileSize: (json['file_size'] ?? json['fileSize']) is num
          ? (json['file_size'] ?? json['fileSize']).toInt()
          : null,
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'job_post_id': jobPostId,
      'file_url': fileUrl,
      'file_type': fileType,
      'file_name': fileName,
      if (fileSize != null) 'file_size': fileSize,
    };
  }

  /// Human-readable file size e.g. "2.4 MB"
  String get fileSizeFormatted {
    if (fileSize == null) return '';
    if (fileSize! < 1024) return '$fileSize B';
    if (fileSize! < 1024 * 1024) {
      return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Extract extension automatically if backend doesn’t provide file_type
  String get resolvedFileType {
    if (fileType.isNotEmpty) return fileType.toLowerCase();

    if (fileName.contains('.')) {
      return fileName.split('.').last.toLowerCase();
    }
    return '';
  }

  /// Icon lookup based on file type
  String get fileTypeIcon {
    switch (resolvedFileType) {
      case 'pdf':
        return 'pdf';
      case 'doc':
      case 'docx':
        return 'word';
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'webp':
        return 'image';
      case 'zip':
      case 'rar':
        return 'archive';
      default:
        return 'file';
    }
  }

  JobFileModel copyWith({
    String? jobFileId,
    String? jobPostId,
    String? fileUrl,
    String? fileType,
    String? fileName,
    int? fileSize,
    String? createdAt,
  }) {
    return JobFileModel(
      jobFileId: jobFileId ?? this.jobFileId,
      jobPostId: jobPostId ?? this.jobPostId,
      fileUrl: fileUrl ?? this.fileUrl,
      fileType: fileType ?? this.fileType,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
