# DDA và thực nghiệm

## Cập nhật Phase 2

Act 3 hiện có baseline 15 wave trong StageResolver. Mô phỏng sáu hồ sơ, test dữ liệu hữu hạn và báo cáo ở [DDA Simulation](DDA_SIMULATION_REPORT.md). Trọng số và biên giữ nguyên Phase 1. Fixed ghi score thô khi có mẫu hợp lệ và giữ multiplier 1. Wave lỗi hoặc roster đổi trong lúc chạy không cập nhật EMA. Chỉ số nghiên cứu áp dụng theo [hướng dẫn telemetry](TELEMETRY_GUIDE.md) và [quy trình thực nghiệm](EXPERIMENT_PROTOCOL.md).

## Ghi nhận Phase 1

Trước thay đổi, WaveData đi theo thứ tự và Endless tăng thông số theo số wave. DifficultyPatch và MapSelect đặt độ khó mặc định/menu. Chưa có đầu vào hiệu suất đưa ngược vào cấu hình wave.

Sau thay đổi, server tạo trạng thái mới cho từng trận. Wave 1 luôn bắt đầu với multiplier 1. Mỗi wave hợp lệ hoàn thành với roster ổn định cho một mẫu:

- `k = killed / spawned`, giới hạn trong [0, 1]. Quái lọt căn cứ làm giảm tỷ lệ này và giảm máu base.
- `h = BaseHealth / MaxBaseHealth`, giới hạn trong [0, 1].
- `p = clamp(1 - (elapsed - expected) / max(expected, 1), 0, 1)`. Expected là tổng khoảng spawn giữa các thành viên trong từng nhóm cộng 25 giây. Thời gian chuẩn bị và bỏ phiếu skip nằm ngoài phép đo.
- Mẫu `s = 0.55k + 0.30h + 0.15p`. EMA xuất phát 0,75 và cập nhật `e := e + 0.35(s - e)`.
- Nếu `|e - 0.75| > 0.05`, đổi multiplier tối đa ±0,08 mỗi wave theo `0.40(e - 0.75)`. Chặn tổng trong từ 0,80 đến 1,25.

Chỉ HP của quái mới thay đổi theo multiplier. Speed, count, interval, tổ hợp và thưởng dùng baseline. Điều chỉnh bắt đầu ở wave sau. Bỏ quái có chi phí máu và mất thưởng hạ quái, giới hạn giảm 20% và yêu cầu mẫu hoàn thành hợp lệ. Chưa đo chiến thuật cố ý chơi kém, độ khó bất khả thi hay tác động multiplayer. Trọng số, mục tiêu và ngưỡng là tham số thử nghiệm. DDA dùng dữ liệu toàn đội; roster và lượt rời ghi theo người, chưa chấm hiệu suất cá nhân hoặc dùng Yen.

## Cách đo

Trong Studio, đặt Boolean Attribute EnableDDA trên GameManager. False hoặc thiếu thuộc tính chạy Fixed; true chạy DDA. Chế độ được chụp khi trận bắt đầu. Dùng hai bản có cùng map, số wave, giá, rewards và quy tắc skip. Phân nhóm trước khi chơi, ghi phiên bản build và quy tắc phân nhóm. Không đổi chế độ giữa trận.

Output server ghi JSON với tiền tố DeckTelemetry. Khóa dedup là matchId + event, thêm wave cho wave_end và userId cho participant_left. Ghép các sự kiện bằng matchId; bản ghi thiếu match_end báo riêng. Lưu Output ngoài Studio hoặc bổ sung kho sự kiện có quyền truy cập; log hiện chưa ghi DataStore, file JSON hay Sheets trực tiếp. Hạn chế phân phối UserId trong log nghiên cứu. Với aborted wave, spawned có thể lớn hơn killed + escaped + removed do còn quái khi cleanup. Các mẫu chưa hoàn tất không đưa vào DDA.

- **Tỷ lệ thắng màn 3** = số trận Act 3 kết thúc Victory / số trận Act 3 hợp lệ đã khởi chạy × 100. Chốt trước quy tắc giữ Abandoned trong mẫu số; đề xuất giữ để tránh loại các lần bỏ cuộc. Công bố riêng Invalid và thiếu log.
- **Tỷ lệ bỏ giữa màn** = số cặp matchId, userId có participant_left trước match_end / tổng số cặp matchId, userId của roster ở các trận hợp lệ × 100. ID có thể xuất hiện ở nhiều trận, mỗi trận là một lượt tham gia.
- **Hiện trạng**. StageData liệt kê The Void Act 3 là Stone Path Ruin, 15 wave. Battle dùng một chuỗi WaveData hữu hạn năm wave và không gắn Act. Tất cả trận hiện ghi TheVoid_Unmapped. Có thể đo thử tỷ lệ bỏ trận chung; tỷ lệ thắng Act 3 chưa có mẫu hợp lệ. Không dùng wave 3 làm đại diện cho Act 3.

Unit test chạy chuỗi đầu vào lặp để kiểm tra hai hướng, giới hạn, Fixed và tính tái lập. Hiệu quả nghiên cứu cần log người chơi thật và báo cáo mẫu số theo nhóm.
