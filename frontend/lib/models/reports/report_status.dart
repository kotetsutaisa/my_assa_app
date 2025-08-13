enum ReportStatus { draft, pending, submitted, locked }

extension ReportStatusX on ReportStatus {
  String get apiValue {
    switch (this) {
      case ReportStatus.draft:
        return 'draft';
      case ReportStatus.pending:
        return 'pending';
      case ReportStatus.submitted:
        return 'submitted';
      case ReportStatus.locked:
        return 'locked';
    }
  }

  static ReportStatus fromApi(String? v) {
    switch (v) {
      case 'pending':
        return ReportStatus.pending;
      case 'submitted':
        return ReportStatus.submitted;
      case 'locked':
        return ReportStatus.locked;
      case 'draft':
      default:
        return ReportStatus.draft;
    }
  }
}

