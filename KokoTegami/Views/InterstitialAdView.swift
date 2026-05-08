import GoogleMobileAds
import UIKit

final class InterstitialAdManager: NSObject, ObservableObject, FullScreenContentDelegate {
    @Published var readCount = 0
    private var interstitialAd: InterstitialAd?

    override init() {
        super.init()
        Task { await loadAd() }
    }

    func loadAd() async {
        do {
            interstitialAd = try await InterstitialAd.load(
                with: "ca-app-pub-9404799280370656/9102530245",
                request: Request()
            )
            interstitialAd?.fullScreenContentDelegate = self
        } catch {
            print("Interstitial load error: \(error.localizedDescription)")
        }
    }

    func letterRead() {
        readCount += 1
        if readCount > 1 && readCount % 3 == 0 {
            showAd()
        }
    }

    private func showAd() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.keyWindow?.rootViewController,
              let ad = interstitialAd else { return }
        ad.present(from: root)
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        interstitialAd = nil
        Task { await loadAd() }
    }
}
