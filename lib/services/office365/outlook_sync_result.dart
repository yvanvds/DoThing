class OutlookSyncResult {
  const OutlookSyncResult({
    required this.scannedCount,
    required this.newCount,
    required this.removedCount,
  });

  final int scannedCount;
  final int newCount;
  final int removedCount;
}
