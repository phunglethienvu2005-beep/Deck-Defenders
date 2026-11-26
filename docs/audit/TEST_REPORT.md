# Kết quả và ma trận kiểm thử

## Cập nhật Phase 2

| Kiểm tra | Kết quả Phase 2 |
| --- | --- |
| Node 24 và luau-web 1.4.0 với tests/run-luau.mjs | PASS, compile 41 Luau repo và 22 nguồn nhúng RBXL |
| Phase 1 DifficultyController.spec | PASS, Fixed, tăng, giảm, biên, wave rỗng và replay |
| Phase2.spec | PASS, Act 3, baseline tương thích, kiểm khóa màn, so khớp roster cùng stage, placement geometry và membership, result dedup, dữ liệu DDA lỗi, 6 mô phỏng |
| node --test tests/telemetry.test.mjs | PASS, 2 test analyzer |
| Parser RBXL | PASS, lớp/đường dẫn script và các asset được assert |
| git diff --check | PASS |
| Studio runtime, tween, Raycast thật, multiplayer, replay, 50 trụ, 10 trận và profiler | REQUIRES ROBLOX STUDIO |
| Mẫu nghiên cứu và cân bằng Act 3 | Chưa thu log người chơi thật |

Unit test placement dùng mock vector và Instance; kết quả xác minh toán hình học và gate, chưa thực hiện raycast engine hay tạo model trong game. Kiểm thử lifecycle và 12 bản sửa Phase 1 trên engine dùng ma trận cũ cùng [checklist Phase 2](STUDIO_TEST_CHECKLIST.md).

## Ghi nhận Phase 1

| Kiểm tra đã chạy | Kết quả |
| --- | --- |
| git status --short, git branch --show-current, git rev-parse HEAD | Đọc trạng thái, nhánh và commit thành công |
| Node 24, zlib.zstdDecompressSync, đọc INST/PROP | PASS: trích 22 nguồn Luau từ RBXL, đọc Name, Source và Disabled |
| Node và luau-web 1.4.0, LuauState.loadstring | PASS: 36 file Luau của repo và 22 nguồn RBXL |
| tests/DifficultyController.spec.luau | PASS: Fixed, tăng, giảm, biên, wave rỗng và replay xác định |
| git diff --check | PASS: không có lỗi whitespace |
| Luau Analyzer, Selene, StyLua, Rojo | NOT RUN: không tìm thấy executable trong PATH |
| TestService, play solo, multiplayer, mobile, MicroProfiler | REQUIRES ROBLOX STUDIO: không tìm thấy executable trong PATH, Roblox Versions cục bộ hay mục cài đặt Windows |
| Thử nghiệm người chơi và chỉ số Act 3 | BLOCKED: chưa có quy trình thu mẫu thật và battle chưa ánh xạ Act 3 |

LuauState chạy bytecode của DDA thuần Luau. Các script Roblox chỉ được compile. Không có kết quả runtime Roblox hoặc benchmark giả định. Để chạy spec, nạp module và file spec thành hai chunk Luau. Gọi hàm do spec trả về với module làm đối số. Trong TestService có thể dùng hai ModuleScript tương ứng và gọi `require(spec)(require(controller))`.

Lệnh tái lập kiểm tra cú pháp repo và unit test từ thư mục gốc với Node 24, cài compiler ngoài repo.

```powershell
$deckCompiler = Join-Path $env:TEMP 'deck-audit-tool'
npm.cmd install --prefix $deckCompiler --no-save --ignore-scripts --no-audit --no-fund luau-web@1.4.0
node tests/run-luau.mjs (Join-Path $deckCompiler 'node_modules/luau-web/src/index.js')
git diff --check
```

## Ma trận Studio

Tạo bản sao place và thực hiện theo [hướng dẫn đồng bộ](ROBLOX_STUDIO_SETUP.md). Mở Output server và client. Với multiplayer dùng Start Server và ít nhất hai client. Tất cả các tình huống runtime bên dưới có trạng thái REQUIRES ROBLOX STUDIO.

| # | Thao tác | Kết quả cần đối chiếu |
| ---: | --- | --- |
| 1 | Vào battle, bấm Start | Một countdown 3–2–1 rồi tally wave 1 |
| 2 | Hai client bấm Start gần đồng thời | Một match_start và một vòng spawn |
| 3 | Bắt đầu wave 1 | Số và loại enemy theo WaveData |
| 4 | Không đặt trụ để quái đến cuối đường | Base giảm đúng một lần/quái, bộ đếm giảm |
| 5 | Đặt IceHero để hạ quái đang đi | Quái dừng và bị dọn khỏi Enemies |
| 6 | Đặt IceHero trên vùng hợp lệ | Một trụ, Yen giảm 500 |
| 7 | Dùng hết Yen rồi thử đặt CrimsonHero | Không mua khi dưới giá |
| 8 | Đặt sát trụ đã có | Server bỏ qua, Yen giữ nguyên |
| 9 | Thử ghost ở lobby, trên đường và ngoài map | Không có trụ ngoài vùng hợp lệ |
| 10 | Bấm đặt nhanh bằng UI bình thường | Số giao dịch hợp lệ tương ứng số trụ, dùng giới hạn cooldown |
| 11 | Đổi First/Last/Strongest/Closest với nhiều enemy | Mục tiêu lần lượt theo tiến độ, máu hoặc khoảng cách |
| 12 | Hạ quái bằng đòn thường và kỹ năng | Sát thương áp dụng lên quái sống trong registry |
| 13 | Hai trụ cùng đánh quái gần chết | Thưởng hạ chỉ một lần cho từng thành viên |
| 14 | Solo bỏ phiếu, rồi lặp lại với hai client | Solo một phiếu đủ; hai client cần hai phiếu |
| 15 | Cho quái về đích đến khi base = 0 | Defeat, HUD và cleanup, một match_end |
| 16 | Dọn wave boss cuối | Victory, một match_end |
| 17 | Một client rời giữa wave | Một participant_left; nếu là người cuối thì Abandoned |
| 18 | Chơi lại sau Victory và Defeat | Match ID mới, base/Yen reset, trụ và quái cũ đã dọn |
| 19 | Hai client vào battle, thêm người ở lobby nếu có | HUD của người tham gia khác lobby, roster chốt khi đếm xong |
| 20 | DDA, hoàn thành các wave bị lọt nhiều | Multiplier về phía dưới 1 nếu mẫu vượt ngưỡng đủ lâu |
| 21 | DDA, hoàn thành nhanh và giữ base | Multiplier tăng dần ở các wave sau |
| 22 | Theo dõi log ở nhiều wave | Bước tối đa 0,08 và [0,80; 1,25]; kiểm tra unit đã PASS |
| 23 | EnableDDA false | Tất cả wave ghi Fixed và multiplier 1; unit đã PASS |
| 24 | Đối chiếu Output với roster/wave | Một match_end, một wave_end mỗi wave và một participant_left mỗi người rời |
| 25 | Chạy 10 trận, có một trận bỏ giữa chừng | Dọn trụ/quái; ghi memory, connection, Instance và frame time |
| 26 | Khởi chạy khi đường đi thiếu trong bản thử | Match Invalid được log, quay về trạng thái chờ |
| 27 | Dùng IceHero, quan sát enemy đi qua AoE | Đi chậm khoảng ba giây, rồi tốc độ bình thường |
| 28 | Nâng cấp, bán, đổi mode bằng UI hai client | Chỉ chủ sở hữu thao tác được; hoàn tiền đúng một lần |
| 29 | Dùng menu party chuyển client vào battle | Party hết khóa chuyển tiếp, sau đó phải bấm Start ở battle |
| 30 | Studio mobile emulator | Nút UI, hotbar, preview và thao tác đặt có thể dùng ở viewport chạm |
