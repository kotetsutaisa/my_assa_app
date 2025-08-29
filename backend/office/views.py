from django.db.models import Q, Subquery, OuterRef, Case, When, Value, IntegerField, F
from rest_framework import generics, permissions
from rest_framework.views import APIView
from rest_framework.response import Response
from django.db.models.functions import Lower
from rest_framework.exceptions import NotFound
from django.utils import timezone as dj_tz

from companies.models import Company
from timeline.permissions import IsCompanyMember  # 既存プロジェクトに合わせる
from .permissions import IsAdminOrClerk
from .models import CompanyPayrollPolicy, WageContract
from users.serializers import SimpleUserSerializer
from .serializers import (
    CompanyPayrollPolicySerializer, WageContractSerializer,
    EmployeeWithContractListItemSerializer, EmployeeDetailSummarySerializer
)
from django.contrib.auth import get_user_model
User = get_user_model()

class CompanyPayrollPolicyView(generics.RetrieveUpdateAPIView):
    """
    GET/PUT /api/office/payroll/policy/
    会社ごとに 1 レコード。存在しなければ初回 GET で自動作成。
    """
    serializer_class   = CompanyPayrollPolicySerializer
    permission_classes = [permissions.IsAuthenticated, IsCompanyMember, IsAdminOrClerk]

    def get_object(self):
        company: Company = self.request.user.company
        if not company:
            raise NotFound("会社が設定されていません。")
        obj, _created = CompanyPayrollPolicy.objects.get_or_create(company=company)
        return obj


class WageContractListCreateAPIView(generics.ListCreateAPIView):
    """
    GET/POST /api/office/payroll/contracts/
      - 会社内の契約一覧
      - 追加: ?user_id=<int> で特定ユーザーの契約だけに絞り込み
              ?user_id=me     も許可（自分のIDに解決）
    """
    serializer_class   = WageContractSerializer
    permission_classes = [permissions.IsAuthenticated, IsCompanyMember, IsAdminOrClerk]

    def get_queryset(self):
        company_id = self.request.user.company_id
        qs = (WageContract.objects
              .filter(company_id=company_id)
              .select_related("user", "company")
              .order_by("-effective_from", "-id"))

        user_id = self.request.query_params.get("user_id")
        if user_id:
            if user_id == "me":
                user_id = str(self.request.user.id)
            # 数値以外は無視して404にせず全体返却でも良いが、厳密に行くなら変換失敗時に0等でヒットしないようにする
            try:
                uid = int(user_id)
                qs = qs.filter(user_id=uid)
            except (TypeError, ValueError):
                qs = qs.none()

        return qs

    def get_serializer_context(self):
        ctx = super().get_serializer_context()
        ctx["request"] = self.request
        return ctx


class WageContractDetailAPIView(generics.RetrieveUpdateDestroyAPIView):
    """
    GET/PATCH /api/office/payroll/contracts/<int:pk>/
    """
    serializer_class   = WageContractSerializer
    permission_classes = [permissions.IsAuthenticated, IsCompanyMember, IsAdminOrClerk]

    def get_queryset(self):
        company: Company = self.request.user.company
        return WageContract.objects.filter(company=company).select_related("user", "company")

    def get_serializer_context(self):
        ctx = super().get_serializer_context()
        ctx["request"] = self.request
        return ctx


class EmployeeWithContractListAPIView(generics.ListAPIView):
    serializer_class = EmployeeWithContractListItemSerializer
    permission_classes = [permissions.IsAuthenticated, IsCompanyMember, IsAdminOrClerk]

    def get_queryset(self):
        me = self.request.user

        # まず必要最小限の列だけ確保（SimpleUserSerializerに合わせて調整）
        qs = (
            User.objects
            .filter(company_id=me.company_id, is_active=True)
            .only("id", "username", "email", "account_id", "role", "iconimg")  # ←必要に応じて調整
        )

        # 役職の手動ランク
        role_rank = Case(
            When(role="admin",   then=Value(0)),
            When(role="clerk",   then=Value(1)),
            When(role="manager", then=Value(2)),
            When(role="member",  then=Value(3)),
            default=Value(9),
            output_field=IntegerField(),
        )

        # “有効”＝ today 時点で効力がある契約:  [effective_from <= today] かつ [effective_to is null or >= today]
        today = dj_tz.localdate()
        latest_contract = (
            WageContract.objects
            .filter(company_id=me.company_id, user_id=OuterRef("pk"))
            .filter(effective_from__lte=today)
            .filter(Q(effective_to__isnull=True) | Q(effective_to__gte=today))
            .order_by("-effective_from", "-updated_at")
        )

        qs = qs.annotate(
            role_rank=role_rank,
            contract_pay_type       = Subquery(latest_contract.values("pay_type")[:1]),
            contract_hourly_wage    = Subquery(latest_contract.values("hourly_wage")[:1]),
            contract_daily_wage     = Subquery(latest_contract.values("daily_wage")[:1]),
            contract_monthly_salary = Subquery(latest_contract.values("monthly_salary")[:1]),
            contract_updated_at     = Subquery(latest_contract.values("updated_at")[:1]),
            username_lower          = Lower("username"),
        )

        # 検索（半角/全角スペースを区切りに AND 検索）
        q = (self.request.query_params.get("q") or "").strip()
        if q:
            terms = [t for t in q.replace("　", " ").split(" ") if t]
            for t in terms:
                qs = qs.filter(
                    Q(username__icontains=t) |
                    Q(account_id__icontains=t) |
                    Q(email__icontains=t)
                )

        # 並び順（ホワイトリスト）
        ordering = (self.request.query_params.get("ordering") or "").strip()
        ORDER_MAP = {
            "username"     : ("role_rank", "username_lower", "id"),
            "-username"    : ("role_rank", "-username_lower", "id"),
            "updated_at"   : (F("contract_updated_at").asc(nulls_last=True), "role_rank", "username_lower", "id"),
            "-updated_at"  : (F("contract_updated_at").desc(nulls_last=True), "role_rank", "username_lower", "id"),
        }
        if ordering in ORDER_MAP:
            qs = qs.order_by(*ORDER_MAP[ordering])
        else:
            # デフォルト：役職 → 名前（lower）→ id
            qs = qs.order_by("role_rank", "username_lower", "id")

        return qs
    


class EmployeeDetailAPIView(APIView):
    """
    GET /api/office/employees/<int:user_id>/
      - 特定ユーザーの詳細サマリー
    """
    permission_classes = [permissions.IsAuthenticated, IsCompanyMember, IsAdminOrClerk]

    def get(self, request, user_id: int):
        me = request.user
        if not me.company_id:
            raise NotFound("会社が設定されていません。")

        # 同一会社内のユーザーのみ
        try:
            user = User.objects.get(id=user_id, company_id=me.company_id, is_active=True)
        except User.DoesNotExist:
            raise NotFound("ユーザーが見つかりません。")

        today = dj_tz.localdate()
        current_contract = (
            WageContract.objects
            .filter(company_id=me.company_id, user_id=user.id)
            .filter(effective_from__lte=today)
            .filter(Q(effective_to__isnull=True) | Q(effective_to__gte=today))
            .order_by("-effective_from", "-updated_at", "-id")
            .first()
        )

        user_data = SimpleUserSerializer(user, context={"request": request}).data
        contract_data = WageContractSerializer(current_contract).data if current_contract else None

        payload = {
            "user": user,
            "current_contract": current_contract,
            "updated_at": getattr(current_contract, "updated_at", None),
        }
        serializer = EmployeeDetailSummarySerializer(payload, context={"request": request})
        return Response(serializer.data)

