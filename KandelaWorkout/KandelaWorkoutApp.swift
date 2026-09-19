import SwiftUI
import SwiftData

@main
struct KandelaWorkoutApp: App {
    @State private var restTimer = RestTimerService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(restTimer)
        }
        .modelContainer(for: [
            WorkoutSession.self,
            ExerciseEntry.self,
            SetEntry.self,
            WorkoutTemplate.self,
            UserProfile.self,
            WeightEntry.self,
        ])
    }
}
