from django.urls import path
from .views import CompanyCreateAPIView
from .views import InviteCodeCreateView
from .views import JoinCompanyView

urlpatterns = [
    path('create/', CompanyCreateAPIView.as_view(), name='company-create'),
    path('invite/', InviteCodeCreateView.as_view(), name='invite-code'),
    path('join/', JoinCompanyView.as_view(), name='join-company'),
]
