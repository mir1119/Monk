# Monk

幫助一般人減少 screen time、擺脫 doom scrolling 的 iOS 自我提升 App，靈感來自 Monk Mode。

## Language

**Monk Mode**:
一種像僧侶般嚴格限制 dopamine 攝入的生活方式，本專案以此為靈感但 MVP 先服務一般人，之後再提供 Hardcore 開關。
_Avoid_: monk mode, hard monk mode

**Dopamine Detox**:
刻意減少高刺激、易成癮行為（尤其是 social media 與無目的瀏覽）以恢復專注與自控的過程。
_Avoid_: digital detox

**Doom Scrolling**:
無目的、連續地下滑瀏覽短影音/社群/新聞的行為，初期以「單次連續使用時長」與「每日總時長」兩個閾值來代理判定。
_Avoid_: infinite scroll, mindless browsing

**Screen Time**:
使用者在被追蹤 App 上花費的時間，為本 App 唯一核心指標。
_Avoid_: usage time, phone time

**Tracked App**:
被使用者選為限制對象的 App，包含預設社群清單與使用者自訂的任意 App。
_Avoid_: monitored app, limited app

**Limit**:
對單一 Tracked App 設定的每日總量上限與單次連續使用上限，兩者皆可觸發阻擋。
_Avoid_: quota, cap

**Hard Block / Cooldown**:
達到 Limit 後的強制阻擋，單次超時需冷卻 1 小時才能再次開啟，與柔性提醒區隔。
_Avoid_: soft block, nudge

**Free Time**:
相較於基準期（使用 App 前或上週）所省下的 Screen Time，作為正向回饋呈現給使用者。
_Avoid_: saved time, recovered time

**Baseline**:
用於計算 Free Time 的對照基準，MVP 以 onboarding 使用者自填的每日使用量為初始基準，並以滾動上週為對照。
_Avoid_: benchmark, reference

**Onboarding**:
新使用者流程：解釋 Monk Mode → 自填各 Tracked App 每日使用量並試算年化浪費 → 選 preset/自訂 Limit → 直接開始。
_Avoid_: setup, tutorial

**Wasted Time (Annualized)**:
Onboarding 依 `(每日使用量 - Limit) × 365` 計算單一 App 的年化超額浪費，用於製造痛點。
_Avoid_: wasted hours, yearly waste

**Emergency Unlock**:
每日一次、5 分鐘的緊急解鎖，用於避免 Hard Block 卡死重要使用。
_Avoid_: bypass, override

**Daily Reset**:
每日總量 Limit 的歸零時點，預設 00:00，可由使用者改為 04:00/05:00。
_Avoid_: midnight reset
