#!/usr/bin/env python3
"""scan_feedback.py — 扫描客户反馈目录 $EVOFLOW_MEDIA_WS/feedback/，输出结构化摘要

用法：
    python3 scan_feedback.py
    python3 scan_feedback.py --since 2026-06-01

行为：
- 读 $EVOFLOW_MEDIA_WS/feedback/*.md（EVOFLOW_MEDIA_WS 未设置时 fail-fast 退出）
- 统计反馈条目数、按日期分布、高频关键词
- 输出 JSON 到 stdout

退出码：
  0  成功（含无反馈）
  1  EVOFLOW_MEDIA_WS 未设置，或指向的目录不存在
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
from collections import Counter
from datetime import datetime
from pathlib import Path

MEDIA_WS = os.environ.get("EVOFLOW_MEDIA_WS")
if not MEDIA_WS:
    sys.stderr.write(
        "error: EVOFLOW_MEDIA_WS is not set（请先 export EVOFLOW_MEDIA_WS，如 E:/xiaobei-data/workspace-main）\n"
    )
    raise SystemExit(1)
MEDIA_WS_PATH = Path(MEDIA_WS)
FEEDBACK_DIR = MEDIA_WS_PATH / "feedback"

ENTRY_RE = re.compile(r"^##\s+Feedback\s*:?\s*(.*)$", re.MULTILINE)
DATE_RE = re.compile(r"(\d{4}-\d{2}-\d{2})")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--since", help="只统计此日期之后（YYYY-MM-DD）")
    args = ap.parse_args()

    if not MEDIA_WS_PATH.exists():
        sys.stderr.write(f"error: EVOFLOW_MEDIA_WS 指向的目录不存在：{MEDIA_WS_PATH}\n")
        return 1

    if not FEEDBACK_DIR.exists():
        sys.stdout.write(json.dumps({
            "feedback_dir": str(FEEDBACK_DIR),
            "total": 0,
            "files": [],
            "note": "feedback 目录不存在，尚无客户反馈",
        }, ensure_ascii=False, indent=2))
        sys.stdout.write("\n")
        return 0

    files = sorted(FEEDBACK_DIR.glob("*.md"))
    since = args.since
    entries = []
    keyword_counter: Counter[str] = Counter()

    for f in files:
        text = f.read_text(encoding="utf-8", errors="replace")
        # 文件名日期回退
        m_date = DATE_RE.search(f.name)
        file_date = m_date.group(1) if m_date else None
        if since and file_date and file_date < since:
            continue
        matches = ENTRY_RE.findall(text)
        for title in matches:
            entries.append({"file": f.name, "date": file_date, "title": title.strip()})
        # 粗关键词：投诉/退款/价格/试用/开票等
        for kw in ["投诉", "退款", "价格", "试用", "开票", "人工", "不满", "bug", "无法"]:
            if kw in text:
                keyword_counter[kw] += text.count(kw)

    summary = {
        "feedback_dir": str(FEEDBACK_DIR),
        "total": len(entries),
        "files": [f.name for f in files],
        "keywords": dict(keyword_counter.most_common(10)),
        "entries": entries,
    }
    sys.stdout.write(json.dumps(summary, ensure_ascii=False, indent=2))
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
