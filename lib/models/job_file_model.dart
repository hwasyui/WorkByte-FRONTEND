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

  factory JobFileModel.fromJson(Map<String, dynamic> json) => JobFileModel(
    jobFileId: json['job_file_id'] as String? ?? '',
    jobPostId: json['job_post_id'] as String? ?? '',
    fileUrl: json['file_url'] as String? ?? '',
    fileType: json['file_type'] as String? ?? '',
    fileName: json['file_name'] as String? ?? '',
    fileSize: (json['file_size'] as num?)?.toInt(),
    createdAt: json['created_at']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'job_post_id': jobPostId,
    'file_url': fileUrl,
    'file_type': fileType,
    'file_name': fileName,
    if (fileSize != null) 'file_size': fileSize,
  };

  /// Human-readable file size e.g. "2.4 MB"
  String get fileSizeFormatted {
    if (fileSize == null) return '';
    if (fileSize! < 1024) return '${fileSize} B';
    if (fileSize! < 1024 * 1024) {
      return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Icon lookup based on file type
  String get fileTypeIcon {
    switch (fileType.toLowerCase()) {
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
}
