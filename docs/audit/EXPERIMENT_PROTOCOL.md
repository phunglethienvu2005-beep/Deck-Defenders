# Quy trình thực nghiệm

1. Đồng bộ vào hai bản thử cùng code, route, stageDifficulty, wave baseline, giá và phần thưởng. Đặt cùng BuildVersion. Bản Fixed dùng EnableDDA=false. Bản DDA dùng EnableDDA=true.
2. Chạy checklist Studio và xác nhận vài lượt pilot trước khi thu số liệu chính thức. Kiểm tra mỗi lượt pilot có match_start đúng world_1.act_3 và TotalWaves 15.
3. Chia nhóm trước trận. Giữ cùng phương thức chọn Act 3 và điều kiện số người. Ghi quy trình phân nhóm, build và lịch chơi. Nếu thử solo và nhiều người, ghi riêng theo quy mô roster.
4. Thu Output server. Lưu ngoài repo nghiên cứu nếu log còn chứa dữ liệu người chơi từ script cũ. Bảo quản bản gốc và giữ chẩn đoán của analyzer.
5. Báo cáo số lượt hợp lệ và Invalid, tỷ lệ thắng, tỷ lệ rời, thời lượng và số bản ghi thiếu. Báo số mẫu trước khi so sánh tỷ lệ. So sánh với cùng build, độ khó và baseline đã đăng ký.
6. Công bố bảng mô phỏng DDA riêng. Các kết quả thực nghiệm chờ dữ liệu từ người chơi.

## Phase 4 — cấu hình và bảng thu số liệu

Chốt một build đã nghiệm thu trước khi tuyển người. Cả hai nhóm dùng cùng Act 3 Normal, 15 wave, baseline `stone-path-v1`, map, số người, quy tắc Skip, vốn đầu trận, phần thưởng, giá, damage, kỹ năng và giới hạn 4 IceHero + 4 CrimsonHero / người, 50 trụ / trận. A dùng `EnableDDA=false`, B dùng `EnableDDA=true`. Gán nhóm trước khi chơi, ghi theo mã nghiên cứu ẩn danh. Chọn trước số lượt mỗi người và quy tắc xử lý lượt lặp. Tách lượt QA và pilot khỏi dữ liệu nghiên cứu.

| Chỉ số | Group A · Fixed | Group B · DDA | Cách tính |
| --- | --- | --- | --- |
| Số người tham gia | — | — | Mã người tham gia duy nhất trong danh sách phân nhóm. Một người có thể có nhiều lượt chơi |
| Số trận hợp lệ | — | — | `valid`. Đếm riêng Invalid và hồ sơ thiếu hoặc mâu thuẫn |
| Tỷ lệ thắng Act 3 | — | — | `winRatePercent`: Victory / (Victory + Defeat + Abandoned) |
| Tỷ lệ bỏ giữa trận | — | — | `leaveRatePercent`: lượt tham gia rời trước khi trận kết thúc / lượt tham gia hợp lệ |
| Thời gian chơi trung bình | — | — | `averageMatchSeconds` trên mọi trận hợp lệ |
| Số wave hoàn thành trung bình | — | — | `averageCompletedWaves`: tổng wave hoàn thành / số trận hợp lệ |
| Hệ số áp dụng trung bình | — | — | `averageAppliedMultiplier`: trung bình multiplier đã áp dụng ở wave hoàn thành; kèm số mẫu `completedWaveSamples` |
| Mức độ khó theo người chơi | — | — | Hỏi sau lượt chơi trên thang 1–5 từ rất dễ đến rất khó; ghi số phản hồi, trung vị và phân bố điểm |

`participantSessions` trong CSV đếm lượt tham gia, không đếm người duy nhất. Thu phản hồi riêng theo mã nghiên cứu và giữ dữ liệu nghiên cứu ngoài Git. Bỏ trống mục chưa có mẫu, kể cả mục không có phản hồi.
