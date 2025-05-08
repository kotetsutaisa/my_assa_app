from rest_framework.throttling import UserRateThrottle

class CompanyCreateThrottle(UserRateThrottle):
    """
    1ユーザーが短時間で大量に Company を作れないよう制限。
    settings.py で 'company_create': '3/hour' のように設定。
    """
    scope = "company_create"
