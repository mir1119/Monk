# ADR 0001: Hard Block with Cooldown and Free Time Feedback over Streaks

Date: 2026-08-19
Status: Accepted

## Context

Monk 是 iOS 上的 dopamine detox / Screen Time 減少工具。核心機制是對 Tracked App 的 Limit（每日總量 + 單次連續）做阻擋，並給予進步回饋。需決定阻擋強度與回饋形式。

## Decision

- 採用 **Hard Block + Cooldown**：單次連續超時 → 冷卻 1 小時；每日總量超時 → 鎖到隔天重置。每日提供一次 5 分鐘緊急解鎖。
- 進步回饋採用 **Free Time**（vs 初始 Baseline 與 vs 上週的省下時間），**不採用 streak**。
- Onboarding 解釋 Monk Mode 後讓使用者自填每日使用量，以 `(每日使用量 - Limit) × 365` 試算年化 Wasted Time 製造痛點，再選 preset/自訂並直接開始。
- 前端呈現：首頁顯示本週 Free Time、全 App 今日環狀剩餘、7 天趨勢；阻擋頁顯示倒數 + 替代行動 + 緊急解鎖。

## Alternatives Considered

- Soft nudge / 無限 snooze：溫柔但使用者回報對重度 doom scrolling 無效。
- Streak：遊戲化強，但斷掉歸零會造成挫折與棄用。
- 被動追蹤 3-7 天建立 Baseline：精準但啟動慢，不如自填年化試算即時產生動機。

## Consequences

- 需要 FamilyControls / DeviceActivity + ManagedSettings 權限才能做真實 Hard Block；未授權時降級為本地計時 + 提醒。
- 需處理 Daily Reset 時點（預設 00:00，可改 04:00/05:00）、冷卻計時、與 Emergency Unlock 次數的邊界邏輯。
- 基於自填的 Baseline 與 Wasted Time 依賴使用者誠實度，後續可接真實數據校正。
- 通知僅三種（80% 提醒、單次即將冷卻預警、每日晚間 Free Time 總結），避免通知本身成為干擾。

## Out of Scope for V1

- 帳號/雲端同步、社群/排行榜、AI 建議、Hardcore Monk Mode 開關。
- 後續以 iCloud 同步與 Hardcore 開關作為增量。
