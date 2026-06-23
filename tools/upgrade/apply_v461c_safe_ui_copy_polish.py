from pathlib import Path
import shutil
import datetime

ROOT = Path(r"D:\body_battery")
MAIN = ROOT / "lib" / "main.dart"
GITIGNORE = ROOT / ".gitignore"

backup_root = ROOT / "_backups" / ("v461c_safe_ui_copy_" + datetime.datetime.now().strftime("%Y%m%d_%H%M%S"))
backup_root.mkdir(parents=True, exist_ok=True)

shutil.copy2(MAIN, backup_root / "main.dart.bak")

text = MAIN.read_text(encoding="utf-8-sig")

safe_replacements = {
    "Runtime V3: đọc engine JSON, chấm điểm thật, lưu lịch sử trong máy và đọc xu hướng hồi/suy giảm.":
    "Check-in nhanh mỗi ngày để nhìn mức hao mòn, khả năng hồi phục và xu hướng cơ thể của bạn.",

    "_SoftChip(text: 'Quan sát ${runtime.observationRules.length} luật'),":
    "_SoftChip(text: '${runtime.observationRules.length} câu quan sát'),",

    "_SoftChip(text: 'Trục ${runtime.nodeRules.length} luật'),":
    "_SoftChip(text: '${runtime.nodeRules.length} trục theo dõi'),",

    "text: 'Full ${questions.length} câu',":
    "text: 'Đầy đủ ${questions.length} câu',",

    "text: 'Full 32 câu',":
    "text: 'Đầy đủ 32 câu',",

    "Node là gì?":
    "Trục là gì?",

    "Node là các trục chính của hệ: nạp, chuyển hóa, dự trữ, tải, phục hồi, thích nghi, hao mòn và mất kiểm soát. Node nào điểm cao hơn thì node đó đang góp phần kéo hệ lệch nhiều hơn.":
    "Trục là các nhóm tín hiệu chính của hệ: nạp, chuyển hóa, dự trữ, tải, phục hồi, thích nghi, hao mòn và mất kiểm soát. Trục nào điểm cao hơn thì trục đó đang góp phần kéo hệ lệch nhiều hơn.",

    "Điểm nghẽn chính":
    "Các điểm nghẽn chính",

    "Diễn giải lấy từ meaning_engine.json.":
    "Các trục đang góp phần kéo mức hao mòn lên.",

    "Khuyến nghị lấy từ recommendation_engine.json.":
    "Chọn 1–2 việc nhỏ, dễ làm ngay hôm nay."
}

changed = []

for old, new in safe_replacements.items():
    if old in text:
        text = text.replace(old, new)
        changed.append(old)

MAIN.write_text(text, encoding="utf-8")

gitignore = GITIGNORE.read_text(encoding="utf-8-sig")

if "play_assets/screenshots/raw/" not in gitignore:
    gitignore = gitignore.rstrip() + "\n\n# Raw local screenshots\nplay_assets/screenshots/raw/\n"
    GITIGNORE.write_text(gitignore, encoding="utf-8")
    changed.append("gitignore raw screenshots")

print("PATCH V4.6.1C SAFE DONE")
print("BACKUP:", backup_root)
print("CHANGED ITEMS:")
for item in changed:
    print("-", item)
