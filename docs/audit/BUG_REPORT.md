# Danh sách lỗi và giới hạn

## Cập nhật Phase 2

| ID | Trạng thái Phase 2 | Điểm đối chiếu | Kiểm chứng còn lại |
| --- | --- | --- | --- |
| DD-08 | Đã triển khai Act 3 ở mã nguồn | StageResolver dòng 41 và 72, GameManager dòng 390 | Chơi hết 15 wave trên bản đã đồng bộ |
| DD-14 | Đã dùng chung quy tắc preview/server và phản hồi đặt trụ | PlacementRules dòng 29, TowerServer dòng 626, PlacementClient tại checkPlacementValidity | Raycast thực, bản sao client thiếu dữ liệu, tranh chấp cùng vị trí |
| DD-15 | Đã xác minh và lập manifest từng Instance | SOURCE_SYNC_MANIFEST và tools/inspect-place.mjs | Đồng bộ vào một bản sao Studio |
| DD-16 | Đã cập nhật HUD, Return và Replay. Đã xác định chính xác legacy consumer | MatchResult dòng 3, HUD dòng 336, StarterGui/LobbyGui/LobbyController trong RBXL | Tắt script cũ ở bản thử, xác minh hành vi trong Studio |
| DD-17 | P2, đã thêm giới hạn GetLobbyData | LobbyService dòng 277, 0,5 giây/lượt, xóa thời điểm khi rời | Kiểm tra vòng đời client nhiều người |
| DD-18 | P2, đã sửa nút Start ẩn khi yêu cầu bị từ chối hoặc đang có trận khác | BattleStartController tại updateStartButton | Hai client ở Act khác nhau |
| DD-19 | P2, đã hoãn trừ Yen đến sau khi chuẩn bị clone thành công | TowerServer tại tryPlaceTower | Kiểm tra mẫu trụ thiếu hoặc không thể clone trong bản thử |

## Ghi nhận Phase 1

16 mục, gồm P0 = 0, P1 = 8, P2 = 7 và P3 = 1. Đã sửa ở mã nguồn 12 mục. Bốn mục còn mở. Các mục có trạng thái “Đã sửa” đã qua kiểm tra cú pháp; kịch bản runtime vẫn chờ Studio. Các trường hợp bảo mật dưới đây nêu tiêu chí kiểm tra phòng thủ.

| ID | Mức | Trạng thái | Bằng chứng, nguyên nhân và thay đổi | Kiểm tra hoặc rủi ro còn lại |
| --- | --- | --- | --- | --- |
| DD-01 | P1 | Đã sửa | GameManager dùng Attribute Yen và chỉ đồng bộ NumberValue; TowerServer dùng IntValue. Dùng chung leaderstats.Yen, khởi tạo và reset ở GameManager | Mua trụ, hạ quái, kết thúc wave và chơi lại |
| DD-02 | P1 | Đã sửa | Nhánh defeat ở GameManager cũ nằm đầu vòng; wave thường break trước khi vào nhánh đó. Gom kết quả và cleanup cuối trận | Để base về 0 trong lúc spawn và khi chờ quái cuối |
| DD-03 | P1 | Đã sửa | Worker spawn nằm ngoài vòng đời, trụ không được dọn khi replay. Spawn theo luồng sở hữu trận và dọn enemy/trụ ở mọi kết quả | Thoát toàn đội khi đang spawn, bắt đầu lại |
| DD-04 | P1 | Đã sửa | EnemyMover có đường thoát khi thiếu waypoint nhưng GameManager vẫn giữ bộ đếm sống. Mover trả trạng thái, quản lý Destroying và kết thúc Invalid khi cần | Tạm bỏ đường đi trong bản Studio thử |
| DD-05 | P1 | Đã sửa | RequestStartMatch/SkipWave chỉ ghi cờ chung. Thêm phase, kiểm tra khu battle, roster và đa số nghiêm ngặt | Hai người start, hai người bỏ phiếu hoặc một người rời |
| DD-06 | P1 | Đã sửa | TowerServer phụ thuộc payload vị trí và Remote khác nhau giữa các bản. Dùng cùng handler cho PlaceTower và PlaceUnit, kiểm tra kiểu, giới hạn, mặt đất và route | Test placement hợp lệ và không hợp lệ qua UI |
| DD-07 | P1 | Đã sửa | Upgrade/Sell/TargetMode thiếu kiểm tra Instance và phạm vi trận. Bổ sung guards, sở hữu, cooldown | Kiểm tra bằng client Studio chính chủ và client khác |
| DD-08 | P1 | Mở | StageData.GetAct và UI có Act 3; GameManager.GetWave không nhận stage. Chưa có kết quả Act 3 hợp lệ | Cần cấu hình wave/map riêng và truyền stage có thẩm quyền |
| DD-09 | P2 | Đã sửa | IceHero sửa Humanoid.WalkSpeed trong khi EnemyMover dùng tốc độ đã chụp. Điều chỉnh từng bước theo SlowUntil/SlowFactor | Quan sát tốc độ, phục hồi và làm chậm lặp |
| DD-10 | P2 | Đã sửa | TowerServer quét mỗi Heartbeat, First/Last phụ thuộc thứ tự con. Giới hạn 10 Hz và dùng tiến độ đường đi | Kiểm tra target mode và đo chi phí theo tải |
| DD-11 | P2 | Đã sửa | LobbyService tạo party thay thế khi join/ngắt kết nối; cờ inMatch bị giữ và BattleActive do hai nơi ghi. Sửa chuyển party và trả cờ chuyển tiếp | Kiểm thử leader rời, join public và replay |
| DD-12 | P2 | Đã sửa | MapSelectServer và LobbyManager giữ debounce và thiếu phase guard; LobbyService chưa kiểm tra đầy đủ stage request. Thêm validation, cooldown và cleanup | Kiểm tra các luồng PlayTrigger, Play Menu và party |
| DD-13 | P2 | Đã sửa | Global HUD và placement hiển thị theo trạng thái toàn server. Thêm thuộc tính membership/kết quả theo người chơi | Hai client, một người ở lobby |
| DD-14 | P2 | Mở | Client preview chỉ kiểm waypoint rời rạc, server kiểm cả đoạn và raycast. Màu xanh có thể bị server từ chối | Đồng bộ dự báo qua quy tắc dùng chung sau khi xác nhận asset mặt đất |
| DD-15 | P3 | Mở | Hai cây nguồn cũ, các script thay thế và export thiếu ở một số đường dẫn. Đã lập hướng dẫn đồng bộ có chọn lọc | Chuẩn hóa export sau vòng test và xác nhận bản Studio |
| DD-16 | P2 | Mở | LobbyController ngắn trong RBXL đợi GameOver/GameWin. GameManager dùng GamePhase và HUD có banner riêng. | Xác định ScreenGui nào được dùng và kiểm tra hành vi Return trước khi hợp nhất |

Điểm đối chiếu theo số dòng của bản sau khi sửa.

- DD-01 đến DD-05 và DD-08 dùng GameManager dòng 101, 160, 176, 215, 349, 354, 368 và 434.
- DD-06, DD-07 và DD-10 dùng TowerServer dòng 521, 607, 628, 768, 801 và 813.
- DD-09 dùng EnemyMover dòng 44 và phần tính stepDist, cùng hàm doIceSkill của TowerServer.
- DD-11 và DD-12 dùng LobbyService dòng 239, 270, 300 và 389, LobbyManager dòng 44 và MapSelectServer dòng 96.
- DD-13 dùng HUD và PlacementClient ở các thuộc tính DeckMatchId và DeckResultMatchId.
- DD-14 dùng PlacementClient tại checkPlacementValidity, đối chiếu với TowerServer tại placeTower.
- DD-15 dùng sơ đồ đồng bộ và bảng phạm vi trong PROJECT_AUDIT.
- DD-16 dùng LobbyController nhúng (tên trùng, bản 1.987 ký tự) và HUD.client.luau tại updatePhaseDisplay. Điểm vào chính là [GameManager](../../src/ServerScriptService/GameManager.server.luau), [TowerServer](../../src/ServerScriptService/TowerServer_server.luau), [LobbyService](../../src/ServerScriptService/LobbyService.server.luau) và [EnemyMover](../../src/ReplicatedStorage/Modules/EnemyMover.luau).
