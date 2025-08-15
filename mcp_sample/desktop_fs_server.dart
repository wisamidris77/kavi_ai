import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_mcp/server.dart';
import 'package:dart_mcp/stdio.dart';
import 'package:path/path.dart' as p;

void main() {
  DesktopFileSystemServer.fromStreamChannel(
    stdioChannel(input: stdin, output: stdout),
  );
}

/// A read-only file system server limited to the desktop directory
final class DesktopFileSystemServer extends MCPServer
    with LoggingSupport, ToolsSupport {
  DesktopFileSystemServer.fromStreamChannel(super.channel)
      : super.fromStreamChannel(
          implementation: Implementation(
            name: 'Desktop File System',
            version: '1.0.0',
          ),
        );

  late final String desktopPath;

  @override
  FutureOr<InitializeResult> initialize(InitializeRequest request) {
    // Get desktop path
    if (Platform.isWindows) {
      desktopPath = p.join(Platform.environment['USERPROFILE']!, 'Desktop');
    } else if (Platform.isMacOS || Platform.isLinux) {
      desktopPath = p.join(Platform.environment['HOME']!, 'Desktop');
    } else {
      throw UnsupportedError('Unsupported platform');
    }

    // Register tools
    registerTool(listFilesTool, _listFiles);
    registerTool(readFileTool, _readFile);
    registerTool(getFileInfoTool, _getFileInfo);
    
    // Log initialization info to stderr for debugging
    stderr.writeln('Desktop File System Server initialized');
    stderr.writeln('Desktop path: $desktopPath');
    
    return super.initialize(request);
  }

  /// Validates that a path is within the desktop directory
  bool _isPathAllowed(String path) {
    try {
      final resolvedPath = p.normalize(p.absolute(path));
      final resolvedDesktop = p.normalize(p.absolute(desktopPath));
      return p.isWithin(resolvedDesktop, resolvedPath) || resolvedPath == resolvedDesktop;
    } catch (e) {
      return false;
    }
  }

  /// Converts a path to be relative to desktop if it's not already
  String _resolvePath(String path) {
    if (p.isAbsolute(path)) {
      return path;
    }
    return p.join(desktopPath, path);
  }

  Future<CallToolResult> _listFiles(CallToolRequest request) async {
    final path = (request.arguments?['path'] as String?) ?? '';
    final resolvedPath = _resolvePath(path);

    if (!_isPathAllowed(resolvedPath)) {
      return CallToolResult(
        content: [
          TextContent(
            text: 'Access denied: Path must be within desktop directory',
          ),
        ],
        isError: true,
      );
    }

    final directory = Directory(resolvedPath);
    if (!await directory.exists()) {
      return CallToolResult(
        content: [
          TextContent(
            text: 'Directory does not exist: ${p.relative(resolvedPath, from: desktopPath)}',
          ),
        ],
        isError: true,
      );
    }

    try {
      final entities = await directory.list().toList();
      final items = <Map<String, dynamic>>[];
      
      for (final entity in entities) {
        final stat = await entity.stat();
        items.add({
          'name': p.basename(entity.path),
          'path': p.relative(entity.path, from: desktopPath),
          'type': entity is Directory ? 'directory' : 'file',
          'size': stat.size,
          'modified': stat.modified.toIso8601String(),
        });
      }

      // Sort: directories first, then by name
      items.sort((a, b) {
        if (a['type'] != b['type']) {
          return a['type'] == 'directory' ? -1 : 1;
        }
        return (a['name'] as String).compareTo(b['name'] as String);
      });

      return CallToolResult(
        content: [
          TextContent(
            text: JsonEncoder.withIndent('  ').convert({
              'path': p.relative(resolvedPath, from: desktopPath),
              'items': items,
              'count': items.length,
            }),
          ),
        ],
      );
    } catch (e) {
      return CallToolResult(
        content: [
          TextContent(text: 'Error listing directory: $e'),
        ],
        isError: true,
      );
    }
  }

  Future<CallToolResult> _readFile(CallToolRequest request) async {
    final path = request.arguments!['path'] as String;
    final resolvedPath = _resolvePath(path);

    if (!_isPathAllowed(resolvedPath)) {
      return CallToolResult(
        content: [
          TextContent(
            text: 'Access denied: Path must be within desktop directory',
          ),
        ],
        isError: true,
      );
    }

    final file = File(resolvedPath);
    if (!await file.exists()) {
      return CallToolResult(
        content: [
          TextContent(
            text: 'File does not exist: ${p.relative(resolvedPath, from: desktopPath)}',
          ),
        ],
        isError: true,
      );
    }

    try {
      final stat = await file.stat();
      
      // Limit file size to 1MB for safety
      if (stat.size > 1024 * 1024) {
        return CallToolResult(
          content: [
            TextContent(
              text: 'File too large (${stat.size} bytes). Maximum allowed: 1MB',
            ),
          ],
          isError: true,
        );
      }

      // Try to read as text
      try {
        final content = await file.readAsString();
        return CallToolResult(
          content: [
            TextContent(
              text: JsonEncoder.withIndent('  ').convert({
                'path': p.relative(resolvedPath, from: desktopPath),
                'size': stat.size,
                'modified': stat.modified.toIso8601String(),
                'content': content,
              }),
            ),
          ],
        );
      } catch (e) {
        // If not text, return file info only
        return CallToolResult(
          content: [
            TextContent(
              text: JsonEncoder.withIndent('  ').convert({
                'path': p.relative(resolvedPath, from: desktopPath),
                'size': stat.size,
                'modified': stat.modified.toIso8601String(),
                'error': 'File is not a text file or uses unsupported encoding',
              }),
            ),
          ],
        );
      }
    } catch (e) {
      return CallToolResult(
        content: [
          TextContent(text: 'Error reading file: $e'),
        ],
        isError: true,
      );
    }
  }

  Future<CallToolResult> _getFileInfo(CallToolRequest request) async {
    final path = request.arguments!['path'] as String;
    final resolvedPath = _resolvePath(path);

    if (!_isPathAllowed(resolvedPath)) {
      return CallToolResult(
        content: [
          TextContent(
            text: 'Access denied: Path must be within desktop directory',
          ),
        ],
        isError: true,
      );
    }

    final entity = FileSystemEntity.typeSync(resolvedPath) == FileSystemEntityType.directory
        ? Directory(resolvedPath)
        : File(resolvedPath);

    if (!await entity.exists()) {
      return CallToolResult(
        content: [
          TextContent(
            text: 'Path does not exist: ${p.relative(resolvedPath, from: desktopPath)}',
          ),
        ],
        isError: true,
      );
    }

    try {
      final stat = await entity.stat();
      final info = {
        'path': p.relative(resolvedPath, from: desktopPath),
        'name': p.basename(resolvedPath),
        'type': entity is Directory ? 'directory' : 'file',
        'size': stat.size,
        'modified': stat.modified.toIso8601String(),
        'accessed': stat.accessed.toIso8601String(),
      };

      if (entity is Directory) {
        final items = await entity.list().length;
        info['itemCount'] = items;
      } else if (entity is File) {
        info['extension'] = p.extension(resolvedPath);
      }

      return CallToolResult(
        content: [
          TextContent(
            text: JsonEncoder.withIndent('  ').convert(info),
          ),
        ],
      );
    } catch (e) {
      return CallToolResult(
        content: [
          TextContent(text: 'Error getting file info: $e'),
        ],
        isError: true,
      );
    }
  }

  final listFilesTool = Tool(
    name: 'listFiles',
    description: 'Lists files and directories in a desktop directory. '
        'Returns name, type, size, and modification date for each item.',
    inputSchema: Schema.object(
      properties: {
        'path': Schema.string(
          description: 'The path relative to desktop directory (optional, defaults to desktop root)',
        ),
      },
      required: [],
    ),
  );

  final readFileTool = Tool(
    name: 'readFile',
    description: 'Reads the contents of a text file from the desktop. '
        'Limited to files under 1MB in size.',
    inputSchema: Schema.object(
      properties: {
        'path': Schema.string(
          description: 'The path to the file relative to desktop directory',
        ),
      },
      required: ['path'],
    ),
  );

  final getFileInfoTool = Tool(
    name: 'getFileInfo',
    description: 'Gets detailed information about a file or directory on the desktop.',
    inputSchema: Schema.object(
      properties: {
        'path': Schema.string(
          description: 'The path to the file or directory relative to desktop directory',
        ),
      },
      required: ['path'],
    ),
  );
} 