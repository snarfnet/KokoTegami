import SwiftUI
import FirebaseCore
import GoogleMobileAds

@main
struct KokoTegamiApp: App {
    init() {
        FirebaseApp.configure()
        MobileAds.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
