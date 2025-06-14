from django.urls import path
from .views import SiteListCreateAPIView, SiteDetailAPIView

urlpatterns = [
    path('', SiteListCreateAPIView.as_view(), name='site-list-create'),
    path('<uuid:id>/', SiteDetailAPIView.as_view(), name='site-detail'),
]