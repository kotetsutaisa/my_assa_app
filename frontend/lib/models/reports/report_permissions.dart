class ReportPermissions {
  final bool canViewDetail;
  final bool canDelete;
  /// 個人日報のみ返る。チーム日報では来ないので null/false で扱う
  final bool canApprove;

  const ReportPermissions({
    required this.canViewDetail,
    required this.canDelete,
    this.canApprove = false,
  });

  factory ReportPermissions.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ReportPermissions(canViewDetail: false, canDelete: false, canApprove: false);
    }
    return ReportPermissions(
      canViewDetail: json['can_view_detail'] as bool? ?? false,
      canDelete    : json['can_delete']      as bool? ?? false,
      canApprove   : json['can_approve']     as bool? ?? false, // チーム側は来ない想定
    );
  }
}
