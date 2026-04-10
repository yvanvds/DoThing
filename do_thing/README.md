# do_thing

A new Flutter project.

## Testing

This project uses Flutter tests with an emphasis on fast, deterministic unit tests.

### Current coverage

- Model parsing and defaults:
	- `test/models/smartschool_message_test.dart`
- Command registry and command bus behavior:
	- `test/commands/command_registry_test.dart`
	- `test/commands/command_bus_test.dart`
- Stateless and UI-state controllers:
	- `test/controllers/basic_controllers_test.dart`
	- `test/controllers/smartschool_inbox_controller_test.dart`
- Smartschool auth and message service actions:
	- `test/services/smartschool_auth_service_test.dart`
	- `test/services/smartschool_messages_actions_test.dart`
- Message cache and polling behavior:
	- `test/services/smartschool_messages_polling_cache_test.dart`
- Drift repository sync logic (in-memory database):
	- `test/database/smartschool_sync_repository_test.dart`

### Run tests

From `do_thing/`:

- Run all tests:

	```bash
	flutter test
	```

- Run with coverage:

	```bash
	flutter test --coverage
	```

- Run a single file (example):

	```bash
	flutter test test/services/smartschool_messages_actions_test.dart
	```

### Test design notes

- Prefer provider overrides and fakes over live network/process dependencies.
- Use `NativeDatabase.memory()` for Drift tests.
- Keep tests deterministic (no real Smartschool login in CI).
