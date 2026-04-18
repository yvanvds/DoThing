import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:highlight/highlight.dart' as highlight;
import 'package:provider/provider.dart' as provider;
import 'package:url_launcher/url_launcher.dart';

import '../../../controllers/ai/ai_chat_controller.dart';
import '../../../controllers/ai/ai_settings_controller.dart';
import '../../../controllers/chat_controller.dart';
import '../../../models/ai/ai_chat_models.dart';
import '../../../models/ai/ai_settings.dart';
import 'agent_confirmation_card.dart';

part 'chat_view_widget.dart';
part 'chat_view_state.dart';
part 'chat_composer.dart';
part 'chat_composer_state.dart';
part 'markdown_text_message.dart';
part 'inline_code_builder.dart';
part 'svg_code_block.dart';
part 'svg_code_block_state.dart';
part 'code_block.dart';
part 'code_block_state.dart';
part 'copy_button.dart';
part 'copy_button_state.dart';
part 'code_syntax_highlighter.dart';
part 'ai_status_bar.dart';
part 'chat_quick_actions_row.dart';

enum _ChatModelPreset { complex, defaultModel, cheap }

_ChatModelPreset _chatModelPresetFromStorage(String value) {
  return switch (value) {
    'cheap' => _ChatModelPreset.cheap,
    'default' => _ChatModelPreset.defaultModel,
    _ => _ChatModelPreset.complex,
  };
}

String _chatModelPresetToStorage(_ChatModelPreset preset) {
  return switch (preset) {
    _ChatModelPreset.complex => 'complex',
    _ChatModelPreset.defaultModel => 'default',
    _ChatModelPreset.cheap => 'cheap',
  };
}

String _chatModelPresetLabel(_ChatModelPreset preset) {
  return switch (preset) {
    _ChatModelPreset.complex => 'Complex',
    _ChatModelPreset.defaultModel => 'Default',
    _ChatModelPreset.cheap => 'Cheap',
  };
}
