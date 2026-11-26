# Deck Defenders — Phase 4 Final Release Report

## Rà soát theo skill

- Sửa CSV Analyzer sau khi test tái hiện bản ghi JSON giống nhau nhưng khác thứ tự trường bị phân loại là xung đột. Nguyên nhân là so sánh chuỗi JSON. So sánh dữ liệu JSON đã parse giữ đúng một bản ghi trùng và tiếp tục loại hồ sơ xung đột thật. Thay đổi nằm trong `tools/analyze-telemetry.mjs` và `tests/telemetry.test.mjs`.
- Kiểm tra tĩnh các luồng Lobby/Act, wave, combat, Yen, remotes, UI và vòng đời trận cùng hồi quy mô phỏng. Chưa có số đo làm căn cứ tối ưu Heartbeat, RenderStepped, raycast, tween, VFX hay animation. Đường đặt trụ vẫn dựa trên con trỏ và cần Device Emulator để xác minh touch.
- RC hiện tại mang build `hero-limits-v2` và khớp 17/17 Source. Log mới xác minh Apply/Verify cùng một lượt Act 3 Fixed dừng ở wave 1. Giữ riêng bằng chứng runtime, mô phỏng và thực nghiệm. [Chi tiết runtime và ca còn thiếu](RUNTIME_TEST_REPORT.md)
- Trước bảo vệ, chạy đủ Act 3 Fixed/DDA cùng baseline, kiểm tra Hero/Yen và vòng đời trận trên hai client, thử touch, đo Boss và 10 trận liên tiếp rồi mới chốt build nghiên cứu.

## Hero-limits-v2 — sửa lỗi chạy nhầm build

Log đặt 5 IceHero thuộc trận `4eb900a9-47ad-4a22-8e47-fe51a4e77c5b` của build `sync-7a71189a55df`. RC v1 lưu riêng có mã kiểm giới hạn. Đã tạo bản sao RC v2 từ RC v1 để chạy bundle mới. Play Test v2 chưa xác minh. Xem [bằng chứng và ca hồi quy](RUNTIME_TEST_REPORT.md#hero-limits-v2--điều-tra-đặt-icehero-thứ-năm).

## Hero-limits-v1 — Release Candidate

Đã chuẩn bị bản sao `reports/local/DeckDefenders-hero-limits-v1-RC.rbxl` và sinh lại bundle gồm 17 đích Source. **RC đang chờ Apply/Verify trong Studio.** Bản sao có cùng SHA-256 với RBXL đầu vào (`7E360CAE42D2F3ADE9B982FCEA91B433527E3E2D8D8AEEFED2F0509D454816D4`). Apply sẽ cập nhật BuildVersion thành `hero-limits-v1` và giữ EnableDDA hiện có. Không ghi vào bản gốc. Kiểm tra `tools/list` của Studio MCP hết thời gian chờ dù proxy đã phản hồi khởi tạo.

### Apply và Verify

1. Mở đúng bản RC trong **Edit Mode**. Chạy `game:SetAttribute("DeckSyncCopy", true)` trong Command Bar.
2. Chạy lần lượt `tools/generated/studio-preflight.luau`, `studio-sync.luau`, `studio-verify.luau` trong cùng phiên. Chờ PASS từng bước. Sau Verify, kiểm tra `ServerScriptService.GameManager.BuildVersion` bằng `hero-limits-v1`, xóa dấu xác nhận bằng `game:SetAttribute("DeckSyncCopy", nil)` và lưu **bản RC**. [Hướng dẫn chi tiết](STUDIO_SYNC_GUIDE.md)

### Phiên nghiệm thu còn lại

1. Solo Act 3 Normal Fixed rồi DDA, cùng build và baseline. Gắn `studio-dda-diagnostics.luau` một lần mỗi phiên Play. Lấy log 15 wave, spawn Boss/MaxHealth, Victory và mẫu DDA tăng/giảm. Thử Defeat, Return và Replay trong các lượt riêng. Với Replay, giữ nguyên phiên Play để đối chiếu MatchId mới và hệ số wave 1 bằng 1. Chụp số enemy/tower ngay sau kết thúc và trước khi thao tác nút.
2. Start Server với hai client. Mỗi người tích lũy Yen và đặt đủ 4 IceHero + 4 CrimsonHero. Kiểm tra ô 4/4, Hero thứ năm bị chặn và Yen không giảm, rồi bán một trụ và đặt lại. Kiểm tra giới hạn độc lập, nâng cấp và reset sau Replay. Lặp các thao tác cảm ứng trên điện thoại dọc/ngang trong Device Emulator.
3. Dùng Performance Stats và MicroProfiler ở server/client với cùng máy và cấu hình. Lưu chuỗi frame time cùng độ dài cho trận thường, multiplayer và Boss wave; tính median/p95 theo từng trace, ghi FPS/RAM và số trụ/quái đi kèm. Chụp RAM, Instance và số enemy/tower sau cleanup của từng trận trong 10 trận liên tiếp. Nếu đo sát mốc 50 trụ, dùng ít nhất 7 người, mỗi người vẫn ≤8 Hero.

**Quyết định RC:** tiếp tục nghiệm thu trên build mới. Các ca Studio của RC vẫn **NOT RUN** theo bằng chứng truy cập được. Điểm 75/100 giữ nguyên; chưa publish hoặc thu số liệu nghiên cứu.

**Trạng thái:** ứng viên nghiệm thu kỹ thuật, chưa chốt release hoặc bắt đầu thu mẫu nghiên cứu. Điểm đánh giá giữ **75/100**. Nhánh `audit/full-project-review`. Build đồng bộ hiện tại `hero-limits-v1`; log Studio đối chiếu được dùng build trước `sync-7a71189a55df`. Studio MCP trả phản hồi khởi tạo nhưng không cung cấp công cụ từ phiên Studio trong thời gian kiểm tra. Đối chiếu runtime dùng file log đã lưu.

## Kiến trúc và tính năng

- **Lobby và stage:** Play Menu, LobbyManager/LobbyService và StageResolver chọn màn; GameManager giữ stage, roster và trạng thái trận phía server.
- **Gameplay:** GameManager chạy wave và quản lý căn cứ, Yen và cleanup. TowerServer cùng PlacementRules xác thực đặt, bán, nâng cấp và chọn mục tiêu. IceHero và CrimsonHero có giới hạn 4 mỗi loại / người, tổng 8 / người, tối đa 50 / trận.
- **DDA:** cùng cấu hình wave Fixed và DDA, cập nhật HP quái mới ở ranh giới wave. Giữ nguyên công thức, giá, sát thương và phần thưởng. Studio diagnostics lấy mẫu HP thực tế.
- **Nghiệm thu:** manifest Studio hỗ trợ Dry Run, Apply, Verify và rollback. Telemetry analyzer xuất CSV theo build, stage, chế độ, độ khó và baseline.

[Kiến trúc chi tiết](ARCHITECTURE.md) · [Manifest](SOURCE_SYNC_MANIFEST.md)

## Lỗi đã xử lý và hồi quy

Các mục DD-01–DD-19 và bản sửa idle trưng bày được theo dõi trong [báo cáo lỗi](BUG_REPORT.md), [Phase 3](PHASE3_ACCEPTANCE_REPORT.md) và [Changelog](CHANGELOG.md). Phase 4 sửa hai vấn đề trong công cụ QA:

- Diagnostics cũ đưa cảnh báo animation từ lịch sử Output vào kết luận của phiên đang theo dõi. Bản mới ghi riêng lịch sử và lỗi trực tiếp sau lúc attach. Cần kiểm tra Output khởi động và chuyển động idle bằng lượt Studio mới.
- Analyzer thiếu hai thống kê wave và có thể đưa hồ sơ thiếu wave trước khi kết thúc vào mẫu số. Bản mới thêm số wave hoàn thành trung bình, hệ số áp dụng trung bình và kiểm tra dữ liệu wave đầy đủ.

| Kiểm thử | Kết quả |
| --- | --- |
| Luau Compilation | **PASS** — 53 file, gồm công cụ đã sinh, và 26 nguồn nhúng RBXL |
| Unit / integration khả dụng | **PASS** — spec DDA, Phase 2, HeroPlacement, diagnostics mô phỏng và Studio Sync mock qua Luau CLI |
| Telemetry và manifest | **PASS** — 8 test Node, CSV xuất trên log Studio thật |
| Security validation | **PASS trong phạm vi unit test và rà Source** — loại payload/MatchId sai, giữ Yen khi từ chối, chỉ chủ trụ được sửa, giới hạn theo chủ sở hữu và cooldown dùng chung hai remote. Multiplayer/thử tải live chưa có trace đối chiếu |
| Git diff check | **PASS** — không thay đổi RBXL trong lượt này. SHA-256 `7E360CAE42D2F3ADE9B982FCEA91B433527E3E2D8D8AEEFED2F0509D454816D4` |

## Runtime và hiệu năng thực tế

Log của `sync-7a71189a55df` xác nhận **Act 3 Normal Fixed 15/15 wave**. Wave 15 hạ 47/47 quái, căn cứ còn 20/20, một Victory. DeckDDA đo Boss **3.200 MaxHealth**, Fixed multiplier 1 và handoff PASS. Trận Act 1 DDA hoàn thành 5/5 wave, có bằng chứng chiều tăng và bước lớn nhất 0,08. Chưa có log đối chiếu độc lập cho Act 3 DDA, chiều giảm hoặc HP dưới DDA.

Người kiểm thử báo đã hoàn thành 13/16 mục. Báo cáo runtime ghi riêng các mục Defeat, Replay, Return, cleanup, multiplayer và idle chưa đối chiếu đủ bằng chứng. Chưa tìm thấy match_start của `hero-limits-v1`; kết quả giới hạn Hero hiện đến từ handler chạy với fixture Roblox mô phỏng. [Đối chiếu đầy đủ](RUNTIME_TEST_REPORT.md)

**Hiệu năng thực tế: NOT RUN.** Chưa có FPS, RAM, CPU, server frame time, hoặc trace thể hiện rò rỉ. Không áp dụng tối ưu thiếu số liệu. Đo cùng máy, chế độ đồ họa, build và baseline cho các ca sau:

| Ca đo | Điều kiện và bằng chứng |
| --- | --- |
| Trận thường và Boss | Solo, đo trước trận, một khoảng cố định trong combat và wave 15; ghi FPS, bộ nhớ, CPU/frame time client và server, median/p95, số quái/trụ |
| Multiplayer | Ít nhất 2 client cho luồng đồng đội; ít nhất 7 người nếu đo đủ 50 trụ. Mỗi người ≤4 IceHero và ≤4 CrimsonHero |
| 10 trận liên tiếp | Chụp sau warm-up và cùng thời điểm sau mỗi cleanup. Đối chiếu xu hướng RAM, số Instance, trụ/quái và callback nếu có trace |
| Phân tích điểm nghẽn | Tách EnemyMover, chọn mục tiêu, raycast, tween, animation và VFX trong MicroProfiler. Chỉ kết luận leak khi xu hướng giữ tài nguyên lặp lại sau cleanup |

## Mobile

**NOT RUN trên Device Emulator hoặc thiết bị thật.** Rà tĩnh thấy đặt trụ/preview vẫn dùng con trỏ và các nút có đường xử lý input khác nhau. Đây là các vị trí cần kiểm tra; giữ UI Desktop cho đến khi tái hiện được lỗi touch hoặc bố cục.

- Kiểm tra một viewport điện thoại dọc, một ngang và một máy tính bảng. Xác nhận HUD, Hotbar, nút hành động và kết quả trong vùng an toàn.
- Tap chọn Hero, quan sát preview, tap đặt hợp lệ và không hợp lệ. Thử thao tác xoay camera/chạm UI để xác nhận không vô tình đặt trụ.
- Chạm Upgrade, Sell, Start, Skip, Return và Replay. Xác nhận Victory và Defeat hiển thị rõ. Sau bất kỳ bản sửa touch nào, chạy lại desktop bằng chuột/phím.

## Cách chạy và checklist trước bảo vệ

1. Tạo bản sao RBXL. Trong Edit Mode chạy Dry Run → Apply → Verify, xác nhận BuildVersion `hero-limits-v1`. Sau đó Play Solo Act 3 Normal và dùng Start Server cho hai client. [Đồng bộ Studio](STUDIO_SYNC_GUIDE.md)
2. Ghi lại build và MatchId đối với các lượt Act 3 Fixed/DDA. Xác nhận 15 wave, Boss, HP tăng/giảm, Defeat, Replay, Return và folder rỗng sau kết thúc.
3. Xác minh Hotbar 4/4, Hero thứ năm, bán để đặt lại, nâng cấp, hai người chơi và reset qua Replay trên build hiện tại.
4. Chạy mobile, đo thường/multiplayer/Boss và lặp 10 trận. Lưu evidence ngoài Git.
5. Khi tất cả mục bắt buộc có bằng chứng, chốt build cho hai nhóm, chạy pilot riêng rồi thu mẫu thật. Chỉ tổng hợp các trận đúng build, baseline và điều kiện đã đăng ký. [Bảng và protocol Fixed/DDA](EXPERIMENT_PROTOCOL.md)

CSV kỹ thuật `reports/local/phase4-act3-technical.csv` chỉ dùng kiểm tra analyzer. Bảng nghiên cứu chưa có dữ liệu. Không commit, push, merge hoặc publish trong lượt này.
