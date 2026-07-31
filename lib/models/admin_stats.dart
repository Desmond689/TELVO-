// lib/models/admin_stats.dart

class AdminStats {
  const AdminStats({
    this.totalUsers = 0,
    this.totalProfessionals = 0,
    this.totalJobs = 0,
    this.totalRevenue = 0.0,
    this.pendingVerifications = 0,
    this.activeJobs = 0,
    this.disputes = 0,
    this.fraudReports = 0,
    this.categoryStats = const {},
    this.recentActivity = const [],
  });

  final int totalUsers;
  final int totalProfessionals;
  final int totalJobs;
  final double totalRevenue;
  final int pendingVerifications;
  final int activeJobs;
  final int disputes;
  final int fraudReports;
  final Map<String, int> categoryStats;
  final List<Map<String, dynamic>> recentActivity;
}
