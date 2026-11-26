# Thiết lập Codex Skills cho Deck Defenders

Các skill nằm tại `.agents/skills/` và chỉ áp dụng trong project. Danh mục Roblox được đối chiếu trên [Skills.sh](https://www.skills.sh/el4cteo/roblox-skills). Các thư mục được chép từ snapshot GitHub theo commit sau khi kiểm tra nội dung. Giấy phép đi cùng các bản chép nguyên gốc.

| Nguồn | Commit | Skill đã cài |
| --- | --- | --- |
| el4cteo/roblox-skills | `cac3ce045f49630f13b76f45c452d1f96e910d50` | roblox-luau, roblox-studio-mcp, roblox-game-systems, roblox-ui, roblox-security, roblox-testing, roblox-performance, roblox-networking, roblox-input, roblox-architecture, roblox-characters-animation, roblox-analytics-liveops, roblox-tooling |
| obra/superpowers | `22f0b463e7a5e579904dd6211a520321035526f7` | systematic-debugging, test-driven-development, verification-before-completion, requesting-code-review, writing-plans |
| tabooharmony/roblox-brain | `ceee4aaa5004502e2a51d78b3c33bba44d84742b` | roblox-game-design |
| ashexplained/roblox-skills | `a3a7b940f0899d4a69c1a7df625996bdfc917388` | roblox-game-ux |
| ag/scientific-agent-skills | `90410b5ce07d6a69816d5ec8da693c7ab75510f5` | experimental-design |
| thedivergentai/game-development-agentic-skills | `db004d74c40686ca2f7a35fe067b119a9cda593e` | genre-tower-defense, bản dự án tự viết dựa trên các nguyên lý dùng được trong Roblox |

Upstream Tower Defense hiện có biến thể Godot và Bevy. Cả hai gói nguyên gốc đều được bỏ qua do ràng buộc engine. Bản Roblox không chứa script hoặc API của hai engine này.

Codex app-server trả về 22/22 skill project đang bật qua `skills/list`. Kiểm tra tĩnh cũng xác nhận mỗi thư mục có `SKILL.md` với tên và mô tả hợp lệ.

## Kết quả rà soát quyền và nội dung

- `roblox-tooling` minh họa tải script từ nhánh động rồi truyền thẳng cho Bash, và có ví dụ CI upload. `roblox-testing` có ví dụ Open Cloud dùng API key và tải bản place lên. `roblox-studio-mcp` mô tả quyền thực thi Luau, Open Cloud, kho dữ liệu và tải asset. Các ví dụ này không cấp thêm quyền cho project.
- `systematic-debugging` kèm ví dụ TypeScript và một shell script có thể chạy npm test. Hướng dẫn chẩn đoán upstream cũng có ví dụ kiểm tra trạng thái danh tính ký mã. Áp dụng quy tắc log tối thiểu trong AGENTS.md.
- `experimental-design` kèm hai script Python cho ngẫu nhiên hóa và thiết kế thí nghiệm, với các dependency NumPy, pandas và pyDOE3. Chỉ dùng dữ liệu nghiên cứu đã được phép và kiểm tra dependencies trước khi chạy.
- `requesting-code-review` và `writing-plans` có hướng dẫn điều phối reviewer, subagent hoặc workflow bổ sung. Dùng trong phạm vi quyền được cấp và áp dụng review tại chỗ khi không có quyền điều phối.
- Phiên cài đặt chỉ chép tệp đã kiểm tra. Không chạy shell, Python hoặc TypeScript từ skill, không cài dependency của skill và không tải mã nguồn, secret hoặc dữ liệu cá nhân của project ra ngoài.

## Roblox Studio MCP

Roblox Studio MCP chưa có trong danh sách server của Codex. Bản `StudioMCP.exe` cục bộ có chữ ký Roblox hợp lệ và trả lời `initialize`, nhưng `tools/list` hết thời gian chờ. Phiên cài đặt chưa có kết nối Studio dùng được và không thay đổi cấu hình MCP. Dùng bundle đồng bộ hiện có trên bản sao RC khi cần.

## Cách gọi skill

Mở chat mới trong project và gõ `$` để chọn skill. Ví dụ `Dùng $systematic-debugging, $roblox-luau và $roblox-testing để tìm nguyên nhân HUD Yen không cập nhật trong RC.` AGENTS.md có bảng chọn skill theo công việc và yêu cầu bằng chứng kiểm thử.
