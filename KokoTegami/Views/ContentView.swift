import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject private var firebase = FirebaseService()
    @StateObject private var locationManager = LocationManager()
    @State private var cameraPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 36.5, longitude: 138.0),
            span: MKCoordinateSpan(latitudeDelta: 15, longitudeDelta: 15)
        )
    )
    @State private var selectedLetter: Letter?
    @State private var showCompose = false
    @State private var showDetail = false
    @State private var nearbyLetter: Letter?

    var body: some View {
        ZStack {
            AppTheme.nightGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar
                mapView
                bottomBar
                BannerAdView()
                    .frame(height: 50)
            }
        }
        .task {
            await firebase.signIn()
            locationManager.requestPermission()
        }
        .sheet(isPresented: $showDetail) {
            if let letter = selectedLetter {
                LetterDetailView(letter: letter, firebase: firebase, locationManager: locationManager) {
                    showDetail = false
                    selectedLetter = nil
                }
            }
        }
        .sheet(isPresented: $showCompose) {
            LetterComposeView(firebase: firebase, locationManager: locationManager) {
                showCompose = false
            }
        }
    }

    private var headerBar: some View {
        ZStack(alignment: .bottomLeading) {
            Image("letter-hero")
                .resizable()
                .scaledToFill()
                .frame(height: 220)
                .clipped()

            LinearGradient(
                colors: [.black.opacity(0.08), .black.opacity(0.85)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("SECRET LETTER MAP", systemImage: "location.north.line")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.envelope)

                    Spacer()

                    Text(firebase.canWrite ? "POST READY" : "READ TO WRITE")
                        .font(.caption2)
                        .fontWeight(.black)
                        .foregroundStyle(firebase.canWrite ? AppTheme.night : AppTheme.cream)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(firebase.canWrite ? AppTheme.teal : AppTheme.waxRed.opacity(0.72))
                        .clipShape(Capsule())
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("ここに手紙を置いてきた。")
                        .font(.system(size: 30, weight: .heavy, design: .serif))
                        .foregroundColor(AppTheme.cream)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("近くまで歩いた人だけが開ける、街の中の小さな秘密。")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.cream.opacity(0.76))
                        .lineSpacing(3)
                }

                HStack(spacing: 8) {
                    StatChip(title: "書ける", value: "\(creditCount)")
                    StatChip(title: "街の手紙", value: "\(firebase.letters.count)")
                    StatChip(title: "開封距離", value: "10m")
                }
            }
            .padding(18)
        }
        .frame(height: 220)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 0))
    }

    private var creditCount: Int {
        var count = 0
        if firebase.canWriteToday { count += 1 }
        count += firebase.bonusCredits
        return count
    }

    private var mapView: some View {
        Map(position: $cameraPosition) {
            UserAnnotation()

            ForEach(firebase.letters) { letter in
                Annotation("", coordinate: letter.coordinate) {
                    letterPin(letter)
                }
            }
        }
        .mapStyle(.imagery(elevation: .realistic))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
        .overlay(alignment: .top) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundStyle(AppTheme.envelope)
                Text("手紙の近くに行くと開封できます")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.cream.opacity(0.9))
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.black.opacity(0.44))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .padding(14)
        }
        .overlay {
            LinearGradient(
                colors: [.black.opacity(0.18), .clear, .black.opacity(0.26)],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)
        }
    }

    private func letterPin(_ letter: Letter) -> some View {
        let dist = locationManager.distance(to: letter.coordinate)
        let isNear = dist != nil && dist! <= 10

        return Button {
            selectedLetter = letter
            showDetail = true
        } label: {
            VStack(spacing: 2) {
                ZStack {
                    Circle()
                        .fill(isNear ? AppTheme.waxRed : AppTheme.panel)
                        .frame(width: 42, height: 42)
                        .overlay(
                            Circle()
                                .stroke(isNear ? AppTheme.cream : AppTheme.envelope, lineWidth: 2)
                        )
                        .shadow(color: (isNear ? AppTheme.waxRed : AppTheme.envelope).opacity(0.45), radius: 10, y: 4)

                    Image(systemName: isNear ? "envelope.open" : "envelope.badge")
                        .font(.system(size: 16))
                        .foregroundColor(isNear ? .white : AppTheme.envelope)
                }

                if let dist, !isNear {
                    Text(distanceText(dist))
                        .font(.system(size: 9, design: .serif))
                        .foregroundColor(AppTheme.cream)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.black.opacity(0.5))
                        .clipShape(Capsule())
                }
            }
        }
    }

    private func distanceText(_ meters: Double) -> String {
        if meters < 1000 {
            return "\(Int(meters))m"
        } else {
            return String(format: "%.1fkm", meters / 1000)
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Label(locationManager.location == nil ? "位置情報を確認中" : "現在地を取得済み", systemImage: locationManager.location == nil ? "location.slash" : "location.fill")
                    .font(.caption)
                    .foregroundStyle(AppTheme.fadedBlue)
                Spacer()
                Label("1日1通 + 開封で追加", systemImage: "seal")
                    .font(.caption)
                    .foregroundStyle(AppTheme.fadedBlue)
            }

            Button {
                showCompose = true
            } label: {
                Label("この場所に手紙を置く", systemImage: "paperplane.fill")
                    .font(.system(size: 17, weight: .bold, design: .serif))
                    .foregroundColor(firebase.canWrite ? AppTheme.night : AppTheme.cream.opacity(0.64))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(firebase.canWrite ? AppTheme.envelope : AppTheme.warmGray.opacity(0.35))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(color: AppTheme.envelope.opacity(firebase.canWrite ? 0.28 : 0), radius: 14, y: 7)
            }
            .disabled(!firebase.canWrite)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(.white.opacity(0.12))
                .frame(height: 1)
        }
    }
}

private struct StatChip: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(AppTheme.fadedBlue)
            Text(value)
                .font(.headline)
                .fontWeight(.black)
                .foregroundStyle(AppTheme.cream)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.black.opacity(0.34))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
