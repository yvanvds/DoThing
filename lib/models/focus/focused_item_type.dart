/// Kind of entity the currently focused item represents.
///
/// The focused-item abstraction is intentionally source-agnostic; this
/// enum captures *what* the item is, orthogonal to *which* backend
/// produced it. Today only [message] is implemented; other values are
/// reserved so the planner prompt and the tool schema do not need to
/// change when more adapters land.
enum FocusedItemType {
  message,
  document,
  calendarEvent,
  todo,
  account,
}

/// Stable snake_case keys used in tool payloads and the planner prompt.
/// Keep them stable across refactors — they are the wire contract.
String focusedItemTypeKey(FocusedItemType type) {
  switch (type) {
    case FocusedItemType.message:
      return 'message';
    case FocusedItemType.document:
      return 'document';
    case FocusedItemType.calendarEvent:
      return 'calendar_event';
    case FocusedItemType.todo:
      return 'todo';
    case FocusedItemType.account:
      return 'account';
  }
}
