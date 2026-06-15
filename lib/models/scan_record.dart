class ScanRecord {
  final String id;
  final String fileName;
  final String filePath;
  final int pageCount;
  final DateTime date;
  final int fileSizeBytes;

  ScanRecord({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.pageCount,
    required this.date,
    required this.fileSizeBytes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'fileName': fileName,
        'filePath': filePath,
        'pageCount': pageCount,
        'date': date.toIso8601String(),
        'fileSizeBytes': fileSizeBytes,
      };

  factory ScanRecord.fromJson(Map<String, dynamic> json) => ScanRecord(
        id: json['id'],
        fileName: json['fileName'],
        filePath: json['filePath'],
        pageCount: json['pageCount'],
        date: DateTime.parse(json['date']),
        fileSizeBytes: json['fileSizeBytes'],
      );
}
