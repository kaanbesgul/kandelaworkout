import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            WorkoutEntryView()
                .tabItem {
                    Label("Antrenman", systemImage: "plus.circle.fill")
                }

            HistoryView()
                .tabItem {
                    Label("Geçmiş", systemImage: "clock.fill")
                }

            TemplatesView()
                .tabItem {
                    Label("Şablonlar", systemImage: "list.bullet.clipboard.fill")
                }

            AIAnalysisView()
                .tabItem {
                    Label("AI Koç", systemImage: "sparkles")
                }

            ProfileView()
                .tabItem {
                    Label("Profil", systemImage: "person.circle.fill")
                }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
