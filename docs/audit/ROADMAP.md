# Checklist trước bảo vệ

## Phase 3

Bộ đồng bộ đã qua kiểm tra generator và mock Apply/Rollback. Bước tiếp theo là chạy Dry Run, Apply và Verify trên bản sao Studio, sau đó xác minh Solo, multiplayer, mobile và hai preset Fixed/DDA. [Hướng dẫn đồng bộ](STUDIO_SYNC_GUIDE.md) · [Checklist release](RELEASE_CHECKLIST.md)

## Cập nhật Phase 2

Ưu tiên đồng bộ bản sao Studio, chạy [checklist](STUDIO_TEST_CHECKLIST.md) và hoàn tất pilot Act 3. Sau đó thu log theo [protocol](EXPERIMENT_PROTOCOL.md), đối chiếu khó dễ thực tế và công bố mẫu số. Các bước liên quan ánh xạ Act 3 trong ghi nhận Phase 1 đã được triển khai ở source.

## Ghi nhận Phase 1

- [ ] Đồng bộ mã vào bản sao RBXL và chạy ma trận Studio Solo, Start Server hai client và mobile emulator.
- [ ] Xác nhận đường đi, mặt đặt trụ, HUD/ghost, IceHero slow, CrimsonHero AoE, hai tên placement remote và lifecycle replay.
- [ ] Ánh xạ server-authoritative cho world_1 Act 3 và dữ liệu 15 wave tương ứng. Xác nhận khác biệt map và điều kiện unlock trước khi đưa vào thử nghiệm.
- [ ] Khóa cùng build cho hai nhóm, bố trí phân nhóm và định nghĩa loại trừ trước khi thu log.
- [ ] Lưu log, dedup, bảo vệ định danh và kiểm tra trận thiếu kết quả. Tính mẫu số, lỗi đo và tỷ lệ theo nhóm.
- [ ] Đo MicroProfiler, giới hạn enemy/tower lớn và tính ổn định sau 10 trận.
- [ ] Đồng bộ client placement preview với server; xác nhận lựa chọn chạm và trạng thái khi cửa sổ UI đóng.
- [ ] Xác nhận ScreenGui kết quả còn dùng, xử lý GameOver/GameWin và xác minh điểm teleport nhúng.
- [ ] Chốt luồng party/teleport multi-place, stage progression và persistence nếu phạm vi buổi bảo vệ yêu cầu.
- [ ] Ghi lại RBXL đã kiểm thử và chuẩn hóa cơ chế xuất mã trước khi hợp nhất nhánh.
