# Kiểm toán Deck Defenders

## Cập nhật Phase 2

Đã triển khai bốn hạng mục còn lại ở mã nguồn hoặc quy trình đồng bộ. Đọc được chính xác 22 Instance script trong RBXL, xác minh cây asset tĩnh và compile 41 file Luau repo. Kết quả gần nhất, giới hạn runtime và điểm theo tiêu chí nằm trong [nghiệm thu Phase 2](FINAL_ACCEPTANCE_REPORT.md). Phần dưới lưu số liệu của Phase 1.

## Ghi nhận Phase 1

Mốc kiểm tra ngày 25/11/2026 là commit `2a123c1217e7929be2ee85e85cb22890f7a19dd6` của `main`. Diff làm việc nằm trên `audit/full-project-review`. Workspace ban đầu có chỉnh sửa tại RBXL và PlayMenuController. Bản RBXL làm việc được đọc ở chế độ chỉ đọc và hai chỉnh sửa sẵn có được giữ lại.

Deck Defenders có một khu battle dùng chung và năm wave hữu hạn, với Zombie, Skeleton, Goblin và Boss. IceHero và CrimsonHero có đặt, nâng cấp, bán, chọn mục tiêu và kỹ năng AoE. Danh mục StageData và UI lobby có nhiều Act, song quá trình chơi dùng chung WaveData. Các profile mẫu nằm trong bộ nhớ và chứa dữ liệu demo.

## Phạm vi kiểm tra

| Nhóm | Bằng chứng | Giới hạn |
| --- | --- | --- |
| 6 file Luau ở thư mục gốc | Kiểm tra cấu trúc, đối chiếu tên và compile | Chuỗi WaveService cũ thiếu EnemyService tại gốc và vắng trong RBXL |
| 7 module ReplicatedStorage và 2 script Zombie trong src | Compile và đối chiếu WaveData, WaveConfig, StageData, EnemyMover và dữ liệu/config thử nghiệm | Asset và chuyển động cần Studio |
| 12 script/module server trong src ban đầu | Compile, rà entry point, dependencies và remote. Đọc sâu đường chạy GameManager, TowerServer và lobby | Các nhánh UnitService, EnemyService, WaveService và TowerCombat là mã ngoài luồng của RBXL này |
| 7 script client/Workspace ban đầu | Compile và đọc luồng remote, HUD, vị trí và placement | Chưa kiểm thử giao diện, thao tác chạm và teleport |
| RBXL làm việc | 22 nguồn được trích đọc và compile. Gồm 10 Script (Health bị tắt), 8 LocalScript và 4 ModuleScript | Chưa mở cây Instance, asset, thiết lập Studio hoặc chơi thử |
| Nguồn sau thay đổi | 36 file Luau gồm 34 file có sẵn, một module DDA và một spec | Compile kiểm tra cú pháp, chưa chạy type checker toàn repo |

RBXL là bằng chứng về script thực tế trong place. `src/` là nơi duyệt thay đổi và đồng bộ từng script. Trong 22 nguồn nhúng ban đầu, tám nguồn trùng bản xuất khi chuẩn hóa newline và khoảng trắng ngoài. Placement trong RBXL dùng PlaceTower, bản xuất dùng PlaceUnit. RBXL có hai LobbyController, HUDAnimator, DifficultyPatch, IdleAnimation và một Script chung tên. Cần kiểm tra vị trí và hành vi của các script riêng này trước lần xuất tiếp theo.

## Điểm kỹ thuật tĩnh

| Tiêu chí | Tối đa | Trước | Sau | Lý do |
| --- | ---: | ---: | ---: | --- |
| Kiến trúc | 10 | 5 | 6 | Quyền điều phối tập trung hơn, vẫn cần đồng bộ place |
| Chất lượng mã | 10 | 5 | 6 | Bớt hai đường xử lý tiền và vòng spawn bất đồng bộ tách rời |
| Gameplay | 15 | 8 | 10 | Có đặt, đánh, thắng, thua và cleanup theo mã, còn thiếu xác nhận Studio |
| DDA | 20 | 3 | 13 | Có phản hồi giữa wave, giới hạn và unit test, còn thiếu cân chỉnh trên người chơi |
| UI/UX | 10 | 5 | 6 | HUD cập nhật vai trò người chơi, mobile chưa xác minh |
| Bảo mật | 10 | 4 | 7 | Kiểm tra server cho trạng thái, vị trí và quyền sở hữu, còn bề mặt lobby |
| Hiệu năng | 10 | 5 | 6 | Giảm tần suất quét mục tiêu, chưa đo profiler |
| Testing | 10 | 1 | 4 | Có compile và unit test, còn thiếu integration/runtime |
| Tài liệu | 5 | 2 | 4 | Có hướng dẫn đồng bộ, ma trận test và quy tắc chỉ số |
| Tổng | 100 | 38 | 62 | Đánh giá kỹ thuật, chưa phải điểm chính thức |

Xem [danh sách lỗi](BUG_REPORT.md), [kiểm thử](TEST_REPORT.md), [kiến trúc](ARCHITECTURE.md) và [checklist bảo vệ](ROADMAP.md).
