from django.urls import path
from .views import WorkCategoryListCreateAPIView, MyMonthlyScheduleAPIView, WorkCategoryDestroyView, ScheduleDetailAPIView

urlpatterns = [
    path('work-categories/', WorkCategoryListCreateAPIView.as_view(), name='work-category-list-create'),
    path('work-categories/<int:pk>/', WorkCategoryDestroyView.as_view(), name='workcategory-delete'),
    path('my-monthly/', MyMonthlyScheduleAPIView.as_view(), name='my-monthly-schedule'),
    path('<uuid:pk>/',   ScheduleDetailAPIView.as_view(),   name='schedule-detail'),
]