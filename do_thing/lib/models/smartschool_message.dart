/// Box type for message listing.
enum SmartschoolBoxType {
  inbox('INBOX'),
  draft('DRAFT'),
  scheduled('SCHEDULED'),
  sent('SENT'),
  trash('TRASH');

  const SmartschoolBoxType(this.value);
  final String value;
}

/// Message label / flag colour.
enum SmartschoolMessageLabel {
  noFlag('NO_FLAG'),
  greenFlag('GREEN_FLAG'),
  yellowFlag('YELLOW_FLAG'),
  redFlag('RED_FLAG'),
  blueFlag('BLUE_FLAG');

  const SmartschoolMessageLabel(this.value);
  final String value;
}

/// A single message header from the inbox / sent / etc. listing.
///
/// All fields map directly to the Python `ShortMessage` attributes.
class SmartschoolMessageHeader {
  const SmartschoolMessageHeader({
    required this.id,
    required this.from,
    required this.fromImage,
    required this.subject,
    required this.date,
    required this.status,
    required this.unread,
    required this.hasAttachment,
    required this.label,
    required this.deleted,
    required this.allowReply,
    required this.allowReplyEnabled,
    required this.hasReply,
    required this.hasForward,
    required this.realBox,
    this.sendDate,
  });

  final int id;

  /// Display name of the sender.
  final String from;

  /// URL to the sender's avatar image.
  final String fromImage;

  final String subject;

  /// ISO-8601 string of the message date.
  final String date;

  /// Smartschool status integer (0 = unread visually, 1 = read visually).
  /// Note: the [unread] bool is **inverted** vs. what Smartschool reports.
  final int status;

  /// True when the message has NOT been read yet.
  /// Smartschool returns `unread=True` for read messages, so this is inverted.
  final bool unread;

  final bool hasAttachment;
  final bool label;
  final bool deleted;
  final bool allowReply;
  final bool allowReplyEnabled;
  final bool hasReply;
  final bool hasForward;

  /// The actual mailbox name, e.g. `'inbox'`.
  final String realBox;

  /// ISO-8601 string of the scheduled send date, or null.
  final String? sendDate;

  factory SmartschoolMessageHeader.fromJson(Map<String, dynamic> json) {
    return SmartschoolMessageHeader(
      id: json['id'] as int,
      from: json['from'] as String? ?? '',
      fromImage: json['from_image'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      date: json['date'] as String? ?? '',
      status: json['status'] as int? ?? 0,
      unread: !(json['unread'] as bool? ?? true),
      hasAttachment: (json['attachment'] as int? ?? 0) > 0,
      label: json['label'] as bool? ?? false,
      deleted: json['deleted'] as bool? ?? false,
      allowReply: json['allowreply'] as bool? ?? false,
      allowReplyEnabled: json['allowreplyenabled'] as bool? ?? false,
      hasReply: json['hasreply'] as bool? ?? false,
      hasForward: json['has_forward'] as bool? ?? false,
      realBox: json['real_box'] as String? ?? 'inbox',
      sendDate: json['send_date'] as String?,
    );
  }
}

/// Full message detail (body, receivers, etc.).
///
/// All fields map directly to the Python `FullMessage` attributes.
class SmartschoolMessageDetail {
  const SmartschoolMessageDetail({
    required this.id,
    required this.from,
    required this.subject,
    required this.body,
    required this.date,
    this.to,
    this.status,
    this.attachment,
    this.unread,
    this.label,
    this.receivers,
    this.ccReceivers,
    this.bccReceivers,
    this.senderPicture,
    this.fromTeam,
    this.totalNrOtherToReceivers,
    this.totalNrOtherCcReceivers,
    this.totalNrOtherBccReceivers,
    this.canReply,
    this.hasReply,
    this.hasForward,
    this.sendDate,
  });

  final int id;
  final String from;
  final String subject;
  final String body;

  /// ISO-8601 string of the message date.
  final String date;

  /// Recipient email (to field), if applicable.
  final String? to;

  /// Smartschool status integer.
  final int? status;

  /// Attachment count.
  final int? attachment;

  /// True when the message has NOT been read yet.
  /// Note: Smartschool returns `unread=True` for read messages, so invert if needed.
  final bool? unread;

  /// Message label / flag state.
  final bool? label;

  /// Primary list of receivers.
  final dynamic receivers;

  /// List of CC receivers (as strings).
  final dynamic ccReceivers;

  /// List of BCC receivers (as strings).
  final dynamic bccReceivers;

  /// Sender's avatar image URL.
  final String? senderPicture;

  /// Team ID if this message is from a team.
  final int? fromTeam;

  /// Count of other recipients (not in main receivers list).
  final int? totalNrOtherToReceivers;

  /// Count of other CC recipients.
  final int? totalNrOtherCcReceivers;

  /// Count of other BCC recipients.
  final int? totalNrOtherBccReceivers;

  /// Whether the user can reply to this message.
  final bool? canReply;

  /// Whether this message has replies.
  final bool? hasReply;

  /// Whether this message has been forwarded.
  final bool? hasForward;

  /// ISO-8601 string of the scheduled send date, or null.
  final String? sendDate;

  factory SmartschoolMessageDetail.fromJson(Map<String, dynamic> json) {
    return SmartschoolMessageDetail(
      id: json['id'] as int? ?? 0,
      from: json['from'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      body: json['body'] as String? ?? '',
      date: json['date'] as String? ?? '',
      to: json['to'] as String?,
      status: json['status'] as int?,
      attachment: json['attachment'] as int?,
      unread: json['unread'] as bool?,
      label: json['label'] as bool?,
      receivers: json['receivers'],
      ccReceivers: json['ccreceivers'],
      bccReceivers: json['bccreceivers'],
      senderPicture: json['sender_picture'] as String?,
      fromTeam: json['from_team'] as int?,
      totalNrOtherToReceivers: json['total_nr_other_to_reciviers'] as int?,
      totalNrOtherCcReceivers: json['total_nr_other_cc_receivers'] as int?,
      totalNrOtherBccReceivers: json['total_nr_other_bcc_receivers'] as int?,
      canReply: json['can_reply'] as bool?,
      hasReply: json['has_reply'] as bool?,
      hasForward: json['has_forward'] as bool?,
      sendDate: json['send_date'] as String?,
    );
  }
}

/// A group of messages sharing the same normalised subject line.
///
/// Used to present a threaded / conversation view in the UI.
class SmartschoolMessageThread {
  const SmartschoolMessageThread({
    required this.threadKey,
    required this.subject,
    required this.latestDate,
    required this.messageCount,
    required this.hasUnread,
    required this.hasReply,
    required this.messages,
  });

  /// Normalised (lower-case, prefix-stripped) subject used for grouping.
  final String threadKey;

  /// Display subject taken from the most recent message.
  final String subject;

  /// ISO-8601 date of the newest message in this thread.
  final String latestDate;

  /// Total number of messages in the thread.
  final int messageCount;

  /// True when at least one message in the thread is unread.
  final bool hasUnread;

  /// True when at least one message in the thread has a reply.
  final bool hasReply;

  /// Individual message headers, newest first.
  final List<SmartschoolMessageHeader> messages;

  factory SmartschoolMessageThread.fromJson(Map<String, dynamic> json) {
    final rawMessages = json['messages'] as List<dynamic>? ?? [];
    return SmartschoolMessageThread(
      threadKey: json['thread_key'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      latestDate: json['latest_date'] as String? ?? '',
      messageCount: json['message_count'] as int? ?? 1,
      hasUnread: json['has_unread'] as bool? ?? false,
      hasReply: json['has_reply'] as bool? ?? false,
      messages: rawMessages
          .cast<Map<String, dynamic>>()
          .map(SmartschoolMessageHeader.fromJson)
          .toList(),
    );
  }
}

/// Attachment metadata + optional content.
class SmartschoolAttachment {
  const SmartschoolAttachment({
    required this.name,
    required this.size,
    this.contentBase64,
  });

  final String name;
  final int size;

  /// Base-64 encoded bytes of the file content (populated after download).
  final String? contentBase64;

  factory SmartschoolAttachment.fromJson(Map<String, dynamic> json) {
    return SmartschoolAttachment(
      name: json['name'] as String? ?? '',
      size: json['size'] as int? ?? 0,
      contentBase64: json['content_base64'] as String?,
    );
  }
}
