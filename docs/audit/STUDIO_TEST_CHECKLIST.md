# Checklist xác minh Studio

Tất cả tình huống dưới đây có trạng thái **REQUIRES ROBLOX STUDIO**. Dùng bản sao RBXL và đồng bộ theo manifest. Ma trận Phase 1 trong TEST_REPORT vẫn áp dụng cho regression.

| Ca | Thao tác | Kết quả chờ xác minh |
| --- | --- | --- |
| S01 | PlayMenu chọn The Void Act 3 Normal, bấm Start | Đúng tên stage, HUD 1/15, đúng sự kiện match_start |
| S02 | Lặp từ LobbyUI party hai client cùng Act 3 | Cùng trận, roster đúng hai người, mỗi người một số thứ tự |
| S03 | Đặt một client chọn Act 1, client kia Act 3 | Countdown và roster chỉ của cùng Act/difficulty |
| S04 | Chọn Act bị khóa theo profile demo, sau đó chọn Act 3 | Act bị khóa bị từ chối, menu giữ mở và Act 3 vào được |
| S05 | Lặp menu map cũ và portal mặc định | Giữ năm wave, HUD đếm đúng |
| S06 | Hoàn thành wave 14 rồi wave 15 | Wave 14 chưa Victory. Wave 15 có boss, kết quả Victory một lần |
| S07 | Tạm đổi tên EnemyBase trong bản thử | Trận Invalid và quay lại chờ |
| P01 | Di chuột trên mặt đất, đoạn giữa hai waypoint, sát trụ và rìa battle | Preview đổi màu theo luật, server khớp ở trạng thái đồng bộ |
| P02 | Hai người đặt cùng vị trí gần đồng thời | Một người thành công, đúng một lần trừ Yen, người còn lại có phản hồi |
| P03 | Thử khi thiếu Yen, đủ 15 trụ cá nhân, hoặc đủ 50 trụ trận | Không spawn và không trừ tiền |
| P04 | Kết thúc trận khi đang đặt, đổi ghost trong lúc đợi phản hồi | Không đặt sang trận mới hoặc xóa preview mới |
| P05 | Đặt trên bề mặt nghiêng, thấp, cao hoặc không có ground | Vị trí hợp lệ được snap tới bề mặt server |
| R01 | Thắng bằng client A, client B ở lobby | A thấy một banner, B không thấy |
| R02 | Thua rồi bấm Về Lobby | Banner đóng, UI lobby trở lại |
| R03 | Chơi lại sau Victory và Defeat | Countdown mới, matchId mới, cùng Act nếu còn đứng trong battle |
| R04 | Lặp 10 trận hoặc rời khi đang chạy | Cleanup trụ/quái, không giữ banner cũ hoặc tăng connection theo mỗi trận |
| D01 | Lặp Act 3 Fixed và DDA | Fixed luôn 1. DDA chỉ thay HP của các quái spawn wave sau |
| D02 | Một người rời lúc wave chạy hoặc wave bị hủy | Không cập nhật EMA bằng mẫu roster đổi hoặc wave lỗi |
| T01 | Lưu log 2 nhóm, thêm kết quả thiếu và trùng vào bản sao log | Analyzer lọc Act 3, chẩn đoán, đối chiếu số trận và số lượt bỏ |
| N01 | Test Solo, 2 client và 50 trụ, chụp MicroProfiler ở boss | Ghi CPU p95, memory, số trụ/quái và độ ổn định |
