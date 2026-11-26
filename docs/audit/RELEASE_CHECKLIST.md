# Checklist chuẩn bị nghiệm thu

- [x] Xác nhận nhánh audit/full-project-review và hash RBXL gốc trước/sau.
- [x] Sinh bundle, kiểm thử manifest, escape, chặn drift và rollback trên mô hình Luau.
- [ ] Verify nguồn, asset và legacy UI trên một bản sao Studio. Lưu Output.
- [ ] Chạy Solo Act 3, hai client và Mobile Emulator. Lưu log và ảnh theo kịch bản.
- [ ] Chạy 50 trụ, boss và 10 trận để kiểm tra cleanup và profiler.
- [ ] Tạo hai bản local Fixed/DDA từ một integration copy. Giữ chung BuildVersion. Chạy pilot rồi mới thu mẫu.
- [ ] Kiểm tra analyzer bằng log thật. Đếm riêng Invalid và log thiếu. Giữ thông tin nghiên cứu ngoài Git.
- [ ] Review diff theo danh sách dưới đây và commit chọn lọc sau nghiệm thu. Giữ original RBXL và thay đổi riêng của người dùng trong diff độc lập.

## Đề xuất phạm vi commit sau nghiệm thu

- Nhóm Phase 1–2: chọn từng Source quản lý trong src, test hiện có, README và các tài liệu kiểm toán. Với PlayMenuController đã có chỉnh sửa riêng trước audit, review và stage theo hunk nếu cần.
- Nhóm Phase 3: .gitignore, tools/generate-studio-sync.mjs, tools/studio-sync-engine.luau, tools/studio-sync-manifest.json, cập nhật tools/inspect-place.mjs, ba file test Studio sync và báo cáo dưới docs/audit.
- Để tools/generated, compiler tạm, Place thử, log nghiên cứu và CSV ngoài commit. Nếu phải giao RBXL đã nghiệm thu, đặt file riêng và review cùng người sở hữu trước khi stage.
- Trước khi commit, chạy git diff --check và kiểm tra git diff --cached. Không stage hàng loạt vì workspace có sửa đổi sẵn tại RBXL.

Các lệnh tái lập test và kết quả nằm trong [báo cáo Phase 3](PHASE3_ACCEPTANCE_REPORT.md).
