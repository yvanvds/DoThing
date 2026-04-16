import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/ai/ai_settings_controller.dart';
import '../../controllers/status_controller.dart';
import '../../models/ai/ai_chat_models.dart';
import '../../models/ai/ai_settings.dart';
import '../../models/ai/reply_quote_summary.dart';
import '../ai/ai_chat_transport.dart';
import '../ai/openai_chat_service.dart';

final aiReplyQuoteServiceProvider = Provider<AiReplyQuoteService>(
  AiReplyQuoteService.new,
);

class AiReplyQuoteService {
  AiReplyQuoteService(this.ref);

  final Ref ref;

  Future<ReplyQuoteSummary?> summarizeReplyQuote({
    required String from,
    required String date,
    required String subject,
    required String fallbackPlainText,
    required String originalHtml,
    String smartschoolBaseUrl = '',
    bool Function()? isCanceled,
  }) async {
    if (isCanceled?.call() ?? false) {
      return null;
    }

    final sourceText = fallbackPlainText.trim();
    if (sourceText.isEmpty) {
      return null;
    }

    final settings = await ref.read(aiSettingsProvider.future);
    if (!settings.hasApiKey) {
      return null;
    }

    final apiKey = await ref.read(aiSettingsProvider.notifier).readApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return null;
    }

    final schoolDomains = _schoolDomains(smartschoolBaseUrl);
    final links = _extractLinks(originalHtml, schoolDomains: schoolDomains);
    final images = _extractImages(originalHtml, smartschoolBaseUrl);
    final transport = ref.read(aiChatTransportProvider);

    final requestMessages = [
      AiChatMessageModel(
        id: 'sys-reply-quote',
        conversationId: 'reply-quote',
        role: AiMessageRole.system,
        content: _systemPrompt,
        createdAt: DateTime.now(),
      ),
      AiChatMessageModel(
        id: 'usr-reply-quote',
        conversationId: 'reply-quote',
        role: AiMessageRole.user,
        content: _buildUserPrompt(
          from: from,
          date: date,
          subject: subject,
          plainText: sourceText,
          links: links,
          images: images,
        ),
        createdAt: DateTime.now(),
      ),
    ];

    final modelCandidates = _modelCandidates(settings);
    for (var i = 0; i < modelCandidates.length; i++) {
      if (isCanceled?.call() ?? false) {
        return null;
      }

      final model = modelCandidates[i];
      final parsed = await _requestSummaryWithModel(
        transport: transport,
        apiKey: apiKey,
        baseUrl: settings.baseUrl,
        model: model,
        requestMessages: requestMessages,
        isCanceled: isCanceled,
      );

      if (parsed == null) {
        continue;
      }

      final filtered = _filterResources(parsed, links: links, images: images);

      if (_hasSufficientContext(filtered, sourceText)) {
        if (i > 0) {
          ref
              .read(statusProvider.notifier)
              .add(
                StatusEntryType.info,
                'Reply quote used ${_modelLabel(model)} model for better context.',
              );
        }
        return filtered;
      }
    }

    ref
        .read(statusProvider.notifier)
        .add(
          StatusEntryType.warning,
          'AI reply quote lacked context; using original quoted content.',
        );
    return null;
  }

  List<String> _modelCandidates(AiSettings settings) {
    final ordered = <String>[
      settings.cheapModel.trim(),
      settings.fastModel.trim(),
      settings.complexModel.trim(),
    ].where((m) => m.isNotEmpty).toList(growable: false);

    final unique = <String>[];
    final seen = <String>{};
    for (final model in ordered) {
      if (seen.add(model)) {
        unique.add(model);
      }
    }
    return unique;
  }

  String _modelLabel(String model) {
    final lower = model.toLowerCase();
    if (lower.contains('nano')) {
      return 'cheap';
    }
    if (lower.contains('mini')) {
      return 'default';
    }
    return 'complex';
  }

  Future<ReplyQuoteSummary?> _requestSummaryWithModel({
    required AiChatTransport transport,
    required String apiKey,
    required String baseUrl,
    required String model,
    required List<AiChatMessageModel> requestMessages,
    bool Function()? isCanceled,
  }) async {
    if (isCanceled?.call() ?? false) {
      return null;
    }

    final buffer = StringBuffer();
    AiErrorState? streamError;

    await for (final event in transport.streamCompletion(
      apiKey: apiKey,
      baseUrl: baseUrl,
      request: AiCompletionRequest(
        model: model,
        stream: false,
        jsonObjectResponse: true,
        messages: requestMessages,
        context: const AiRequestContext(
          kind: 'reply_quote_summary',
          summary: 'Summarize a message thread into a compact reply quote.',
        ),
      ),
    )) {
      if (isCanceled?.call() ?? false) {
        return null;
      }

      if (event.error != null) {
        streamError = event.error;
        break;
      }
      if (event.delta.isNotEmpty) {
        buffer.write(event.delta);
      }
    }

    if (streamError != null) {
      return null;
    }

    final raw = buffer.toString().trim();
    if (raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(_extractJsonObject(raw));
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return ReplyQuoteSummary.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  ReplyQuoteSummary _filterResources(
    ReplyQuoteSummary parsed, {
    required List<Map<String, String>> links,
    required List<Map<String, String>> images,
  }) {
    final allowedLinks = links.map((entry) => entry['url']!).toSet();
    final allowedImages = images.map((entry) => entry['url']!).toSet();

    return ReplyQuoteSummary(
      summaryLines: parsed.effectiveSummaryLines
          .take(8)
          .toList(growable: false),
      topic: parsed.topic,
      decisionOrReply: parsed.decisionOrReply,
      actionItems: parsed.actionItems.take(5).toList(growable: false),
      keyPeople: parsed.keyPeople.take(6).toList(growable: false),
      keySystems: parsed.keySystems.take(6).toList(growable: false),
      carryOverContext: parsed.carryOverContext,
      links: parsed.links
          .where((entry) => allowedLinks.contains(entry['url']))
          .take(6)
          .toList(growable: false),
      images: parsed.images
          .where(
            (entry) =>
                allowedImages.contains(entry['url']) &&
                _isRenderableImageUrl((entry['url'] ?? '').trim()),
          )
          .take(4)
          .toList(growable: false),
    );
  }

  bool _hasSufficientContext(ReplyQuoteSummary summary, String sourceText) {
    final normalized = sourceText.toLowerCase();
    final hasBookwidget = normalized.contains('bookwidget');
    final hasSmartschool = normalized.contains('smartschool');
    final hasAccount = normalized.contains('account');
    final hasActivation =
        normalized.contains('active') || normalized.contains('activat');

    final summaryBlob = [
      ...summary.effectiveSummaryLines,
      summary.topic,
      summary.decisionOrReply,
      summary.carryOverContext,
      ...summary.actionItems,
      ...summary.keySystems,
      ...summary.keyPeople,
    ].join(' ').toLowerCase();

    bool expects(String needle, bool condition) =>
        !condition || summaryBlob.contains(needle);

    final expectedMentions = [
      expects('bookwidget', hasBookwidget),
      expects('smartschool', hasSmartschool),
      expects('account', hasAccount),
      expects('activ', hasActivation),
    ];

    final mentionsOkay =
        expectedMentions.where((ok) => ok).length >=
        expectedMentions.length - 1;
    final hasAction =
        summary.actionItems.isNotEmpty ||
        summary.carryOverContext.isNotEmpty ||
        summary.topic.isNotEmpty;
    final hasSubstance =
        summary.effectiveSummaryLines.join(' ').trim().length >= 60;

    return mentionsOkay && hasAction && hasSubstance;
  }

  String _buildUserPrompt({
    required String from,
    required String date,
    required String subject,
    required String plainText,
    required List<Map<String, String>> links,
    required List<Map<String, String>> images,
  }) {
    final payload = <String, dynamic>{
      'sender': from,
      'date': date,
      'subject': subject,
      'message_text': plainText,
      'available_links': links,
      'available_images': images,
    };
    return jsonEncode(payload);
  }

  String _extractJsonObject(String raw) {
    final trimmed = raw.trim();
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      return trimmed;
    }

    final fenced = RegExp(
      r'```(?:json)?\s*(\{[\s\S]*\})\s*```',
    ).firstMatch(trimmed);
    if (fenced != null) {
      return fenced.group(1)!;
    }

    final start = trimmed.indexOf('{');
    final end = trimmed.lastIndexOf('}');
    if (start >= 0 && end > start) {
      return trimmed.substring(start, end + 1);
    }

    return trimmed;
  }

  List<Map<String, String>> _extractLinks(
    String html, {
    required Set<String> schoolDomains,
  }) {
    final seen = <String>{};
    final anchorExp = RegExp(
      r'''<a\b[^>]*href=["']([^"']+)["'][^>]*>(.*?)</a>''',
      caseSensitive: false,
      dotAll: true,
    );
    final matches = anchorExp.allMatches(html);

    final links = <Map<String, String>>[];
    for (final match in matches) {
      final url = (match.group(1) ?? '').trim();
      final label = _stripTags(match.group(2) ?? '');
      final snippet = _htmlWindow(html, match.start, radius: 220);
      if (!_isUsefulLinkResource(
        url: url,
        label: label,
        snippet: snippet,
        schoolDomains: schoolDomains,
      )) {
        continue;
      }
      if (url.isEmpty || !seen.add(url)) {
        continue;
      }
      links.add({'url': url, if (label.isNotEmpty) 'label': label});
    }
    return links;
  }

  List<Map<String, String>> _extractImages(
    String html,
    String smartschoolBaseUrl,
  ) {
    final seen = <String>{};
    final imageExp = RegExp(
      r'''<img\b[^>]*src=["']([^"']+)["'][^>]*>''',
      caseSensitive: false,
    );
    final matches = imageExp.allMatches(html);

    final images = <Map<String, String>>[];
    for (final match in matches) {
      final rawUrl = (match.group(1) ?? '').trim();
      final url = _resolveSmartschoolImageUrl(rawUrl, smartschoolBaseUrl);
      final snippet = _htmlWindow(html, match.start, radius: 240);
      final tag = match.group(0) ?? '';
      final altMatch = RegExp(
        r'''alt=["']([^"']+)["']''',
        caseSensitive: false,
      ).firstMatch(tag);
      final label = (altMatch?.group(1) ?? '').trim();

      if (!_isUsefulImageResource(url: url, label: label, snippet: snippet)) {
        continue;
      }
      if (url.isEmpty || !seen.add(url)) {
        continue;
      }
      images.add({'url': url, if (label.isNotEmpty) 'label': label});
    }
    return images;
  }

  bool _isUsefulLinkResource({
    required String url,
    required String label,
    required String snippet,
    required Set<String> schoolDomains,
  }) {
    final trimmedUrl = url.trim();
    if (trimmedUrl.isEmpty) {
      return false;
    }

    final parsed = Uri.tryParse(trimmedUrl);
    final scheme = parsed?.scheme.toLowerCase() ?? '';
    if (scheme != 'http' && scheme != 'https') {
      return false;
    }

    final combined =
        '${label.toLowerCase()} ${trimmedUrl.toLowerCase()} ${snippet.toLowerCase()}';
    if (_signatureCueCount(combined) >= 2) {
      return false;
    }

    final labelLower = label.toLowerCase().trim();
    final phoneLike = RegExp(r'^[+()0-9 ./-]{6,}$').hasMatch(labelLower);
    if (phoneLike) {
      return false;
    }

    final host = parsed?.host.toLowerCase() ?? '';
    final schoolHost = _isSchoolRelatedHost(host, schoolDomains);
    final nonEmptySegments = (parsed?.pathSegments ?? const <String>[])
        .where((segment) => segment.trim().isNotEmpty)
        .toList(growable: false);
    final verySpecificSchoolUrl =
        nonEmptySegments.length >= 2 ||
        (parsed?.query.isNotEmpty ?? false) ||
        (parsed?.fragment.isNotEmpty ?? false);
    final hasActionContext = RegExp(
      r'(bookwidget|smartschool|account|toets|resultaat|activ|limiet|vervang)',
    ).hasMatch(combined);
    final hostLikeLabel =
        labelLower == host ||
        labelLower == 'www.$host' ||
        schoolDomains.any((domain) => labelLower.contains(domain));

    final genericSchoolLink =
        schoolHost && (hostLikeLabel || _looksLikeContactLabel(labelLower));
    if (genericSchoolLink ||
        (schoolHost && !verySpecificSchoolUrl && !hasActionContext)) {
      return false;
    }

    return true;
  }

  bool _isUsefulImageResource({
    required String url,
    required String label,
    required String snippet,
  }) {
    final trimmedUrl = url.trim();
    if (trimmedUrl.isEmpty || !_isRenderableImageUrl(trimmedUrl)) {
      return false;
    }

    final combined =
        '${label.toLowerCase()} ${trimmedUrl.toLowerCase()} ${snippet.toLowerCase()}';
    if (_signatureCueCount(combined) >= 1) {
      return false;
    }

    final looksLikeLogo = RegExp(
      r'\b(logo|signature|footer|banner|icon|svg)\b',
    ).hasMatch(combined);
    if (looksLikeLogo) {
      return false;
    }

    return true;
  }

  bool _isRenderableImageUrl(String url) {
    final normalized = url.toLowerCase();
    final raster = RegExp(r'\.(png|jpg|jpeg|gif|webp|bmp)(\?|#|$)');
    return raster.hasMatch(normalized);
  }

  bool _looksLikeContactLabel(String labelLower) {
    final compact = labelLower.trim();
    if (compact.isEmpty) {
      return false;
    }

    final hasAddressCue = RegExp(
      r'\b(straat|laan|road|avenue|boulevard|plein|postcode|city|gemeente)\b',
    ).hasMatch(compact);
    final hasOrgCue = RegExp(
      r'\b(instituut|school|campus|college|vzw|vbs|atheneum)\b',
    ).hasMatch(compact);
    final hasPostalPattern = RegExp(r'\b\d{4,5}\b').hasMatch(compact);

    return hasAddressCue || hasOrgCue || hasPostalPattern;
  }

  int _signatureCueCount(String text) {
    final cues = <RegExp>[
      RegExp(r'\bvriendelijke groeten\b'),
      RegExp(r'\bmet vriendelijke groeten\b'),
      RegExp(r'\bdirecteur\b'),
      RegExp(r'\bleerkracht\b'),
      RegExp(r'\bvertrouwelijk\b'),
      RegExp(r'\bbestemmeling\b'),
      RegExp(r'\bafzender\b'),
      RegExp(r'\bwww\.[a-z0-9-]+\.[a-z]{2,}\b'),
      RegExp(r'\borganisat(ie|ion)\b'),
      RegExp(r'\blogistiek\b'),
      RegExp(r'\bonthaal\b'),
      RegExp(r'\bsales\b'),
    ];

    var score = 0;
    for (final cue in cues) {
      if (cue.hasMatch(text)) {
        score++;
      }
    }
    return score;
  }

  Set<String> _schoolDomains(String smartschoolBaseUrl) {
    final parsed = Uri.tryParse(smartschoolBaseUrl.trim());
    final host = parsed?.host.toLowerCase().trim() ?? '';
    if (host.isEmpty) {
      return const <String>{};
    }

    final domains = <String>{host};
    if (host.startsWith('www.')) {
      domains.add(host.substring(4));
    } else {
      domains.add('www.$host');
    }

    if (host.endsWith('.smartschool.be')) {
      final tenant = host.substring(0, host.length - '.smartschool.be'.length);
      if (tenant.isNotEmpty) {
        domains.add('$tenant.be');
        domains.add('www.$tenant.be');
      }
    }

    return domains;
  }

  bool _isSchoolRelatedHost(String host, Set<String> schoolDomains) {
    final normalized = host.toLowerCase().trim();
    if (normalized.isEmpty) {
      return false;
    }

    for (final domain in schoolDomains) {
      final value = domain.toLowerCase().trim();
      if (value.isEmpty) {
        continue;
      }
      if (normalized == value || normalized.endsWith('.$value')) {
        return true;
      }
    }

    return false;
  }

  String _htmlWindow(String html, int center, {int radius = 200}) {
    final start = (center - radius).clamp(0, html.length);
    final end = (center + radius).clamp(0, html.length);
    return _stripTags(html.substring(start, end));
  }

  String _resolveSmartschoolImageUrl(String source, String smartschoolBaseUrl) {
    final value = source.trim();
    if (value.isEmpty) {
      return value;
    }

    final parsed = Uri.tryParse(value);
    if (parsed != null && parsed.hasScheme) {
      return value;
    }

    if (value.startsWith('/public/') && smartschoolBaseUrl.isNotEmpty) {
      return '$smartschoolBaseUrl$value';
    }

    return value;
  }

  String _stripTags(String raw) {
    return raw
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static const String _systemPrompt =
      'You create compact but context-rich reply quotes for a mail composer. '
      'Keep the original language. Preserve core thread context, not just the '
      'latest sentence. You must identify the main topic, concrete pending '
      'actions, and carry-over context from earlier quoted/forwarded parts '
      'when needed to understand what needs to happen. Ignore signatures, '
      'disclaimers, legal notices, logos and contact blocks unless they are '
      'part of the requested action. Only keep links/images that matter for '
      'the action context. Return strict JSON only with this exact shape: '
      '{"topic":"...","decision_or_reply":"...","action_items":["..."],'
      '"key_people":["..."],"key_systems":["..."],'
      '"carry_over_context":"...","summary_lines":["..."],'
      '"links":[{"url":"...","label":"..."}],'
      '"images":[{"url":"...","label":"..."}]}. '
      'Constraints: summary_lines must have 3-6 lines; action_items should be '
      'specific and task-oriented; key_people should include request owners '
      'when present; key_systems should include tools/platforms like '
      'Bookwidget/Smartschool when present. Use only URLs from '
      'available_links and available_images.';
}
