class PayResult {
  PayResult({
    required this.gross,
    required this.tax,
    required this.net,
    required this.totalHours,
    required this.leaveDeduction,
    required this.breakdown,
    required this.accruedLeaveHours,
  });

  final double gross;
  final double tax;
  final double net;
  final double totalHours;
  final double leaveDeduction;
  final Map<String, double> breakdown;
  final double accruedLeaveHours;
}
