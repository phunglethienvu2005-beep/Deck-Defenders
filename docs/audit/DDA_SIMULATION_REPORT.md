# Mô phỏng DDA 15 wave

Bảng ghi multiplier **áp dụng khi bắt đầu từng wave**, làm tròn ba chữ số. Luau VM chạy DifficultyController thật với đầu vào mô phỏng xác định. Đây là dữ liệu synthetic để đánh giá hành vi điều khiển.

| Hồ sơ | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Yếu | 1.000 | 0.941 | 0.861 | 0.800 | 0.800 | 0.800 | 0.800 | 0.800 | 0.800 | 0.800 | 0.800 | 0.800 | 0.800 | 0.800 | 0.800 |
| Trung bình | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 |
| Giỏi | 1.000 | 1.035 | 1.093 | 1.165 | 1.245 | 1.250 | 1.250 | 1.250 | 1.250 | 1.250 | 1.250 | 1.250 | 1.250 | 1.250 | 1.250 |
| Dao động | 1.000 | 0.970 | 0.970 | 0.970 | 0.993 | 0.993 | 1.018 | 1.018 | 1.044 | 1.044 | 1.071 | 1.071 | 1.098 | 1.098 | 1.125 |
| Khó giữa trận | 1.000 | 1.035 | 1.093 | 1.165 | 1.245 | 1.250 | 1.250 | 1.189 | 1.109 | 1.029 | 0.949 | 0.893 | 0.893 | 0.927 | 0.984 |
| Cố tình chơi kém | 1.000 | 0.920 | 0.840 | 0.800 | 0.800 | 0.800 | 0.800 | 0.800 | 0.800 | 0.800 | 0.800 | 0.842 | 0.904 | 0.979 | 1.059 |

Hồ sơ giỏi đạt trần ở wave 6. Hồ sơ yếu chạm sàn ở wave 4. Kịch bản cố tình chơi kém cho thấy người chơi có thể nhận giảm HP ngắn hạn và tác động còn kéo dài do EMA. Log score, mất máu căn cứ và mất thưởng hạ quái hỗ trợ phát hiện và đánh giá chi phí hành vi. Chưa có bằng chứng về lợi ích ròng trong gameplay.

Mô phỏng giữ nguyên trọng số, alpha, target, deadband, biên và bước tối đa Phase 1. Dánh giá trên dữ liệu trận thật cần xem thêm thời gian sống của quái, số người chơi và số wave đi tới. Đầu vào chính xác ở [Phase2.spec](../../tests/Phase2.spec.luau).
