# SmartSchool Researcher MCP Server

A Dart-based Model Context Protocol (MCP) server that enables direct querying of SmartSchool data using the `flutter_smartschool` library.

## Overview

This MCP server allows you to:
- Query your SmartSchool inbox and read full message contents
- Access the Intradesk shared document repository (folders and files)
- Verify authentication with SmartSchool
- View actual API responses for debugging SmartSchool integration issues

## Prerequisites

- Dart SDK 3.10.1 or later
- A `credentials.yml` file in the project root with SmartSchool login credentials
- Access to the `flutter_smartschool` library (via path dependency)

## Setup

### 1. Credentials File

Create a `credentials.yml` in the project root:

```yaml
username: your_username
password: your_password
main_url: school_code.smartschool.be
mfa: YOUR_2FA_TOKEN  # Optional, only if you have 2FA enabled
```

### 2. Install Dependencies

```bash
cd smartschool-researcher-mcp
dart pub get
```

## Running the Server

### Direct Execution

```bash
dart bin/server.dart
```

The server reads JSON-RPC messages from stdin and writes responses to stdout.

### Integration with Copilot Chat

To integrate with Copilot Chat, configure the server in VS Code's settings.

## Available Tools

### 1. `test_connection`
Test if the connection to SmartSchool is working.

**No parameters required.**

**Response:**
```json
{
  "status": "connected",
  "authenticated": true,
  "timestamp": "2024-04-11T10:30:00Z"
}
```

### 2. `get_authenticated_user`
Get information about the currently authenticated user.

**No parameters required.**

**Response:**
```json
{
  "authenticated": true,
  "user": {
    "username": "john.doe",
    // ... other user properties from SmartSchool
  }
}
```

### 3. `get_messages_headers`
Get a list of message headers from your inbox.

**Parameters:**
- `limit` (integer, optional): Maximum number of messages to return (default: 50)

**Response:**
```json
{
  "total": 100,
  "returned": 50,
  "messages": [
    {
      "id": 12345,
      "sender": "Jane Smith",
      "from_image": "https://...",
      "subject": "Project Update",
      "date": "2024-04-11T09:00:00Z",
      "status": 1,
      "attachment": 0,
      "unread": true,
      "deleted": false,
      "allow_reply": true,
      "allow_reply_enabled": true,
      "has_reply": false,
      "has_forward": false,
      "real_box": "inbox",
      "send_date": "2024-04-11T08:55:00Z",
      "colored_flag": 0
    }
  ]
}
```

### 4. `get_message_by_id`
Get the full content of a specific message.

**Parameters:**
- `message_id` (integer, required): The ID of the message to retrieve

**Response:**
```json
{
  "id": 12345,
  "sender": "Jane Smith",
  "sender_picture": "https://...",
  "to": null,
  "receivers": ["john.doe"],
  "cc_receivers": [],
  "bcc_receivers": [],
  "date": "2024-04-11T09:00:00Z",
  "send_date": "2024-04-11T08:55:00Z",
  "subject": "Project Update",
  "body": "Here is the full message content...",
  "status": 1,
  "unread": true,
  "can_reply": true,
  "has_reply": false,
  "has_forward": false,
  "from_team": 0,
  "attachment_count": 1,
  "total_other_to_receivers": 0,
  "total_other_cc_receivers": 0,
  "total_other_bcc_receivers": 0,
  "colored_flag": 0,
  "attachments": [
    {
      "file_id": 1001,
      "name": "document.pdf",
      "mime": "application/pdf",
      "size": "2.5 MB",
      "icon": "pdf",
      "wopi_allowed": false,
      "order": 0
    }
  ]
}
```

### 5. `get_intradesk_root`
Get root folders and files from Intradesk (shared document repository).

**No parameters required.**

**Response:**
```json
{
  "folders": [
    {
      "id": "folder-uuid-1",
      "name": "Project Documents",
      "color": "blue",
      "state": "active",
      "visible": true,
      "confidential": false,
      "office_template_folder": false,
      "has_children": true,
      "date_created": "2024-01-15T10:00:00Z",
      "date_state_changed": "2024-04-01T14:30:00Z"
    }
  ],
  "files": [
    {
      "id": "file-uuid-1",
      "name": "readme.txt",
      "extension": "txt",
      "state": "active",
      "visible": true,
      "confidential": false,
      "date_created": "2024-02-20T09:00:00Z",
      "date_state_changed": "2024-03-15T11:45:00Z"
    }
  ],
  "folder_count": 3,
  "file_count": 5
}
```

## Architecture

```
smartschool-researcher-mcp/
├── bin/
│   └── server.dart           # Entry point
├── lib/
│   ├── mcp_server.dart       # MCP protocol handler
│   └── smartschool_tools.dart # Tool implementations
├── pubspec.yaml              # Dart dependencies
└── README.md                 # This file
```

### Key Components

- **mcp_server.dart**: Implements the MCP JSON-RPC protocol, handles incoming requests, manages SmartSchool client lifecycle, and reads credentials
- **smartschool_tools.dart**: Provides individual tools that query SmartSchool APIs
- **SmartschoolClient**: From `flutter_smartschool` library, handles authentication and API calls

## Credentials Management

The server automatically loads credentials from `../credentials.yml` relative to the working directory. The YAML file should contain:

```yaml
username: your_smartschool_username
password: your_smartschool_password
main_url: your_school.smartschool.be
mfa: TOTP_SECRET_IF_ENABLED  # Optional
```

Credentials are loaded once at startup and used for the entire session.

## Error Handling

The server handles errors gracefully:

1. **Connection Errors**: Returns error responses with descriptive messages
2. **Authentication Failures**: Logs to stderr and returns auth error responses
3. **Tool Errors**: Returns tool-specific error information
4. **Missing Credentials**: Logs detailed error and exits at startup

All errors follow the JSON-RPC 2.0 error format:

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "error": {
    "code": -32603,
    "message": "Internal error",
    "data": {
      "error": "Detailed error message"
    }
  }
}
```

## Debugging

The server logs to stderr for debugging purposes:

```bash
dart bin/server.dart 2> server.log
```

Log entries will show:
- Initialization status
- Tools being called
- Any errors encountered with full stack traces

## Tips for Debugging SmartSchool Issues

1. **Use `test_connection`** to verify authentication is working
2. **Use `get_messages_headers`** to see if the messages API is functional
3. **Use `get_message_by_id`** to inspect full message data and identify parsing issues
4. **Use `get_intradesk_root`** to verify file repository access
5. **Check server logs** (stderr) for underlying HTTP errors or parsing problems
6. **Inspect raw API responses** in the returned JSON to understand SmartSchool's format

## License

Unofficial implementation for research and debugging purposes.

