from pathlib import Path
import re

root = Path(r"D:\body_battery")
main = root / "lib" / "main.dart"
pubspec = root / "pubspec.yaml"

text = main.read_text(encoding="utf-8")

# 1) Xóa các nút / text demo dễ thấy
replacements = {
    "Lịch sử 3 ngày": "Lịch sử",
    "Tạo lịch sử 3 ngày": "Lịch sử",
    "Seed demo 3 ngày": "Lịch sử",
    "Demo 3 ngày": "Lịch sử",
    "demo history": "history",
    "Demo history": "History",
}

for a, b in replacements.items():
    text = text.replace(a, b)

# 2) Xóa button gọi _seedDemoHistory nếu có dạng callback đơn giản
patterns = [
    r"\s*TextButton\.icon\(\s*onPressed:\s*_seedDemoHistory,[\s\S]*?\),\s*",
    r"\s*FilledButton\.icon\(\s*onPressed:\s*_seedDemoHistory,[\s\S]*?\),\s*",
    r"\s*OutlinedButton\.icon\(\s*onPressed:\s*_seedDemoHistory,[\s\S]*?\),\s*",
    r"\s*IconButton\(\s*onPressed:\s*_seedDemoHistory,[\s\S]*?\),\s*",
]

for p in patterns:
    text = re.sub(p, "\n", text)

# 3) Xóa hàm _seedDemoHistory nếu hàm độc lập async có body cân bằng đơn giản
marker = "Future<void> _seedDemoHistory"
idx = text.find(marker)

if idx != -1:
    start = idx
    brace = text.find("{", start)
    if brace != -1:
        depth = 0
        end = None
        for i in range(brace, len(text)):
            if text[i] == "{":
                depth += 1
            elif text[i] == "}":
                depth -= 1
                if depth == 0:
                    end = i + 1
                    break
        if end:
            # ăn thêm newline sau hàm
            while end < len(text) and text[end] in "\r\n":
                end += 1
            text = text[:start] + text[end:]

# 4) Xóa các dòng comment rõ demo/test nếu chỉ là UI demo
lines = []
for line in text.splitlines():
    lower = line.lower()
    if "seed demo" in lower:
        continue
    if "demo history" in lower:
        continue
    if "lịch sử 3 ngày" in lower:
        continue
    lines.append(line)

text = "\n".join(lines) + "\n"
main.write_text(text, encoding="utf-8")

# 5) Tăng version Play: versionName 1.0.1, versionCode 2
ptext = pubspec.read_text(encoding="utf-8")
ptext = re.sub(r"^version:\s*.*$", "version: 1.0.1+2", ptext, flags=re.MULTILINE)
pubspec.write_text(ptext, encoding="utf-8")

print("V4.10.1 demo history UI removed and version bumped to 1.0.1+2")
