import SwiftUI
import FirebaseCore
import GoogleMobileAds

@main
struct KokoTegamiApp: App {
    init() {
        FirebaseApp.configure()
        GADMobileAds.sharedInstance().start(completionHandler: nil)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
