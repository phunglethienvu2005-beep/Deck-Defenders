# Nghiệm thu kỹ thuật Phase 2

Phase 3 bổ sung generator, Dry Run, Apply, Verify, Rollback và runtime diagnostics. Các lượt Studio sau đó đã xác nhận Apply/Verify và một Victory Act 1 DDA. Điểm giữ 75/100. [Báo cáo Phase 3](PHASE3_ACCEPTANCE_REPORT.md)

## Bằng chứng nghiệm thu Studio mới nhất

**Phase 4:** Log xác nhận Act 3 Normal Fixed thắng 15/15 wave và Boss wave 15 có MaxHealth 3.200 trên build `sync-7a71189a55df`. DDA Act 1 vẫn là lượt DDA có thể đối chiếu độc lập. Các mục người dùng đã xác nhận nhưng chưa có trace tương ứng được ghi riêng trong báo cáo runtime. Chưa chốt release khi Hero Hotbar, mobile, performance và bằng chứng DDA Act 3 còn chờ. Điểm giữ **75/100**. [Báo cáo release Phase 4](FINAL_RELEASE_REPORT.md)

**Phase 3.3 — Chưa chốt bản ổn định.** Telemetry Act 1 DDA đã xác nhận hệ số bắt đầu ở 1, tăng đến giá trị áp dụng 1,2452875 ở wave 5, bước tối đa 0,08 và kết quả Victory đúng một lần. `nextMultiplier = 1.25` được tính sau wave cuối. Chưa có chứng cứ quái dùng giá trị đó. [Bảng số liệu runtime theo wave](RUNTIME_TEST_REPORT.md#phase-33--nghiệm-thu-dda-trong-gameplay)

Đề xuất chốt bản ổn định sau khi cùng build có lượt Act 3 Normal Fixed và DDA đủ 15 wave, Boss và outcome được ghi nhận, HP thật khớp baseline/hệ số, có mẫu tăng và giảm trong runtime, Defeat và các nút Return/Replay hoạt động, cleanup rỗng và idle sau sửa đã xác minh. Các log kỹ thuật hiện tại và mô phỏng chưa đủ để kết luận DDA tăng tỷ lệ thắng. Điểm kỹ thuật giữ **75/100**.

Ngày 25/11/2026, server ghi Victory lúc 14:34:32 (UTC+7) cho MatchId `df9b5476-181f-4958-bc85-26596a644121`, StageId `world_1.act_1`, Normal, DDA, build `sync-7a71189a55df`. Có đủ năm `wave_end`, wave 5 hoàn tất và đúng một `match_end` Victory. Người kiểm thử báo thấy màn Chiến thắng với nút Về Lobby và Chơi lại.

- **Đã xác minh:** Kết thúc Act 1 DDA với 5/5 wave. Hệ số wave sau khớp telemetry wave trước và các bước quan sát nằm trong giới hạn.
- **Chưa nghiệm thu:** Act 3 đủ 15 wave và Boss wave 15, MaxHealth thực tế, cleanup ngay sau Victory, thao tác Return/Replay và animation sau sửa. Không có dòng DeckDDA trong lượt này.
- **Phạm vi bằng chứng:** Log server xác nhận stage, thời điểm và outcome. Giao diện do người dùng quan sát. Các kết quả mô phỏng được giữ riêng. [Báo cáo runtime](RUNTIME_TEST_REPORT.md)

Nhánh audit/full-project-review, mốc 2a123c1, ngày 25/11/2026. Xử lý bốn mục còn mở trong phạm vi mã nguồn và quy trình đồng bộ. Tổng 16 mục Phase 1 đã có sửa đổi hoặc phương án thực thi. Thêm ba lỗi P2 trong lượt này và sửa ở mã nguồn. Không phát hiện P0 mới trong phạm vi đã chạy. Kiểm thử Roblox Studio vẫn là điều kiện nghiệm thu gameplay.

| Hạng mục | Kết quả |
| --- | --- |
| DD-08 | StageResolver nối lựa chọn, khóa stage theo server, Act 3 có 15 wave và boss cuối. Cần chơi hết trận trên route thật. |
| DD-14 | Module placement dùng chung, server kiểm tra CFrame, stage membership, raycast và giao dịch. Trả thành công hoặc từ chối để UI giữ đúng ghost. |
| DD-15 | Bảng đầy đủ từ root, src và nguồn nhúng. Đã đọc cây parent và Disabled. Dùng quy trình đồng bộ từng Instance. |
| DD-16 | HUD hiển thị theo phase và result ID, có Return/Replay. Đã tìm đúng legacy consumer. Cần tắt script này và xác nhận ScreenGui trong bản thử Studio. |
| DD-17–19 | Sửa GetLobbyData chưa giới hạn, Start ẩn khi yêu cầu bị từ chối, trừ Yen trước khi clone được chuẩn bị. |

## Kiến trúc và đo lường

Phase 1 dùng một chuỗi WaveData cho menu nhiều Act, hai bộ kiểm tra placement và Output thiếu ActId. Phase 2 dùng StageResolver để tạo snapshot stage/roster, module placement dùng chung, HUD đánh dấu match ID kết quả và analyzer CSV lọc world_1.act_3. DDA giữ biên 0,80–1,25, bước tối đa 0,08 và tác động HP quái mới. Xem [kiến trúc](ARCHITECTURE.md), [mô phỏng](DDA_SIMULATION_REPORT.md) và [telemetry](TELEMETRY_GUIDE.md).

Chỉ số thắng Act 3 và tỷ lệ bỏ giữa trận đã có phép tính và bài test fixture. Cần log server thật. Kết quả mô phỏng chỉ mô tả bộ điều khiển khi có chuỗi hiệu suất giả định. Không có dữ liệu để kết luận tỷ lệ thắng, cải thiện FPS hoặc mức RAM.

## Điểm theo bằng chứng

| Tiêu chí | Tối đa | Phase 1 | Phase 2 | Bằng chứng tăng điểm |
| --- | ---: | ---: | ---: | --- |
| Kiến trúc | 10 | 6 | 8 | StageResolver, đường đồng bộ rõ |
| Chất lượng mã | 10 | 6 | 7 | Placement chung, module kiểm thử được |
| Gameplay | 15 | 10 | 11 | 15 wave/Boss, Return/Replay ở source |
| DDA | 20 | 13 | 16 | Sáu mô phỏng, guards và telemetry |
| UI/UX | 10 | 6 | 7 | Preview và HUD kết quả theo ID |
| Bảo mật | 10 | 7 | 8 | Stage validation, membership, GetLobbyData |
| Hiệu năng | 10 | 6 | 6 | Chưa đo profiler |
| Testing | 10 | 4 | 7 | 41 nguồn, 22 nguồn RBXL, test Luau và Node |
| Tài liệu | 5 | 4 | 5 | Manifest, protocol, checklist |
| Tổng | 100 | 62 | 75 | Điểm kỹ thuật trước xác minh Studio |

## File Phase 2

- Thêm StageResolver.luau, PlacementRules.luau, MatchResult.luau.
- Sửa StageData.luau, DifficultyController.luau, GameManager.server.luau, LobbyManager.server.luau, LobbyService.server.luau, MapSelectServer.server.luau và TowerServer_server.luau.
- Sửa PlayMenuController.client.luau, BattleStartController.client.luau, HUD.client.luau, LobbyUI/LobbyController.client.luau và PlacementClient.client.luau.
- Thêm tools/analyze-telemetry.mjs, tools/inspect-place.mjs, tests/Phase2.spec.luau, tests/roblox-value-mocks.luau và tests/telemetry.test.mjs. Mở rộng tests/run-luau.mjs.
- Sửa README.md, src/README.md và 10 báo cáo kiểm toán gốc. Thêm STAGE_SYSTEM, DDA_SIMULATION_REPORT, TELEMETRY_GUIDE, STUDIO_TEST_CHECKLIST, SOURCE_SYNC_MANIFEST, EXPERIMENT_PROTOCOL và tài liệu này.
- Không xóa file. SHA-256 của TowerDefense_DoAn.rbxl vẫn là 238700D2742FA2B0667E3A644F737AA14ED5DB413F4FEF1D46E251E8395B8BD3. Không push hoặc merge main.

## Trạng thái bàn giao

Studio không khả dụng trong môi trường kiểm tra. Chưa tạo place thứ hai đã đồng bộ bởi thao tác dán Source và xác nhận asset/GUI cần Studio. Dùng [hướng dẫn đồng bộ](ROBLOX_STUDIO_SETUP.md), chạy [Studio checklist](STUDIO_TEST_CHECKLIST.md) và [quy trình thực nghiệm](EXPERIMENT_PROTOCOL.md). Các module và analyzer đã có lệnh kiểm thử ở [TEST_REPORT](TEST_REPORT.md).
