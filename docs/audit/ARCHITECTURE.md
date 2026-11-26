# Kiến trúc và vòng đời

## Cập nhật Phase 2

```mermaid
flowchart LR
  UI[PlayMenu hoặc LobbyUI] --> Lobby[LobbyManager/LobbyService]
  Map[MapSelect cũ] --> Resolver[StageResolver]
  Lobby --> Resolver
  Resolver --> Match[GameManager chốt stage và roster]
  Match --> Wave[Wave baseline]
  Wave --> DDA[DDA tại ranh giới wave]
  DDA --> Spawn[HP quái mới]
  Match --> Result[GamePhase và DeckResultMatchId]
  Result --> HUD[HUD Return/Replay]
  Match --> Log[JSON server]
  Log --> CSV[Analyzer CSV]
  Rules[PlacementRules] --> Ghost[Ghost Preview]
  Rules --> Server[TowerServer]
```

StageResolver tra StageData, lập cấu hình Act 3 hoặc dùng WaveData cũ. WaveConfig vẫn là module song song. Server lấy state của người yêu cầu và chỉ nhận các client cùng stage/difficulty vào trận. Return dùng TeleportToLobby. Replay được GameManager nhận trong phase terminal và xếp vào lượt kế tiếp sau thời gian hiển thị kết quả.

## Ghi nhận Phase 1

`GameManager` sở hữu roster, trận, wave, căn cứ, spawn và thưởng. `TowerServer` ghi giao dịch mua, nâng cấp, bán trên cùng IntValue và chỉ tìm mục tiêu trong Workspace.Enemies của trận. `EnemyMover` giữ tiến độ. `Damage → Humanoid.Died` và callback đến đích hội tụ về registry. Registry loại enemy trước khi hạch toán.

```mermaid
flowchart LR
  Lobby[Lobby và chọn map] -->|Di chuyển nhân vật| Battle[Khu battle]
  UI[BattleStart và HUD] -->|Start và Skip| GM[GameManager]
  GM -->|Attributes và Remotes| UI
  Wave[WaveData] --> GM
  GM -->|Quái của trận| Mover[EnemyMover]
  Mover -->|Đến đích| GM
  Placement[Placement và UnitInfo] --> Tower[TowerServer]
  Tower -->|Humanoid damage| GM
  GM --> Yen[leaderstats.Yen]
  Tower --> Yen
  GM -->|Chỉ số wave đã xong| DDA[DifficultyController]
  DDA -->|HP wave sau| GM
  GM --> Output[DeckTelemetry JSON]
```

```mermaid
stateDiagram-v2
  [*] --> WaitingForStart
  WaitingForStart --> Countdown
  Countdown --> WaitingForStart: khu battle trống
  Countdown --> Intermission: chốt roster
  Intermission --> WaveActive: hết giờ hoặc đủ phiếu
  WaveActive --> WaveClear: đã tạo và xử lý hết quái
  WaveClear --> Intermission: còn wave
  WaveClear --> Victory: wave cuối hữu hạn
  WaveActive --> Defeat: căn cứ về 0
  WaveActive --> Abandoned: không còn người tham gia
  Intermission --> Abandoned: không còn người tham gia
  WaveActive --> Invalid: lỗi mẫu quái hoặc đường đi
  Victory --> WaitingForStart
  Defeat --> WaitingForStart
  Abandoned --> WaitingForStart
  Invalid --> WaitingForStart
```

Server hiện có một trận dùng chung. Thành viên được chốt ở cuối countdown. Rời server hoặc khu battle trong trận kết thúc membership của người chơi đó. Các luồng chọn party và map đưa người chơi đến khu battle. `RequestStartMatch` là bước bắt đầu riêng. Các giá trị khó Easy/Normal/Hard từ menu cũ chưa quyết định WaveData. Startup scripts thay thế vắng trong RBXL kiểm tra, vì vậy đồng bộ chọn lọc theo hướng dẫn Studio.
