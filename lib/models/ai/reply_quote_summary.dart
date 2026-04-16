class ReplyQuoteSummary {
  const ReplyQuoteSummary({
    required this.summaryLines,
    this.topic = '',
    this.decisionOrReply = '',
    this.actionItems = const <String>[],
    this.keyPeople = const <String>[],
    this.keySystems = const <String>[],
    this.carryOverContext = '',
    this.links = const <Map<String, String>>[],
    this.images = const <Map<String, String>>[],
  });

  final List<String> summaryLines;
  final String topic;
  final String decisionOrReply;
  final List<String> actionItems;
  final List<String> keyPeople;
  final List<String> keySystems;
  final String carryOverContext;
  final List<Map<String, String>> links;
  final List<Map<String, String>> images;

  bool get isEmpty =>
      summaryLines.isEmpty &&
      topic.isEmpty &&
      decisionOrReply.isEmpty &&
      actionItems.isEmpty &&
      carryOverContext.isEmpty &&
      links.isEmpty &&
      images.isEmpty;

  List<String> get effectiveSummaryLines {
    if (summaryLines.isNotEmpty) {
      return summaryLines;
    }

    final lines = <String>[];
    if (topic.isNotEmpty) {
      lines.add('Topic: $topic');
    }
    if (decisionOrReply.isNotEmpty) {
      lines.add('Reply decision: $decisionOrReply');
    }
    if (actionItems.isNotEmpty) {
      lines.add('Pending actions: ${actionItems.join('; ')}');
    }
    if (carryOverContext.isNotEmpty) {
      lines.add('Earlier thread context: $carryOverContext');
    }
    return lines;
  }

  factory ReplyQuoteSummary.fromJson(Map<String, dynamic> json) {
    List<String> parseLines(dynamic raw) {
      if (raw is! List) {
        return const <String>[];
      }

      return raw
          .map((item) => item?.toString().trim() ?? '')
          .where((line) => line.isNotEmpty)
          .toList(growable: false);
    }

    String parseString(dynamic raw) => raw?.toString().trim() ?? '';

    List<Map<String, String>> parseResources(dynamic raw) {
      if (raw is! List) {
        return const <Map<String, String>>[];
      }

      return raw
          .whereType<Map>()
          .map((item) {
            final url = (item['url'] ?? '').toString().trim();
            final label = (item['label'] ?? '').toString().trim();
            return <String, String>{
              'url': url,
              if (label.isNotEmpty) 'label': label,
            };
          })
          .where((item) => (item['url'] ?? '').isNotEmpty)
          .toList(growable: false);
    }

    final summaryLines = parseLines(json['summary_lines']);
    final topic = parseString(json['topic']);
    final decision = parseString(json['decision_or_reply']);
    final actionItems = parseLines(json['action_items']);
    final keyPeople = parseLines(json['key_people']);
    final keySystems = parseLines(json['key_systems']);
    final carryOverContext = parseString(json['carry_over_context']);

    final fallbackSummary = <String>[
      if (summaryLines.isNotEmpty) ...summaryLines,
      if (summaryLines.isEmpty && topic.isNotEmpty) 'Topic: $topic',
      if (summaryLines.isEmpty && decision.isNotEmpty)
        'Reply decision: $decision',
      if (summaryLines.isEmpty && actionItems.isNotEmpty)
        'Pending actions: ${actionItems.join('; ')}',
      if (summaryLines.isEmpty && carryOverContext.isNotEmpty)
        'Earlier thread context: $carryOverContext',
    ];

    return ReplyQuoteSummary(
      summaryLines: fallbackSummary,
      topic: topic,
      decisionOrReply: decision,
      actionItems: actionItems,
      keyPeople: keyPeople,
      keySystems: keySystems,
      carryOverContext: carryOverContext,
      links: parseResources(json['links']),
      images: parseResources(json['images']),
    );
  }
}
