import logging

logger = logging.getLogger(__name__)

def register_event(actor, verb, target, extra=None):
    """
    監査ログや通知用の簡易フック。
    本番では DB テーブル + Celery 送信などに差し替え。
    """
    logger.info(
        "[AUDIT] %s %s (%s) extra=%s",
        actor, verb, target, extra or {},
    )
