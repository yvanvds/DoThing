# Copilot instructions for this repository

- Use one public class per file unless classes are tiny and tightly coupled.
- create folders to bundle related classes together, e.g. `services/`, `repositories/`, `widgets/`, `outlook/`, `smartschool/`.
- Prefer small, focused services with a single responsibility.
- Extract DTOs and models into separate files under `models/`.
- Keep business logic out of Flutter widgets.
- When generating Dart code, prefer clear naming and null-safe patterns.
- Before adding a new class, check whether an existing abstraction already fits.
- When refactoring, do not change public behavior unless asked.