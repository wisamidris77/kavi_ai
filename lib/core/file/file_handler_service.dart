import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

class FileHandlerService {
  static const int _maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> _supportedExtensions = [
    'txt', 'md', 'json', 'xml', 'csv', 'log',
    'jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp',
    'pdf', 'doc', 'docx', 'rtf',
    'py', 'js', 'ts', 'java', 'cpp', 'c', 'cs', 'php', 'rb', 'go', 'rs', 'swift', 'kt',
    'html', 'css', 'scss', 'sass', 'less',
    'sql', 'yaml', 'yml', 'toml', 'ini', 'cfg',
  ];

  /// Pick files using file picker
  Future<List<File>> pickFiles({
    bool allowMultiple = true,
    List<String>? allowedExtensions,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: allowMultiple,
        allowedExtensions: allowedExtensions ?? _supportedExtensions,
        // type: FileType.image,
      );

      if (result != null && result.files.isNotEmpty) {
        final files = <File>[];
        for (final platformFile in result.files) {
          if (platformFile.path != null) {
            final file = File(platformFile.path!);
            if (await _validateFile(file)) {
              files.add(file);
            }
          }
        }
        return files;
      }
    } catch (e) {
      throw FileHandlerException('Failed to pick files: $e');
    }
    
    return [];
  }

  /// Validate a file for size and type
  Future<bool> _validateFile(File file) async {
    try {
      // Check if file exists
      if (!await file.exists()) {
        return false;
      }

      // Check file size
      final stat = await file.stat();
      if (stat.size > _maxFileSize) {
        throw FileHandlerException(
          'File ${file.path} is too large. Maximum size is ${_maxFileSize ~/ (1024 * 1024)}MB'
        );
      }

      // Check file extension
      final extension = path.extension(file.path).toLowerCase().replaceAll('.', '');
      if (!_supportedExtensions.contains(extension)) {
        throw FileHandlerException(
          'File type .$extension is not supported'
        );
      }

      return true;
    } catch (e) {
      if (e is FileHandlerException) {
        rethrow;
      }
      return false;
    }
  }

  /// Get file info
  FileInfo getFileInfo(File file) {
    final name = path.basename(file.path);
    final extension = path.extension(file.path).toLowerCase().replaceAll('.', '');
    final size = file.lengthSync();
    
    return FileInfo(
      name: name,
      path: file.path,
      extension: extension,
      size: size,
      type: _getFileType(extension),
    );
  }

  /// Get file type category
  FileType _getFileType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
        return FileType.image;
      case 'pdf':
      case 'doc':
      case 'docx':
      case 'rtf':
        return FileType.document;
      case 'py':
      case 'js':
      case 'ts':
      case 'java':
      case 'cpp':
      case 'c':
      case 'cs':
      case 'php':
      case 'rb':
      case 'go':
      case 'rs':
      case 'swift':
      case 'kt':
      case 'html':
      case 'css':
      case 'scss':
      case 'sass':
      case 'less':
        return FileType.code;
      case 'txt':
      case 'md':
      case 'json':
      case 'xml':
      case 'csv':
      case 'log':
      case 'sql':
      case 'yaml':
      case 'yml':
      case 'toml':
      case 'ini':
      case 'cfg':
        return FileType.text;
      default:
        return FileType.other;
    }
  }

  /// Read file content as text
  Future<String> readFileAsText(File file) async {
    try {
      return await file.readAsString();
    } catch (e) {
      throw FileHandlerException('Failed to read file: $e');
    }
  }

  /// Read file content as bytes
  Future<Uint8List> readFileAsBytes(File file) async {
    try {
      return await file.readAsBytes();
    } catch (e) {
      throw FileHandlerException('Failed to read file: $e');
    }
  }

  /// Format file size for display
  String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}

class FileInfo {
  final String name;
  final String path;
  final String extension;
  final int size;
  final FileType type;

  FileInfo({
    required this.name,
    required this.path,
    required this.extension,
    required this.size,
    required this.type,
  });

  String get formattedSize => FileHandlerService().formatFileSize(size);
}

enum FileType {
  image,
  document,
  code,
  text,
  other,
}

class FileHandlerException implements Exception {
  final String message;
  
  FileHandlerException(this.message);
  
  @override
  String toString() => message;
}