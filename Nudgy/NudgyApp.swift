import SwiftUI

@main
struct NudgyApp: App {
    @StateObject private var model = AppModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
                .environmentObject(model.engine)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { model.engine.didBecomeActive() }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject private var engine: SessionEngine

    var body: some View {
        if let session = engine.active {
            RunningSessionView(session: session)
        } else {
            PresetListView()
        }
    }
}
