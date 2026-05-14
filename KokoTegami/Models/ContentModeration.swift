import Foundation

enum ContentModeration {
    static let blockedTerms: [String] = [
        "死ね",
        "殺す",
        "自殺しろ",
        "消えろ",
        "バカ",
        "fuck",
        "shit",
        "kill yourself",
        "kys"
    ]

    static func objectionableTerm(in text: String) -> String? {
        let normalized = text
            .folding(options: [.caseInsensitive, .widthInsensitive, .diacriticInsensitive], locale: .current)
            .lowercased()

        return blockedTerms.first { term in
            normalized.contains(term.lowercased())
        }
    }
}
