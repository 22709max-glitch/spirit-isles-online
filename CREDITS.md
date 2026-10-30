# 素材來源與授權

地圖、建築、人物與道具使用Kenney製作的公開素材，均為CC0 1.0：

- Tiny Town：https://kenney.nl/assets/tiny-town
- Tiny Dungeon：https://kenney.nl/assets/tiny-dungeon
- Roguelike / RPG pack：https://kenney.nl/assets/roguelike-rpg-pack

CC0：https://creativecommons.org/publicdomain/zero/1.0/
原始授權檔完整保留於assets/public各素材包，副本位於docs/licenses；下載來源與SHA256紀錄為assets/public/sources.json。商業／個人使用皆可，無強制署名要求；此處保留作者與來源供查核。

精靈、進化概念與屬性圖示為本對話產生的原創設計。沒有使用寶可夢角色圖或拆包素材。Godot與字體授權另附。

背景音樂：Juhani Junkala，5 Chiptunes (Action)，CC0；介面與RPG音效：Kenney，CC0。完整連結與授權檔見設計參考與來源.md。


## v0.4新增來源

- Kenney Tiny Ski、RPG Urban Pack、Sokoban、Tower Defense Top-Down：CC0。對應雪景、城市／設施地磚、調查物件及岩石裝飾。來源：https://kenney.nl/assets/tiny-ski 、https://kenney.nl/assets/rpg-urban-pack 、https://kenney.nl/assets/sokoban 、https://kenney.nl/assets/tower-defense-top-down 。原包授權保留於assets/public各目錄。
- Monster RPG 2音樂，Nooskewl Games，troutsneeze以CC0再發布：https://opengameart.org/content/42-monster-rpg-2-music-tracks 。本版使用41首，排除來源包中非原創的叢林環境音。轉為單聲道Vorbis以降低遊玩包大小；對應曲名見assets/audio/tracks-v04.json，來源雜湊見assets/sources-v04.json。
- v0.4群島世界地圖及16組三格招式圖集：本專案透過影像生成工具製作的原創素材，非Kenney作品。精靈仍使用既有原創圖集。


## v0.5介面素材

- Kenney UI Pack RPG Expansion（按鍵材質）、UI Pack Adventure（配電盤金屬框）、Game Icons（返回、關閉、出口等圖示），均為CC0：
https://kenney.nl/assets/ui-pack-rpg-expansion
https://kenney.nl/assets/ui-pack-adventure
https://kenney.nl/assets/game-icons
原始授權檔保留在docs/licenses/kenney-*-license.txt，所用素材整理於assets/ui-v05。其餘下載的UI包僅作評估，不代表已套用。
- 深藍與金色向量面板、按鍵皮膚及背景為本專案原創SVG。
- 48幅物品基底插畫為本專案透過影像生成工具製作的原創素材；各品級及屬性道具共用插畫並搭配文字標籤。區域橫幅與配電電流以Godot繪製。


## v0.7 原創生成與字型處理

people-v07.png：原創生成16種玩家／NPC像素插畫。costumes-v07.png：原創生成8種搞怪時裝；透明背景清理由圖像工具處理。gacha-v07.png：原創生成扭蛋機插畫。圖片以遊戲引擎 AtlasTexture 區域引用，沒有從參考圖擷取第三方角色。

SpiritUI-Regular.otf：從既有 Noto Sans CJK TC Regular 字面提取並保留常用中日文字區間、拉丁字、標點與符號，移除其他語系字面以縮小發行檔。使用 fontTools 處理，字型原授權及來源見 FONT-LICENSE.txt；沒有改變原字形設計。

v0.8：新增五組傳說的十張形態與六張既有路線進化原畫，使用圖像生成工具製作原創設計，清除分隔線與背景後以圖集座標引用。圖集原檔assets/creatures-v08.png，矩形設定assets/sprite-frames-v08.json；未取用既有商業角色圖像。

v0.9：新增30張原創精靈形態立繪（兩張透明圖集creatures-v09-a.png、creatures-v09-b.png），以圖像生成工具製作與調整排版。index_sprites_v09.py只讀取alpha連通範圍、輸出引用座標，不改動原PNG像素；遊戲匯入時以高品質WebP壓縮節省封包。原始生成PNG保留在專案備份。新版仍使用既有Kenney材質及遊戲內原創道具、屬性與精靈圖片。


v0.9.2手機網頁介面、觸控操作與服務啟動器為本專案原始碼。啟動器以Go 1.24.9及標準函式庫建置；Go BSD授權隨手機包Go-LICENSE.txt附上。圖片沿用原有精靈、物品與地圖素材，沒有新增第三方圖像。
