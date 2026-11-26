# Nghiệm thu tích hợp Phase 3

Nhánh audit/full-project-review, base 2a123c1, ngày 25/11/2026. Phase 3 bổ sung bộ đồng bộ và chẩn đoán Studio. Cấu hình gameplay, DDA và Stage hiện có được giữ. Điểm kỹ thuật giữ **75/100** do chưa có bằng chứng runtime Roblox.

## Kết quả thực tế

| Kiểm tra | Kết quả |
| --- | --- |
| Compile repo | PASS, 48 file Luau bằng CLI gồm 42 file gameplay/test, engine và năm lệnh sinh ra |
| Compile nội dung RBXL | PASS, 22 script nhúng |
| Compile bundle | PASS, năm script Studio sinh ra |
| DifficultyController.spec và Phase2.spec | PASS |
| Node test | PASS, 5 test gồm 3 generator/manifest và 2 telemetry |
| Test giao dịch đồng bộ trên cây Instance mô phỏng | PASS, yêu cầu Dry Run, chặn Play và bản sao chưa đánh dấu, đường dẫn mơ hồ, drift Source, rollback tự động khi lỗi editor, Verify, Apply lặp không nhân đôi, rollback thủ công |
| git diff --check | PASS |
| Apply thực tế, Play Solo, multiplayer, mobile và MicroProfiler | REQUIRES ROBLOX STUDIO |
| Log server thật, analyzer trên dữ liệu thật và so sánh Fixed/DDA | NOT RUN, chưa có dữ liệu |

Bài test rollback chạy bằng Luau CLI chính thức 0.748. Luau-web 1.4.0 trong môi trường này ném lỗi ra JavaScript ngay cả khi thử lỗi Luau bên trong pcall. Vì vậy chạy test đường thất bại bằng CLI; dùng WASM cho compile và các spec hiện có. Các dòng FAIL trong test mock là lỗi cố ý được kiểm tra bằng assertion. [Luau CLI 0.748](https://github.com/luau-lang/luau/releases/tag/0.748)

## Trạng thái DD-01 đến DD-19

Các sửa đổi ở source và phương án đồng bộ giữ trạng thái Phase 2. Kiểm tra hồi quy runtime cho từng hàng vẫn **REQUIRES ROBLOX STUDIO**.

| ID | Bằng chứng hiện có | Kiểm tra runtime trọng tâm |
| --- | --- | --- |
| DD-01 | Source dùng chung IntValue Yen | Mua, thưởng và reset khi replay |
| DD-02 | Source tập trung kết thúc trận | Defeat khi đang spawn và khi chờ quái |
| DD-03 | Source cleanup sau kết thúc | Rời toàn đội rồi chơi lại |
| DD-04 | Source báo Invalid khi thiếu route | Thử thiếu waypoint ở bản sao |
| DD-05 | Source kiểm roster/đa số | Race Start và phiếu Skip |
| DD-06 | Source kiểm CFrame, cooldown và hai Remote | Placement thông thường và cạnh tranh |
| DD-07 | Source kiểm chủ sở hữu và trận | Upgrade, Sell và TargetMode với hai người |
| DD-08 | Test StageResolver 15 wave và boss | Chơi hết Act 3 và đối chiếu log |
| DD-09 | Source slow tác động tốc độ đi | Quan sát IceHero trong wave |
| DD-10 | Source giới hạn tần suất và target theo tiến độ | First/Last và profiler |
| DD-11 | Source sửa chuyển party và cờ | Rời leader, chuyển party và replay |
| DD-12 | Source có phase guard, kiểm Act và cooldown | Các lối vào battle |
| DD-13 | Test predicate kết quả và membership | HUD của người chơi ngoài trận |
| DD-14 | Test geometry, giới hạn và membership | Raycast thật và hai người cùng chỗ |
| DD-15 | Manifest đối chiếu RBXL, Dry Run và rollback mock | Apply/Verify trên bản sao thật |
| DD-16 | Test dedup, xác định consumer cũ theo đường dẫn | Victory/Defeat, Return/Replay |
| DD-17 | Source giới hạn GetLobbyData theo player | Hai client và UI retry |
| DD-18 | Source cập nhật Start theo phase | Hai client chọn Act khác nhau |
| DD-19 | Source chuẩn bị clone trước trừ Yen | Thử template chưa sẵn sàng |

Không xác nhận lỗi gameplay mới trong Phase 3. Một điểm làm rõ của quy trình tải là 50 trụ cần ít nhất bốn người vì giới hạn 15 trụ/người. Mốc Act 3, thông số DDA và schema telemetry được xác nhận ở source và fixture, còn thiếu trận thật.

## Lệnh và file bàn giao

Đặt biến PowerShell $luauWeb thành đường dẫn tới luau-web/src/index.js (bản 1.4.0) và $luauCli thành đường dẫn tới luau.exe (bản 0.748).

```powershell
node tools/generate-studio-sync.mjs
node tests/run-luau.mjs $luauWeb
node --test tests/telemetry.test.mjs tests/studio-sync.test.mjs
node tests/run-studio-sync.mjs $luauWeb $luauCli
git diff --check
```

- Thêm tools/generate-studio-sync.mjs, tools/studio-sync-manifest.json, tools/studio-sync-engine.luau và năm script sinh ra trong tools/generated.
- Cập nhật tools/inspect-place.mjs để đối chiếu thêm lớp các asset và container. Bổ sung ignore cho output tái tạo.
- Thêm tests/studio-sync.test.mjs, tests/run-studio-sync.mjs, tests/studio-sync-mocks.luau.
- Thêm bốn tài liệu Phase 3. Cập nhật ROADMAP và FINAL_ACCEPTANCE_REPORT.
- RBXL giữ SHA-256 238700D2742FA2B0667E3A644F737AA14ED5DB413F4FEF1D46E251E8395B8BD3. Không stage, commit, push, merge hoặc publish.

[Hướng dẫn chạy Studio](STUDIO_SYNC_GUIDE.md) · [Bộ kiểm thử runtime](RUNTIME_TEST_REPORT.md) · [Checklist release](RELEASE_CHECKLIST.md)
