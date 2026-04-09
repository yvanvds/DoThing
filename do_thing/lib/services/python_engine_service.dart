import 'dart:io';

import 'package:py_engine_desktop/py_engine_desktop.dart';

import '../controllers/status_controller.dart';
import 'smartschool_bridge.dart';

/// Manages the embedded Python runtime, direct package installation,
/// and the long-lived bridge process that lets
/// Dart talk to the `smartschool` Python library.
class PythonEngineService {
  SmartschoolBridge? _bridge;
  bool _initialized = false;
  String? _bridgeScriptPath;

  bool get isInitialized => _initialized;

  /// The running bridge instance. Throws if not yet initialised.
  SmartschoolBridge get bridge {
    if (_bridge == null) {
      throw StateError('PythonEngineService has not been initialised.');
    }
    return _bridge!;
  }

  /// Full initialisation sequence:
  ///
  /// 1. Extract the embedded Python runtime (idempotent).
  /// 2. Install `smartschool[mfa]` (includes pyotp) into that runtime.
  /// 3. Deploy the bridge script.
  /// 4. Start the bridge process and verify it responds.
  Future<void> initialize(StatusController status) async {
    if (_initialized) return;

    // ── 1. Init embedded Python ──────────────────────────────────────────
    status.add(StatusEntryType.info, 'Initializing Python runtime…');
    await PyEngineDesktop.init();
    status.add(StatusEntryType.success, 'Python runtime ready.');

    // ── 2. Paths ─────────────────────────────────────────────────────────
    final sep = Platform.pathSeparator;
    final appData = Platform.environment['APPDATA'];
    final basePath = (appData != null && appData.isNotEmpty)
        ? appData
        : Directory.current.path;
    final appDir = '$basePath${sep}DoThing';
    _bridgeScriptPath = '$appDir${sep}smartschool_bridge.py';

    // ── 3. Install packages directly into embedded runtime ──────────────
    status.add(
      StatusEntryType.info,
      'Installing Python packages (smartschool, pyotp)…',
    );
    await PyEngineDesktop.pipInstall('smartschool[mfa]');
    await PyEngineDesktop.pipInstall('pyotp');
    status.add(StatusEntryType.success, 'Python packages installed.');

    // ── 4. Deploy bridge script ──────────────────────────────────────────
    await File(_bridgeScriptPath!).writeAsString(_bridgeScriptContent);

    // ── 5. Start bridge process ──────────────────────────────────────────
    status.add(StatusEntryType.info, 'Starting Smartschool bridge…');
    final script = await PyEngineDesktop.startScript(_bridgeScriptPath!);
    _bridge = SmartschoolBridge(script);

    // ── 6. Health-check ──────────────────────────────────────────────────
    final alive = await _bridge!.ping();
    if (!alive) {
      throw StateError('Smartschool bridge did not respond to ping.');
    }

    final missing = await _bridge!.checkPackages();
    if (missing.isNotEmpty) {
      throw StateError(
        'Missing Python packages after install: ${missing.join(", ")}',
      );
    }

    status.add(StatusEntryType.success, 'Smartschool bridge ready.');
    _initialized = true;
  }

  /// Shut down the bridge process and reset state.
  void dispose() {
    _bridge?.dispose();
    _bridge = null;
    _initialized = false;
  }
}

// ---------------------------------------------------------------------------
// Bridge script (Python)
//
// Runs as a long-lived child process.  Reads JSON commands from stdin,
// executes them against the `smartschool` library, and writes JSON
// responses to stdout.  Library print() calls are redirected to stderr
// so they never pollute the protocol stream.
// ---------------------------------------------------------------------------

const String _bridgeScriptContent = r'''
import sys
import json
import traceback

# Redirect stdout → stderr so library prints don't pollute our JSON protocol.
_out = sys.stdout
sys.stdout = sys.stderr


def respond(data):
    _out.write(json.dumps(data) + '\n')
    _out.flush()


session = None


def handle(cmd):
    global session
    action = cmd['action']

    # ── lifecycle ──────────────────────────────────────────────────────────

    if action == 'ping':
        return {'pong': True}

    if action == 'check_packages':
        missing = []
        try:
            import smartschool  # noqa: F401
        except ImportError:
            missing.append('smartschool')
        try:
            import pyotp  # noqa: F401
        except ImportError:
            missing.append('pyotp')
        return {'missing': missing}

    # ── authentication ─────────────────────────────────────────────────────

    if action == 'login':
        from smartschool import Smartschool, AppCredentials, TopNavCourses
        creds = AppCredentials(
            username=cmd['username'],
            password=cmd['password'],
            main_url=cmd['url'],
            mfa=cmd.get('mfa', ''),
        )
        session = Smartschool(creds)
        # Force one authenticated request so login errors surface here.
        list(TopNavCourses(session))
        return {'success': True}

    if action == 'logout':
        session = None
        return {'success': True}

    if action == 'is_authenticated':
        return {'authenticated': session is not None}

    # ── messages ───────────────────────────────────────────────────────────

    if action == 'get_message_headers':
        if session is None:
            return {'error': 'Not authenticated'}
        from smartschool import MessageHeaders, BoxType
        box = getattr(BoxType, cmd.get('box_type', 'INBOX'))
        kwargs = {'box_type': box}
        seen = cmd.get('already_seen_ids')
        if seen:
            kwargs['already_seen_message_ids'] = seen
        headers = []
        for h in MessageHeaders(session, **kwargs):
            headers.append({
                'id': h.id,
                'from': h.from_,
                'from_image': h.from_image,
                'subject': h.subject,
                'date': str(h.date),
                'status': h.status,
                'unread': h.unread,
                'attachment': h.attachment,
                'label': h.label,
                'deleted': h.deleted,
                'allowreply': h.allowreply,
                'allowreplyenabled': h.allowreplyenabled,
                'hasreply': h.hasreply,
                'has_forward': h.has_forward,
                'real_box': h.real_box,
                'send_date': str(h.send_date) if h.send_date is not None else None,
            })
        return {'headers': headers}

    if action == 'get_message':
        if session is None:
            return {'error': 'Not authenticated'}
        from smartschool import Message
        messages = []
        for msg in Message(session, cmd['message_id']):
            m = {
                'id': msg.id,
                'from': msg.from_,
                'to': msg.to,
                'subject': msg.subject,
                'body': msg.body,
                'date': str(msg.date) if hasattr(msg, 'date') else None,
                'status': msg.status,
                'attachment': msg.attachment,
                'unread': msg.unread,
                'label': msg.label,
                'receivers': msg.receivers if hasattr(msg, 'receivers') else [],
                'ccreceivers': msg.ccreceivers if hasattr(msg, 'ccreceivers') else [],
                'bccreceivers': msg.bccreceivers if hasattr(msg, 'bccreceivers') else [],
                'sender_picture': msg.sender_picture if hasattr(msg, 'sender_picture') else None,
                'from_team': msg.from_team if hasattr(msg, 'from_team') else None,
                'total_nr_other_to_reciviers': msg.total_nr_other_to_reciviers if hasattr(msg, 'total_nr_other_to_reciviers') else 0,
                'total_nr_other_cc_receivers': msg.total_nr_other_cc_receivers if hasattr(msg, 'total_nr_other_cc_receivers') else 0,
                'total_nr_other_bcc_receivers': msg.total_nr_other_bcc_receivers if hasattr(msg, 'total_nr_other_bcc_receivers') else 0,
                'can_reply': msg.can_reply if hasattr(msg, 'can_reply') else False,
                'has_reply': msg.has_reply if hasattr(msg, 'has_reply') else False,
                'has_forward': msg.has_forward if hasattr(msg, 'has_forward') else False,
                'send_date': str(msg.send_date) if hasattr(msg, 'send_date') and msg.send_date is not None else None,
            }
            messages.append(m)
        return {'messages': messages}

    if action == 'get_threaded_headers':
        if session is None:
            return {'error': 'Not authenticated'}
        import re
        from collections import defaultdict
        from smartschool import MessageHeaders, BoxType
        box = getattr(BoxType, cmd.get('box_type', 'INBOX'))
        kwargs = {'box_type': box}
        seen = cmd.get('already_seen_ids')
        if seen:
            kwargs['already_seen_message_ids'] = seen
        headers = []
        for h in MessageHeaders(session, **kwargs):
            headers.append({
                'id': h.id,
                'from': h.from_,
                'from_image': h.from_image,
                'subject': h.subject,
                'date': str(h.date),
                'status': h.status,
                'unread': h.unread,
                'attachment': h.attachment,
                'label': h.label,
                'deleted': h.deleted,
                'allowreply': h.allowreply,
                'allowreplyenabled': h.allowreplyenabled,
                'hasreply': h.hasreply,
                'has_forward': h.has_forward,
                'real_box': h.real_box,
                'send_date': str(h.send_date) if h.send_date is not None else None,
            })

        def _normalize_subject(subj):
            if not subj:
                return ''
            s = subj.strip().lower()
            prev = None
            while prev != s:
                prev = s
                s = re.sub(r'^(re|fw|fwd)\s*:\s*', '', s).strip()
            return s

        groups = defaultdict(list)
        for h in headers:
            key = _normalize_subject(h['subject'])
            groups[key].append(h)

        threads = []
        for key, msgs in groups.items():
            msgs.sort(key=lambda m: m['date'], reverse=True)
            any_unread = any(not m['unread'] for m in msgs)
            any_has_reply = any(m['hasreply'] for m in msgs)
            threads.append({
                'thread_key': key,
                'subject': msgs[0]['subject'],
                'latest_date': msgs[0]['date'],
                'message_count': len(msgs),
                'has_unread': any_unread,
                'has_reply': any_has_reply,
                'messages': msgs,
            })

        threads.sort(key=lambda t: t['latest_date'], reverse=True)
        return {'threads': threads}

    if action == 'get_attachments':
        if session is None:
            return {'error': 'Not authenticated'}
        from smartschool import Attachments
        import base64
        attachments = []
        for a in Attachments(session, cmd['message_id']):
            content = a.download()
            attachments.append({
                'name': a.name,
                'size': a.size,
                'content_base64': base64.b64encode(content).decode('utf-8'),
            })
        return {'attachments': attachments}

    # ── message operations ─────────────────────────────────────────────────

    if action == 'mark_unread':
        if session is None:
            return {'error': 'Not authenticated'}
        from smartschool import MarkMessageUnread
        list(MarkMessageUnread(session, msg_id=cmd['message_id']))
        return {'success': True}

    if action == 'set_label':
        if session is None:
            return {'error': 'Not authenticated'}
        from smartschool import AdjustMessageLabel, MessageLabel
        label = getattr(MessageLabel, cmd['label'])
        list(AdjustMessageLabel(session, msg_id=cmd['message_id'], label=label))
        return {'success': True}

    if action == 'archive':
        if session is None:
            return {'error': 'Not authenticated'}
        from smartschool import MessageMoveToArchive
        MessageMoveToArchive(session, msg_id=cmd['message_id']).get()
        return {'success': True}

    if action == 'trash':
        if session is None:
            return {'error': 'Not authenticated'}
        from smartschool import MessageMoveToTrash
        list(MessageMoveToTrash(session, msg_id=cmd['message_id']))
        return {'success': True}

    return {'error': f'Unknown action: {action}'}


# ── main loop ──────────────────────────────────────────────────────────────────
while True:
    line = sys.stdin.readline()
    if not line:
        break
    line = line.strip()
    if not line:
        continue
    cmd = None
    try:
        cmd = json.loads(line)
        request_id = cmd.get('id')
        result = handle(cmd)
        result['id'] = request_id
        respond(result)
    except Exception as e:
        respond({
            'error': str(e),
            'error_type': type(e).__name__,
            'traceback': traceback.format_exc(),
            'id': cmd.get('id') if cmd else None,
        })
''';
