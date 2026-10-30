# 線上版驗證

已在實際GitHub Pages HTTPS網址完成5項瀏覽器流程：

- 網址導向手機介面。
- 實際WASM與遊戲資料成功載入並選擇夥伴。
- 訪客進度寫入獨立存檔空間。
- 重新整理保留進度。
- 另一個瀏覽器同網址無法讀到前一位訪客存檔。

測試使用Chromium手機尺寸與觸控模擬；未實體手機或Safari測試。測試環境使用網路代理，瀏覽器對代理憑證做限定公鑰釘選，公開HTTPS另以系統正常憑證驗證確認。網站未要求玩家放寬瀏覽器或防毒設定。

帳號客戶端7項本機測試通過，包括不同帳號本機資料隔離、不同裝置版本衝突拒絕覆蓋、秘密金鑰拒收。Supabase尚未設定，所以目前不開放實際註冊、登入與雲端存檔；沒有宣稱已在實際資料庫驗證。免設定多人雲端房間尚未部署。

## 手機版 v0.9.4

本機實際載入 Godot WASM/PCK，以 Playwright 的 WebKit 與 Chromium 各完成42項檢查，包含320×568、390×844、430×932與844×390、主要選單寬度與觸控尺寸、固定標頭、搜尋焦點、精靈詳情、圖鑑返回分頁、製作搜尋及真實戰鬥操作。兩個引擎均無測試收集到的瀏覽器錯誤。WebKit為Linux測試引擎，沒有宣稱已在實體iPhone／Safari驗證。

舊版實際存檔載入新版PCK後，金幣與精靈UID保留；不需要清除網站資料。圖形探測確認WebKit不再執行原本有錯誤的root framebuffer blit。預輸出UI圖片避免手機執行期間同步編碼PNG。

執行：`python tests/mobile-layout-regression.py chromium`、`python tests/mobile-layout-regression.py webkit`、`python tests/mobile-flows.py`、`python tests/mobile-save-upgrade.py`。測試用的本機HTTP伺服器為8770；WebKit的本機執行路徑可依環境調整。

另驗證接電線保留原生旋轉按鈕，挖掘保留完整6×6可操作格與座標標頭，沒有把棋盤當成物品清單分頁。
