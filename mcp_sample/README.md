# Desktop File System MCP Server

A secure, read-only MCP server that provides controlled access to files and folders on your desktop directory.

## Features

- **Secure Access**: Limited to desktop directory only - cannot access files outside of desktop
- **Read-Only Operations**: No write, delete, or modify operations allowed
- **File Size Limits**: Text files limited to 1MB for safety
- **Three Main Tools**:
  1. `listFiles` - List contents of directories
  2. `readFile` - Read text file contents
  3. `getFileInfo` - Get detailed file/directory information

## Usage

### 1. Running the Server

```bash
# From the project root
dart run mcp_sample/desktop_fs_server.dart
```

### 2. Configuring in Kavi AI

Add this server configuration in MCP Settings:

- **Name**: Desktop File System
- **Command**: `dart`
- **Arguments**: `run mcp_sample/desktop_fs_server.dart`
- **Enabled**: ✓

### 3. Available Tools

#### listFiles
Lists files and directories in a desktop directory.

**Arguments**:
- `path` (optional): Path relative to desktop (defaults to desktop root)

**Example**:
```
User: List all files on my desktop

AI: I'll list the files on your desktop for you.

TOOL_CALL:Desktop File System:listFiles
ARGUMENTS:
{}
```

#### readFile
Reads the contents of text files from the desktop.

**Arguments**:
- `path` (required): Path to file relative to desktop

**Example**:
```
User: Read the contents of notes.txt on my desktop

AI: I'll read the notes.txt file from your desktop.

TOOL_CALL:Desktop File System:readFile
ARGUMENTS:
{"path": "notes.txt"}
```

#### getFileInfo
Gets detailed information about a file or directory.

**Arguments**:
- `path` (required): Path relative to desktop

**Example**:
```
User: Get info about the Documents folder on my desktop

AI: I'll get information about the Documents folder.

TOOL_CALL:Desktop File System:getFileInfo
ARGUMENTS:
{"path": "Documents"}
```

## Security Features

1. **Path Validation**: All paths are validated to ensure they remain within the desktop directory
2. **Size Limits**: Files larger than 1MB cannot be read
3. **No Write Access**: Server is read-only by design
4. **Error Handling**: Graceful error messages for invalid operations

## Example Conversations

### Browsing Desktop
```
User: What files are on my desktop?

AI: I'll list the files on your desktop for you.
[Tool executes and shows file list]

AI: Based on the tool result, here are the files and folders on your desktop:
- Documents (folder)
- Pictures (folder) 
- notes.txt (file, 2KB)
- project_plan.pdf (file, 156KB)
...
```

### Reading a File
```
User: Can you read my todo list from the desktop?

AI: I'll look for and read your todo list file.
[Tool executes]

AI: I found and read your todo.txt file. Here's your todo list:
1. Complete project proposal
2. Review code changes
3. Schedule team meeting
...
```

## Troubleshooting

1. **"Access denied" errors**: Ensure you're only accessing files within the desktop directory
2. **"File too large" errors**: The server limits file reading to 1MB for safety
3. **Server won't start**: Check that Dart is installed and the path is correct
4. **No tools appearing**: Ensure the server is enabled in MCP settings

## Development

The server implementation is in `desktop_fs_server.dart`. Key features:

- Uses the official `dart_mcp` package
- Implements proper path sandboxing
- Provides detailed JSON responses
- Includes comprehensive error handling

## Platform Support

- ✅ Windows (uses `%USERPROFILE%\Desktop`)
- ✅ macOS (uses `~/Desktop`)
- ✅ Linux (uses `~/Desktop`)
- ❌ Mobile platforms (not supported) 