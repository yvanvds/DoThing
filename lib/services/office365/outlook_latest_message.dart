import 'outlook_body_content.dart';
import 'outlook_sender_info.dart';

class OutlookLatestMessage {
  const OutlookLatestMessage({
    required this.id,
    required this.subject,
    required this.sender,
    required this.receivedAt,
    required this.body,
    required this.isRead,
    required this.hasAttachments,
  });

  final String id;
  final String subject;
  final OutlookSenderInfo sender;
  final DateTime receivedAt;
  final OutlookBodyContent body;
  final bool isRead;
  final bool hasAttachments;

  OutlookLatestMessage copyWith({
    String? subject,
    OutlookSenderInfo? sender,
    DateTime? receivedAt,
    OutlookBodyContent? body,
    bool? isRead,
    bool? hasAttachments,
  }) {
    return OutlookLatestMessage(
      id: id,
      subject: subject ?? this.subject,
      sender: sender ?? this.sender,
      receivedAt: receivedAt ?? this.receivedAt,
      body: body ?? this.body,
      isRead: isRead ?? this.isRead,
      hasAttachments: hasAttachments ?? this.hasAttachments,
    );
  }
}
