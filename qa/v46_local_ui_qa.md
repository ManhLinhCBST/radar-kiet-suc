RADAR KIỆT SỨC — V4.6.1 LOCAL UI QA

DATE=2026-06-23 14:24:43
PACKAGE=vn.mlcbst.radarkietsuc
VERSION=1.0.0+1
BUILD=debug local
AAB_READY=YES
PRIVACY_URL=https://ManhLinhCBST.github.io/radar-kiet-suc/privacy-policy.html

CORE TESTS:
[x] Fresh install OK
[x] App launch OK
[x] Main check-in screen OK
[x] Quick check-in OK
[x] Full 32-question check-in OK
[x] Result screen OK
[x] Recommendation screen OK
[x] History screen OK
[x] Demo 3-day data OK
[x] Export JSON OK
[x] Help page OK
[x] Privacy page OK
[x] Back navigation OK
[x] No crash observed
[x] No major overflow observed
[x] No medical overclaim observed
[x] Screenshots captured

COPY FIXES V4.6.1:
[x] Removed Runtime V3 wording
[x] Removed engine JSON wording from user-facing UI
[x] Replaced Node wording with Trục wording
[x] Removed meaning_engine.json wording
[x] Removed recommendation_engine.json wording
[x] Preserved Dart runtime identifiers AppRuntime / RuntimeResult / RuntimeAction
[x] Rebuilt release AAB after copy polish

NOTES:
- UI đủ ổn cho Internal Testing sau khi Play Console mở khóa tài khoản.
- Store screenshots cần chụp lại từ bản V4.6.1.
- Raw screenshots local không đưa lên Git.
