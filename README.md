# Deck Defenders

**Phát triển Deck Defenders: game thủ thành 3D trên nền tảng Roblox tự cân bằng độ khó dựa trên cơ chế điều chỉnh độ khó động**

*Developing Deck Defenders: A Self-Balancing 3D Tower Defense Game on Roblox Platform Based on Dynamic Difficulty Adjustment*

> Đồ án chuyên ngành CMP436 · Khoa Công nghệ thông tin · HUTECH · HK1 2026–2027

---

## Câu định vị

Đồ án giải quyết **tình trạng thua oan ức do mất cân bằng độ khó cố định** cho **nhóm người chơi game thủ thành trên nền tảng Roblox và cộng đồng**, đo bằng **tỉ lệ thắng màn 3 và tỉ lệ bỏ giữa màn**.

---

## Vấn đề nghiên cứu

Game thủ thành thường cố tình mất cân bằng để ép xem quảng cáo hoặc nạp tiền; người chơi bỏ cuộc vì thấy thua do hệ thống ép buộc chứ không phải do thiếu kỹ năng chiến thuật.

Hệ thống tiếp cận độ khó như một vòng điều khiển phản hồi âm (negative feedback loop): tự động điều chỉnh thông số sinh quái để giữ trận đấu trong vùng thử thách vừa sức.

---

## Bảng Trước – Sau (Baseline & Metrics)

| Chỉ số | Cách đo lường | Trước (Baseline / Kế hoạch) | Sau (Kết quả thực tế) | Ngày đo | Bằng chứng |
| --- | --- | --- | --- | --- | --- |
| **1. Tỉ lệ thắng màn 3 (%)** | Thống kê tự động từ hệ thống Telemetry lưu log khi hoàn thành màn 3 | Kế hoạch: đo nhóm A (độ khó cố định), W5–W6 | _(Để trống)_ | Nhóm A: W5–W6 / Nhóm B: 27/11–03/12 | Log file JSON / Google Sheets |
| **2. Tỉ lệ bỏ giữa màn (%)** | Ghi nhận sự kiện người chơi bấm thoát/tắt game khi trận chưa kết thúc | Kế hoạch: đo nhóm A, W5–W6 | _(Để trống)_ | Nhóm A: W5–W6 / Nhóm B: 27/11–03/12 | Log file JSON / Google Sheets |

---

## Mã nguồn và kiểm thử

Bản place nằm trong TowerDefense_DoAn.rbxl. Thư mục src chứa bản xuất mã để review và cập nhật. Hãy dùng [hướng dẫn đồng bộ Studio](docs/audit/ROBLOX_STUDIO_SETUP.md) và [báo cáo kiểm toán](docs/audit/PROJECT_AUDIT.md) để chọn script cần đồng bộ.

Phase 2 bổ sung baseline thử nghiệm 15 wave cho Stone Path Ruin (The Void Act 3) và giữ cấu hình năm wave cho các Act hữu hạn còn lại. Chưa có kết quả nghiên cứu người chơi. Xem [nghiệm thu Phase 2](docs/audit/FINAL_ACCEPTANCE_REPORT.md) và [hướng dẫn telemetry](docs/audit/TELEMETRY_GUIDE.md).

## Nghiệm thu và thực nghiệm

Build đồng bộ hiện tại là `hero-limits-v2`, tối đa 4 IceHero, 4 CrimsonHero mỗi người và 50 trụ toàn trận. Log của build trước xác nhận Act 3 Fixed thắng đủ 15 wave và Boss có MaxHealth 3.200. Trước khi chốt release, còn cần đối chiếu bằng chứng DDA Act 3, giới hạn Hero trong Studio, mobile và đo hiệu năng. Mở bản sao RBXL, đồng bộ theo hướng dẫn Studio rồi Play Solo hoặc Start Server. [Báo cáo release](docs/audit/FINAL_RELEASE_REPORT.md) · [Hướng dẫn đồng bộ](docs/audit/STUDIO_SYNC_GUIDE.md) · [Quy trình thực nghiệm](docs/audit/EXPERIMENT_PROTOCOL.md)

## Thông tin tác giả

- **Họ và tên:** Phùng Lê Thiên Vũ
- **MSSV:** 2380602599
- **Lớp:** 23DTHC7
- **Giảng viên hướng dẫn:** ThS. Nguyễn Quang Trung
