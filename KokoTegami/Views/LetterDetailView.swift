import SwiftUI

struct LetterDetailView: View {
    let letter: Letter
    let firebase: FirebaseService
    let locationManager: LocationManager
    let interstitial: InterstitialAdManager
    let onDismiss: () -> Void

    @State private var isReading = false
    @State private var readComplete = false

    private var distance: Double? {
        locationManager.distance(to: letter.coordinate)
    }

    private var isNear: Bool {
        guard let d = distance else { return false }
        return d <= 10
    }

    var body: some View {
        ZStack {
            AppTheme.nightGradient.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Envelope icon
                ZStack {
                    Circle()
                        .fill(AppTheme.panel)
                        .frame(width: 92, height: 92)
                        .overlay(
                            Circle()
                                .stroke(isNear ? AppTheme.envelope : AppTheme.fadedBlue.opacity(0.5), lineWidth: 2)
                        )
                        .shadow(color: (isNear ? AppTheme.envelope : AppTheme.fadedBlue).opacity(0.35), radius: 18, y: 8)

                    Image(systemName: isNear ? "envelope.open" : "envelope.badge")
                        .font(.system(size: 36))
                        .foregroundColor(isNear ? AppTheme.envelope : AppTheme.fadedBlue)
                }

                if readComplete {
                    // Show letter content
                    VStack(spacing: 16) {
                        letterContent
                        doneButton
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else if isNear {
                    // Can read
                    VStack(spacing: 12) {
                        Text("手紙を見つけた")
                            .font(.system(size: 24, weight: .heavy, design: .serif))
                            .foregroundColor(AppTheme.cream)

                        Text("開封すると手紙は消えます。\n代わりに1通書く権利がもらえます。")
                            .font(.system(size: 14, design: .serif))
                            .foregroundColor(AppTheme.fadedBlue)
                            .multilineTextAlignment(.center)

                        Button {
                            readLetter()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "envelope.open")
                                Text("読む")
                            }
                            .font(.system(size: 16, weight: .medium, design: .serif))
                            .foregroundColor(AppTheme.night)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 14)
                            .background(AppTheme.envelope)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .disabled(isReading)
                    }
                } else {
                    // Too far
                    VStack(spacing: 12) {
                        Text("まだ遠い...")
                            .font(.system(size: 24, weight: .heavy, design: .serif))
                            .foregroundColor(AppTheme.cream)

                        if let d = distance {
                            Text("あと\(distanceText(d))")
                                .font(.system(size: 28, weight: .bold, design: .serif))
                                .foregroundColor(AppTheme.envelope)
                        }

                        Text("10m以内に近づくと読めます")
                            .font(.system(size: 14, design: .serif))
                            .foregroundColor(AppTheme.fadedBlue)
                    }
                }

                Spacer()

                Button("閉じる") { onDismiss() }
                    .font(.system(size: 15, design: .serif))
                    .foregroundColor(AppTheme.fadedBlue)
                    .padding(.bottom, 30)
            }
            .padding()
        }
        .animation(.easeInOut(duration: 0.4), value: readComplete)
    }

    private var letterContent: some View {
        VStack(spacing: 0) {
            // Craft paper letter
            VStack(alignment: .leading, spacing: 12) {
                Text(letter.text)
                    .font(.system(size: 17, design: .serif))
                    .foregroundColor(AppTheme.ink)
                    .lineSpacing(6)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack {
                    Spacer()
                    Text(formatDate(letter.createdAt))
                        .font(.system(size: 12, design: .serif))
                        .foregroundColor(AppTheme.fadedBlue)
                }
            }
            .padding(24)
            .background(AppTheme.parchment)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppTheme.envelope.opacity(0.75), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.35), radius: 18, y: 10)
        }
        .padding(.horizontal)
    }

    private var doneButton: some View {
        VStack(spacing: 8) {
            Text("手紙を1通書く権利を得た")
                .font(.system(size: 14, design: .serif))
                .foregroundColor(AppTheme.envelope)
        }
    }

    private func readLetter() {
        isReading = true
        Task {
            await firebase.readLetter(letter)
            await MainActor.run {
                readComplete = true
                isReading = false
                interstitial.letterRead()
            }
        }
    }

    private func distanceText(_ meters: Double) -> String {
        if meters < 1000 {
            return "\(Int(meters))m"
        }
        return String(format: "%.1fkm", meters / 1000)
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy.MM.dd"
        return f.string(from: date)
    }
}
