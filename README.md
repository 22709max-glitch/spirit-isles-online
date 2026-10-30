# 靈嶼：固定網址手機網頁版

公開遊戲網址：**https://22709max-glitch.github.io/spirit-isles-online/**

手機瀏覽器直接開啟即可遊玩，不需要下載啟動器，也不需要自己的電腦保持開啟。首次約下載105MB，建議Wi-Fi。

網站已經發布，並通過公開HTTPS網址的實際載入與存檔測試。Supabase尚未設定；帳號與雲端按鈕在未設定時會停用，訪客仍可遊玩。多人同地圖的免設定房間需要另設雲端房間伺服器，本專案沒有假裝已提供這項服務。

## 1. 固定網址

將整個專案上傳到專用的公開GitHub程式庫（遊戲檔案約106MB）。程式庫 Settings → Pages → Deploy from a branch → main、/（root）→ Save。

發布後開啟 `https://你的帳號.github.io/程式庫名稱/`。分享這個網址給朋友即可；朋友不用安裝任何東西。每台裝置、每個瀏覽器的訪客存檔各自分開，不會因為使用同一網址而共用。

Godot的index.pck約65MiB、index.wasm約36MiB，都小於GitHub單檔100MiB上限；需要用git/API上傳，不能用GitHub網頁的25MB單檔上傳功能。本專案不要放進原本的課程程式庫。

## 2. 一次性設定真正的帳號與雲端存檔

1. 建立你自己名下的Supabase專案。朋友只需要遊戲帳號，不需要Supabase帳號。
2. Supabase SQL Editor執行 `supabase/schema.sql`。資料表依登入使用者隔離；雲端更新使用版本比對，避免兩台裝置互相蓋掉。
3. Authentication開啟Email登入與Email驗證，Site URL及允許的Redirect URL設為實際的遊戲網址（包含 `/web/`）。正式使用時依Supabase方案配置寄信服務與寄信限額。
4. 在 `web/online-config.json` 填 `supabaseUrl` 和公開的 `publishableKey`（也支援舊anon key）。**不要放service_role、secret key或資料庫密碼。**
5. 更新網站後測試：Email註冊→驗證→登入→遊玩→儲存→另一台裝置登入並續玩。

網址和公開publishable key本來就會出現在瀏覽器。資料保護依靠伺服器驗證登入與資料庫Row Level Security，而非把公開金鑰藏起來。

## 存檔規則

- 訪客使用獨立guest空間；每個登入帳號另有專屬本機檔案與快取，登出後不會把進度帶給下一個帳號。
- 登入後可選擇雲端或本機進度；兩份有差異時不會默默合併或覆蓋。
- 遊戲中每45秒嘗試儲存可保存的進度，手動存檔也會觸發同步。戰鬥中不自動存檔。
- 網路失敗時保留本機進度，介面清楚顯示尚未同步。
- 另一台裝置先儲存時，資料庫拒絕舊版本覆寫；需要使用者比較後選擇。
- 可沿用手機設定中的JSON匯入／匯出搬移舊版進度。

## 驗證狀態

帳號REST客戶端使用本機測試替身驗證註冊、登入、帳號隔離與版本衝突；尚未在真實Supabase專案執行。SQL的RLS仍需部署後用兩個實際帳號驗證。瀏覽器遊戲與本機檔案隔離另有觸控模擬測試；未實體手機或Safari驗證。

遊戲素材與授權沿用靈嶼專案，見遊戲下載包的CREDITS與FONT-LICENSE。
