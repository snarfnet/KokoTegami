import GoogleMobileAds
import UIKit

final class InterstitialAdManager: NSObject, ObservableObject, GADFullScreenContentDelegate {
    @Published var readCount = 0
    private var interstitial: GADInterstitialAd?

    override init() {
        super.init()
        loadAd()
    }

    func loadAd() {
        GADInterstitialAd.load(withAdUnitID: "ca-app-pub-9404799280370656/9102530245", request: GADRequest()) { [weak self] ad, error in
            if let error {
                print("Interstitial load failed: \(error.localizedDescription)")
                return
            }
            self?.interstitial = ad
            self?.interstitial?.fullScreenContentDelegate = self
        }
    }

    func letterRead() {
        readCount += 1
        if readCount > 1 && readCount % 3 == 0 {
            showAd()
        }
    }

    private func showAd() {
        guard let interstitial,
              let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = windowScene.windows.first?.rootViewController else { return }
        interstitial.present(fromRootViewController: root)
    }

    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        loadAd()
    }
}
