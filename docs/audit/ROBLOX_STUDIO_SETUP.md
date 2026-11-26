# Đồng bộ và chạy trong Roblox Studio

## Cập nhật Phase 2

Dùng quy trình Phase 2 sau đây. Tên và trạng thái Instance chi tiết trong [manifest](SOURCE_SYNC_MANIFEST.md).

1. Nhân bản TowerDefense_DoAn.rbxl sang một tên thử nghiệm. Mở bản sao trong Studio. Không nhập cả src.
2. Tạo bốn ModuleScript. Trong ServerScriptService có StageResolver và DifficultyController. Trong ReplicatedStorage.Modules có PlacementRules và MatchResult.
3. Cập nhật Source của GameManager, TowerServer, LobbyManager, LobbyService, MapSelectServer. Cập nhật EnemyMover và StageData ở ReplicatedStorage.Modules. Giữ WaveData nhúng và tài sản hiện có.
4. Cập nhật StarterPlayer/StarterPlayerScripts/PlacementClient và các LocalScript BattleStartController, HUD, PlayMenuController và LobbyUI/LobbyController như manifest.
5. Tắt đúng LocalScript ở StarterGui/LobbyGui/LobbyController vốn chờ GameOver/GameWin. Giữ nguyên LobbyGui và script để có thể bật lại. LobbyUI/LobbyController ở ScreenGui khác phải giữ bật.
6. Đặt thuộc tính EnableDDA (Boolean) và BuildVersion (String) trên GameManager. Dùng cùng BuildVersion cho hai nhóm cùng build.
7. Thực hiện Play Solo và Test → Start Server. Chọn The Void → Act 3 → Normal, sau đó bấm Start ở battle. Chạy checklist, lưu Output server và phân tích thử. Chỉ lưu RBXL thử nghiệm sau khi xác nhận Instance và Output.

## Ghi nhận Phase 1

1. Mở bản sao TowerDefense_DoAn.rbxl bằng Studio. Giữ bản làm việc gốc riêng. Chuyển sang Explorer và Output.
2. Thay **Source của Instance đang có**, giữ vị trí và loại script. Trong ServerScriptService, thay GameManager, TowerServer, LobbyManager, LobbyService và MapSelectServer bằng các file tương ứng trong src. TowerServer dùng file TowerServer_server.luau.
3. Tạo ModuleScript DifficultyController trực tiếp dưới ServerScriptService và dán mã. Đặt Boolean Attribute EnableDDA trên GameManager với giá trị false cho bản Fixed và true cho bản DDA.
4. Thay ReplicatedStorage.Modules.EnemyMover. Giữ WaveData nhúng cho lần đối chiếu trước khi đổi baseline. Giữ Health của Zombie ở Disabled như RBXL đã đọc. Xác nhận asset nội bộ và model templates IceHero, CrimsonHero, Zombie, Workspace.Waypoints, EnemySpawn và EnemyBase.
5. Đồng bộ PlacementClient ở StarterPlayer → StarterPlayerScripts và HUD ở ScreenGui battle tương ứng theo Explorer. Chỉ thay đúng script cùng chức năng. Bản RBXL giữ PlaceTower tương thích với server cập nhật, còn bản xuất PlacementClient dùng PlaceUnit.
6. Mở Play Solo, qua Play menu/teleport đến vùng battle và bấm Start. Mở Test → Start Server với hai client, thực hiện ma trận trong TEST_REPORT. Lưu Output server khi kiểm tra log.
7. Chỉ lưu một RBXL thử nghiệm mới sau khi test thành công. So sánh lại script đang Enabled trong Explorer trước khi đổi file chính. Repo chưa có dự án Rojo.

WaveService, EnemyService, UnitService và TowerCombat là nhánh nguồn khác; các script này không xuất hiện trong RBXL kiểm tra. Giữ danh sách script thực thi theo Explorer khi đồng bộ. Nếu khác phiên bản place, xác nhận các Asset, Remote và script đích trước khi dán. Script nhúng có thể có thay đổi so với src, đặc biệt LobbyManager, LobbyService, HUD, PlacementClient và StageData.
