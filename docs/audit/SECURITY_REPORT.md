# Bảo mật client và server

## Cập nhật Phase 2

- TeleportToBattle xác thực world, act, level và tiến độ từ profile do server nắm. Party xác thực từng thành viên. Client gửi lựa chọn, server quyết định nội dung wave.
- PlacementResult chỉ dùng server → client và đối chiếu ID yêu cầu. Server vẫn kiểm tra membership, dữ liệu hữu hạn, cooldown, map, giới hạn, giá và mẫu. Không trừ tiền khi bước chuẩn bị clone thất bại.
- RequestReplay bị giới hạn bởi kết quả terminal, matchId kết quả của người chơi và vị trí battle. Một yêu cầu chờ cho mỗi kết quả.
- GetLobbyData giới hạn 0,5 giây. PlayerRemoving dọn state lựa chọn stage và bảng hạn mức. Telemetry mới dùng số thứ tự người tham gia ngắn hạn.
- Kiểm tra danh mục remote bằng parser RBXL. GameOver/GameWin có consumer cũ trong LobbyGui. Các remote nhúng chưa có handler server tương ứng trong đường chạy chính gồm GetGameState và các sự kiện wave/economy cũ. Đánh giá troll spam ở mức runtime vẫn chờ Studio.

## Ghi nhận Phase 1

| Hướng | Remote | Kiểm soát trong mã cập nhật |
| --- | --- | --- |
| Client → server | RequestStartMatch | Phase chờ, người gọi ở battle, một yêu cầu chờ |
| Client → server | SkipWave | Phase intermission, roster và vị trí, một phiếu mỗi thành viên, trên 50% |
| Client → server | PlaceUnit, PlaceTower | Chung cooldown 0,2 giây, CFrame hữu hạn, allowlist unit, khu vực và bề mặt, khoảng cách đường và trụ, 15 trụ/người và 50 trụ/trận, giá server |
| Client → server | UpgradeUnit, SellUnit, SetTargetMode | Cooldown riêng, kiểm tra Model, folder, chủ sở hữu và match ID, allowlist TargetMode |
| Client → server | TeleportToBattle, TeleportToLobby, StartBattle | Cooldown điều hướng hoặc lựa chọn đã mở gần nhất, phase phù hợp, map/difficulty hợp lệ |
| Client → server | PartyAction, Matchmaking, StartMatch | Cooldown, dữ liệu stage lấy qua StageData, leader, public/capacity, khóa chuyển nhóm |
| Client → server | GetLobbyData | Trả profile của chính người gọi và danh mục; chưa cache/rate-limit RemoteFunction |
| Server → client | MatchCountdown, MatchStarted, ResetBattleUI, UpdateCash, LocationChanged, OpenMapSelect, BattleStarted, TeleportNotice, PartyUpdate | Dùng để hiển thị; quyết định kinh tế và sát thương ở server |

LobbyController ngắn trong RBXL lắng nghe GameOver và GameWin. Script chạm vùng trong RBXL gọi teleport đến một PlaceId cố định. Cần xác nhận script và đích trong Studio trước khi phát hành. Bề mặt còn lại gồm kiểm tra quyền truy cập đơn vị nếu thêm inventory thật, vùng đặt riêng theo map, lưu bền profile, các remote thuộc script chỉ có trong RBXL, và rà secrets theo quy trình phát hành. Pause/SetGameSpeed hoặc giao dịch của các service thử nghiệm chỉ có ý nghĩa nếu ai đó đưa chúng vào runtime. Phân tích phòng thủ hiện dựa trên mã; xử lý end-to-end và tải RemoteFunction cần Studio.
