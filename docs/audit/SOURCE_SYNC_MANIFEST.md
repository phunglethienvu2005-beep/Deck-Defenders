# Ánh xạ mã nguồn và Instance

Bundle giao diện có 18 đích và giữ BuildVersion `hero-limits-v2`. One-click dùng RC hiện tại, kiểm tra fingerprint của hai controller trước khi cập nhật và tạo module theme. Output Verify ghi thêm fingerprint bundle.

Bundle `hero-limits-v2` giữ 17 đích Source. PlacementRules, TowerServer và PlacementClient có fingerprint của các phiên bản trước, gồm RC v1 đã lưu. Apply cập nhật thuộc tính BuildVersion của GameManager, giữ Source GameManager. Dry Run dừng nếu TowerCombat, UnitService hoặc TowerServer_server cũ được nhập và có thể chạy bên cạnh TowerServer.

Đọc nhị phân ở chế độ chỉ đọc bằng `node tools/inspect-place.mjs TowerDefense_DoAn.rbxl`. Công cụ giải nén zstd và đọc INST, PROP, PRNT để định vị từng script, loại và thuộc tính Disabled. Cột Enabled mô tả bản RBXL hiện có. ModuleScript chỉ chạy khi được require. Script con của template chỉ được kiểm tra trong ngữ cảnh của template và bản clone.

| File nguồn | Instance Roblox Studio | Loại Script | Enabled | Trạng thái đồng bộ |
| --- | --- | --- | --- | --- |
| `src/ReplicatedStorage/Modules/UnitLoadout.luau` | `ReplicatedStorage/Modules/UnitLoadout` | `ModuleScript` | `—` | `Tạo ModuleScript` |
| `src/ReplicatedStorage/Modules/UnitCollectionView.luau` | `ReplicatedStorage/Modules/UnitCollectionView` | `ModuleScript` | `—` | `Tạo ModuleScript` |
| `src/ServerScriptService/PlayerDash.server.luau` | `ServerScriptService/PlayerDash` | `Script` | `Có` | `Tạo Script` |
| `src/StarterPlayerScripts/PlayerDash.client.luau` | `StarterPlayer/StarterPlayerScripts/PlayerDash` | `LocalScript` | `Có` | `Tạo LocalScript` |
| `ReplicatedStorage/Modules/Config.luau` | `—` | `ModuleScript` | `—` | `Bản gốc cũ, ngoài runtime` |
| `ReplicatedStorage/Modules/EnemyData.luau` | `—` | `ModuleScript` | `—` | `Bản gốc cũ, ngoài runtime` |
| `ReplicatedStorage/Modules/UnitData.luau` | `—` | `ModuleScript` | `—` | `Bản gốc cũ, ngoài runtime` |
| `ReplicatedStorage/Modules/WaveData.luau` | `—` | `ModuleScript` | `—` | `Bản gốc cũ, ngoài runtime` |
| `ReplicatedStorage/Modules/WaveData.module.luau` | `—` | `ModuleScript` | `—` | `Bản gốc cũ, ngoài runtime` |
| `ServerScriptService/WaveService.server.luau` | `—` | `Script` | `—` | `Bản gốc cũ, ngoài runtime` |
| `src/ReplicatedStorage/Enemies/Zombie/Animate.server.luau` | `ReplicatedStorage/Enemies/Zombie/Animate` | `Script` | `Có` | `Khớp, giữ` |
| `src/ReplicatedStorage/Enemies/Zombie/Health.server.luau` | `ReplicatedStorage/Enemies/Zombie/Health` | `Script` | `Tắt` | `Khớp, giữ` |
| `src/ReplicatedStorage/Modules/Config.luau` | `—` | `ModuleScript` | `—` | `Thử nghiệm hoặc thay thế, không nhập` |
| `src/ReplicatedStorage/Modules/CrystalMenuTheme.luau` | `ReplicatedStorage/Modules/CrystalMenuTheme` | `ModuleScript` | `—` | `Tạo ModuleScript` |
| `src/ReplicatedStorage/Modules/EnemyData.luau` | `—` | `ModuleScript` | `—` | `Thử nghiệm hoặc thay thế, không nhập` |
| `src/ReplicatedStorage/Modules/EnemyMover.luau` | `ReplicatedStorage/Modules/EnemyMover` | `ModuleScript` | `—` | `Cập nhật Source` |
| `src/ReplicatedStorage/Modules/MatchResult.luau` | `ReplicatedStorage/Modules/MatchResult` | `ModuleScript` | `—` | `Tạo ModuleScript` |
| `src/ReplicatedStorage/Modules/PlacementRules.luau` | `ReplicatedStorage/Modules/PlacementRules` | `ModuleScript` | `—` | `Tạo ModuleScript` |
| `src/ReplicatedStorage/Modules/StageData.luau` | `ReplicatedStorage/Modules/StageData` | `ModuleScript` | `—` | `Cập nhật Source` |
| `src/ReplicatedStorage/Modules/UnitData.luau` | `—` | `ModuleScript` | `—` | `Thử nghiệm hoặc thay thế, không nhập` |
| `src/ReplicatedStorage/Modules/WaveConfig.luau` | `ReplicatedStorage/Modules/WaveConfig` | `ModuleScript` | `—` | `Khớp, giữ` |
| `src/ReplicatedStorage/Modules/WaveData.luau` | `ReplicatedStorage/Modules/WaveData` | `ModuleScript` | `—` | `Khác bản xuất, giữ bản nhúng` |
| `src/ServerScriptService/DifficultyController.luau` | `ServerScriptService/DifficultyController` | `ModuleScript` | `—` | `Tạo ModuleScript` |
| `src/ServerScriptService/EnemyService.luau` | `—` | `ModuleScript` | `—` | `Thử nghiệm hoặc thay thế, không nhập` |
| `src/ServerScriptService/EnemyService.server.luau` | `—` | `Script` | `—` | `Thử nghiệm hoặc thay thế, không nhập` |
| `src/ServerScriptService/GameManager.server.luau` | `ServerScriptService/GameManager` | `Script` | `Có` | `Cập nhật Source` |
| `src/ServerScriptService/LobbyManager.server.luau` | `ServerScriptService/LobbyManager` | `Script` | `Có` | `Cập nhật Source` |
| `src/ServerScriptService/LobbyService.server.luau` | `ServerScriptService/LobbyService` | `Script` | `Có` | `Cập nhật Source` |
| `src/ServerScriptService/MapSelectServer.server.luau` | `ServerScriptService/MapSelectServer` | `Script` | `Có` | `Cập nhật Source` |
| `src/ServerScriptService/StageResolver.luau` | `ServerScriptService/StageResolver` | `ModuleScript` | `—` | `Tạo ModuleScript` |
| `src/ServerScriptService/TowerCombat.server.luau` | `—` | `Script` | `—` | `Thử nghiệm hoặc thay thế, không nhập` |
| `src/ServerScriptService/TowerServer_server.luau` | `ServerScriptService/TowerServer` | `Script` | `Có` | `Cập nhật Source` |
| `src/ServerScriptService/UnitService.luau` | `—` | `ModuleScript` | `—` | `Thử nghiệm hoặc thay thế, không nhập` |
| `src/ServerScriptService/UnitService.server.luau` | `—` | `Script` | `—` | `Thử nghiệm hoặc thay thế, không nhập` |
| `src/ServerScriptService/WaveService.luau` | `—` | `ModuleScript` | `—` | `Thử nghiệm hoặc thay thế, không nhập` |
| `src/ServerScriptService/WaveService.server.luau` | `—` | `Script` | `—` | `Thử nghiệm hoặc thay thế, không nhập` |
| `src/StarterGui/AnimePlayMenuUI/PlayMenuController.client.luau` | `StarterGui/AnimePlayMenuUI/PlayMenuController` | `LocalScript` | `Có` | `Cập nhật Source` |
| `src/StarterGui/BattleStartGui/BattleStartController.client.luau` | `StarterGui/BattleStartGui/BattleStartController` | `LocalScript` | `Có` | `Cập nhật Source` |
| `src/StarterGui/GameUI/HUD.client.luau` | `StarterGui/GameUI/HUD` | `LocalScript` | `Có` | `Cập nhật Source` |
| `src/StarterGui/LobbyUI/LobbyController.client.luau` | `StarterGui/LobbyUI/LobbyController` | `LocalScript` | `Có` | `Cập nhật Source` |
| `src/StarterGui/UnitInfoGui/UnitInfoController.client.luau` | `StarterGui/UnitInfoGui/UnitInfoController` | `LocalScript` | `Có` | `Khớp, giữ` |
| `src/StarterPlayerScripts/PlacementClient.client.luau` | `StarterPlayer/StarterPlayerScripts/PlacementClient` | `LocalScript` | `Có` | `Cập nhật Source` |
| `src/Workspace/TheVoid_Teleport.server.luau` | `Workspace/The Void/Model/Part/Script` | `Script` | `Có` | `Khác bản xuất, giữ bản nhúng` |
| `tests/DifficultyController.spec.luau` | `—` | `ModuleScript` | `—` | `Kiểm thử cục bộ, ngoài place` |
| `tests/Phase2.spec.luau` | `—` | `ModuleScript` | `—` | `Kiểm thử cục bộ, ngoài place` |
| `tests/roblox-value-mocks.luau` | `—` | `ModuleScript` | `—` | `Kiểm thử cục bộ, ngoài place` |
| `—` | `StarterGui/LobbyGui/LobbyController` | `LocalScript` | `Có` | `Chỉ RBXL, UI kết quả cũ, tắt trong bản thử` |
| `—` | `StarterGui/AnimeLobbyHUD/HUDAnimator` | `LocalScript` | `Có` | `Chỉ RBXL, giữ` |
| `src/Workspace/CrimsonHero/IdleAnimation.server.luau` | `Workspace/CrimsonHero/IdleAnimation` | `Script` | `Có` | `Cập nhật Source, giữ Enabled` |
| `—` | `ServerScriptService/DifficultyPatch` | `Script` | `Có` | `Chỉ RBXL, global preset cũ, giữ` |

## Asset và điểm đồng bộ

Đã thấy Workspace/EnemySpawn, Workspace/EnemyBase, Workspace/Waypoints với WP1–WP8, Workspace/BattleSpawn, ReplicatedStorage/Towers/{IceHero,CrimsonHero}, ReplicatedStorage/Enemies/Zombie và ReplicatedStorage/VFX. Kết quả xác nhận tên, lớp và cây parent. Cần Studio để xác minh hình học, collision, animation, vị trí và quyền asset. Act 3 dùng cùng tuyến The Void.

GameOver và GameWin tồn tại trong Remotes. Consumer cũ nằm chính xác ở StarterGui/LobbyGui/LobbyController. Giữ ScreenGui và script, tắt riêng LocalScript này trong bản thử sau khi đối chiếu nội dung; GameUI/HUD đảm nhiệm kết quả. StarterGui/LobbyUI/LobbyController là script lobby khác và phải giữ bật.

Repo chưa có cấu hình Rojo và place chứa cây asset/GUI do Studio quản lý. Nếu thử Rojo, dùng project riêng cho các module mới trong bản sao và xác nhận scope trên Explorer. Quy trình được chọn cho lần này là đồng bộ Source từng Instance.
