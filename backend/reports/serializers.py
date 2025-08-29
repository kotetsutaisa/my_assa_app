# reports/serializers.py（該当クラスのみ抜粋・上書き）

from typing import List, Dict, Set
from django.contrib.auth import get_user_model
from django.db import transaction, IntegrityError
from django.utils import timezone as dj_tz
from django.utils.dateparse import parse_time
from rest_framework import serializers

from companies.models import Company, Team, TeamMember
from site_app.models import Site
from site_app.serializers import SiteSerializer
from users.serializers import SimpleUserSerializer
from schedule.models import WorkCategory
from schedule.serializers import WorkCategorySerializer

from .models import (
    TeamReport, TeamReportEntry,
    PersonalReport, PersonalReportEntry,
    ReportStatus,
)

from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from users.models import CustomUser

User = get_user_model()


# ================== 共通: permissions 計算ヘルパ ==================
class _PermissionsMixin:
    """
    シリアライザー内で permissions を計算する共通ユーティリティ。
    self.context['_perm_cache'] に簡易キャッシュを保持して N+1 を軽減。
    """
    @property
    def _perm_cache(self) -> dict:
        cache = self.context.get("_perm_cache")
        if cache is None:
            cache = {"my_leader_team_ids": None, "author_team_ids": {}}
            self.context["_perm_cache"] = cache
        return cache

    def _get_my_leader_team_ids(self, user):
        """リクエストユーザーが leader として所属するチームID集合"""
        from companies.models import TeamMember
        cache = self._perm_cache
        if cache["my_leader_team_ids"] is not None:
            return cache["my_leader_team_ids"]
        qs = TeamMember.objects.filter(user_id=user.id, role="leader", is_active=True)
        team_ids = set(qs.values_list("team_id", flat=True))
        cache["my_leader_team_ids"] = team_ids
        return team_ids

    def _get_author_team_ids(self, user_id: int):
        """投稿者(= user_id) が所属するチームID集合"""
        from companies.models import TeamMember
        cache = self._perm_cache
        if user_id in cache["author_team_ids"]:
            return cache["author_team_ids"][user_id]
        qs = TeamMember.objects.filter(user_id=user_id, is_active=True)
        team_ids = set(qs.values_list("team_id", flat=True))
        cache["author_team_ids"][user_id] = team_ids
        return team_ids

    def _is_admin(self, user) -> bool:
        # CustomUser.role が 'admin'。保険で is_superuser / is_staff も許可
        role = getattr(user, "role", None)
        if isinstance(role, str) and role.lower() == "admin":
            return True
        return bool(getattr(user, "is_superuser", False) or getattr(user, "is_staff", False))

    def _is_manager(self, user) -> bool:
        role = getattr(user, "role", None)
        return bool(isinstance(role, str) and role.lower() == "manager")
    
    def _is_admin_or_manager(self, user) -> bool:
        return self._is_admin(user) or self._is_manager(user)



# ========== 明細 ==========
class PersonalReportEntrySerializer(serializers.ModelSerializer):
    site = SiteSerializer(read_only=True)
    work_category = WorkCategorySerializer(read_only=True)

    site_id = serializers.PrimaryKeyRelatedField(
        queryset=Site.objects.none(),
        source="site",
        write_only=True,
    )
    work_category_id = serializers.PrimaryKeyRelatedField(
        queryset=WorkCategory.objects.none(),
        source="work_category",
        write_only=True,
        required=False,
        allow_null=True,
    )

    class Meta:
        model = PersonalReportEntry
        fields = (
            "id",
            "site", "work_category",
            "site_id", "work_category_id",
            "start_time", "end_time", "note",
            "work_minutes",            # read-only（@property）
            "changed_from_source",     # read-only（サーバー側で管理）
        )
        read_only_fields = ("work_minutes", "changed_from_source")

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        req = self.context.get("request")
        if req and getattr(req.user, "company", None):
            company: Company = req.user.company
            self.fields["site_id"].queryset = Site.objects.filter(company=company)
            self.fields["work_category_id"].queryset = WorkCategory.objects.filter(company=company)

    def validate(self, data):
        # 開始と終了が全く同じはNG（0分実績）
        if "start_time" in data and "end_time" in data:
            if data["start_time"] == data["end_time"]:
                raise serializers.ValidationError({"end_time": "開始と終了が同一は無効です。"})
        return data


# ========== 個人日報 ==========
class PersonalReportSerializer(_PermissionsMixin, serializers.ModelSerializer):
    user = SimpleUserSerializer(read_only=True)
    entries = PersonalReportEntrySerializer(many=True)

    user_id = serializers.PrimaryKeyRelatedField(
        queryset=User.objects.all(),
        write_only=True,
        required=False,
        allow_null=True,
        source="user",
    )
    approved_by = SimpleUserSerializer(read_only=True)

    permissions = serializers.SerializerMethodField(read_only=True)
    has_diff_from_source = serializers.SerializerMethodField(read_only=True)

    class Meta:
        model = PersonalReport
        fields = (
            "id", "date", "status",
            "user", "user_id",
            "note",
            "submitted_at",
            "entries",
            "created_at",
            "approved_by", "approved_at",
            "permissions",
            "has_diff_from_source",
        )
        read_only_fields = (
            "submitted_at", "created_at", "approved_by", "approved_at",
            "permissions", "has_diff_from_source"
        )

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        req = self.context.get("request")
        if req and getattr(req.user, "company", None):
            company: Company = req.user.company
            entry_child: PersonalReportEntrySerializer = self.fields["entries"].child
            entry_child.fields["site_id"].queryset = Site.objects.filter(company=company)
            entry_child.fields["work_category_id"].queryset = WorkCategory.objects.filter(company=company)

    # -------- permissions(JSON) 生成 --------
    def get_permissions(self, obj):
        req = self.context.get("request")
        if not req or not hasattr(req, "user"):
            return {"can_view_detail": False, "can_delete": False, "can_approve": False}

        me = req.user
        is_admin = self._is_admin(me)
        is_manager = self._is_manager(me)

        own = (obj.user_id == me.id)

        # 「投稿者が所属するチーム」×「自分がleaderのチーム」の積集合
        author_team_ids = self._get_author_team_ids(obj.user_id)
        my_leader_team_ids = self._get_my_leader_team_ids(me)
        leader_of_authors_team = bool(my_leader_team_ids & author_team_ids)

        # 詳細 / 削除
        can_view_detail = (is_admin or is_manager or own or leader_of_authors_team)
        can_delete      = (is_admin or is_manager or own or leader_of_authors_team)

        # 承認（pending のときのみ）
        can_approve = False
        if obj.status == ReportStatus.PENDING:
            can_approve = (is_admin or is_manager or leader_of_authors_team)

        return {
            "can_view_detail": bool(can_view_detail),
            "can_delete": bool(can_delete),
            "can_approve": bool(can_approve),
        }

    # -------- create --------
    def create(self, validated_data):
        entries_data = validated_data.pop("entries", [])
        req = self.context["request"]
        user = validated_data.pop("user", None) or req.user
        company: Company = req.user.company

        # 新規提出ルール:
        # - status=submitted で作成要求が来た場合、
        #   権限者(admin/manager/投稿者チームのリーダー)は即 SUBMITTED、一般は PENDING。
        desired_status = validated_data.pop("status", ReportStatus.DRAFT)
        me = req.user
        is_admin = self._is_admin(me)
        is_manager = self._is_manager(me)
        leader_of_authors_team = bool(
            self._get_my_leader_team_ids(me) & self._get_author_team_ids(user.id)
        )
        privileged = (is_admin or is_manager or leader_of_authors_team)

        final_status = desired_status
        submitted_at = None
        if desired_status == ReportStatus.SUBMITTED:
            if privileged:
                final_status = ReportStatus.SUBMITTED
                submitted_at = dj_tz.now()
            else:
                final_status = ReportStatus.PENDING
                submitted_at = None

        report = PersonalReport.objects.create(
            company=company,
            user=user,
            status=final_status,
            submitted_at=submitted_at,
            **validated_data,
        )
        self._replace_entries(report, entries_data)
        return report

    # -------- update --------
    def update(self, instance: PersonalReport, validated_data):
        if instance.status == ReportStatus.LOCKED:
            raise serializers.ValidationError("締め後の日報は編集できません。")

        entries_data = validated_data.pop("entries", None)
        validated_data.pop("user", None)
        validated_data.pop("company", None)

        # 通常フィールド更新
        for k, v in validated_data.items():
            setattr(instance, k, v)
        instance.save()

        # 明細入れ替え
        if entries_data is not None:
            self._replace_entries(instance, entries_data)

        # 提出時のステータス遷移
        if validated_data.get("status") == ReportStatus.SUBMITTED:
            has_diff = self._needs_approval(instance)

            me = self.context["request"].user
            is_admin = self._is_admin(me)
            is_manager = self._is_manager(me)
            leader_of_authors_team = bool(
                self._get_my_leader_team_ids(me) & self._get_author_team_ids(instance.user_id)
            )

            if (instance.source_team_report_id is not None) and (not has_diff):
                # ★ チーム日報由来 かつ 差分なし → 一般メンバーでも即 SUBMITTED
                instance.status = ReportStatus.SUBMITTED
                if instance.submitted_at is None:
                    instance.submitted_at = dj_tz.now()
                    instance.save(update_fields=["status", "submitted_at"])
                else:
                    instance.save(update_fields=["status"])
            elif (is_admin or is_manager or leader_of_authors_team):
                # 権限者は差分があっても即 SUBMITTED
                instance.status = ReportStatus.SUBMITTED
                if instance.submitted_at is None:
                    instance.submitted_at = dj_tz.now()
                    instance.save(update_fields=["status", "submitted_at"])
                else:
                    instance.save(update_fields=["status"])
            else:
                # 一般メンバーで差分あり、またはチーム由来でない提出 → PENDING
                instance.status = ReportStatus.PENDING
                instance.save(update_fields=["status"])

        return instance
    
    def validate(self, attrs):
        """
        entries 内で時間帯が重なる行があれば NG（端が接する = OK）
        """
        entries_initial = self.initial_data.get("entries", [])
        if self.instance is None or "entries" in self.initial_data:
            def to_minutes(v):
                # v は "HH:MM" / "HH:MM:SS" か datetime.time
                if isinstance(v, str):
                    t = parse_time(v)
                else:
                    t = v
                if t is None:
                    return None
                return t.hour * 60 + t.minute

            times = []
            for i, e in enumerate(entries_initial):
                st = to_minutes(e.get("start_time"))
                et = to_minutes(e.get("end_time"))
                if st is None or et is None:
                    continue
                times.append((st, et, i))

            times.sort(key=lambda x: x[0])  # start でソート

            errors = {}
            prev_end = None
            prev_idx = None
            for st, et, idx in times:
                if prev_end is not None and st < prev_end:  # 接触(st == prev_end)はOK
                    # どの行がぶつかっているか両方に付ける
                    msg = "他の行と時間帯が重複しています。"
                    errors.setdefault(prev_idx, {}).setdefault("start_time", msg)
                    errors.setdefault(idx, {}).setdefault("start_time", msg)
                if errors:
                    break
                prev_end = et
                prev_idx = idx

            if errors:
                raise serializers.ValidationError({"entries": errors})
        return attrs

    # -------- helpers --------
    def _replace_entries(self, report: PersonalReport, entries_data: List[dict]):
        report.entries.all().delete()
        objs = [PersonalReportEntry(report=report, **e) for e in entries_data]
        if objs:
            PersonalReportEntry.objects.bulk_create(objs)

    def _needs_approval(self, pr: PersonalReport) -> bool:
        """
        生成元 TeamReport があり、当該ユーザー分の明細が
        （site, work_category, start_time, end_time, note）の完全一致を外れる
        ものが1件でもあれば True（＝差分あり）
        """
        if pr.source_team_report_id is None:
            return False

        src_qs = (
            TeamReportEntry.objects
            .filter(report_id=pr.source_team_report_id, member_id=pr.user_id)
            .select_related("site", "work_category")
        )
        src = sorted([
            (e.site_id, e.work_category_id, e.start_time, e.end_time, (e.note or ""))
            for e in src_qs
        ])

        cur = sorted([
            (e.site_id, e.work_category_id, e.start_time, e.end_time, (e.note or ""))
            for e in pr.entries.all()
        ])

        return src != cur

    def get_has_diff_from_source(self, obj) -> bool:
        return bool(self._needs_approval(obj))



# ---- Team (表示用の最小) ----
class SimpleTeamSerializer(serializers.ModelSerializer):
    class Meta:
        model = Team
        fields = ("id", "name")


# ========== TeamReportEntry ==========
class TeamReportEntrySerializer(serializers.ModelSerializer):
    # 展開（read-only）
    site = SiteSerializer(read_only=True)
    work_category = WorkCategorySerializer(read_only=True)
    member = SimpleUserSerializer(read_only=True)

    # 書込（write-only）
    site_id = serializers.PrimaryKeyRelatedField(
        queryset=Site.objects.none(), source="site", write_only=True
    )
    work_category_id = serializers.PrimaryKeyRelatedField(
        queryset=WorkCategory.objects.none(), source="work_category",
        write_only=True, required=False, allow_null=True
    )
    member_id = serializers.PrimaryKeyRelatedField(
        queryset=User.objects.none(), source="member", write_only=True
    )

    class Meta:
        model = TeamReportEntry
        fields = (
            "id",
            # read
            "site", "work_category", "member",
            # write
            "site_id", "work_category_id", "member_id",
            # core
            "start_time", "end_time", "note",
        )

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        req = self.context.get("request")
        if req and getattr(req.user, "company", None):
            company: Company = req.user.company
            self.fields["site_id"].queryset = Site.objects.filter(company=company)
            self.fields["work_category_id"].queryset = WorkCategory.objects.filter(company=company)
            self.fields["member_id"].queryset = User.objects.filter(company=company)

    def validate(self, data):
        # 完全一致(同時刻)はNG（0分）
        st = data.get("start_time")
        et = data.get("end_time")
        if st is not None and et is not None and st == et:
            raise serializers.ValidationError({"end_time": "開始と終了が同一は無効です。"})
        # ここで None を空文字へ寄せる（保険）
        data["note"] = (data.get("note") or "").strip()
        return data


# ========== TeamReport（ネスト） ==========
class TeamReportSerializer(_PermissionsMixin, serializers.ModelSerializer):
    team = SimpleTeamSerializer(read_only=True)
    team_id = serializers.PrimaryKeyRelatedField(
        queryset=Team.objects.none(), source="team", write_only=True
    )

    entries = TeamReportEntrySerializer(many=True)
    created_by = SimpleUserSerializer(read_only=True)

    permissions = serializers.SerializerMethodField(read_only=True)

    class Meta:
        model = TeamReport
        fields = (
            "id", "date", "status",
            "team", "team_id",
            "note",
            "created_by", "created_at", "submitted_at",
            "entries",
            "permissions",
        )
        read_only_fields = ("created_by", "created_at", "submitted_at", "permissions")

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        req = self.context.get("request")
        if req and getattr(req.user, "company", None):
            company: Company = req.user.company
            self.fields["team_id"].queryset = Team.objects.filter(company=company)
            # ネスト側の queryset も company で絞る
            child: TeamReportEntrySerializer = self.fields["entries"].child
            child.fields["site_id"].queryset = Site.objects.filter(company=company)
            child.fields["work_category_id"].queryset = WorkCategory.objects.filter(company=company)
            child.fields["member_id"].queryset = User.objects.filter(company=company)


    def get_permissions(self, obj):
        req = self.context.get("request")
        if not req or not hasattr(req, "user"):
            return {"can_view_detail": False, "can_delete": False}

        me = req.user
        if self._is_admin(me) or self._is_manager(me):
            return {"can_view_detail": True, "can_delete": True}

        # リーダーは「自分が leader のチーム」のみ可
        my_leader_team_ids = self._get_my_leader_team_ids(me)
        is_leader_of_this_team = obj.team_id in my_leader_team_ids
        return {
            "can_view_detail": bool(is_leader_of_this_team),
            "can_delete": bool(is_leader_of_this_team),
        }
    

    def validate(self, attrs):
        """
        追加バリデーション:
        - entries が 1件以上（既存維持）
        - Admin/Manager 以外は “自分が leader のチーム” だけ作成/更新可（既存維持）
        - 既存レポートの team を PATCH で付け替え不可（既存維持）
        - ※ entries の member は「会社内ユーザーなら誰でも可」に変更（= チーム所属チェックを撤廃）
        """
        req = self.context.get("request")
        if not req:
            return attrs

        # --- entries 必須（既存のチェックを維持） ---
        entries_initial = self.initial_data.get("entries", [])
        if self.instance is None or "entries" in self.initial_data:
            if not entries_initial:
                raise serializers.ValidationError({"entries": "1件以上の明細が必要です。"})

        user = req.user
        company: Company | None = getattr(user, "company", None)
        if not company:
            raise serializers.ValidationError({"detail": "会社が未設定のユーザーです。"})

        is_admin_or_manager: bool = (self._is_admin(user) or self._is_manager(user))

        # --- 対象チームの決定（create: attrs['team'] / update: 変更が無ければ instance.team） ---
        team_obj: Team | None = attrs.get("team")
        if self.instance is not None and team_obj is None:
            team_obj = self.instance.team
        if team_obj is None:
            raise serializers.ValidationError({"team_id": "チームは必須です。"})

        # --- PATCHで team の付け替えを禁止（既存維持） ---
        if self.instance is not None and "team" in attrs and team_obj.id != self.instance.team_id:
            raise serializers.ValidationError({"team_id": "既存日報のチームは変更できません。"})

        # --- 作成/更新権限（既存維持） ---
        if not is_admin_or_manager:
            is_leader_of_team = TeamMember.objects.filter(
                team_id=team_obj.id, user_id=user.id, role="leader", is_active=True
            ).exists()
            if not is_leader_of_team:
                raise serializers.ValidationError({"team_id": "このチームの日報を作成・更新する権限がありません。"})

        # --- （変更点）entries の member チェックを撤廃 ---
        # 以前は「当該チーム所属か」を検証していたが、会社内ユーザーなら誰でも可に変更。
        # 会社内ユーザー制約は TeamReportEntrySerializer 側の queryset で担保。

        if self.instance is None or "entries" in self.initial_data:
            entries_initial = self.initial_data.get("entries", [])
            def to_min(v):
                if isinstance(v, str):
                    t = parse_time(v)
                else:
                    t = v
                if t is None:
                    return None
                return t.hour * 60 + t.minute

            per_member = {}
            for i, e in enumerate(entries_initial):
                mid = e.get("member_id")
                if mid is None:
                    continue
                try:
                    mid = int(mid)
                except Exception:
                    continue
                st = to_min(e.get("start_time"))
                et = to_min(e.get("end_time"))
                if st is None or et is None:
                    continue
                per_member.setdefault(mid, []).append((st, et, i))

            errors = {}
            for _, arr in per_member.items():
                arr.sort(key=lambda x: x[0])
                prev_end = None
                prev_idx = None
                for st, et, idx in arr:
                    if prev_end is not None and st < prev_end:
                        msg = "同一メンバーの時間が重複しています。"
                        errors.setdefault(prev_idx, {}).setdefault("start_time", msg)
                        errors.setdefault(idx, {}).setdefault("start_time", msg)
                        break
                    prev_end = et
                    prev_idx = idx

            if errors:
                raise serializers.ValidationError({"entries": errors})

        return attrs

    @transaction.atomic
    def create(self, validated_data):
        entries_data = validated_data.pop("entries", [])
        req = self.context["request"]
        company: Company = req.user.company
        try:
            report = TeamReport.objects.create(
                company=company,
                created_by=req.user,
                **validated_data,
            )
        except IntegrityError:
            raise serializers.ValidationError({"date": "このチームの当日日報は既に存在します。"})
        self._replace_entries(report, entries_data)
        self._apply_status_side_effects(report, prev_status=None)
        return report

    @transaction.atomic
    def update(self, instance: TeamReport, validated_data):
        entries_data = validated_data.pop("entries", None)
        prev_status = instance.status

        # company/created_by は固定
        validated_data.pop("company", None)
        validated_data.pop("created_by", None)

        for k, v in validated_data.items():
            setattr(instance, k, v)
        instance.save()

        if entries_data is not None:
            self._replace_entries(instance, entries_data)

        self._apply_status_side_effects(instance, prev_status=prev_status)
        return instance

    def _replace_entries(self, report: TeamReport, entries_data: List[dict]):
        report.entries.all().delete()
        objs = [TeamReportEntry(report=report, **e) for e in entries_data]
        if objs:
            TeamReportEntry.objects.bulk_create(objs)

    def _apply_status_side_effects(self, report: TeamReport, prev_status: str | None):
        # status 遷移に伴う submitted_at の更新
        if report.status == ReportStatus.SUBMITTED and prev_status != ReportStatus.SUBMITTED:
            from django.utils import timezone as dj_tz
            report.submitted_at = dj_tz.now()
            report.save(update_fields=["submitted_at"])
        if report.status != ReportStatus.SUBMITTED and prev_status == ReportStatus.SUBMITTED:
            # 取り消し時は消す運用（必要なければ外す）
            report.submitted_at = None
            report.save(update_fields=["submitted_at"])



class GeneratePersonalFromTeamSerializer(serializers.Serializer):
    """
    入力:  team_report_id / replace_existing
    出力:  生成/更新した個人日報の概要

    仕様:
    - チーム日報に登場する全ユーザーが対象
    - 既存個人日報が
        * DRAFT ... replace_existing=True のときは entries を上書き、それ以外は触らない
        * PENDING / SUBMITTED / LOCKED ... 触らない（スキップ）
        * 無し ... 新規作成
    - 新規/更新の初期ステータス:
        * 作成者(created_by)のみ、チーム日報が SUBMITTED の場合は SUBMITTED（submitted_at 付与）
        * 作成者以外は DRAFT
    - entries 差し替えは “今回対象にするユーザーの個人日報” のみに限定
    """
    team_report_id = serializers.UUIDField()
    replace_existing = serializers.BooleanField(required=False, default=True)

    def save(self) -> Dict:
        req = self.context["request"]
        company: Company = req.user.company

        # ① チーム日報取得（会社スコープ）
        try:
            report = (
                TeamReport.objects
                .select_related("team", "created_by")
                .prefetch_related(
                    "entries__member",
                    "entries__site",
                    "entries__work_category",
                )
                .get(company=company, id=self.validated_data["team_report_id"])
            )
        except TeamReport.DoesNotExist:
            raise serializers.ValidationError({"team_report_id": "対象のチーム日報が見つかりません。"})

        # ② ユーザー集合（明細に登場するユーザー） ※会社所属に限定
        entries: List[TeamReportEntry] = list(report.entries.all())
        if not entries:
            return {"date": str(report.date), "team_id": str(report.team_id), "reports": [], "count_entries": 0}

        all_user_ids: Set[int] = {e.member_id for e in entries}
        users_all: List["CustomUser"] = list(User.objects.filter(id__in=all_user_ids, company=company))
        if not users_all:
            return {"date": str(report.date), "team_id": str(report.team_id), "reports": [], "count_entries": 0}

        # ③ 既存個人日報（当日分）
        personal_by_uid: Dict[int, PersonalReport] = {
            pr.user_id: pr
            for pr in PersonalReport.objects.filter(company=company, date=report.date, user__in=users_all)
        }

        creator_user_id: int = report.created_by_id

        # ④ 対象の振り分け
        replace_existing: bool = bool(self.validated_data.get("replace_existing", True))
        # 触る対象（新規 or 上書きする DRAFT）
        target_user_ids: Set[int] = set()
        to_create_users: List["CustomUser"] = []
        to_update_drafts: List[PersonalReport] = []

        for u in users_all:
            pr = personal_by_uid.get(u.id)
            if pr is None:
                # 未作成 → 生成対象
                to_create_users.append(u)
                target_user_ids.add(u.id)
            else:
                # 既存あり → ステータスで条件分岐
                if pr.status == ReportStatus.DRAFT:
                    if replace_existing:
                        to_update_drafts.append(pr)
                        target_user_ids.add(u.id)
                    # replace_existing=False の場合は触らない
                else:
                    # PENDING / SUBMITTED / LOCKED は触らない（スキップ）
                    pass

        # ⑤ 生成＆上書き
        with transaction.atomic():
            # --- 未作成ユーザー: 新規作成 ---
            for u in to_create_users:
                # 作成者のみ、チーム日報が SUBMITTED の場合に SUBMITTED
                initial_status = (
                    ReportStatus.SUBMITTED
                    if (u.id == creator_user_id and report.status == ReportStatus.SUBMITTED)
                    else ReportStatus.DRAFT
                )
                pr = PersonalReport.objects.create(
                    company=company,
                    user=u,
                    date=report.date,
                    status=initial_status,
                    submitted_at=(dj_tz.now() if initial_status == ReportStatus.SUBMITTED else None),
                    source_team_report=report,
                )
                personal_by_uid[u.id] = pr

            # --- 既存 DRAFT の上書き（replace_existing=True のときのみ）---
            # entries は一旦消してから再作成。source_team_report も紐付け（なければ付ける/更新する）
            if to_update_drafts:
                PersonalReportEntry.objects.filter(report__in=to_update_drafts).delete()
                # source_team_report を統一しておく（元々違う/空でも本チーム日報に合わせる）
                PersonalReport.objects.filter(id__in=[pr.id for pr in to_update_drafts]).update(
                    source_team_report=report
                )

            # --- entries 一括作成（今回触る人だけ）---
            entries_target: List[TeamReportEntry] = [
                te for te in entries if te.member_id in target_user_ids
            ]
            bulk_entries: List[PersonalReportEntry] = [
                PersonalReportEntry(
                    report=personal_by_uid[te.member_id],
                    site=te.site,
                    work_category=te.work_category,
                    start_time=te.start_time,
                    end_time=te.end_time,
                    note=te.note or "",
                )
                for te in entries_target
            ]
            if bulk_entries:
                PersonalReportEntry.objects.bulk_create(bulk_entries)

            # --- 作成者の PR を SUBMITTED に（チーム日報が SUBMITTED の場合のみ）---
            # ただし今回対象に含まれている（新規 or DRAFT上書き）場合のみ。既に PENDING/SUBMITTED/LOCKED は触らない。
            if report.status == ReportStatus.SUBMITTED and (creator_user_id in target_user_ids):
                pr_creator = personal_by_uid[creator_user_id]
                if pr_creator.status != ReportStatus.SUBMITTED:
                    now = dj_tz.now()
                    pr_creator.status = ReportStatus.SUBMITTED
                    pr_creator.submitted_at = now
                    pr_creator.save(update_fields=["status", "submitted_at"])

        # ⑥ レスポンス
        return {
            "date": str(report.date),
            "team_id": str(report.team_id),
            "reports": [
                {"user_id": u.id, "report_id": personal_by_uid[u.id].id}
                for u in users_all
                if u.id in target_user_ids  # 今回触った分だけ返す（必要なら全員に変更可）
            ],
            "count_entries": len(entries_target),
        }




class ClosingPreviewSerializer(serializers.Serializer):
    year_month = serializers.DateField(help_text="対象月の1日 (YYYY-MM-01)")
    period_start = serializers.DateField()
    period_end   = serializers.DateField()
    counts = serializers.DictField(child=serializers.IntegerField())  # {"draft":0,"pending":2,"submitted":10,"locked":50}
    pending = serializers.ListField(child=serializers.UUIDField(), required=False)   # 承認待ちPRのID
    drafts  = serializers.ListField(child=serializers.UUIDField(), required=False)   # 下書きPRのID
    already_closed = serializers.BooleanField()