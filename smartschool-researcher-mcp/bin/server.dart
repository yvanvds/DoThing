import 'dart:async';
import 'dart:io';
import 'package:logging/logging.dart';
import 'package:smartschool_researcher_mcp/mcp_server.dart';

final _logger = Logger('smartschool_mcp.bin.server');

Future<void> main() async {
  // Set up logging
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    stderr.writeln(
      '[${record.level.name}] ${record.loggerName}: ${record.message}',
    );
    if (record.error != null) {
      stderr.writeln('Error: ${record.error}');
      stderr.writeln('Stack: ${record.stackTrace}');
    }
  });

  _logger.info('SmartSchool Researcher MCP Server starting...');

  final server = SmartschoolMcpServer();

  try {
    await server.run();
  } catch (e, st) {
    _logger.severe('Unhandled error in MCP server', e, st);
    exit(1);
  }
}
