class ProposalFileModel {
  final String proposalFileId;
  final String proposalId;
  final String fileUrl;
  final String fileType;
  final String fileName;
  final int? fileSize;
  final String? createdAt;

  const ProposalFileModel({
    required this.proposalFileId,
    required this.proposalId,
    required this.fileUrl,
    required this.fileType,
    required this.fileName,
    this.fileSize,
    this.createdAt,
  });

  factory ProposalFileModel.fromJson(Map<String, dynamic> json) {
    return ProposalFileModel(
      proposalFileId: json['proposal_file_id'] as String,
      proposalId: json['proposal_id'] as String,
      fileUrl: json['file_url'] as String,
      fileType: json['file_type'] as String,
      fileName: json['file_name'] as String,
      fileSize: json['file_size'] as int?,
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'proposal_file_id': proposalFileId,
    'proposal_id': proposalId,
    'file_url': fileUrl,
    'file_type': fileType,
    'file_name': fileName,
    'file_size': fileSize,
    'created_at': createdAt,
  };

  /// Human-readable file size e.g. "1.2 MB"
  String get formattedSize {
    if (fileSize == null) return '';
    if (fileSize! < 1024) return '${fileSize} B';
    if (fileSize! < 1024 * 1024) {
      return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// True if file is a PDF
  bool get isPdf =>
      fileType.toLowerCase() == 'pdf' ||
      fileName.toLowerCase().endsWith('.pdf');

  /// True if file is an image
  bool get isImage => [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
  ].any((ext) => fileName.toLowerCase().endsWith('.$ext'));
}
