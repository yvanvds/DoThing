import 'dart:convert';
import 'package:flutter_smartschool/flutter_smartschool.dart';
import 'package:logging/logging.dart';

final _logger = Logger('smartschool_mcp.tools');

/// Provides tools for querying SmartSchool data via MCP
class SmartschoolTools {
  final SmartschoolClient _client;

  SmartschoolTools(this._client);

  /// Get list of available tools
  List<Map<String, dynamic>> getAvailableTools() {
    return [
      {
        'name': 'get_messages_headers',
        'description':
            'Get the list of message headers (subjects, senders, dates) from inbox',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'limit': {
              'type': 'integer',
              'description':
                  'Maximum number of messages to return (default: 50)',
              'default': 50,
            },
          },
          'required': [],
        },
      },
      {
        'name': 'get_message_by_id',
        'description': 'Get the full content of a specific message by its ID',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'message_id': {
              'type': 'integer',
              'description': 'The ID of the message to retrieve',
            },
          },
          'required': ['message_id'],
        },
      },
      {
        'name': 'get_intradesk_root',
        'description':
            'Get root folders and files from Intradesk (shared document repository)',
        'inputSchema': {'type': 'object', 'properties': {}, 'required': []},
      },
      {
        'name': 'get_authenticated_user',
        'description': 'Get information about the authenticated user',
        'inputSchema': {'type': 'object', 'properties': {}, 'required': []},
      },
      {
        'name': 'test_connection',
        'description': 'Test if the connection to SmartSchool is working',
        'inputSchema': {'type': 'object', 'properties': {}, 'required': []},
      },
    ];
  }

  /// Call a tool by name with parameters
  Future<String> callTool(String toolName, Map<String, dynamic> params) async {
    _logger.info('Calling tool: $toolName with params: $params');

    switch (toolName) {
      case 'get_messages_headers':
        return _getMessagesHeaders(params);

      case 'get_message_by_id':
        return _getMessageById(params);

      case 'get_intradesk_root':
        return _getIntradeskRoot(params);

      case 'get_authenticated_user':
        return _getAuthenticatedUser(params);

      case 'test_connection':
        return _testConnection(params);

      default:
        throw Exception('Unknown tool: $toolName');
    }
  }

  Future<String> _testConnection(Map<String, dynamic> params) async {
    try {
      // Try to access authenticated user to verify authentication
      await _client.ensureAuthenticated();
      return jsonEncode({
        'status': 'connected',
        'authenticated': true,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return jsonEncode({
        'status': 'error',
        'authenticated': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<String> _getAuthenticatedUser(Map<String, dynamic> params) async {
    try {
      final user = await _client.authenticatedUser;
      return jsonEncode({'authenticated': true, 'user': user});
    } catch (e) {
      return jsonEncode({'authenticated': false, 'error': e.toString()});
    }
  }

  Future<String> _getMessagesHeaders(Map<String, dynamic> params) async {
    try {
      final limit = params['limit'] as int? ?? 50;

      final messagesService = MessagesService(_client);
      final headers = await messagesService.getHeaders();

      // Limit results
      final limitedHeaders = headers.take(limit).toList();

      final result = limitedHeaders.map((msg) {
        return {
          'id': msg.id,
          'sender': msg.sender,
          'from_image': msg.fromImage,
          'subject': msg.subject,
          'date': msg.date.toIso8601String(),
          'status': msg.status,
          'attachment': msg.attachment,
          'unread': msg.unread,
          'deleted': msg.deleted,
          'allow_reply': msg.allowReply,
        };
      }).toList();

      return jsonEncode({
        'total': headers.length,
        'returned': result.length,
        'messages': result,
      });
    } catch (e, st) {
      _logger.warning('Error getting messages headers', e, st);
      return jsonEncode({'error': e.toString(), 'details': st.toString()});
    }
  }

  Future<String> _getMessageById(Map<String, dynamic> params) async {
    try {
      final messageIdParam = params['message_id'];
      if (messageIdParam == null) {
        return jsonEncode({'error': 'message_id is required'});
      }

      // Convert to int if it's a string
      final messageId = messageIdParam is int
          ? messageIdParam
          : int.tryParse(messageIdParam.toString());

      if (messageId == null) {
        return jsonEncode({'error': 'message_id must be an integer'});
      }

      final messagesService = MessagesService(_client);
      final message = await messagesService.getMessage(messageId);

      if (message == null) {
        return jsonEncode({
          'error': 'Message not found',
          'message_id': messageId,
        });
      }

      // Fetch attachments separately
      final attachmentsList = <Map<String, dynamic>>[];
      if (message.attachment > 0) {
        try {
          final attachments = await messagesService.getAttachments(messageId);
          attachmentsList.addAll(
            attachments.map((a) {
              return {
                'file_id': a.fileId,
                'name': a.name,
                'mime': a.mime,
                'size': a.size,
                'icon': a.icon,
                'wopi_allowed': a.wopiAllowed,
                'order': a.order,
              };
            }),
          );
        } catch (e) {
          _logger.warning(
            'Error getting attachments for message $messageId',
            e,
          );
        }
      }

      return jsonEncode({
        'id': message.id,
        'sender': message.sender,
        'sender_picture': message.senderPicture,
        'to': message.to,
        'receivers': message.receivers,
        'cc_receivers': message.ccReceivers,
        'bcc_receivers': message.bccReceivers,
        'date': message.date.toIso8601String(),
        'send_date': message.sendDate?.toIso8601String(),
        'subject': message.subject,
        'body': message.body,
        'status': message.status,
        'unread': message.unread,
        'can_reply': message.canReply,
        'has_reply': message.hasReply,
        'has_forward': message.hasForward,
        'from_team': message.fromTeam,
        'attachment_count': message.attachment,
        'total_other_to_receivers': message.totalNrOtherToReceivers,
        'total_other_cc_receivers': message.totalNrOtherCcReceivers,
        'total_other_bcc_receivers': message.totalNrOtherBccReceivers,
        'colored_flag': message.coloredFlag,
        'attachments': attachmentsList,
      });
    } catch (e, st) {
      _logger.warning('Error getting message by ID', e, st);
      return jsonEncode({'error': e.toString(), 'details': st.toString()});
    }
  }

  Future<String> _getIntradeskRoot(Map<String, dynamic> params) async {
    try {
      final intradeskService = IntradeskService(_client);
      final listing = await intradeskService.getRootListing();

      final foldersData = listing.folders.map((f) {
        return {
          'id': f.id,
          'name': f.name,
          'color': f.color,
          'state': f.state,
          'visible': f.visible,
          'confidential': f.confidential,
          'office_template_folder': f.officeTemplateFolder,
          'has_children': f.hasChildren,
          'date_created': f.dateCreated.toIso8601String(),
          'date_state_changed': f.dateStateChanged.toIso8601String(),
        };
      }).toList();

      final filesData = listing.files.map((f) {
        return {
          'id': f.id,
          'name': f.name,
          'state': f.state,
          'confidential': f.confidential,
          'owner_id': f.ownerId,
          'is_favourite': f.isFavourite,
          'date_created': f.dateCreated.toIso8601String(),
          'date_state_changed': f.dateStateChanged.toIso8601String(),
          'date_changed': f.dateChanged.toIso8601String(),
          'current_revision': f.currentRevision == null
              ? null
              : {
                  'id': f.currentRevision!.id,
                  'file_size': f.currentRevision!.fileSize,
                  'label': f.currentRevision!.label,
                  'date_created': f.currentRevision!.dateCreated
                      .toIso8601String(),
                  'owner': f.currentRevision!.owner.name,
                },
        };
      }).toList();

      return jsonEncode({
        'folders': foldersData,
        'files': filesData,
        'folder_count': listing.folders.length,
        'file_count': listing.files.length,
      });
    } catch (e, st) {
      _logger.warning('Error getting intradesk root', e, st);
      return jsonEncode({'error': e.toString(), 'details': st.toString()});
    }
  }
}
