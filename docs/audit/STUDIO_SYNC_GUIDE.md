# Đồng bộ Deck Defenders trong Roblox Studio

## Đồng bộ RC hiện tại

Mở đúng RC hiện tại `reports/local/DeckDefenders-hero-limits-v2-RC.rbxl` trong Edit Mode. Chép bundle với lệnh bên dưới, dán vào Command Bar và bấm Run một lần. Chờ `Verified stored Source for 22 targets; BuildVersion=hero-limits-v2; bundle=…` rồi lưu RC hiện tại.

```powershell
Get-Content -Raw -Encoding UTF8 -LiteralPath 'E:\Roblox Game ĐACN\tools\generated\studio-one-click-sync.luau' | Set-Clipboard
```

Ca nghiệm thu đầu tiên là Play → Story → Act 3 Normal → Select Stage → Party → Start. Kiểm tra Stage hiện 15 Waves, Party nhận đúng stage từ server, rồi kiểm tra vào trận trên đúng build. Thử Back, Change Map, Change Mode, Matchmaking, 1920×1080, 1366×768, 1280×720 và Device Emulator landscape.

## Đồng bộ v2 bằng một lệnh

Phần này ghi lại quy trình bundle 17 đích trước redesign. Dùng hướng dẫn ở đầu trang cho bundle hiện tại.

Mở đúng `reports/local/DeckDefenders-hero-limits-v2-RC.rbxl` trong **Edit Mode**. Script một lần chạy kiểm tra local place, BuildVersion v1/v2 và fingerprint của PlacementRules, TowerServer, PlacementClient. File gốc đang mang build `sync-7a71189a55df` sẽ bị từ chối trước khi ghi. Giữ bản RC v1 riêng làm bản sao dự phòng.

```powershell
Get-Content -Raw -Encoding UTF8 -LiteralPath 'E:\Roblox Game ĐACN\tools\generated\studio-one-click-sync.luau' | Set-Clipboard
```

Dán toàn bộ vào **Command Bar trong Edit Mode**, bấm Run một lần và chờ `[DeckSync][one-click][PASS] Verified stored Source for 17 targets; BuildVersion=hero-limits-v2`. Chế độ này tự chạy Preflight → Apply → Verify, giữ journal để rollback nếu có lỗi và đối chiếu cả Source của Instance lẫn Source mà Script Editor hiển thị. Nếu PASS và updated entries=0, RC đang khớp bundle. Lưu bản sao nếu có thay đổi, rồi chạy **Play trong đúng tab RC**. Kiểm tra `[HeroLimit] Guard ready. BuildVersion=hero-limits-v2` trước khi đặt Hero.

Các chế độ rời dưới đây vẫn dùng được để kiểm tra hoặc phục hồi thủ công khi cần.

Chạy bằng Node 24. Hai lệnh dưới đây dùng đường dẫn tuyệt đối nên chạy được từ bất kỳ thư mục PowerShell nào. Generator chỉ đọc RBXL gốc, manifest và Source trong src. Năm lệnh được tạo trong tools/generated. Cùng một bundle phải dùng cho toàn bộ lượt đồng bộ.

```powershell
node 'E:\Roblox Game ĐACN\tools\generate-studio-sync.mjs'
Get-ChildItem -LiteralPath 'E:\Roblox Game ĐACN\tools\generated'
```

## Chuẩn bị bản sao

1. Đóng phiên Play/Test. Tạo bản sao của TowerDefense_DoAn.rbxl bằng Explorer, ví dụ DeckDefenders-Integration.rbxl. Mở **bản sao** trong Studio. Giữ một bản RBXL sạch riêng để phục hồi nếu phiên Studio bị đóng.
2. Xem thanh tiêu đề/tên file trong Studio để xác nhận đang mở đúng bản sao. Trong Edit Mode, mở Output và Command Bar. Bật **Multi-line Command Bar** nếu phiên Studio yêu cầu.
3. Đánh dấu đúng place thử bằng lệnh sau. Thuộc tính này là xác nhận của người vận hành. Công cụ không đọc được tên file RBXL đang mở.

```luau
game:SetAttribute("DeckSyncCopy", true)
```

## Dry Run → Apply → Verify

Mở từng file sinh ra trong trình soạn thảo, sao chép toàn bộ nội dung, dán vào Command Bar và bấm **Run** hoặc **Ctrl+Enter**. Giữ cùng phiên Studio và cùng bộ file.

| Thứ tự | File | Kết quả cần thấy |
| --- | --- | --- |
| 1 | tools/generated/studio-preflight.luau | PASS Dry Run, liệt kê thay Source, tạo module, tắt consumer cũ và thuộc tính còn thiếu. Dry Run không ghi vào Instance. |
| 2 | tools/generated/studio-sync.luau | PASS Apply verified. Apply chạy lại toàn bộ kiểm tra và đối chiếu với Dry Run đã ghi trong bộ nhớ. |
| 3 | tools/generated/studio-verify.luau | PASS khi Source, kiểu, đường dẫn, asset, Legacy Disabled và thuộc tính GameManager khớp. |
| 4 | tools/generated/studio-rollback.luau | Chỉ chạy khi cần phục hồi trong cùng phiên Studio. Verify cũ sau rollback sẽ báo khác Source, đúng với trạng thái phục hồi. |

Bundle hiện tại đặt GameManager.BuildVersion thành `hero-limits-v2` và giữ EnableDDA hiện có. Nếu EnableDDA chưa tồn tại, Apply tạo với giá trị false. Có thể dùng bản sao `reports/local/DeckDefenders-hero-limits-v2-RC.rbxl` được tạo từ RC v1 đã lưu. Sau Verify, lưu đúng bản sao rồi bấm Play. Output phải có `[HeroLimit] Guard ready. BuildVersion=hero-limits-v2` trước khi thử đặt trụ. Nếu thấy Unexpected local Source, hãy trích/export Source để đối chiếu trong một backup riêng. Generator kiểm tra fingerprint của các phiên bản được phép cập nhật; Dry Run chặn các đường dẫn script tạo trụ cũ đã biết.

Công cụ dùng ScriptEditorService.GetEditorSource và UpdateSourceAsync, hai API được Roblox cung cấp cho Command Bar và plugin. Hành vi API, kích thước clipboard và việc chia sẻ bộ nhớ giữa các lệnh còn phải xác minh trên phiên Studio thực tế. Nếu phiên mất trạng thái, Apply dừng và yêu cầu chạy lại Dry Run. [ScriptEditorService](https://create.roblox.com/docs/reference/engine/classes/ScriptEditorService) · [Command Bar](https://create.roblox.com/docs/studio/overview#command-bar)

## Lỗi và phục hồi

- Nếu Apply lỗi sau khi bắt đầu ghi, công cụ thử rollback theo thứ tự ngược. Journal giữ Source cũ, Disabled cũ, giá trị thuộc tính cũ và tham chiếu tới module vừa tạo.
- Nếu rollback báo xung đột, giữ riêng bản chứa chỉnh sửa mới và dùng lại bản sao sạch cho lần tích hợp tiếp theo. Các module được tạo trong lần Apply là những Instance duy nhất rollback có thể xóa.
- Journal nằm trong phiên Studio. Nếu đóng file hoặc khởi động lại, dùng bản sao sạch để phục hồi.
- Nếu Command Bar không nhận đủ lệnh, API bị từ chối hoặc khả năng chạy nối tiếp không hoạt động, cập nhật từng Instance bằng Script Editor theo SOURCE_SYNC_MANIFEST và ROBLOX_STUDIO_SETUP. So sánh lại WaveData nhúng, hai LobbyController và cây asset trước khi lưu.
- Sau khi Apply/Verify hoặc rollback đã hoàn tất, xóa dấu xác nhận trên bản sao bằng `game:SetAttribute("DeckSyncCopy", nil)`. Lưu bản sao bằng Studio khi bạn quyết định giữ bản thử.

## Runtime và hai nhóm thực nghiệm

Trong Play Solo hoặc Start Server, chuyển Command Bar sang **Server** rồi chạy tools/generated/studio-diagnostics.luau. Chạy một lần ở lobby, một lần trong wave Act 3 và một lần sau cleanup. Công cụ chỉ đọc, không thêm remote hoặc require module để tránh kích hoạt side effect.

Tạo hai bản từ **bản sao đã Verify**. Đặt GameManager.EnableDDA = false cho Fixed và true cho DDA, giữ cùng BuildVersion, stageDifficulty Normal và baseline stone-path-v1. Xác minh từng preset trước khi thu dữ liệu pilot. [Checklist runtime](RUNTIME_TEST_REPORT.md) · [Quy trình thực nghiệm](EXPERIMENT_PROTOCOL.md)
