import SwiftUI
import UIKit

struct LetterComposeView: View {
    let firebase: FirebaseService
    let locationManager: LocationManager
    let onDismiss: () -> Void

    @State private var text = ""
    @State private var isSending = false
    @State private var sent = false
    @FocusState private var isTextEditorFocused: Bool
    private let maxLength = 300

    var body: some View {
        ZStack {
            AppTheme.nightGradient.ignoresSafeArea()
                .onTapGesture {
                    dismissKeyboard()
                }

            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Image(systemName: "envelope.badge")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(AppTheme.envelope)

                    Text("手紙を書く")
                        .font(.system(size: 28, weight: .heavy, design: .serif))
                        .foregroundColor(AppTheme.cream)
                }
                    .padding(.top, 30)

                Text("今いる場所に手紙を置きます")
                    .font(.system(size: 14, design: .serif))
                    .foregroundColor(AppTheme.fadedBlue)

                if sent {
                    sentView
                } else {
                    composeView
                }

                Spacer()
            }
            .padding()
        }
    }

    private var composeView: some View {
        ScrollView {
            VStack(spacing: 16) {
            // Letter paper
            VStack(spacing: 0) {
                TextEditor(text: $text)
                    .font(.system(size: 16, design: .serif))
                    .foregroundColor(AppTheme.ink)
                    .scrollContentBackground(.hidden)
                    .padding(4)
                    .frame(minHeight: 200)
                    .focused($isTextEditorFocused)
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("完了") {
                                dismissKeyboard()
                            }
                            .foregroundColor(AppTheme.envelope)
                        }
                    }
                    .onChange(of: text) { _, newValue in
                        if newValue.count > maxLength {
                            text = String(newValue.prefix(maxLength))
                        }
                    }

                HStack {
                    Spacer()
                    Text("\(text.count)/\(maxLength)")
                        .font(.system(size: 12, design: .serif))
                        .foregroundColor(AppTheme.fadedBlue)
                }
                .padding(.horizontal, 4)
            }
            .padding(16)
            .background(AppTheme.parchment)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(AppTheme.envelope.opacity(0.75), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: .black.opacity(0.3), radius: 18, y: 10)

            if isTextEditorFocused {
                Button {
                    dismissKeyboard()
                } label: {
                    Label("キーボードを閉じる", systemImage: "keyboard.chevron.compact.down")
                        .font(.system(size: 15, weight: .semibold, design: .serif))
                        .foregroundColor(AppTheme.cream)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppTheme.warmGray.opacity(0.22))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            HStack(spacing: 16) {
                Button("やめる") {
                    dismissKeyboard()
                    onDismiss()
                }
                    .font(.system(size: 15, design: .serif))
                    .foregroundColor(AppTheme.fadedBlue)

                Button {
                    dismissKeyboard()
                    sendLetter()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "paperplane")
                        Text("置いてくる")
                    }
                    .font(.system(size: 15, weight: .medium, design: .serif))
                    .foregroundColor(AppTheme.night)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(canSend ? AppTheme.envelope : AppTheme.warmGray.opacity(0.35))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .disabled(!canSend)
            }
            }
            .padding(.bottom, 20)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var sentView: some View {
        VStack(spacing: 16) {
            Image(systemName: "envelope.badge.shield.half.filled")
                .font(.system(size: 48))
                .foregroundColor(AppTheme.envelope)

            Text("手紙を置いてきた")
                .font(.system(size: 20, weight: .medium, design: .serif))
                .foregroundColor(AppTheme.cream)

            Text("誰かがこの場所で見つけてくれるのを待ちます")
                .font(.system(size: 14, design: .serif))
                .foregroundColor(AppTheme.fadedBlue)
                .multilineTextAlignment(.center)

            Button("閉じる") { onDismiss() }
                .font(.system(size: 15, design: .serif))
                .foregroundColor(AppTheme.fadedBlue)
                .padding(.top, 8)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !isSending
            && firebase.canWrite
            && locationManager.location != nil
    }

    private func sendLetter() {
        guard let loc = locationManager.location else { return }
        isSending = true
        Task {
            let success = await firebase.writeLetter(
                text: text.trimmingCharacters(in: .whitespacesAndNewlines),
                latitude: loc.coordinate.latitude,
                longitude: loc.coordinate.longitude
            )
            await MainActor.run {
                isSending = false
                if success { sent = true }
            }
        }
    }

    private func dismissKeyboard() {
        isTextEditorFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
