import SwiftUI

/// Root coordinator: switches between the seven screens per `AppState.screen`
/// and surfaces a level-load failure (malformed bundled JSON) as an alert.
struct ContentView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        Group {
            switch appState.screen {
            case .title:
                TitleScreen(appState: appState)
            case .levelSelect:
                LevelSelectScreen(appState: appState)
            case .settings:
                SettingsScreen(appState: appState, settings: appState.settings)
            case .gameplay, .pause:
                if let viewModel = appState.gameViewModel {
                    GameplayScreen(appState: appState, viewModel: viewModel)
                } else {
                    TitleScreen(appState: appState)
                }
            case .levelComplete:
                if let viewModel = appState.gameViewModel {
                    LevelCompleteScreen(appState: appState, viewModel: viewModel)
                } else {
                    TitleScreen(appState: appState)
                }
            case .victory:
                VictoryScreen(appState: appState)
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .alert("Couldn't load levels", isPresented: errorBinding) {
            Button("OK") { appState.dismissError() }
        } message: {
            Text(appState.loadError ?? "")
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { appState.loadError != nil },
            set: { isPresented in if !isPresented { appState.dismissError() } }
        )
    }
}
