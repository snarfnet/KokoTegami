import GoogleMobileAds

final class InterstitialAdManager: NSObject, ObservableObject, FullScreenContentDelegate {
    @Published var readCount = 0
    private var interstitial: InterstitialAd?

    override init() {
        super.init()
        loadAd()
    }

    func loadAd() {
        InterstitialAd.load(with: "ca-app-pub-9404799280370656/9102530245") { [weak self] ad, error in
            if let ad {
                self?.interstitial = ad
                self?.interstitial?.fullScreenContentDelegate = self
            }
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
              let ad = interstitial else { return }
        ad.present(fromRootViewController: root)
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        loadAd()
    }
}
