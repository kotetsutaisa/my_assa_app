# reports/utils/closing.py
from __future__ import annotations
from dataclasses import dataclass
from datetime import date, timedelta
import calendar

@dataclass(frozen=True)
class ClosingWindow:
    start: date   # 期間開始（含む）
    end: date     # 期間終了（含む）
    label_month: date  # 表示用に「この月の締め」（1日）

def _month_end(y: int, m: int) -> date:
    last = calendar.monthrange(y, m)[1]
    return date(y, m, last)

def _prev_month(d: date) -> date:
    y, m = d.year, d.month
    if m == 1:
        return date(y-1, 12, 1)
    return date(y, m-1, 1)

def _next_month(d: date) -> date:
    y, m = d.year, d.month
    if m == 12:
        return date(y+1, 1, 1)
    return date(y, m+1, 1)

def calc_closing_window(year_month: date, closing_day: int) -> ClosingWindow:
    """
    year_month: 対象“締め月”の1日（例: 2025-07-01）
    closing_day: 0=月末, 1〜28
    例: closing_day=15, year_month=2025-07-01 → 対象期間は 2025-06-16〜2025-07-15
    """
    ym_first = date(year_month.year, year_month.month, 1)
    ym_end   = _month_end(ym_first.year, ym_first.month)

    # end（締め日）
    if closing_day == 0:
        end = ym_end
    else:
        # その月に closing_day は必ず存在（1〜28）する
        end = date(ym_first.year, ym_first.month, closing_day)

    # start（前月の締め翌日）
    prev_first = _prev_month(ym_first)
    prev_end   = _month_end(prev_first.year, prev_first.month)

    if closing_day == 0:
        start = date(ym_first.year, ym_first.month, 1)  # 当月1日〜月末
    else:
        start = date(prev_first.year, prev_first.month, closing_day) + timedelta(days=1)

    return ClosingWindow(start=start, end=end, label_month=ym_first)
