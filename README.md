# OpenChess Arena ♟️

A modern, free, open-source chess platform alternative to Chess.com built with Flutter + Node.js + Firebase.

## Features

### 🎮 Gameplay
- Full online multiplayer chess with real-time WebSocket communication
- Matchmaking: Bullet (1+0), Blitz (3+2), Rapid (10+5), Classical (30+10)
- Play with friends via invite codes
- Stockfish AI integration with 6 difficulty levels (800-2600 ELO)
- Guest mode and registered accounts

### 📊 Progression
- ELO rating system with 7 ranks (Bronze → Grandmaster)
- Global leaderboards for each time control
- Achievement/badge system (12+ achievements)
- Daily rewards with streak bonuses
- Player levels and XP

### 🧩 Learning
- Daily puzzles with rating system
- Puzzle themes (Forks, Pins, Sacrifices, etc.)
- Chess lessons and openings explorer
- Move classification (Brilliant, Great, Mistake, Blunder)

### 🏆 Tournaments
- Create and join tournaments
- Knockout and Swiss formats
- Spectator mode for live games

### 🎨 UI/UX
- Chess.com-inspired dark theme with green accents
- Rounded cards, smooth animations, modern typography
- Multiple board themes (Green, Brown, Blue, Purple, Gray)
- Multiple piece themes (Default, Neo, Ocean, Wood, Marble, Classic)
- Sound effects and piece animations
- Mobile-first responsive design
- Dark mode everywhere

### 🔧 Technical
- Real-time game sync via Socket.IO
- Anti-cheat basic detection
- Push notifications
- Reconnect system on disconnect
- Offline mode vs AI

## Tech Stack

| Component | Technology |
|-----------|------------|
| Frontend | Flutter 3.x, Dart |
| Backend | Node.js, Express |
| Real-time | Socket.IO |
| Database | Firebase Firestore |
| Auth | Firebase Authentication |
| AI Engine | Stockfish |
| State Mgmt | Provider |

## Project Structure

```
chess_apk/
├── flutter_app/                 # Flutter mobile app
│   ├── lib/
│   │   ├── config/             # Theme, API config, constants
│   │   ├── models/             # User, Game, Puzzle models
│   │   ├── providers/          # Auth, Game, Chat, Puzzle, Settings
│   │   ├── screens/            # UI screens
│   │   │   ├── auth/          # Login, Register, Guest
│   │   │   ├── home/          # Home tab, cards
│   │   │   ├── game/          # Lobby, Game board, Play AI
│   │   │   ├── profile/       # Profile, Stats, Achievements
│   │   │   ├── puzzles/       # Daily puzzles, themes
│   │   │   ├── learn/         # Lessons, openings
│   │   │   ├── chat/          # Global chat
│   │   │   └── tournaments/   # Tournaments list
│   │   ├── services/          # API service, HTTP client
│   │   └── widgets/           # Chess board, cards
│   └── android/               # Android configuration
├── backend/                    # Node.js server
│   ├── config/                # Firebase, Constants
│   ├── models/                # User, Game, Tournament
│   ├── routes/                # REST API routes
│   ├── socket/                # WebSocket handlers
│   ├── services/              # Matchmaking, ELO, Chess engine
│   └── seeds/                 # Database seed script
```

## Quick Start

### Prerequisites
- Flutter SDK 3.x
- Node.js 18+
- Firebase project
- Android Studio / Xcode

### Backend Setup

```bash
cd backend
cp .env.example .env
# Edit .env with your Firebase credentials
npm install
npm run seed    # Create sample users & data
npm run dev     # Start development server
```

### Flutter Setup

```bash
cd flutter_app
flutter pub get
flutter run                    # Run on connected device
flutter build apk --release    # Build release APK
```

### Environment Variables

| Variable | Description |
|----------|-------------|
| PORT | Server port (default: 3000) |
| FIREBASE_PROJECT_ID | Firebase project ID |
| FIREBASE_PRIVATE_KEY | Firebase private key |
| FIREBASE_CLIENT_EMAIL | Firebase client email |
| JWT_SECRET | JWT signing secret |
| STOCKFISH_PATH | Path to Stockfish binary |

## Building APK

```bash
cd flutter_app
flutter build apk --release --split-per-abi
```

APK files will be at:
- `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
- `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk`
- `build/app/outputs/flutter-apk/app-x86_64-release.apk`

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login with Firebase token
- `POST /api/auth/guest` - Create guest account
- `POST /api/auth/check-username` - Check username availability

### Profile
- `GET /api/profile/:uid` - Get user profile
- `PUT /api/profile/:uid` - Update profile
- `GET /api/profile/:uid/stats` - Get user stats
- `POST /api/profile/:uid/daily-reward` - Claim daily reward
- `GET /api/profile/:uid/achievements` - Get achievements

### Games
- `POST /api/games/create` - Create a new game
- `GET /api/games/:gameId` - Get game details
- `GET /api/games/history/:uid` - Get game history
- `GET /api/games/live/list` - Get live games

### Leaderboard
- `GET /api/leaderboard/:timeControl` - Get leaderboard
- `GET /api/leaderboard/:timeControl/around/:uid` - Get ranking around user

### Puzzles
- `GET /api/puzzles/daily` - Get daily puzzle
- `GET /api/puzzles/random` - Get random puzzle
- `GET /api/puzzles/by-rating` - Get puzzles by rating range

### Tournaments
- `POST /api/tournaments/create` - Create tournament
- `GET /api/tournaments/active` - Get active tournaments
- `POST /api/tournaments/:id/register` - Register for tournament

## WebSocket Events

### Client → Server
- `user:online` - Set user online
- `matchmaking:join` - Join matchmaking queue
- `matchmaking:leave` - Leave queue
- `game:move` - Make a move
- `game:resign` - Resign game
- `game:draw` - Offer draw
- `chat:global:send` - Send global chat message
- `chat:game:send` - Send game chat message
- `spectate:game` - Spectate a game

### Server → Client
- `match:found` - Match found
- `game:move` - Move made
- `game:over` - Game ended
- `game:state` - Full game state
- `chat:global:message` - New global message
- `player:disconnected` - Player disconnected
- `queue:sizes` - Queue size updates

## Sample Users

The seed script creates 25 sample users with realistic ELO ratings:

| Username | Rapid ELO | Level |
|----------|-----------|-------|
| MagnusCarlsen | 2850 | 50 |
| HikaruNakamura | 2800 | 48 |
| GothamChess | 2350 | 35 |
| SpeedDemon | 2200 | 40 |
| ... and 20+ more | 900-2850 | 5-50 |

## License

MIT License - free to use, modify, and distribute.
