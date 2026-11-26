# Mã nguồn Deck Defenders

Thư mục này chứa các bản xuất Luau và các bản thử nghiệm. Bản place hiện có các Instance và asset trong TowerDefense_DoAn.rbxl.

- ServerScriptService/GameManager.server.luau quản lý trận, trạng thái HUD, wave, spawn và Yen.
- ServerScriptService/TowerServer_server.luau quản lý placement và combat cho IceHero và CrimsonHero.
- ServerScriptService/DifficultyController.luau quản lý multiplier HP ở ranh giới wave.
- ServerScriptService/StageResolver.luau xác thực stage và định nghĩa baseline thử nghiệm Act 3 gồm 15 wave.
- ReplicatedStorage/Modules/WaveData.luau chứa năm wave baseline cũ và cấu hình Endless. EnemyMover.luau điều khiển quái theo waypoint.
- ReplicatedStorage/Modules/PlacementRules.luau và MatchResult.luau chứa quy tắc dùng chung cho placement và dedup kết quả.
- StarterGui và StarterPlayerScripts chứa các bản xuất giao diện và placement. Workspace chứa bản xuất script teleport.

Đọc [phân tích kiến trúc](../docs/audit/ARCHITECTURE.md) và [cách đồng bộ](../docs/audit/ROBLOX_STUDIO_SETUP.md) trước khi cập nhật Studio.
