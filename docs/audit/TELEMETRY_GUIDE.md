# Thu và phân tích telemetry

Phase 4 bổ sung `completedWaveSamples`, `averageCompletedWaves` và `averageAppliedMultiplier` vào CSV. AverageCompletedWaves tính trên trận hợp lệ; AverageAppliedMultiplier tính trên wave hoàn thành của các trận đó. Quá trình kiểm tra loại hồ sơ thiếu một wave bắt buộc trước wave kết thúc. Số người duy nhất và đánh giá độ khó lấy từ hồ sơ phân nhóm/phản hồi ẩn danh theo [protocol](EXPERIMENT_PROTOCOL.md).

Lưu Output của **server** từ bản Studio đã đồng bộ, giữ các dòng [DeckTelemetry]. File có thể chứa dòng Output khác. Chạy từ thư mục gốc với Node 24.

```powershell
node tools/analyze-telemetry.mjs server.log act3-summary.csv 3 world_1
```

CSV UTF-8 có BOM để mở bằng Excel. Stdout chứa bảng kết quả và chẩn đoán. Tập dữ liệu được phân nhóm theo buildVersion, Fixed/DDA, stageDifficulty và baseline. Mặc định lọc world_1.act_3 với 15 wave. Đánh dấu JSON lỗi, metadata thiếu, bản ghi trùng, trận thiếu đầu/cuối, roster sai và Victory thiếu wave. Trận Invalid được đếm riêng.

| Sự kiện | Trường |
| --- | --- |
| Tất cả | matchId, timestamp (epoch ms), buildVersion, worldId, actId, stageId, stageName, baseline, stageDifficulty, mode, wave, totalWaves, participantCount, baseHealth, maxBaseHealth |
| match_start | roster chứa participantId cục bộ theo trận |
| wave_end | spawned, killed, escaped, removed, elapsed, multiplier áp dụng, nextMultiplier, smoothedPerformanceScore, complete; performanceScore có khi mẫu hợp lệ |
| participant_left | participantId theo trận, số người còn lại |
| match_end | outcome gồm Victory, Defeat, Abandoned, Invalid và duration tính theo giây |

Trường cũ được giữ tên khi tiếp tục cùng ý nghĩa như mode, wave, multiplier, elapsed. Dòng Phase 1 không có ActId được báo thiếu và nằm ngoài thống kê Act 3. Fixed có score thô khi mẫu hợp lệ, EMA giữ ở trạng thái đầu vì bộ điều khiển không cập nhật Fixed.

- Tỷ lệ thắng theo trận bằng Victory chia cho tổng Victory, Defeat và Abandoned.
- Tỷ lệ bỏ giữa trận bằng số lượt participantId khác nhau rời sau match_start và trước hoặc cùng timestamp match_end chia tổng lượt tham gia hợp lệ. Dùng matchId cùng participantId.
- Thời gian trung bình dùng duration của trận hợp lệ. Thiếu match_end không được xem là rời trận tự động.

Payload sử dụng số thứ tự người chơi riêng từng trận. Không cần UserId, tên, secret hoặc API key. Tool test dùng fixture tổng hợp. Log người chơi thật chưa được thu thập.
