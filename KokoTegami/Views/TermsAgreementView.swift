import SwiftUI

struct TermsAgreementView: View {
    let onAgree: () -> Void

    @State private var accepted = false

    var body: some View {
        ZStack {
            AppTheme.nightGradient.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("安全に使うための約束", systemImage: "shield.lefthalf.filled")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(AppTheme.envelope)

                        Text("利用規約")
                            .font(.system(size: 34, weight: .heavy, design: .serif))
                            .foregroundColor(AppTheme.cream)

                        Text("ここに手紙を置いてきた。は、誰かが街に残した手紙を読むアプリです。登録またはログインの前に、次の内容へ同意してください。")
                            .font(.system(size: 15, design: .serif))
                            .foregroundColor(AppTheme.fadedBlue)
                            .lineSpacing(4)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        TermsRow(icon: "xmark.shield", title: "不適切な内容を禁止", bodyText: "差別、脅迫、性的な内容、いやがらせ、個人情報、法律に反する内容は投稿できません。違反する投稿やユーザーは許可しません。")
                        TermsRow(icon: "text.magnifyingglass", title: "投稿前に内容を確認", bodyText: "不適切な言葉を含む手紙は投稿前に止めます。")
                        TermsRow(icon: "flag", title: "通報できます", bodyText: "問題のある手紙を見つけたら、手紙の画面から通報できます。通報後、その手紙はあなたの表示から消えます。")
                        TermsRow(icon: "person.crop.circle.badge.xmark", title: "ブロックできます", bodyText: "迷惑なユーザーをブロックできます。ブロックすると、そのユーザーの手紙はすぐ表示されなくなり、開発者へ通知されます。")
                        TermsRow(icon: "clock.badge.checkmark", title: "24時間以内に対応", bodyText: "開発者は通報を24時間以内に確認し、問題のある内容を削除し、投稿したユーザーを利用停止にします。")
                    }
                    .padding(16)
                    .background(.black.opacity(0.26))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    Toggle(isOn: $accepted) {
                        Text("上記の利用規約に同意します")
                            .font(.system(size: 15, weight: .semibold, design: .serif))
                            .foregroundColor(AppTheme.cream)
                    }
                    .toggleStyle(.switch)

                    Button {
                        onAgree()
                    } label: {
                        Text("同意してはじめる")
                            .font(.system(size: 17, weight: .bold, design: .serif))
                            .foregroundColor(accepted ? AppTheme.night : AppTheme.cream.opacity(0.55))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(accepted ? AppTheme.envelope : AppTheme.warmGray.opacity(0.35))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .disabled(!accepted)
                }
                .padding(20)
                .padding(.top, 44)
            }
        }
    }
}

private struct TermsRow: View {
    let icon: String
    let title: String
    let bodyText: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppTheme.envelope)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .serif))
                    .foregroundColor(AppTheme.cream)

                Text(bodyText)
                    .font(.system(size: 13, design: .serif))
                    .foregroundColor(AppTheme.fadedBlue)
                    .lineSpacing(3)
            }
        }
    }
}
