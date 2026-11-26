# Cấu hình màn chơi

PlayMenu chuyển world_1, ID Act và Normal/Hard qua TeleportToBattle. LobbyService xác thực lựa chọn và từng thành viên trước khi chuyển party. MapSelect cũ tiếp tục vào baseline Act 1. StageResolver kiểm tra World/Act, level, tiến độ mở màn và lưu stage phía server. Progress hiện vẫn là profile demo do server tạo. Chưa có progression bền vững.

GameManager lấy lựa chọn của người yêu cầu, chốt roster trong khu battle theo cùng StageId và độ khó, cấp ID trận mới và phát CurrentWave, TotalWaves, StageId, StageName, WorldId và ActId. Server giữ một khu battle, một trận tại một thời điểm. Hai party cùng stage/difficulty có thể cùng tham gia nếu cùng đứng trong battle trước khi countdown kết thúc.

- **Act 3**. world_1.act_3, Stone Path Ruin, baseline stone-path-v1, 15 wave hữu hạn. Boss ở wave 15. Dữ liệu ở StageResolver và dùng lại các loại quái trong WaveData. Đây là baseline đề xuất, chưa cân bằng bằng người chơi thật.
- **Act hữu hạn khác**. Giữ chuỗi năm wave có sẵn. Các con số thiết kế cũ trong catalog không được dùng làm giới hạn trận. UI lấy số playable qua StageData.
- **Infinite**. Dùng thể thức endless nếu hồ sơ đạt điều kiện Act 7. Chuỗi mở rộng lấy từ WaveData. WaveConfig là cấu hình song song có từ trước và chưa được dùng cho trận phase 2.
- **Fixed và DDA**. Dùng cùng baseline, cùng thành phần quái, thứ tự và thời gian. Chỉ DDA áp multiplier HP cho quái mới. Normal/Hard là metadata và điều kiện mở khóa hiện có; chưa kích hoạt preset thay đổi chỉ số.

Act 3 dùng lại đường The Void. Parser xác nhận EnemySpawn, EnemyBase, WP1–WP8, BattleSpawn, Zombie và hai model trụ. GameManager ghi Invalid khi thiếu spawn, base hoặc waypoint. Độ cao, collision, hướng waypoint và khả năng hoàn thành cần Play Solo hoặc Start Server.

Điểm vào [StageResolver](../../src/ServerScriptService/StageResolver.luau), [GameManager](../../src/ServerScriptService/GameManager.server.luau), [StageData](../../src/ReplicatedStorage/Modules/StageData.luau).
