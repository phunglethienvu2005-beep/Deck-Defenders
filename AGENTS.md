# Deck Defenders

Project Roblox Studio và Luau cho tower defense 3D và nghiên cứu DDA. Giữ các thay đổi trong phạm vi được yêu cầu và bảo toàn thay đổi đang có của người dùng.

## Khi dùng skill

| Công việc | Skill và quy tắc |
| --- | --- |
| Sửa lỗi | Dùng `systematic-debugging`, `roblox-luau` và `roblox-testing`. Xác minh nguyên nhân bằng chứng trước khi sửa. |
| Giao diện và input | Dùng `roblox-ui`, `roblox-game-ux` và `roblox-input` cho HUD, Hotbar, Yen, Shop, Lobby, Victory và Defeat. Kiểm tra Desktop và Mobile khi có môi trường phù hợp. |
| Gameplay | Dùng `roblox-game-systems`, `roblox-game-design` và `genre-tower-defense` cho Hero, Enemy, Wave, Combat, Economy và DDA. Chỉ áp dụng nguyên lý thiết kế Tower Defense phù hợp Roblox và dùng API Roblox/Luau. |
| Client–server | Dùng `roblox-networking` và `roblox-security`. Server quyết định số tiền, sát thương, quyền sở hữu và giới hạn Hero. |
| Tối ưu | Dùng `roblox-performance`. Đo trước khi tối ưu và chỉ báo cáo FPS, RAM cùng các số liệu có bằng chứng. |
| Đồng bộ Studio | Dùng `roblox-studio-mcp` và `roblox-tooling`. Xác minh đúng bản sao RBXL, Source thực tế và BuildVersion. Khi MCP không khả dụng, dùng `tools/generated/studio-one-click-sync.luau` trong Edit Mode của bản sao RC. |
| Kiểm thử và nghiệm thu | Dùng `test-driven-development`, `roblox-testing`, `requesting-code-review` và `verification-before-completion`. Chỉ đánh dấu runtime PASS khi đã chạy trong Studio và có bằng chứng. Dùng checklist review tại chỗ nếu không có quyền điều phối reviewer. |
| Nghiên cứu DDA | Dùng `experimental-design` và `roblox-analytics-liveops`. Tách rõ dữ liệu mô phỏng, QA và dữ liệu thực nghiệm người chơi thật. |
| Công việc bổ sung | Dùng `writing-plans` cho thay đổi nhiều bước, `roblox-architecture` khi thay đổi ranh giới hệ thống và `roblox-characters-animation` khi xử lý nhân vật hoặc animation. |

## Phạm vi và quyền truy cập

- Skill nằm trong `.agents/skills/`. Khi skill chưa có hoặc chưa được Codex nhận diện, áp dụng quy tắc của dự án và ghi rõ giới hạn đó.
- Ví dụ cài công cụ, chạy script, cấu hình MCP, dùng Open Cloud hoặc tải dữ liệu lên chỉ là tài liệu tham khảo. Kiểm tra mã và quyền hiện có trước khi thực hiện. Giữ mã nguồn, secret và thông tin cá nhân trong môi trường được phép. Tránh in tên hoặc giá trị secret vào log.
- Giữ nguyên RBXL gốc. Đồng bộ và kiểm thử trên bản sao đã xác nhận. Chỉ push, merge, publish hoặc gửi dữ liệu ra ngoài khi người dùng đã cho phép hành động đó.

## Quy tắc phát triển Deck Defenders

- Chỉ làm việc tại `E:\Roblox Game ĐACN\` trên nhánh `audit/full-project-review`. Bản Studio duy nhất dùng để đồng bộ là `reports/local/DeckDefenders-hero-limits-v2-RC.rbxl`. Áp dụng các quy tắc này cho mọi nhiệm vụ tiếp theo.
- Chỉnh trực tiếp Source của project hiện tại. Tái sử dụng Script, ModuleScript, Controller và RemoteEvent hiện có. Giới hạn thay đổi trong phạm vi nhiệm vụ và bảo toàn chức năng ổn định. Dùng 22 skill đã cài theo bảng trên và Git để theo dõi, đối chiếu và hỗ trợ rollback.
- Giữ nguyên cấu trúc thư mục, project, workspace và repository. Chỉ tạo nhánh khi người dùng yêu cầu. Không viết lại toàn bộ project, dựng hệ thống hoặc Script trùng, tạo tài liệu trùng lặp, tạo thêm RBXL hay bản RC v3, v4 hoặc premium-play-ui-v1.
- Khi Source đổi, cập nhật manifest và sinh lại `tools/generated/studio-one-click-sync.luau`. Đồng bộ trong Edit Mode vào đúng RC hiện tại. Giữ `BuildVersion=hero-limits-v2` và dùng fingerprint Source của bundle để phân biệt từng lần cập nhật. Khi cần thao tác thủ công, cung cấp đúng một lệnh PowerShell để chép bundle.
- Chạy regression trước khi báo hoàn thành. Giữ nguyên RBXL gốc và tránh mọi thao tác tự động push, merge hoặc publish.

## Phạm vi redesign Play UI

- Chỉ nâng cấp Play Menu, Story, World Selection, Act Selection và Party Lobby dựa trên video tham chiếu. Tập trung vào bố cục, typography, gradient, banner, thumbnail, hiệu ứng và trải nghiệm người chơi.
- Giữ nguyên gameplay, Hero, Yen Economy, combat, wave, multiplayer, DDA và telemetry. Dùng lại các controller và luồng server sẵn có.
