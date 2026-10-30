# Mã Nguồn Dự Án Roblox Tower Defense

Thư mục này chứa toàn bộ các file mã nguồn (`.luau`) được trích xuất trực tiếp từ dự án Roblox Studio.

## Cấu trúc thư mục

```
src/
├── ServerScriptService/
│   ├── GameManager.server.luau        # Script quản lý tiến trình trò chơi, wave, spawn Zombie và chia thưởng
│   └── TowerServer.server.luau        # Script quản lý đặt trụ (chống overlap < 5 studs), combat loop, animation và kỹ năng VFX
│
├── StarterPlayerScripts/
│   └── PlacementClient.client.luau    # LocalScript UI Hotbar đặt trụ, ghost preview màu xanh/đỏ và raycast loại trừ
│
├── ReplicatedStorage/
│   ├── Modules/
│   │   ├── WaveConfig.luau            # Module cấu hình toàn bộ 10 Wave chỉ sinh ra Zombie theo độ khó tăng dần
│   │   └── EnemyMover.luau            # Module di chuyển Zombie theo Waypoints sử dụng CFrame tweening (không rơi rạc tay chân)
│   │
│   └── Enemies/
│       └── Zombie/
│           ├── Health.server.luau     # Script hồi máu nguyên bản của Zombie
│           └── Animate.server.luau    # Script cử động/animation R15 nguyên bản của Zombie
│
└── Workspace/
    └── TheVoid_Teleport.server.luau   # Script dịch chuyển người chơi khi rơi xuống vùng The Void
```
