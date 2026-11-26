# Kế hoạch xác minh runtime và ghi bằng chứng

## Collection UI polish

- Đổi nền sang obsidian, thêm banner vàng cam cạnh nhọn và halftone. Grid dùng thẻ gần vuông với 4–5 cột trên desktop theo chiều rộng thực tế. Portrait tăng lên 62% chiều cao panel, có camera cận mặt và xoay chuột hoặc touch. Chỉ số tách thành ba card Damage, SPA và Range. Đóng/mở có Scale và Fade, bản xem trước được giải phóng khi đóng.
- Chỉ sửa Source `UnitCollectionView`. Manifest chấp nhận fingerprint giao diện cũ. **PASS cục bộ** gồm 10 test Node, hồi quy Luau, biên dịch sáu bundle và đối chiếu 22 đích với RC hiện tại.
- **NOT RUN trong Studio:** chưa Apply, chưa có ảnh runtime để đối chiếu hình ảnh, chưa xác minh hiển thị màn hình nhỏ hoặc đo FPS.

## Collection và Loadout trên RC hero-limits-v2

- Mở Collection bằng Units hoặc H trong Lobby. Equip, Unequip và Unequip All dùng PartyAction hiện có. Server xác thực sở hữu, slot 1–2, chống lặp, cooldown và chỉ cho sửa đội hình ở Lobby. Slot 3–6 giữ khóa. Party và Hotbar đọc dữ liệu từ cùng profile. GameManager chốt đội hình theo MatchId và TowerServer kiểm tra trước khi trừ Yen hoặc tạo Hero.
- Level của hai Unit khởi đầu là 1 theo profile trong phiên. Các chỉ số hiển thị dùng đúng cấu hình TowerServer. Portrait dùng mẫu Hero có thật. Chưa có DataStore sở hữu hoặc Loadout trong project, nên trạng thái được giữ trong cùng phiên, gồm Replay và Return to Lobby.
- **PASS cục bộ:** Kiểm tra trùng, Hero chưa sở hữu, giữ vị trí slot, slot khóa, Unequip All, và handler từ chối Hero ngoài Loadout mà không trừ Yen. Hồi quy Hero Limit, Blink, DDA, Node và bộ đồng bộ PASS.
- **NOT RUN trong Studio:** Units/H, Search/Filters, kéo portrait, Equip và Hotbar, party hai client, vào trận với một Hero, đội hình rỗng, Replay/Return, touch và chất lượng hình ảnh.

## Avatar Blink trên RC hero-limits-v2

- Blink thay thế Dash trong hai Source `PlayerDash` hiện có. Q yêu cầu dịch chuyển tức thời qua `PivotTo`, tối đa 15 studs và cooldown 250 ms. Server tự lấy hướng Avatar, rút ngắn đường đi trước vật cản và chỉ nhận điểm đáp có sàn phù hợp trong cùng `MainLobby` hoặc `The Void`. Client chỉ vẽ hai điểm sáng xanh trắng rồi dọn hiệu ứng.
- **PASS cục bộ:** test server mô phỏng Blink ngay trong request, chặn tại 249 ms, cho phép tại 250 ms, kiểm tra tường, mép map, chết, khóa điều khiển, respawn và tham số request thừa.
- **NOT RUN trong Studio:** thử Q liên tiếp trong Lobby và Battle, sát tường và mép sàn. Kiểm tra WASD, Space và camera ngay sau Blink, cùng hai điểm sáng. Mục Avatar Dash bên dưới là lịch sử trước khi thay thế.

## Avatar Dash trên RC hero-limits-v2

- Q yêu cầu Dash cho Avatar điều khiển trực tiếp. X hoặc chuột phải hủy Ghost Preview. Server tính hướng từ HumanoidRootPart, tối đa 20 studs trong 0,25 giây và cooldown 1,5 giây. Blockcast kiểm tra trước và trong mỗi bước. Hiệu ứng chạy cục bộ. Dash ngắt khi Avatar mất điều kiện di chuyển, đổi nhân vật hoặc bị dịch chuyển bên ngoài.
- **PASS cục bộ:** Mô phỏng quãng đường, thời gian, khóa điều khiển, tham số request thừa, tường, cooldown, respawn, dịch chuyển và nhân vật chết. Hồi quy Hero/DDA/Node cùng mô phỏng đồng bộ và rollback PASS.
- **NOT RUN trong Studio:** Sau Apply trên RC hiện tại, thử Lobby và Battle, sát tường, khi đang chat và sau respawn. Quan sát tàn ảnh, độ nghiêng, vệt gió, speed lines, bụi và FOV.

## Story và Party Lobby — polish trên RC hero-limits-v2

- Preview dựng WorldModel từ toàn bộ BasePart hữu hình có thể clone trong `Workspace.The Void`. Camera phối cảnh căn khung theo giới hạn mô hình và tỷ lệ viewport. Bản sao giữ Mesh, Decal, Texture và SurfaceAppearance, dùng màu sáng môi trường cùng gradient tối dưới tên màn. Các Act hiện dùng chung cảnh The Void. ViewportFrame chưa tái tạo Terrain voxel hoặc hiệu ứng Lighting toàn cảnh.
- Story làm mỏng viền, phóng lớn World card, đổi thứ tự tab và nút độ khó, xuống dòng tên Act và dùng thứ tự hiển thị để tránh HUD che nút. Party tăng kích thước banner, portrait và thẻ Hero, thu gọn hàng trống. Flow match và remote dùng lại hệ thống hiện có.
- Đối chiếu Source cho thấy server thực sự cấp Yen khi hạ quái và hoàn thành wave. Panel mới hiển thị bounty theo `WaveData.EnemyStats` và ghi thưởng hoàn thành wave thay đổi theo wave. Gems, Gold, EXP và drop trong cấu hình stage chưa có đường cấp sau trận được xác nhận, nên UI không hiển thị chúng như phần thưởng đã được hỗ trợ.
- **NOT RUN trong Studio:** Chưa Apply polish vào RC hiện tại. Chưa có ảnh sau sửa để đối chiếu với hai ảnh và video tham chiếu, kiểm tra camera trên thiết bị nhỏ, Story → Party, touch hoặc FPS. Chưa chấm điểm hình ảnh.

## Premium Play UI v1

Tham chiếu video tại 00:02 cho drawer bên trái, 00:04–00:10 cho Story ba cột, 00:12 cho Party bên trái và Lobby 3D bên phải. Bản Deck Defenders dùng khung Blue Crystal, nút viền kép/gradient, ViewportFrame từ The Void và model Hero trong project, cùng dữ liệu StageData và PartyUpdate. Các mode ngoài Story được đánh dấu chưa hỗ trợ. Không nhập hình ảnh từ video hoặc tạo ID asset.

**PASS cục bộ:** manifest 18 đích, kiểm tra Source trên bản sao RC xác nhận 15 đích trùng, hai Source cũ khớp fingerprint và một module mới cần tạo. Studio Sync mô phỏng xác nhận Apply/Verify, kiểm tra BuildVersion, rollback và chạy lại. Hồi quy Luau và Node được chạy trên workspace. RC nguồn và RBXL gốc giữ nguyên.

Bundle hiện tại đồng bộ vào RC `hero-limits-v2` đang dùng và giữ BuildVersion này. Fingerprint trong Output Verify phân biệt lần cập nhật giao diện.

**NOT RUN trong Studio:** chưa Apply giao diện vào RC hiện tại, chưa chụp Play Menu, Story và Party Lobby, chưa xác nhận chất lượng hình ảnh, touch, khả năng đọc ở các kích thước mục tiêu, party/matchmaking hay FPS. Preview sử dụng cảnh chung The Void qua ViewportFrame và khung góc dựng từ Roblox UI. Chưa có bộ ảnh riêng cho từng mode/Act, texture PNG tùy chỉnh hoặc ảnh preview từng Act để so sánh trực quan với video.

## Gameplay polish — Hero và Yen trên RC v2

- **PASS cục bộ:** Mở rộng `HeroPlacement.spec.luau` để kiểm tra đúng số Yen khi đặt đủ 4 IceHero và 4 CrimsonHero, nâng cấp IceHero lần đầu (400 Yen), bán trụ đã nâng cấp (hoàn 630 Yen) và đặt lại (500 Yen). Người khác bán trụ không làm thay đổi số dư của cả hai. Các ca Hero thứ năm, spam, giới hạn riêng và reset theo MatchId tiếp tục PASS. 10 test Node, DDA và diagnostics mô phỏng cũng PASS.
- **Bằng chứng runtime hiện có:** RC đã lưu khớp 17/17 Source. Log mới nhất vẫn là trận Act 3 Fixed dừng ở wave 1 được ghi bên dưới. Log xác nhận hai lượt đặt và số dư sau đặt. Không có lượt Play mới trong đợt này. Studio MCP trả `initialize` nhưng `tools/list` hết thời gian chờ.
- **Cân bằng theo cấu hình:** Vốn 2.500 Yen. Đặt IceHero 500 và CrimsonHero 800, nên triển khai đủ 4+4 cần 5.200 Yen trước nâng cấp. Chưa đủ dữ liệu để đánh giá khả năng thắng với cap này. Fixed và DDA dùng chung giá, phần thưởng, giới hạn và lịch wave. Multiplier DDA tác động lên HP quái mới.
- **Luồng thưởng hiện tại:** Hạ quái cấp thưởng theo cấu hình cho roster đang tham gia, gồm chủ Hero nếu còn trong trận. Thưởng hoàn thành wave cũng chia cho roster. Registry chỉ xử lý một kết quả mỗi enemy và nhánh lọt hoặc cleanup không thưởng kill. Đây là kết quả đọc Source, chưa có ca kiểm chứng thưởng trong Studio.
- **NOT RUN:** Act 3 đủ 15 wave trên RC, Boss/HP, DDA tăng và giảm thật, phối hợp hai client, cap, UI Yen/Hotbar, ghost và touch, Upgrade/Sell và vòng đời kết quả trong Studio. FPS, RAM, frame time và tài nguyên tồn đọng chưa đo. Không có thay đổi Source Studio, manifest hoặc cân bằng trong đợt này.

## Rà soát RC bằng log Studio mới nhất

Log `0.748.0.7481526_20261125T083350Z_Studio_0A2A4_last.log` ghi Verify **17 Source** với build `hero-limits-v2` và **2 thay đổi** ở dòng 3349. Các lỗi đồng bộ trước đó trong Play bị chặn. Đọc trực tiếp bản RC đã lưu cho thấy **17/17 Source** khớp workspace. RBXL gốc chỉ khớp 13/17 đích. Các kết quả dưới đây áp dụng cho RC.

| Hạng mục | Bằng chứng |
| --- | --- |
| Act 3 Normal Fixed | `world_1.act_3`, baseline `stone-path-v1`, 15 wave cấu hình. MatchId `e9ff84ca-2485-4a84-8ac7-03cb979f4cdb`. |
| Placement và Yen | Một IceHero và một CrimsonHero được đặt, mỗi loại ghi 1/4. Server ghi số dư 2.000 rồi 1.200 Yen. Chưa có bằng chứng độc lập về hình dạng, vị trí HUD hoặc chữ thưởng từ log. |
| Kết thúc | Người chơi rời ở wave 1. Log ghi 6/8 địch bị hạ, BaseHealth 20/20, `complete=false`, applied và next multiplier đều 1, một `match_end` với `Abandoned`. |
| CSV Analyzer | Chạy trên log Studio tạo một dòng QA cho Fixed, một Abandoned và 0 wave hoàn thành, không có chẩn đoán lỗi. Dòng này không thuộc dữ liệu thực nghiệm người chơi. |
| Ca runtime RC còn thiếu | Đủ 15 wave, Boss và MaxHealth, DDA tăng/giảm, Victory/Defeat/Replay/Return/cleanup, cap 4+4, chạm màn hình, multiplayer, HUD Yen và animation sau sửa vẫn cần bằng chứng riêng. Log này không có lỗi asset 507770000 nhưng không đủ xác nhận animation phát đúng. Không có trace hiệu năng. |

**Hồi quy tự động PASS.** 10 test Node, native compile 48 file Luau, compile 26 Source trích từ RBXL, Hero Placement, DDA, Phase 2, diagnostics và Studio Sync mô phỏng. Các ca mô phỏng không thay thế kiểm thử Studio. MCP trả `initialize` nhưng `tools/list` hết thời gian chờ, nên không có phiên Play mới qua MCP.

## Battle HUD Yen trên hero-limits-v2

Manifest vẫn có 17 đích Source. Bản cập nhật Yen thay đổi GameManager và PlacementClient. Đã đối chiếu fingerprint của cả hai Source với bản RC v2 đã lưu để kiểm tra đường nâng cấp. Cả RBXL gốc và RC giữ nguyên SHA-256.

**Hồi quy tự động — PASS.** Biên dịch native 48 tệp Luau gồm sáu script đồng bộ, biên dịch 26 Source trích từ RBXL, chạy test Hero Placement, DDA, Phase 2, diagnostics và chín test Node. Mock Studio xác nhận nâng cấp từ Source v2 đã pin, kiểm tra Source đã lưu, rollback khi Apply lỗi và chạy lại không tạo thay đổi. `git diff --check` PASS.

**Roblox Studio Desktop và Mobile — NOT RUN.** Sau khi đồng bộ bản RC trong Edit Mode, kiểm tra ô Yen cách Hotbar 10 px và hiển thị số dư đầu trận theo định dạng `2.500 ¥`. Thử đặt và nâng cấp Hero, quan sát số dư cập nhật theo server. Hạ quái và xác nhận chữ xanh hiển thị số thưởng thật. Replay để kiểm tra hiệu ứng cũ được dọn và số dư đầu trận được khôi phục. Kiểm tra ô Yen biến mất khi trận kết thúc và khi về Lobby.

## Hero-limits-v2 — đồng bộ một lần chạy

**Khởi động Studio v2: PASS.** Output người kiểm thử gửi và file log Studio `0.748.0.7481526_20261125T083350Z_Studio_0A2A4_last.log` đều có dòng `[HeroLimit] Guard ready. BuildVersion=hero-limits-v2`. Trong bằng chứng đã đọc, chưa có log đặt Hero hoặc từ chối yêu cầu thứ năm trên build v2. Giới hạn 4+4 và Yen tại runtime vẫn **NOT RUN**.

Đọc trực tiếp bản RC v2 đã lưu cho thấy **17/17 Source trong manifest khớp** sau khi chuẩn hóa xuống dòng và khoảng trắng ngoài. PlacementRules, TowerServer và PlacementClient khớp nội dung v2. Báo cáo Play của người dùng vẫn ghi `sync-7a71189a55df`, đúng với build cũ của RBXL gốc. Kết quả đọc tĩnh RC không xác nhận phiên Play đang mở đúng tab.

Bundle mới chứa `studio-one-click-sync.luau`. Mock kiểm chứng chặn place publish, build gốc, fingerprint RC sai và Source khác bản đang hiện trong editor. Mock cũng xác nhận lỗi giữa chừng rollback được, Apply đổi đúng BuildVersion, Verify đối chiếu Source thật và chạy lại là no-op. Hồi quy Hero Placement, DDA, Phase 2, Studio sync, diagnostics, chín test Node và diff check đều PASS. Studio MCP trả handshake nhưng không có phiên để gọi công cụ. One-click và ca Hero thứ năm tại runtime v2 **NOT RUN**. [Một lệnh đồng bộ](STUDIO_SYNC_GUIDE.md#đồng-bộ-v2-bằng-một-lệnh)

## Hero-limits-v2 — điều tra đặt IceHero thứ năm

**FAIL đã xác nhận trên build cũ.** Log ghi năm lượt đặt IceHero liên tiếp trong MatchId `4eb900a9-47ad-4a22-8e47-fe51a4e77c5b`, Act 3 Normal Fixed. `match_start` khai báo BuildVersion `sync-7a71189a55df`. Giải mã thuộc tính GameManager trong hai RBXL cho thấy bản gốc giữ build cũ và ba Source chưa có bộ đếm Hero. Bản RC v1 đã lưu ghi `hero-limits-v1` và có logic giới hạn trong TowerServer, PlacementRules, PlacementClient. Dry Run/Apply/Verify của RC trong file log riêng đều PASS. Không tìm thấy match_start v1 xác nhận lỗi thứ năm trên RC đã đồng bộ.

Đã rà Source nhúng: chỉ TowerServer tạo Hero trong hai place kiểm tra. Hai RemoteEvent PlaceUnit và PlaceTower dùng cùng handler, cùng cooldown; không thấy RemoteFunction tạo Hero. TowerCombat và UnitService cũ ở cây nguồn thử nghiệm không tồn tại trong hai RBXL. Bundle v2 kiểm chặn các đường dẫn writer song song đã biết. Tệp place lưu chưa có các model của trận đã chạy, log cũ không ghi Owner/UnitType/DeckMatchId của từng model. Bản mới ghi các thuộc tính này sau khi đặt và ghi số đang có, MatchId và Yen khi từ chối.

Server đếm model Hero theo thuộc tính server gán trước khi parent vào Workspace.Towers. Model Hero đã đăng ký vẫn được đếm nếu thiếu HumanoidRootPart. Kiểm tra giới hạn, chuẩn bị clone, thu Yen và parent model không yield trong handler. Yêu cầu vượt giới hạn trả về trước Clone và thu Yen. Không thay đổi giá, damage, skill, animation, wave, map hoặc DDA.

**Hồi quy cục bộ PASS:** mô phỏng server xác nhận cả hai loại đủ 4, chặn con thứ năm không gọi Clone và giữ nguyên tiền, gồm trường hợp root bị thiếu, gọi lặp qua alias cũ, bán/đặt lại, replay và người chơi độc lập; đồng bộ thử nâng cấp từ v1. **Runtime v2: NOT RUN.** Trong bản sao RC, chạy bundle v2 rồi kiểm tra `[HeroLimit] Guard ready. BuildVersion=hero-limits-v2` trước khi thử. Hotbar chặn thao tác bình thường ở 4/4; server chỉ in REJECTED khi thực sự nhận được yêu cầu vượt số lượng.

## Release Candidate validation — hero-limits-v1

Log Studio mới nhất truy cập được chỉ có BuildVersion `sync-7a71189a55df` trong `match_start`. Đã xác minh trước đó: Act 3 Normal Fixed thắng 15/15, Boss 3.200 MaxHealth, Fixed multiplier 1; Act 1 Normal DDA thắng 5/5 và đã tăng độ khó trong phạm vi quan sát. Không dùng các kết quả này làm PASS cho RC. Xác nhận của người dùng về Act 3 DDA, chiều giảm, Defeat, Replay, Return, cleanup và multiplayer vẫn được ghi nhận riêng cho tới khi có log, ảnh hoặc số đo tương ứng trên đúng build.

| Hạng mục RC | Trạng thái |
| --- | --- |
| Generator, manifest và 17 đích Source | **PASS cục bộ** — sinh lại bundle `a18bab8df39c2cf13d243f833d77adc794ad5067e9249641481b424bb5ac46b7`, 8 test Node và git diff --check đạt |
| Studio Dry Run / Apply / Verify của RC | **NOT RUN** — Studio MCP khởi tạo được nhưng không cung cấp công cụ từ phiên Studio |
| Giới hạn 4+4, Hero thứ năm không mất Yen, bán/Replay, Hotbar và multiplayer trên RC | **NOT RUN trong Studio** — chỉ có bằng chứng mô phỏng handler ở lần regression trước |
| Hai lượt Act 3 Fixed/DDA cùng build RC, Boss, HP, tăng/giảm, Victory, Defeat, Replay, Return, cleanup | **NOT RUN** — chưa có log `hero-limits-v1` |
| Mobile và thao tác cảm ứng | **NOT RUN** |
| FPS, RAM, frame time median/p95, Boss, tải 50 trụ và tài nguyên sau 10 trận | **NOT RUN** — chưa có trace/snapshot thuộc RC |

Đã tạo một bản sao RBXL trước Apply và giữ nguyên byte của RBXL gốc. Các bước thực hiện và tiêu chí thử trực tiếp nằm trong [báo cáo release](FINAL_RELEASE_REPORT.md).

## Phase 4 — đối chiếu bằng chứng nghiệm thu

Đã đối chiếu log Studio ngày 25/11/2026 và kết quả 13/16 do người kiểm thử báo. Các nhãn dưới đây phản ánh bằng chứng có trong log được đọc.

| Mục | Trạng thái | Bằng chứng |
| --- | --- | --- |
| DeckDDA, Act 3 Fixed đủ 15 wave và Victory | **PASS** | MatchId `80f886b1-9b6b-422b-b3ca-fdd668d5f0a7`, build `sync-7a71189a55df`, baseline `stone-path-v1`. Wave 15 hoàn tất, hạ 47/47, căn cứ 20/20, một match_end Victory, 444,15 giây |
| Boss wave 15 và MaxHealth Fixed | **PASS** | DeckDDA ghi MaxHealth thực tế/đích bằng 3.200 cho Boss. Giá trị quan sát của Zombie, Skeleton, Goblin lần lượt 120, 180, 75; hệ số Fixed và handoff PASS |
| DDA tăng | **PASS phạm vi Act 1** | Act 1 DDA hoàn tất năm wave, bắt đầu ở 1, bước tối đa 0,08. Bảng số liệu nằm ở mục 3.3 |
| Act 3 DDA 15 wave, giảm độ khó và MaxHealth dưới DDA | **Người dùng xác nhận; thiếu log đối chiếu** | Không có trận Act 3 DDA hay mẫu MaxHealth dưới DDA trong log truy cập được |
| Defeat, Replay, Return, cleanup và multiplayer | **Người dùng xác nhận; thiếu log đối chiếu** | Lượt Fixed ghi Defeat và Replay là NOT RUN; file đã đọc thiếu snapshot folder sau trận, lần bấm Return và lượt từ hai người |
| IdleAnimation CrimsonHero | **Nguồn đã sửa; cần xác nhận lại** | Report DeckDDA cũ gắn FAIL ngay trước Ready, trong khi cảnh báo raw cuối cùng về ID 507770000 thuộc lượt Play trước. Công cụ cũ đọc lịch sử Output mà không phân phạm vi phiên. Phase 4 tách lịch sử khỏi lỗi trực tiếp; vẫn cần xác nhận chuyển động idle và Output của lượt mới |
| Hero limit build `hero-limits-v1` | **PASS mô phỏng / NOT RUN Studio từ log** | Handler Luau kiểm thử 4+4, từ chối Hero thứ năm không mất Yen, bán/đặt lại, nâng cấp, replay, nhiều chủ sở hữu và payload/MatchId sai. Chưa tìm thấy match_start của build này |
| Mobile và hiệu năng | **NOT RUN** | Chưa có báo cáo Device Emulator/thiết bị thật hoặc trace có số đo gameplay. Sự kiện nội bộ của Studio không được tính là bằng chứng sử dụng mobile |

Analyzer xuất một dòng QA cho Act 3 Fixed: 2 trận có bản ghi kết thúc hợp lệ (1 Victory, 1 Abandoned), 16 wave hoàn tất, trung bình 8 wave/trận, 233,46 giây và hệ số áp dụng trung bình 1. Ba hồ sơ thiếu sự kiện được báo riêng. Đây là dữ liệu kiểm thử kỹ thuật, không đưa vào bảng nghiên cứu. CSV: `reports/local/phase4-act3-technical.csv`.

## Hero Placement Limit — hero-limits-v1

Server đếm model trong Workspace.Towers theo Owner, UnitType, DeckMatchId hiện tại và HumanoidRootPart hợp lệ. Cả hai remote đặt trụ đi qua cùng hàm kiểm tra giới hạn trước khi trừ Yen hoặc tạo model. Cấu hình tập trung ở PlacementRules. Hotbar cập nhật theo model sở hữu đã replicate và membership trận.

| Kiểm thử | Kết quả |
| --- | --- |
| Đặt đủ 4 IceHero và 4 CrimsonHero, hai Hero thứ năm bị từ chối | **PASS — handler server qua mô phỏng Luau** |
| Từ chối giữ nguyên Yen và số model, bao gồm lặp yêu cầu qua remote cũ và thiếu tiền | **PASS — handler server qua mô phỏng Luau** |
| Bán rồi đặt lại, nâng cấp giữ đếm, chặn bán trụ người khác | **PASS — handler server qua mô phỏng Luau** |
| Hai người có giới hạn độc lập, model trưng bày và model thiếu root bị loại, MatchId mới đếm về 0 | **PASS — handler server qua mô phỏng Luau** |
| Nâng cấp Source trên bản đã đồng bộ, cập nhật BuildVersion, giữ EnableDDA và rollback | **PASS — mock bộ đồng bộ Studio** |
| Hiển thị/bấm Hotbar, Ghost Preview, phản hồi Studio, Replay, Return và multiplayer thật | **NOT RUN** |

Regression PASS gồm compile 53 file Luau (cả công cụ sinh ra), 26 nguồn nhúng RBXL, spec DDA/Phase 2/HeroPlacement, mock diagnostics, mock Studio sync, 7 test Node và `git diff --check`. SHA-256 RBXL không đổi.

Trên bản sao Studio, chạy Dry Run → Apply → Verify với bundle mới. Kiểm tra BuildVersion là `hero-limits-v1` trong GameManager và sự kiện match_start. Chơi để tích lũy Yen theo luật hiện tại. Đặt đủ 4 trụ mỗi loại trong cùng một trận, thử chọn Hero thứ năm và kiểm tra ô `4/4` màu đỏ, thông báo và Yen. Thử bán, nâng cấp, hai người chơi, Replay và về Lobby. Cần ít nhất **7 người** để kiểm thử mốc 50 trụ hợp lệ theo giới hạn mới.

## Phase 3.3 — Nghiệm thu DDA trong gameplay

Log Studio ngày 25/11/2026 có một trận DDA hoàn chỉnh, MatchId `df9b5476-181f-4958-bc85-26596a644121`, kết thúc lúc 14:34:32 (UTC+7). Trận thuộc **Act 1 Normal**, build `sync-7a71189a55df`, baseline `void-legacy-v1`. Đối chiếu toàn bộ MatchId cho thấy năm `wave_end` hoàn chỉnh và đúng một `match_end` Victory. Bảng dưới lấy trực tiếp từ telemetry server, các hệ số được hiển thị theo độ chính xác thuận tiện để đọc.

| Wave | Hạ / sinh | Lọt | HP căn cứ | Performance score | EMA | Áp dụng | Kế tiếp | Chênh lệch |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | 5/5 | 0 | 20/20 | 1 | 0,8375 | 1 | 1,035 | +0,035 |
| 2 | 12/12 | 0 | 20/20 | 1 | 0,894375 | 1,035 | 1,09275 | +0,05775 |
| 3 | 16/16 | 0 | 20/20 | 1 | 0,93134375 | 1,09275 | 1,1652875 | +0,0725375 |
| 4 | 30/30 | 0 | 20/20 | 1 | 0,9553734375 | 1,1652875 | 1,2452875 | +0,08 |
| 5 | 29/29 | 0 | 20/20 | 1 | 0,970992734375 | 1,2452875 | 1,25 | +0,0047125 |

**PASS trong phạm vi telemetry Act 1:** khởi tạo ở 1, tăng theo các mẫu quan sát, hệ số áp dụng wave 2–5 khớp hệ số kế tiếp của wave trước, giới hạn và bước lớn nhất đều đạt. Giá trị 1,25 là hệ số kế tiếp sau wave cuối. Trận đã kết thúc nên log không cho thấy quái nào dùng hệ số này.

| Cổng nghiệm thu Act 3 / runtime | Trạng thái | Tiêu chí cần có |
| --- | --- | --- |
| Stage và Fixed ban đầu | **PASS một phần** | Đã có bốn lượt Act 3 Normal Fixed với 15 wave được cấu hình; mỗi lượt có wave 1 hoàn chỉnh và hệ số 1. Chưa có Victory Act 3 |
| Fixed/DDA cùng build và baseline | **NOT RUN** | Hai lượt cùng `world_1.act_3`, Normal, cùng BuildVersion và `stone-path-v1`. Log hiện chưa có lượt Act 3 DDA |
| HP thật và áp dụng sang wave sau | **NOT RUN** | Dòng `[DeckDDA]` ghi `enemyMaxHealth = max(1, round(HP baseline × appliedMultiplier))` ở Act 3; hệ số wave sau khớp `nextMultiplier` trước đó |
| Chiều giảm DDA | **NOT RUN** | Một wave hoàn chỉnh có mẫu hợp lệ và `nextMultiplier < multiplier` trong log thật. Mô phỏng trước đây có chiều giảm, chưa chứng minh runtime |
| Boss và Victory Act 3 | **NOT RUN** | `enemyType = Boss` ở wave 15, đủ 15 `wave_end` hoàn chỉnh và một `match_end` Victory |
| Defeat, Return, Replay | **NOT RUN** | BaseHealth 0 và outcome Defeat; Return đưa người chơi về Lobby; Replay cho MatchId khác và wave 1 dùng hệ số 1 sau trận DDA đã điều chỉnh |
| Dọn enemy và tower | **NOT RUN** | Sau khi có màn kết quả, trước khi rời hoặc Replay, Server Explorer cho thấy cả `Workspace.Enemies` và `Workspace.Towers` đều rỗng |
| CrimsonHero idle sau sửa | **Chưa đủ bằng chứng** | Confirm Waist chuyển động trên model trưng bày cùng phiên log không có lỗi `507770000`. Lượt thắng Act 1 không có cảnh báo mới, nhưng không ghi quan sát chuyển động |

Không tìm thấy mẫu `[DeckDDA]` trong log hiện có. Hai dòng `[DeckHPProbe]` chỉ báo Ready. Bảng số liệu ở trên là **kiểm thử kỹ thuật thực tế**; [bảng mô phỏng 15 wave](DDA_SIMULATION_REPORT.md) là dữ liệu giả lập. Chưa có mẫu nghiên cứu để kết luận hiệu quả về tỷ lệ thắng.

**Lượt Studio còn thiếu:** dùng [quy trình diagnostics duy nhất](#một-quy-trình-cho-hai-lượt) cho Fixed và DDA, cùng lượt chọn Act 3 Normal. Chơi đủ 15 wave để kiểm tra Boss/Victory. Trong lượt DDA riêng, thử chiến thuật ít trụ ở giữa trận để tìm một wave khó nhưng vẫn hoàn tất, sau đó đối chiếu chiều giảm bằng log. Trong các lượt kết thúc, kiểm tra hai folder trên Server Explorer trước khi dùng nút, thử Replay và Return trên các lượt riêng, rồi đối chiếu idle và Output. Chỉ đề xuất chốt bản ổn định khi đủ bằng chứng cho các cổng trên.

## Đối chiếu giao diện Chiến thắng — 25/11/2026

Nguồn log là phiên Studio `0.748.0.7481526_20261125T061519Z_Studio_F7A96_last.log`. Kết quả Victory ghi lúc **14:34:32 (UTC+7)**.

| Trường | Giá trị từ server |
| --- | --- |
| MatchId | `df9b5476-181f-4958-bc85-26596a644121` |
| StageId | `world_1.act_1` · Void Outskirts · Normal |
| DifficultyMode | `DDA` |
| BuildVersion | `sync-7a71189a55df` |
| Wave cuối / tổng wave | `5/5` |

| Hạng mục | Trạng thái | Bằng chứng |
| --- | --- | --- |
| Giao diện Chiến thắng | **Đã quan sát theo người kiểm thử** | Người dùng báo thấy giao diện CHIẾN THẮNG và hai nút VỀ LOBBY, CHƠI LẠI. Lượt yêu cầu này không kèm ảnh; quan sát UI không xác nhận thao tác nút |
| Hoàn thành cả trận | **PASS — Act 1** | Menu chọn Act 1. Một `match_start`, đủ năm `wave_end` lần lượt 1–5 và một `match_end` |
| Wave cuối và Victory | **PASS — Act 1** | Wave 5 có `complete = true`, hạ 29/29 quái, 0 lọt, căn cứ 20/20. `match_end` ghi `outcome = Victory` đúng một lần cho MatchId này. Thời lượng khoảng 165,01 giây |
| Act 3 đủ 15 wave và Boss ở wave 15 | **NOT RUN** | Victory trên thuộc Act 1. Analyzer Act 3 không có Victory. Boss wave 15 có trong cấu hình; chưa có bản ghi spawn theo loại hoặc ảnh Boss ở wave đó |
| DDA theo telemetry | **PASS trong phạm vi năm wave Act 1** | Hệ số áp dụng lần lượt 1 → 1,035 → 1,09275 → 1,1652875 → 1,2452875. Hệ số kế tiếp cuối cùng là 1,25. Wave sau dùng đúng hệ số kế tiếp của wave trước; bước lớn nhất 0,08. Chưa đo MaxHealth trực tiếp |
| Cleanup enemy/tower | **NOT RUN** | Source dọn cả hai folder sau khi ghi `match_end`. Log đóng Play Solo không cung cấp số Instance của hai folder ngay sau Victory |
| Return / Replay | **NOT RUN** | Chưa có bằng chứng nhấn nút, xác nhận trở về lobby hoặc MatchId mới do Replay sau trận |
| Animation 507770000 | **Chưa đủ bằng chứng nghiệm thu** | Log có 12 cảnh báo trust ở các lượt trước. Không thấy cảnh báo ID này trong lượt DDA Victory vừa đối chiếu. Log chưa ghi kiểm tra chuyển động idle hoặc xác nhận phiên Play dùng đúng Source đã sửa |
| DeckDDA diagnostics | **NOT RUN** | Không có dòng `[DeckDDA]` trong log đã đọc. Các dòng `[DeckHPProbe]` cũ chỉ báo Ready, không có mẫu HP |

Analyzer chạy trên log thật xác nhận một Victory Act 1 DDA và không báo lỗi cấu trúc của trận này. Lọc Act 3 cho một Abandoned, ba hồ sơ thiếu dữ liệu và không có Victory. Các bài mô phỏng diagnostics ở mục dưới xác nhận logic kiểm tra trên dữ liệu giả lập; không dùng thay cho bằng chứng runtime hoặc dữ liệu nghiên cứu.

## Phase 3.2 — DDA runtime diagnostics

Windows có `StudioMCP.exe`. Tiến trình proxy trả handshake MCP, nhưng `tools/list` hết thời gian chờ và không có phiên Studio được gắn qua công cụ của cuộc trò chuyện. Vì vậy lượt này đọc log có sẵn và kiểm thử diagnostics trên mô hình Luau. Không thực thi lệnh trong Studio và không chỉnh place.

| Hạng mục | Trạng thái runtime hiện tại | Bằng chứng |
| --- | --- | --- |
| Stage, build và Fixed | **PASS trong các wave ghi được** | Log `sync-7a71189a55df` ghi 4 lượt bắt đầu Act 3 Normal và 4 bản ghi wave hoàn tất đầu tiên với hệ số áp dụng và kế tiếp bằng 1 |
| MaxHealth thật và chuyển hệ số sang wave sau | **NOT RUN** | Telemetry trước đó chưa quan sát MaxHealth của quái mới |
| DDA bắt đầu ở 1, giới hạn 0,80–1,25, bước ≤ 0,08 và phản hồi từ mẫu hợp lệ | **NOT RUN** | Log Act 3 hiện chỉ có Fixed |
| Wave lỗi hoặc thay đổi roster không cập nhật EMA | **NOT RUN** | Chưa có mẫu runtime DDA liên quan |
| Replay có MatchId mới và reset DDA | **NOT RUN** | Chưa quan sát RequestReplay và wave 1 của trận kế |
| Victory / Defeat | **NOT RUN** | Một lượt Act 3 có `match_end` là Abandoned. Ba lượt khác thiếu kết quả cuối trong log |
| Animation 507770000 sau khi đồng bộ | **NOT RUN** | Lỗi có trong log trước sửa. Chưa có Play Test sau sửa được xác định |

[Studio DDA diagnostics](../../tools/studio-dda-diagnostics.luau) thay cho probe HP riêng trong hướng dẫn cũ. Công cụ chỉ chạy trong Studio Server, đọc telemetry và MaxHealth thực tế. Mỗi wave đối chiếu HP với baseline `stone-path-v1` và hệ số đang áp dụng. Output ghi một mẫu theo loại quái mỗi wave, mọi sai khác HP, và báo cáo tích lũy PASS/FAIL/NOT RUN sau mỗi wave hoặc kết thúc trận. `ddaResponse` cần quan sát hệ số thực sự đổi. `replayReset` cần lượt trước đã rời trạng thái DDA ban đầu và wave 1 của lượt Replay có mẫu hợp lệ. Kiểm tra animation chỉ bao phủ chuyển động Waist và Output thấy được ở server. Cơ chế thu Output dùng LogService, nội dung bị thiếu hoặc cắt bớt có thể khiến ca kiểm thử vẫn ở NOT RUN. [Roblox LogService](https://create.roblox.com/docs/reference/engine/classes/LogService)

### Một quy trình cho hai lượt

1. Dùng bản sao RBXL đã đồng bộ. Trong Edit Mode đặt `GameManager.EnableDDA = false`. Bấm Play, chuyển Command Bar sang **Server** trước khi bắt đầu trận.
2. Chép **cùng một** script bằng PowerShell, dán vào Command Bar rồi bấm **Run**. Chờ dòng `[DeckDDA]` có `event = ready`.

   ```powershell
   Get-Content -Raw -Encoding UTF8 -LiteralPath 'E:\Roblox Game ĐACN\tools\studio-dda-diagnostics.luau' | Set-Clipboard
   ```

3. Chọn **The Void → Act 3 → Normal**, bắt đầu trận và chơi ít nhất hai wave. Giữ lại các dòng `[DeckDDA]`. Dừng Play, đổi duy nhất `EnableDDA = true` trong Edit Mode, rồi lặp lại bước trên cùng build. Để xác minh Replay, chơi đến khi hệ số hoặc EMA đã thay đổi, kết thúc trận, bấm **Chơi lại** và hoàn thành wave 1. Giữ cửa sổ Play mở trong lúc Replay để diagnostics thấy cả hai MatchId.

Kiểm thử cục bộ diagnostics dùng mô hình sự kiện Luau cho Fixed, HP, chuyển hệ số, bỏ mẫu, Replay, lỗi animation và Victory quá sớm. PASS của fixture chỉ xác nhận logic phân loại. Biên dịch 44 file Luau của repo, 26 nguồn nhúng của RBXL hiện tại và script diagnostics. Spec DDA, Phase 2, bảy test Node và `git diff --check` đều PASS. Không đổi gameplay, công thức DDA, manifest, RBXL hoặc điểm kỹ thuật.

## Cập nhật Act 3 Normal Fixed

Build thu log là `sync-7a71189a55df`, baseline `stone-path-v1`.

| Trạng thái | Hạng mục | Bằng chứng |
| --- | --- | --- |
| **PASS trong phạm vi đã chạy** | Chọn Stone Path Ruin | `match_start` xác nhận `world_1.act_3`, `actId = 3`, `totalWaves = 15`, Normal và Fixed |
| **PASS** | HUD wave 1 và 2 | Người kiểm thử xác nhận HUD hiển thị `1/15` và `2/15`. Log server xác nhận tổng 15 wave; phần hiển thị HUD dựa trên quan sát trong Studio |
| **PASS** | Combat wave 1 | `wave_end` ghi `spawned = 8`, `killed = 8`, `escaped = 0`, `baseHealth = 20`, `maxBaseHealth = 20`, `complete = true` |
| **PASS trong các mẫu đã ghi** | Fixed | `multiplier = 1` và `nextMultiplier = 1` |
| **PASS** | Đặt trụ | Log TowerServer xác nhận đặt IceHero với giá 500 Yen và CrimsonHero với giá 800 Yen |
| **Đã sửa Source, chưa xác minh runtime** | Animation 507770000 | Source TweenService đã có trong RBXL hiện nằm tại đường dẫn workspace khi kiểm tra tĩnh và trong bundle mới. Chưa có Play Test sau sửa để xác nhận idle và cảnh báo |
| **CHƯA KIỂM THỬ** | Các ca còn lại | Boss wave 15, Victory/Defeat, Return/Replay, DDA trong trận thật, multiplayer, mobile và profiler |

Analyzer Act 3 xuất được CSV với một trận Abandoned có đủ dữ liệu và báo ba hồ sơ thiếu đầu/cuối hoặc roster. Đây là log kiểm thử kỹ thuật. Không dùng để tính tỷ lệ thắng hoặc bỏ trận trong thực nghiệm.

Manifest và bundle sinh ra hiện cập nhật Source của đúng Script `Workspace/CrimsonHero/IdleAnimation`, giữ trạng thái Enabled. Generator đã được chỉnh để chấp nhận ModuleScript đã đồng bộ nếu loại và Source khớp, đồng thời vẫn chặn Source khác. Không ghi vào RBXL, không sửa gameplay hoặc DDA và không tăng điểm kỹ thuật.

## Animation 507770000

**FAIL trên bản Studio trước sửa.** Đếm được 12 dòng `Asset is not trusted for this place` và 12 dòng `Failed to load animation with sanitized ID` cho cùng ID trong log Studio ngày 25/11/2026. Chúng là hai dạng thông báo cho cùng lỗi tải. Yêu cầu tải ghi `serverplaceid=0` trong Play Test cục bộ. Log xác nhận ID bị từ chối trong phiên này; quyền của experience đã publish và chủ sở hữu cụ thể chưa xác minh được. Chú thích “Roblox-owned R15 idle” trong script cũ chưa được kiểm chứng.

| Nơi kiểm tra | Kết quả |
| --- | --- |
| Mã Luau xuất ra trước sửa | Không có ID 507770000 |
| Source nhúng RBXL | Một script đang bật: `Workspace/CrimsonHero/IdleAnimation`. Dòng 2 gán ID, dòng 19 gán thuộc tính AnimationId, dòng 22 gọi Animator:LoadAnimation |
| Instance/runtime | Script tạo một `Animation` con tên `IdleAnimation` lúc chạy trên model CrimsonHero trong Workspace. Không có Animation instance lưu sẵn mang ID này |
| Các ID khác | Có 10 Animation nhúng dưới `ReplicatedStorage/Enemies/Zombie/Animate`: 616156119, 616157476, 616158929, 616160636, 616161997, 507768133, 616165109, 616166655, 507768375 và 616168032. ID walk 616168032 và idle 616158929 cũng là ứng viên mà EnemyMover có thể chọn theo tên. Script Animate còn có ID mặc định cho chuyển động/emote. Chưa thấy cảnh báo trust cho các ID khác trong log đã đọc; quyền của chúng trên place đích vẫn cần xác minh |

**Bản sửa giới hạn ở model trưng bày.** Source [IdleAnimation](../../src/Workspace/CrimsonHero/IdleAnimation.server.luau) tạo chuyển động idle nhẹ bằng TweenService trên `UpperTorso.Waist`, khớp đã xác nhận tồn tại trong RBXL. Idle này dùng chuyển động tương đương về chức năng nhưng không tái tạo từng pose của clip cũ. TowerServer vẫn xử lý animation đánh, skill và VFX của trụ đặt. RBXL gốc giữ nguyên; không đổi template Zombie hoặc các ID khác.

**Nếu cần đúng clip cũ**, kiểm tra asset trong Creator Dashboard → Development Items → Animations → Permissions → Experiences (nếu chủ asset cho phép cấp quyền), đối chiếu đúng Universe ID. Nếu không thể cấp quyền, dùng clip R15 mà dự án có quyền xuất, chọn đúng chủ experience hoặc group khi xuất từ Animation Editor, rồi Play Test ID thật trên bản đích trước khi thay thế. [Asset privacy](https://create.roblox.com/docs/projects/assets/privacy) · [Animation Editor](https://create.roblox.com/docs/animation/editor)

**Kiểm thử sau sửa:** trên bản sao đang dùng, thay Source của đúng Script `Workspace → CrimsonHero → IdleAnimation` bằng file mới, giữ Enabled. Chạy Play Solo, xác nhận model trưng bày có idle và Output hết lỗi 507770000. Vào battle, đặt CrimsonHero và IceHero, quan sát đòn thường, skill, VFX và Zombie đi đường. Trạng thái runtime sau sửa **CHƯA XÁC MINH**.

Regression cục bộ PASS: biên dịch 43 file Luau và 22 nguồn RBXL, spec DDA và Phase 2, sáu test Node (gồm kiểm tra truy được đúng script lỗi, joint Waist và URI Zombie), cùng `git diff --check`. SHA-256 RBXL gốc vẫn là `238700D2742FA2B0667E3A644F737AA14ED5DB413F4FEF1D46E251E8395B8BD3`.

## Kết quả Studio ngày 25/11/2026

Đã đối chiếu log Studio do phiên kiểm thử của người dùng tạo, build `sync-7a71189a55df`. Log gốc và CSV kiểm tra nằm ngoài repository.

| Hạng mục | Trạng thái | Bằng chứng |
| --- | --- | --- |
| Dry Run, Apply, Verify | PASS | Dry Run dự kiến 19 thay đổi, Apply cập nhật đủ 19, Verify xác nhận Source, thuộc tính, script cũ và asset được kiểm tra |
| Solo Act 1 Normal, Fixed | PASS một phần | Log ghi `world_1.act_1`, 5 wave, 1 người. Server ghi nhận đặt IceHero với chi phí 500 Yen và CrimsonHero với chi phí 800 Yen |
| Combat và Fixed | PASS trong phạm vi wave đã ghi | Wave 1 hoàn tất trong khoảng 11 giây, hạ 5/5 quái, 0 lọt, căn cứ 20/20. Hai bản ghi wave đều có multiplier áp dụng và kế tiếp bằng 1 |
| Rời trận | PASS | Một `participant_left` ở wave 2, một `match_end` với kết quả `Abandoned` sau khoảng 20,05 giây |
| Analyzer trên log thật | PASS | Xuất được CSV Act 1 và tính đúng một trận Abandoned, không có chẩn đoán. Lọc Act 3 cho kết quả rỗng |
| Act 3 Normal, HUD 1/15 và boss | NGOÀI PHẠM VI PHIÊN ACT 1 | Xem mục cập nhật Act 3 ở đầu báo cáo |
| DDA thực tế, Victory/Defeat, Return/Replay, multiplayer, mobile, 50 trụ và profiler | CHƯA XÁC MINH | Phiên log trên chưa bao phủ các ca này |

Một trận kiểm tra đường rời trận không đủ để suy ra tỷ lệ bỏ trận hoặc tỷ lệ thắng trong nghiên cứu. Lần chạy kế tiếp cần xác nhận `match_start` có `stageId = world_1.act_3` và `totalWaves = 15` ngay sau khi chọn Act 3 Normal.

### Đối chiếu phiên Act 1 của Phase 3.1 và các bước kiểm thử tiếp theo

Khi lọc riêng lượt Act 1, năm dòng telemetry gồm một `match_start`, hai `wave_end` (wave 2 chưa hoàn tất), một `participant_left` và một `match_end`. Analyzer cho một nhóm Fixed, một Abandoned và không có cảnh báo trong lượt này. Menu và server cùng ghi Act 1. Kết quả Act 3 sau đó nằm ở đầu báo cáo.

Log hiện tại thiếu HP đo trực tiếp. Đã bổ sung công cụ [studio-enemy-hp-probe.luau](../../tools/studio-enemy-hp-probe.luau) chạy trong Command Bar ở ngữ cảnh **Server khi Play**. Công cụ đọc MaxHealth của quái mới, ghi tối đa một mẫu cho mỗi loại quái mỗi wave, dùng tiền tố `[DeckHPProbe]` và không sửa instance gameplay hay thay đổi schema telemetry. Dừng Play để gỡ listener. Công cụ nằm ngoài bundle đồng bộ nên bản đã Verify có thể dùng ngay.

1. Trong **Edit Mode**, đặt `ServerScriptService.GameManager.EnableDDA` là `false`. Vào Play Solo, chạy probe ở Server trước khi bấm Start, chọn **The Void → Act 3 → Normal**. Chụp HUD **1/15** và giữ log từ `match_start` đến `match_end`.
2. Với lượt đủ điều kiện Victory, xác nhận wave 14 chưa kết thúc trận, probe hoặc hình ảnh ghi Boss ở wave 15 và `match_end` là Victory sau `wave_end` hoàn chỉnh của wave 15. Chạy Defeat riêng và đối chiếu `baseHealth = 0`.
3. Dừng Play. Trên cùng bản thử, giữ `BuildVersion`, stage, roster và điều kiện chơi, đổi duy nhất `EnableDDA` thành `true`, rồi lặp lại. So HP cùng loại quái giữa Fixed và DDA theo `math.max(1, math.round(HP baseline × appliedMultiplier))` cho Act 3. Đối chiếu `nextMultiplier` ở wave trước với hệ số áp dụng ở wave sau. Sau Replay, kiểm tra MatchId mới, wave 1 bắt đầu với hệ số 1. Ca roster thay đổi cần Start Server từ hai client.
4. Khi có log Act 3, chạy analyzer cho Act 3 và đối chiếu với ảnh hoặc Output. Các lượt này là kiểm thử kỹ thuật.

Chưa có phép đo runtime cho HP, nâng cấp, bán, hiệu ứng kỹ năng, thưởng chính xác, Return/Replay, cleanup qua nhiều trận hoặc multiplayer. Không có thay đổi điểm kỹ thuật trong lượt này.

Regression đã chạy PASS cho 42 file Luau của gameplay và test, 22 nguồn nhúng RBXL, cú pháp probe, spec DDA và Phase 2, năm test Node và `git diff --check`. Probe chưa được chạy trong Studio ở phiên này.

## Kế hoạch kiểm thử ban đầu

Trong phiên chuẩn bị Phase 3, Codex chưa truy cập được Roblox Studio trực tiếp. Bảng dưới mô tả các ca Studio để tiếp tục kiểm thử sau phiên Solo có bằng chứng ở trên.

| Nhóm | Kịch bản | Bằng chứng cần lưu |
| --- | --- | --- |
| Đồng bộ | Bản sao sạch, Dry Run/Apply/Verify, chạy lại và thử rollback trên bản sao thứ hai | Output từng lệnh, kiểm tra hai LobbyController và snapshot Explorer |
| Solo | The Void → Act 3 → Normal, HUD 1/15, IceHero và CrimsonHero, damage/range, slow/AoE, Upgrade/Sell, thưởng, Skip, boss, Victory/Defeat, Return/Replay | Video hoặc ảnh checkpoint, Output server, kiểm tra wave 14 chưa Victory |
| Multiplayer | Hai client cùng/khác Act, Start gần nhau, cùng vị trí, tower ownership, Skip, rời giữa trận, client ở lobby | Snapshot cả hai client, đúng một giao dịch khi tranh vị trí, output roster và kết quả |
| Mobile | Device Emulator ít nhất một điện thoại dọc và một máy tính bảng ngang; hotbar, ghost, đặt bằng chạm, Start/Skip, Upgrade/Sell, Return/Replay | Ảnh/video thao tác và ghi rõ thiết bị mô phỏng |
| Lifecycle | 10 trận, có Replay, rời đột ngột, boss và một trận Invalid trên bản sao fixture | MatchId khác nhau, đúng số match_end, Folder trụ/quái sau cleanup |
| DDA | Chạy Fixed và DDA cùng build, StageId và baseline. So HP của quái mới, chu kỳ roster đổi, wave hủy, trận mới và hành vi bỏ hạ quái | Sự kiện wave_end, hệ số trước/sau, chi phí máu và Yen |
| Telemetry | Thu Output server thật cho Victory, Defeat, Abandoned, Invalid, participant_left | File log ngoài repo, CSV, chẩn đoán analyzer và đối chiếu roster |

Ma trận từng ca xem [STUDIO_TEST_CHECKLIST](STUDIO_TEST_CHECKLIST.md) và [TEST_REPORT](TEST_REPORT.md). Ghi riêng PASS, FAIL, WARNING, NOT RUN hoặc REQUIRES ROBLOX STUDIO kèm build và bằng chứng. Diagnostics PASS xác nhận trạng thái được đọc ở một thời điểm, gameplay phải có bằng chứng riêng.

## Hiệu năng

- Dùng cùng máy, đồ họa, độ phân giải và build. Tách Solo, hai client, 8 trụ cá nhân, cực tải 50 trụ, boss và 10 trận lặp. Với build hero-limits-v1 cần ít nhất 7 người để đạt 50 trụ hợp lệ. Ghi rõ wave và số quái/số trụ thực tế mỗi lần chụp.
- Bật Performance Stats và MicroProfiler ở client và server. Giữ snapshot sau warm-up, chụp 30 giây giữa wave và khi Cleanup. Lưu frame time tính bằng ms, median và p95 từ cùng chuỗi mẫu, FPS client, bộ nhớ, số Instance và bộ đếm kèm thời điểm.
- So snapshot trước trận và sau cleanup qua 10 trận. Xem TowerServer tìm mục tiêu, EnemyMover, raycast, VFX, RenderStepped và Heartbeat. Kết nối chỉ ghi theo bằng chứng profiler hoặc instrumentation nếu thực sự đo được.
- Chưa có giá trị FPS, RAM, frame time hoặc benchmark Phase 3. Log hiện có là một phiên Play Test, chưa có mẫu thực nghiệm người chơi.

```powershell
node tools/analyze-telemetry.mjs server.log act3-summary.csv 3 world_1
```
