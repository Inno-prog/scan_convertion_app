import 'package:flutter/material.dart';

class ConversionFormat {
  final String label;
  final String extension;
  final IconData icon;
  final Color color;

  const ConversionFormat({
    required this.label,
    required this.extension,
    required this.icon,
    required this.color,
  });
}

class FileCategory {
  final String name;
  final IconData icon;
  final Color color;
  final List<String> inputExtensions;
  final List<ConversionFormat> outputFormats;

  const FileCategory({
    required this.name,
    required this.icon,
    required this.color,
    required this.inputExtensions,
    required this.outputFormats,
  });
}

final List<FileCategory> fileCategories = [
  FileCategory(
    name: 'Document',
    icon: Icons.description_rounded,
    color: const Color(0xFF4F8EF7),
    inputExtensions: const ['pdf', 'doc', 'docx', 'txt', 'odt', 'rtf'],
    outputFormats: const [
      ConversionFormat(label: 'PDF', extension: 'pdf', icon: Icons.picture_as_pdf_rounded, color: Color(0xFFE53935)),
      ConversionFormat(label: 'Word', extension: 'docx', icon: Icons.description_rounded, color: Color(0xFF1565C0)),
      ConversionFormat(label: 'Excel', extension: 'xlsx', icon: Icons.table_chart_rounded, color: Color(0xFF2E7D32)),
      ConversionFormat(label: 'PowerPoint', extension: 'pptx', icon: Icons.slideshow_rounded, color: Color(0xFFE65100)),
      ConversionFormat(label: 'TXT', extension: 'txt', icon: Icons.text_snippet_rounded, color: Color(0xFF6D4C41)),
      ConversionFormat(label: 'HTML', extension: 'html', icon: Icons.code_rounded, color: Color(0xFF6A1B9A)),
      ConversionFormat(label: 'ODT', extension: 'odt', icon: Icons.article_rounded, color: Color(0xFF00838F)),
      ConversionFormat(label: 'RTF', extension: 'rtf', icon: Icons.text_fields_rounded, color: Color(0xFF558B2F)),
    ],
  ),
  FileCategory(
    name: 'Image',
    icon: Icons.image_rounded,
    color: const Color(0xFFE91E8C),
    inputExtensions: const ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'tiff', 'svg', 'heic'],
    outputFormats: const [
      ConversionFormat(label: 'JPG', extension: 'jpg', icon: Icons.image_rounded, color: Color(0xFFFF6F00)),
      ConversionFormat(label: 'PNG', extension: 'png', icon: Icons.image_rounded, color: Color(0xFF1565C0)),
      ConversionFormat(label: 'WebP', extension: 'webp', icon: Icons.image_rounded, color: Color(0xFF2E7D32)),
      ConversionFormat(label: 'GIF', extension: 'gif', icon: Icons.gif_rounded, color: Color(0xFF6A1B9A)),
      ConversionFormat(label: 'BMP', extension: 'bmp', icon: Icons.image_rounded, color: Color(0xFF4E342E)),
      ConversionFormat(label: 'TIFF', extension: 'tiff', icon: Icons.image_rounded, color: Color(0xFF00695C)),
      ConversionFormat(label: 'PDF', extension: 'pdf', icon: Icons.picture_as_pdf_rounded, color: Color(0xFFE53935)),
      ConversionFormat(label: 'SVG', extension: 'svg', icon: Icons.auto_awesome_rounded, color: Color(0xFFAD1457)),
    ],
  ),
  FileCategory(
    name: 'Audio',
    icon: Icons.audiotrack_rounded,
    color: const Color(0xFF9C27B0),
    inputExtensions: const ['mp3', 'wav', 'flac', 'aac', 'ogg', 'm4a', 'wma'],
    outputFormats: const [
      ConversionFormat(label: 'MP3', extension: 'mp3', icon: Icons.music_note_rounded, color: Color(0xFFE53935)),
      ConversionFormat(label: 'WAV', extension: 'wav', icon: Icons.graphic_eq_rounded, color: Color(0xFF1565C0)),
      ConversionFormat(label: 'FLAC', extension: 'flac', icon: Icons.high_quality_rounded, color: Color(0xFF2E7D32)),
      ConversionFormat(label: 'AAC', extension: 'aac', icon: Icons.music_note_rounded, color: Color(0xFFE65100)),
      ConversionFormat(label: 'OGG', extension: 'ogg', icon: Icons.music_note_rounded, color: Color(0xFF6A1B9A)),
      ConversionFormat(label: 'M4A', extension: 'm4a', icon: Icons.music_note_rounded, color: Color(0xFF00838F)),
    ],
  ),
  FileCategory(
    name: 'Vidéo',
    icon: Icons.videocam_rounded,
    color: const Color(0xFFFF5722),
    inputExtensions: const ['mp4', 'avi', 'mov', 'mkv', 'wmv', 'flv', 'webm', 'm4v'],
    outputFormats: const [
      ConversionFormat(label: 'MP4', extension: 'mp4', icon: Icons.videocam_rounded, color: Color(0xFFE53935)),
      ConversionFormat(label: 'AVI', extension: 'avi', icon: Icons.videocam_rounded, color: Color(0xFF1565C0)),
      ConversionFormat(label: 'MOV', extension: 'mov', icon: Icons.videocam_rounded, color: Color(0xFF2E7D32)),
      ConversionFormat(label: 'MKV', extension: 'mkv', icon: Icons.videocam_rounded, color: Color(0xFF6A1B9A)),
      ConversionFormat(label: 'WebM', extension: 'webm', icon: Icons.videocam_rounded, color: Color(0xFF00838F)),
      ConversionFormat(label: 'GIF', extension: 'gif', icon: Icons.gif_rounded, color: Color(0xFFAD1457)),
      ConversionFormat(label: 'MP3', extension: 'mp3', icon: Icons.music_note_rounded, color: Color(0xFFE65100)),
    ],
  ),
  FileCategory(
    name: 'Tableur',
    icon: Icons.table_chart_rounded,
    color: const Color(0xFF4CAF50),
    inputExtensions: const ['xlsx', 'xls', 'csv', 'ods'],
    outputFormats: const [
      ConversionFormat(label: 'Excel', extension: 'xlsx', icon: Icons.table_chart_rounded, color: Color(0xFF2E7D32)),
      ConversionFormat(label: 'CSV', extension: 'csv', icon: Icons.grid_on_rounded, color: Color(0xFF1565C0)),
      ConversionFormat(label: 'PDF', extension: 'pdf', icon: Icons.picture_as_pdf_rounded, color: Color(0xFFE53935)),
      ConversionFormat(label: 'ODS', extension: 'ods', icon: Icons.table_chart_rounded, color: Color(0xFF00838F)),
      ConversionFormat(label: 'HTML', extension: 'html', icon: Icons.code_rounded, color: Color(0xFF6A1B9A)),
    ],
  ),
];

FileCategory? getCategoryForFile(String extension) {
  final ext = extension.toLowerCase().replaceAll('.', '');
  for (final cat in fileCategories) {
    if (cat.inputExtensions.contains(ext)) return cat;
  }
  return null;
}
