# Thay đổi trên nhánh kiểm toán

## Build hero-limits-v2

- Thêm ô Yen trong trận, căn giữa trên Hotbar và cách 10 px. Số dư dùng `leaderstats.Yen`, hiệu ứng nổi dùng khoản thưởng do server gửi theo MatchId. Bundle một lần chạy chấp nhận bản RC v2 đã lưu trước khi có HUD Yen.

- Thêm dấu nhận biết build khi TowerServer khởi động và log số Hero, Owner, UnitType, MatchId và Yen trong Studio.
- Đếm model Hero đã được server đăng ký bằng thuộc tính ngay cả khi root part bị thiếu. Cả hai remote kiểm giới hạn trước Clone và giao dịch Yen.
- Bundle nâng cấp RC v1 và kiểm tra các script tạo trụ song song đã biết. Hotbar báo “Đã đạt giới hạn 4 Hero!”.

## Phase 4 QA

- Tách cảnh báo animation có sẵn trong lịch sử Output khỏi lỗi trực tiếp trong phiên diagnostics đang theo dõi.
- CSV telemetry thêm số wave hoàn thành trung bình, hệ số đã áp dụng trung bình và số wave dùng làm mẫu. Analyzer loại hồ sơ thiếu các wave bắt buộc trước khi kết thúc.
- Ghi nhận Victory Act 3 Fixed và MaxHealth Boss từ log thật; lập bảng kiểm thử mobile, performance và điều kiện chốt release.

## Build hero-limits-v1

- Giới hạn mỗi người chơi trong một trận ở 4 IceHero và 4 CrimsonHero, tối đa 8 Hero. Giới hạn toàn trận vẫn là 50 trụ.
- Hotbar hiển thị số lượng hiện có trên mỗi loại, đổi đỏ ở 4/4 và chặn mở Ghost Preview khi đã đủ. Bán trụ trả lại một chỗ đặt. Nâng cấp giữ nguyên bộ đếm.
- Studio Sync nâng cấp đúng PlacementRules, TowerServer và PlacementClient trên bản sao đã đồng bộ. Apply đặt GameManager.BuildVersion thành hero-limits-v1 và giữ giá trị EnableDDA hiện có.

## Cập nhật Phase 2

- Thêm StageResolver, PlacementRules và MatchResult. Cập nhật StageData và UI chọn màn.
- Cập nhật GameManager, các server lobby, BattleStart, HUD, TowerServer và PlacementClient.
- Bổ sung schema telemetry, analyzer CSV, công cụ đọc cây RBXL, hai spec Phase 2, mô phỏng, manifest và quy trình nghiên cứu.
- Không xóa script hoặc asset. Chỉ cập nhật Source qua bản sao Studio theo manifest.

## Ghi nhận Phase 1

- GameManager.server.luau quản lý một luồng trận, roster, bỏ phiếu skip, Yen, kết quả, replay, DDA và telemetry.
- DifficultyController.luau và tests/DifficultyController.spec.luau thêm bộ điều khiển thuần Luau và unit test.
- TowerServer_server.luau xử lý hai tên remote placement qua cùng handler, thêm kiểm tra server, giới hạn trụ, quyền sở hữu và chọn mục tiêu theo tiến độ.
- EnemyMover.luau trả trạng thái khởi động và áp dụng chậm khi di chuyển.
- LobbyManager.server.luau, LobbyService.server.luau và MapSelectServer.server.luau bổ sung kiểm tra đầu vào, trạng thái chuyển tiếp và dọn dữ liệu.
- PlacementClient.client.luau và HUD.client.luau dùng match membership. Phần hiển thị kết quả dùng match ID.
- README và src/README cập nhật đường dẫn tài liệu và mô tả baseline. RBXL và PlayMenuController đã có thay đổi trước cuộc kiểm toán.
