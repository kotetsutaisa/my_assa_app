from rest_framework.permissions import BasePermission
from django.shortcuts import get_object_or_404
from .models import TeamReport
# チームメンバーの中間モデルに合わせて import 名を調整してください
from companies.models import TeamMember  # ←あなたの実装に応じて

class CanGeneratePersonalDraft(BasePermission):
    """
    /api/reports/team/generate-personal/ を許可する条件:
    - 認証済み かつ
    - (スーパーユーザー) または
      (会社管理者) または
      (対象 TeamReport のチームリーダー) または
      (対象 TeamReport の作成者)
    """
    def has_permission(self, request, view):
        if request.method != "POST":
            return False
        user = request.user
        if not user or not user.is_authenticated:
            return False

        team_report_id = request.data.get("team_report_id")
        if not team_report_id:
            return False

        # 会社縛り & 対象レポート取得
        report = get_object_or_404(
            TeamReport.objects.select_related("team", "company"),
            id=team_report_id,
            company=getattr(user, "company", None),
        )

        # 1) superuser
        if getattr(user, "is_superuser", False):
            return True

        # 2) 会社管理者（あなたの実装に合わせて判定してください）
        # 例: Userに is_company_admin(company_id) ヘルパがある場合
        if hasattr(user, "is_company_admin") and user.is_company_admin(report.company_id):
            return True

        # 3) チームリーダー
        is_leader = TeamMember.objects.filter(
            team_id=report.team_id, user_id=user.id, role="leader"
        ).exists()
        if is_leader:
            return True

        # 4) レポート作成者自身
        if report.created_by_id == user.id:
            return True

        return False
