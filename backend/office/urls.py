# office/urls.py
from django.urls import path
from .views import (
    CompanyPayrollPolicyView,
    WageContractListCreateAPIView,
    WageContractDetailAPIView,
    EmployeeWithContractListAPIView,
    EmployeeDetailAPIView,
)

app_name = "office"

urlpatterns = [
    # 会社ポリシー（GET/PUT）
    path("payroll/policy/", CompanyPayrollPolicyView.as_view(), name="payroll-policy"),

    # 契約（一覧/作成, 詳細/更新）
    path("payroll/contracts/", WageContractListCreateAPIView.as_view(), name="wagecontract-list-create"),
    path("payroll/contracts/<int:pk>/", WageContractDetailAPIView.as_view(), name="wagecontract-detail"),

    # 従業員（一覧, 詳細サマリー）
    path("employees/", EmployeeWithContractListAPIView.as_view(), name="employee-list"),
    path("employees/<int:user_id>/", EmployeeDetailAPIView.as_view(), name="employee-detail"),
]
