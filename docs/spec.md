# Spec: Monk V1 — Screen Time 減少與 Doom Scrolling 阻擋

## Problem Statement

使用者想減少在 Social Media 與 Doom Scrolling 上浪費的 Screen Time，但缺乏可信的追蹤、明確的 Limit 與有效的阻擋機制。現有工具多為 soft nudge 或 streak 遊戲化，斷掉後挫折棄用，對重度使用者無效；使用者也難以感知「省下了多少 Free Time」，缺乏正向回饋與痛點。

## Solution

提供 iOS 優先的 Monk App，聚焦於 Tracked App（預設社群清單 + 使用者自訂任意 App）的 Screen Time 管理。核心為 Onboarding 自填每日使用量並以 `(每日使用量 - Limit) × 365` 試算年化 Wasted Time 製造痛點、為每個 Tracked App 設定每日總量 + 單次連續雙 Limit、達到 Limit 時採 Hard Block + Cooldown（單次→1hr 冷卻，每日→鎖到 Daily Reset），每日一次 5 分鐘 Emergency Unlock，首頁以 Free Time（vs 初始 Baseline 與 vs 上週）與今日剩餘環狀、7 天趨勢作為非懲罰性回饋。資料完全本地儲存，無帳號。

## User Stories

1. 作為新使用者，我想要在 Onboarding 看到對 Monk Mode 的簡短解釋，以便理解 App 的理念再開始。
2. 作為新使用者，我想要自填各 Tracked App 的每日使用量，以便建立初始 Baseline。
3. 作為新使用者，我想要看到基於 `（每日使用量 - Limit）× 365` 的年化 Wasted Time 試算，以便感知一年浪費了多少時間而產生改變動機。
4. 作為新使用者，我想要從預設社群清單（IG/TikTok/X/Threads/YouTube Shorts/Reddit/Facebook）勾選要管的 App，以便快速開始。
5. 作為新使用者，我想要額外自訂 1 至多個任意 App 加入 Tracked App，以便限制我個人的特定成癮來源。
6. 作為新使用者，我想要為每個 Tracked App 選擇 Limit preset（輕量 60/20、標準 30/15、嚴格 15/10，單位分鐘，分別為每日總量/單次連續），以便不用從零決定數字。
7. 作為新使用者，我想要在 preset 之外自訂每日總量與單次連續的分鐘數，以便符合個人需求。
8. 作為使用者，我想要在首頁看到本週 Free Time 總量，以便知道省下了多少時間。
9. 作為使用者，我想要在首頁同時看到 Free Time vs 初始 Baseline 與 vs 上週的對比，以便感知長期與近期的進步。
10. 作為使用者，我想要在首頁看到每個 Tracked App 今日剩餘額度的環狀進度，以便一秒判斷今天還能用多久。
11. 作為使用者，我想要在首頁看到過去 7 天的 Screen Time 長條對比，以便掌握趨勢。
12. 作為使用者，我想要當單次連續使用達到 Limit 時被 Hard Block 並進入 1 小時 Cooldown，以便有效中斷 Doom Scrolling。
13. 作為使用者，我想要在單次 Cooldown 期間看到全螢幕阻擋頁與倒數計時，以便明確知道何時可再使用。
14. 作為使用者，我想要在阻擋頁看到替代行動建議（散步、深呼吸 1 分鐘、查看待辦），以便把衝動轉向正向行為。
15. 作為使用者，我想要當每日總量達到 Limit 時被鎖到隔天 Daily Reset，以便限制全天過度使用。
16. 作為使用者，我想要每日有一次 5 分鐘 Emergency Unlock，以便在被鎖期間處理真正重要的訊息或工作。
17. 作為使用者，我想要清楚看到 Emergency Unlock 今日剩餘次數與使用後剩餘時間，以便謹慎使用。
18. 作為使用者，我想要在達到每日總量 80% 時收到提醒，以便提前自我調節。
19. 作為使用者，我想要在單次連續即將觸發 Cooldown 前 2 分鐘收到預警，以便有機會主動停下。
20. 作為使用者，我想要在每日晚間收到總結通知，告知今日省下的 Free Time，以便獲得正向回饋。
21. 作為使用者，我想要設定 Daily Reset 時點（預設 00:00，可改 04:00/05:00），以便符合熬夜作息。
22. 作為使用者，我想要在設定中隨時調整任一 Tracked App 的每日總量與單次連續 Limit，以便隨進步收緊或放鬆。
23. 作為使用者，我想要在設定中新增或移除 Tracked App，以便動態管理想限制的對象。
24. 作為使用者，我想要授權 FamilyControls/DeviceActivity 後獲得真實系統級 Screen Time 與阻擋，以便阻擋可信有效。
25. 作為使用者，當我未授權系統權限時，我想要降級為本地計時 + 提醒的自律模式仍可使用 App，以便不因權限卡死而無法開始。
26. 作為使用者，我想要在 Onboarding 與初次觸發阻擋時被清楚告知需要授權什麼與為什麼，以便安心授予權限。
27. 作為使用者，我想要所有 Screen Time 資料僅儲存在本地、無需帳號，以便隱私獲得保障。
28. 作為使用者，我想要在未達 Limit 時正常使用 Tracked App 完全不受干擾，以便 App 不會過度打擾日常生活。
29. 作為使用者，我想要在跨日後看到每日總量已按 Daily Reset 自動歸零，以便新的一天重新計算。
30. 作為使用者，我想要在 Cooldown 結束後自動恢復可用而無需手動操作，以便體驗流暢。
31. 作為使用者，我想要在 Emergency Unlock 的 5 分鐘結束後自動恢復阻擋狀態，以便不會意外無限使用。
32. 作為使用者，我想要在首頁區分「今日已達每日總量」與「單次 Cooldown 中」兩種阻擋狀態，以便理解為何被擋。
33. 作為使用者，我想要在 Onboarding 完成後立即開始追蹤與阻擋而無需等待多天 Baseline 期，以便立即獲得回饋。
34. 作為使用者，我想要在通知不過量的前提下（僅 3 種）保持專注，以便通知本身不成為另一種干擾。
35. 作為未來使用者，我想要在 V1 之後可選擇開啟 Hardcore Monk Mode 取得更嚴格限制，以便進階挑戰。

## Implementation Decisions

- **平台與技術**：iOS 優先，SwiftUI 為主；有授權時使用 FamilyControls / DeviceActivity + ManagedSettings 做真實 Screen Time 讀取與 Hard Block，無授權時降級為 App 內本地計時 + 本地通知提醒的自律模式。
- **模組拆分**：
  - Onboarding 與 Baseline/Wasted Time 計算模組：負責解釋 Monk Mode、自填每日使用量、`（每日量 - Limit）× 365` 年化計算、preset 選擇。
  - Tracked App 與 Limit 管理模組：維護 Tracked App 清單（預設 + 自訂）與每個 App 的雙 Limit（每日總量、單次連續），支援三檔 preset 與自訂分鐘數。
  - Usage Tracking Adapter 模組：抽象系統數據與本地降級，統一對外提供各 Tracked App 的今日已用與單次連續已用時長。
  - Limit Enforcement / Block Engine 模組：純邏輯核心，根據使用時長、Limit、Cooldown 剩餘、Emergency Unlock 狀態、Daily Reset 時點決定是否阻擋與阻擋類型。
  - Cooldown 與 Emergency Unlock 狀態機：單次超時→1hr Cooldown，每日超時→鎖到 Daily Reset；Emergency Unlock 每日 1 次、每次 5 分鐘，狀態需跨重啟持久化。
  - Dashboard 與 Free Time 計算模組：聚合今日剩餘、7 天趨勢、本週 Free Time（vs 初始 Baseline 與 vs 上週滾動 Baseline）。
  - Notification 排程模組：僅三種通知 — 80% 達量、單次即將 Cooldown 前 2 分鐘預警、每日晚間 Free Time 總結。
  - Settings 與 Daily Reset 模組：管理 Daily Reset 時點（00:00 預設，可改 04:00/05:00）與所有 Limit/Tracked App 編輯。
  - Local Persistence 模組：所有資料本地儲存，無帳號；後續再考慮 iCloud 同步。
- **關鍵互動**：
  - Onboarding 完成即寫入初始 Baseline，Dashboard 的 Free Time 同時計算 vs 初始 Baseline 與 vs 上週。
  - 達到單次連續 Limit 立即觸發 Cooldown 阻擋頁（倒數 + 替代行動 + Emergency Unlock 入口）；達到每日總量 Limit 鎖到下一次 Daily Reset。
  - Cooldown 與 Emergency Unlock 計時需在背景與重啟後仍正確恢復。
- **架構決策**：遵循 ADR 0001，採用 Hard Block + Free Time 而非 streak/soft nudge；通知節制以避免本身成為干擾。
- **權限與降級**：首次需要阻擋時請求 FamilyControls 授權，拒絕則自動降級且不阻斷主流程，UI 明確標示當前為「系統級」或「自律」模式。

## Testing Decisions

- **什麼是好測試**：只測外部可觀察行為，不測實作細節；從使用者與系統可見的輸入/輸出驗證，不綁定 SwiftUI 佈局或內部私有方法。
- **哪些模組要測**：
  - Limit Enforcement / Block Engine：給定使用時長、Limit、Cooldown、Emergency Unlock、Daily Reset 的組合，斷言是否阻擋與阻擋類型。
  - Cooldown 與 Emergency Unlock 狀態機：單次→1hr、日總量→到重置、每日 1 次 5 分鐘的邊界與跨日重置、計時到期自動恢復。
  - Free Time 與 Wasted Time 計算：`（每日量 - Limit）× 365`、本週 Free Time vs 初始 Baseline 與 vs 上週的聚合。
  - Usage Tracking Adapter：系統數據可用與降級路徑的行為一致性（不測 Apple 框架本身，測轉接邏輯）。
  - Notification 排程：80%、預警、晚間總結的觸發條件。
  - Onboarding 與 Settings 的輸入驗證與持久化。
- **Prior art**：本 repo 為 greenfield，無既有測試可參考；以純邏輯單元測試 + 狀態機測試為主，UI 僅測關鍵流程的行為測試。

## Out of Scope

- 帳號/雲端同步（V1 僅本地，後續再考慮 iCloud 同步）。
- 社群、排行榜、分享。
- AI 建議或自動 Limit 調整。
- Hardcore Monk Mode 開關（V1 後增量）。
- Android / Web 版本。
- 複雜的滑動/滾動手勢偵測來判定 Doom Scrolling（V1 僅用雙閾值代理）。
- 複雜的 Screen Time 儀表板以外的數據維度。

## Further Notes

- 隱私為賣點，V1 無帳號、無雲端，文案需明確傳達。
- 基於自填的 Baseline 與 Wasted Time 依賴誠實度，後續可在取得真實數據後提供校正提示，但不強迫。
- Daily Reset、Cooldown、Emergency Unlock 的時區與跨日邊界需特別注意。
- 用語以 `CONTEXT.md` 為準（Monk Mode / Dopamine Detox / Doom Scrolling / Screen Time / Tracked App / Limit / Hard Block / Cooldown / Free Time / Baseline / Wasted Time / Emergency Unlock / Daily Reset）。
