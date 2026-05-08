import SwiftUI
import FirebaseCore
import GoogleMobileAds

@main
struct KokoTegamiApp: App {
    init() {
        FirebaseApp.configure()
        MobileAds.shared.start(completionHandler: nil)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
