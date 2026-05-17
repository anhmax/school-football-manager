import SwiftUI

struct EventsView: View {
    var body: some View {
        NavigationView {
            Text("イベント管理画面")
                .navigationTitle("イベント")
        }
    }
}

#Preview {
    EventsView()
}