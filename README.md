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

| :--- | :--- | :--- | :--- | :--- | :--- |

| **1. Tỉ lệ thắng màn 3 (%)** | Thống kê tự động từ hệ thống Telemetry lưu log khi hoàn thành màn 3 | Kế hoạch: đo nhóm A (độ khó cố định), W5–W6 | *(Để trống)* | Nhóm A: W5–W6<br>Nhóm B: 27/11–03/12 | Log file JSON / Google Sheets |

| **2. Tỉ lệ bỏ giữa màn (%)** | Ghi nhận sự kiện người chơi bấm thoát/tắt game khi trận chưa kết thúc | Kế hoạch: đo nhóm A, W5–W6 | *(Để trống)* | Nhóm A: W5–W6<br>Nhóm B: 27/11–03/12 | Log file JSON / Google Sheets |



---



## Thông tin tác giả



- **Họ và tên:** Phùng Lê Thiên Vũ

- **MSSV:** 2380602599

- **Lớp:** 23DTHC7

- **Giảng viên hướng dẫn:** ThS. Nguyễn Quang Trung

