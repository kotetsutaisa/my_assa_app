# resources/urls.py
from django.urls import path
from .views import ResourceListCreateAPIView, ResourceDetailAPIView

urlpatterns = [
    path('', ResourceListCreateAPIView.as_view(), name='resource-list-create'),
    path('<uuid:pk>/', ResourceDetailAPIView.as_view(), name='resource-detail'),
]
