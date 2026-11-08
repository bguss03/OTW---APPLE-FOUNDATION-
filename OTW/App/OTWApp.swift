import SwiftUI
import SwiftData

@main
struct OTWApp: App {
    private let container: ModelContainer
    @State private var appModel: AppModel

    init() {
        do {
            container = try ModelContainer(for: Event.self, Reminder.self)
        } catch {
            fatalError("Failed to create the OTW model container: \(error)")
        }
        SampleData.seedIfNeeded(in: container.mainContext)

        let model = AppModel()
        _appModel = State(initialValue: model)
        NotificationManager.shared.configure(container: container, appModel: model)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appModel)
        }
        .modelContainer(container)
    }
}

private struct RootView: View {
    @Environment(AppModel.self) private var appModel
    @Namespace private var zoomNamespace

    var body: some View {
        @Bindable var appModel = appModel

        NavigationStack(path: $appModel.path) {
            HomeView(today: .now)
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .calendar:
                        CalendarView(selectedDate: $appModel.selectedDate)
                    case .event(let id, let source):
                        EventDetailView(eventID: id)
                            .zoomTransitionDestination(source, in: zoomNamespace)
                    case .reminder(let id, let source):
                        ReminderDetailView(reminderID: id)
                            .zoomTransitionDestination(source, in: zoomNamespace)
                    }
                }
        }
        .environment(\.zoomNamespace, zoomNamespace)
        .task { await NotificationManager.shared.rescheduleAll() }
    }
}
