# Hiệu năng

## Cập nhật Phase 2

Preview vẫn bám chuột qua RenderStepped, còn quét đường, trụ và raycast xác thực màu chạy tối đa khoảng 10 Hz. Lúc click kiểm tra lại. Server giữ kiểm tra đồng bộ trước khi publish clone. GetLobbyData giới hạn 0,5 giây theo player, phản hồi đặt bị từ chối cũng giới hạn nhịp. Phân tích telemetry và CSV chạy ngoài Roblox. Chưa có benchmark; ca N01 trong checklist cần được đo với 50 trụ, boss, nhiều client và 10 trận liên tiếp.

## Ghi nhận Phase 1

Đây là đánh giá tĩnh. Chưa có dữ liệu MicroProfiler, FPS, server frame time hoặc bộ nhớ theo trận.

- TowerServer giới hạn chọn mục tiêu ở 10 Hz mỗi trụ và dùng tìm cực trị một lượt. Chi phí vẫn xấp xỉ O(trụ × quái). Kỹ năng AoE còn quét folder quái khi kích hoạt.
- EnemyMover có một coroutine mỗi enemy và raycast ground theo bước khoảng 0,03 giây. Đo ở wave boss và các fixture có nhiều enemy trước khi thay sang bộ cập nhật tập trung.
- Registry được xóa trước hủy model. GameManager giữ một luồng spawn trong trận, dọn quái và trụ khi kết thúc. Hiệu ứng ngắn còn dùng Debris và tween; kiểm tra số Instance qua nhiều trận.
- PlacementClient vẫn cập nhật preview với RenderStepped và duyệt trụ/waypoint để báo hợp lệ. Cần đo client máy yếu và thiết bị chạm.
- Telemetry có một dòng mỗi wave và sự kiện vào/ra theo vòng đời. Test snapshot Output/server logs trước khi mở rộng số người chơi.

Kịch bản đo gồm solo bình thường, multiplayer, 50 trụ ở giới hạn, wave boss và 10 trận liên tiếp. Ghi median/p95 frame time, số model/connection và bộ nhớ trước/sau. So sánh build gốc và build đồng bộ trong cùng thiết bị và kịch bản.
