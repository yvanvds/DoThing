import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'outlook_body_content.dart';

class OutlookMessageBodyCacheController
    extends Notifier<Map<int, OutlookBodyContent>> {
  @override
  Map<int, OutlookBodyContent> build() => {};

  void put(int localMessageId, OutlookBodyContent body) {
    state = {...state, localMessageId: body};
  }

  void clear() => state = {};
}

final outlookMessageBodyCacheProvider = NotifierProvider<
    OutlookMessageBodyCacheController,
    Map<int, OutlookBodyContent>>(
  OutlookMessageBodyCacheController.new,
);
