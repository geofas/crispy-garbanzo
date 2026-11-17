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
                .environmentObject(model.store)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                model.engine.didBecomeActive()
                Task { await model.store.refresh() }
            }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var engine: SessionEngine

    var body: some View {
        Group {
            if let session = engine.active {
                RunningSessionView(session: session)
            } else {
                PresetListView()
            }
        }
        .themed(model.theme)
    }
}
