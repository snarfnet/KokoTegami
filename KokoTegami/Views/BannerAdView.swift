import SwiftUI
import GoogleMobileAds

struct BannerAdView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        let banner = BannerView()
        banner.adUnitID = "ca-app-pub-9404799280370656/PLACEHOLDER"
        banner.rootViewController = vc
        banner.translatesAutoresizingMaskIntoConstraints = false
        vc.view.addSubview(banner)
        NSLayoutConstraint.activate([
            banner.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor),
            banner.bottomAnchor.constraint(equalTo: vc.view.bottomAnchor)
        ])
        banner.load(Request())
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
