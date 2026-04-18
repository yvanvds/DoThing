/// The intrinsic behavior category of a tool, independent of how the
/// orchestrator treats it.
///
/// Mode describes what a tool fundamentally does; [ToolRiskTier] describes
/// how the orchestrator gates it. They match by default but can diverge
/// (e.g. a commit-mode tool bumped to privileged risk by user settings).
enum ToolMode { read, prepare, commit, privileged }
