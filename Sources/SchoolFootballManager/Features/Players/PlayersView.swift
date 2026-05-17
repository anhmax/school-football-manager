import SwiftUI

struct PlayersView: View {
    var body: some View {
        NavigationView {
            Text("選手管理画面")
                .navigationTitle("選手")
        }
    }
}

#Preview {
    PlayersView()
}