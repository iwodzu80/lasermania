# Lasermania

A native macOS remake of *Lasermania*, the 1990 Atari 8-bit laser-routing
puzzle game by L.K. Avalon. Guide a beam to destroy every alarm sensor,
collect every memory capsule, then reach the exit door — pushing boxes and
mirrors to route the laser, Sokoban-style.

## Requirements

- macOS 13 (Ventura) or later
- Xcode 15+ / Swift 5.9+ toolchain

## Build & run

```sh
swift run Lasermania
```

or open the package in Xcode (`File ▸ Open…` on `Package.swift`) and run
the `Lasermania` scheme.

## Run tests

```sh
swift test
```

The test suite covers the pure game model only (`LasermaniaCoreTests`):
laser tracing/reflection, push rules, win conditions, scoring, level
loading/validation, and a BFS solver used to assert every bundled level is
actually solvable.

> **Note on provenance:** this project was developed in a Linux sandbox with
> no Swift toolchain available (`swift` is not on `PATH`), so the AppKit /
> SwiftUI / SpriteKit code in `LasermaniaApp` has never been compiled. Every
> API used there was instead verified by hand against the actual source of
> the file declaring it (cross-checking method/property signatures across
> files rather than trusting recollection). `LasermaniaCore` is pure Swift
> with no Apple-only frameworks, so it is the part most likely to build
> cleanly anywhere a Swift toolchain exists; build and test on macOS before
> relying on this for anything beyond review.

## Project structure

```
LasermaniaCore/            // pure Swift, no SpriteKit/AppKit — unit-tested
  Direction.swift           Coord.swift           Terrain.swift
  Grid.swift                GameState.swift        LaserTracer.swift
  LevelDefinition.swift     LevelLoader.swift      BundledLevels.swift
  GameSession.swift         Scoring.swift
  Resources/Levels/         // bundled JSON level pack (12 levels + manifest)

LasermaniaApp/              // macOS app (SwiftUI + SpriteKit)
  AppMain.swift              // @main entry point, WindowGroup
  AppState.swift             // navigation/level-loading coordinator
  GameViewModel.swift        // per-level Observable wrapper over GameSession
  GameScene.swift            // SpriteKit render + keyboard/mouse input
  Audio.swift                 Persistence.swift     Palette.swift
  Screens/                   // Title, LevelSelect, Gameplay+HUD, Pause,
                              // LevelComplete, Victory, Settings, ContentView
  Resources/Audio/            // music + SFX

Tests/LasermaniaCoreTests/  // LaserTracer, push rules, win conditions,
                              // scoring, level loader, BFS solvability
```

## Controls

| Action | Keys |
|---|---|
| Move / push | Arrow keys or WASD |
| Undo | `Z` or `⌘Z` |
| Restart level | `R` |
| Pause / menu | `Esc` or `P` |
| Confirm / select | `Return` or mouse click |
| Navigate menus | Arrow keys + `Return`, or mouse |

## Persistence

Settings (volume, control scheme, color theme, reduce motion) and progress
(best moves per level, used to derive level unlocks) are stored in
`UserDefaults` — no account or network access required.
