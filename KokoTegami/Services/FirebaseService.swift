import Foundation
import FirebaseFirestore
import FirebaseAuth

final class FirebaseService: ObservableObject {
    private let db = Firestore.firestore()
    @Published var letters: [Letter] = []
    @Published var bonusCredits: Int = 0
    @Published var lastFreeDate: String = ""
    @Published var blockedUserIds: Set<String> = []
    @Published var hiddenLetterIds: Set<String> = []

    private var userId: String?
    private var listener: ListenerRegistration?
    private var allLetters: [Letter] = []

    var canWriteToday: Bool {
        let today = dateString(Date())
        return lastFreeDate != today
    }

    var canWrite: Bool {
        canWriteToday || bonusCredits > 0
    }

    func signIn() async {
        do {
            let result = try await Auth.auth().signInAnonymously()
            userId = result.user.uid
            await loadUserData()
            await loadSafetyData()
            listenLetters()
        } catch {
            print("Auth error: \(error)")
        }
    }

    private func loadUserData() async {
        guard let uid = userId else { return }
        do {
            let doc = try await db.collection("users").document(uid).getDocument()
            if let data = doc.data() {
                await MainActor.run {
                    self.bonusCredits = data["bonusCredits"] as? Int ?? 0
                    self.lastFreeDate = data["lastFreeDate"] as? String ?? ""
                }
            }
        } catch {
            print("Load user error: \(error)")
        }
    }

    private func loadSafetyData() async {
        guard let uid = userId else { return }
        do {
            let blocked = try await db.collection("users").document(uid).collection("blockedUsers").getDocuments()
            let hidden = try await db.collection("users").document(uid).collection("hiddenLetters").getDocuments()
            await MainActor.run {
                self.blockedUserIds = Set(blocked.documents.map(\.documentID))
                self.hiddenLetterIds = Set(hidden.documents.map(\.documentID))
                self.applySafetyFilters()
            }
        } catch {
            print("Load safety data error: \(error)")
        }
    }

    private func listenLetters() {
        listener?.remove()
        listener = db.collection("letters").addSnapshotListener { [weak self] snapshot, error in
            guard let docs = snapshot?.documents else { return }
            let letters = docs.compactMap { try? $0.data(as: Letter.self) }
            DispatchQueue.main.async {
                self?.allLetters = letters
                self?.applySafetyFilters()
            }
        }
    }

    private func applySafetyFilters() {
        letters = allLetters.filter { letter in
            guard let id = letter.id else { return false }
            if hiddenLetterIds.contains(id) { return false }
            if let authorId = letter.authorId, blockedUserIds.contains(authorId) { return false }
            return true
        }
    }

    func readLetter(_ letter: Letter) async {
        guard let id = letter.id, let uid = userId else { return }
        do {
            try await db.collection("letters").document(id).delete()
            let newBonus = bonusCredits + 1
            try await db.collection("users").document(uid).setData([
                "bonusCredits": newBonus
            ], merge: true)
            await MainActor.run {
                self.bonusCredits = newBonus
            }
        } catch {
            print("Read letter error: \(error)")
        }
    }

    func writeLetter(text: String, latitude: Double, longitude: Double) async -> Bool {
        guard let uid = userId, canWrite else { return false }
        guard ContentModeration.objectionableTerm(in: text) == nil else { return false }

        let letter = [
            "text": text,
            "latitude": latitude,
            "longitude": longitude,
            "createdAt": Timestamp(date: Date()),
            "authorId": uid
        ] as [String: Any]

        do {
            try await db.collection("letters").addDocument(data: letter)

            let today = dateString(Date())
            if canWriteToday {
                try await db.collection("users").document(uid).setData([
                    "lastFreeDate": today
                ], merge: true)
                await MainActor.run { self.lastFreeDate = today }
            } else {
                let newBonus = max(0, bonusCredits - 1)
                try await db.collection("users").document(uid).setData([
                    "bonusCredits": newBonus
                ], merge: true)
                await MainActor.run { self.bonusCredits = newBonus }
            }
            return true
        } catch {
            print("Write letter error: \(error)")
            return false
        }
    }

    func reportLetter(_ letter: Letter, reason: String) async {
        guard let uid = userId, let letterId = letter.id else { return }
        do {
            try await db.collection("moderationReports").addDocument(data: [
                "type": "report",
                "letterId": letterId,
                "reportedUserId": letter.authorId ?? "",
                "reporterUserId": uid,
                "letterText": letter.text,
                "reason": reason,
                "createdAt": Timestamp(date: Date()),
                "status": "new",
                "reviewSlaHours": 24
            ])
            try await hideLetter(letterId)
        } catch {
            print("Report letter error: \(error)")
        }
    }

    func blockAuthor(of letter: Letter) async {
        guard let uid = userId, let letterId = letter.id else { return }
        let authorId = letter.authorId ?? "unknown-author-\(letterId)"

        do {
            try await db.collection("moderationReports").addDocument(data: [
                "type": "block",
                "letterId": letterId,
                "reportedUserId": authorId,
                "reporterUserId": uid,
                "letterText": letter.text,
                "reason": "Blocked abusive user",
                "createdAt": Timestamp(date: Date()),
                "status": "new",
                "reviewSlaHours": 24
            ])

            if let realAuthorId = letter.authorId, realAuthorId != uid {
                try await db.collection("users").document(uid).collection("blockedUsers").document(realAuthorId).setData([
                    "createdAt": Timestamp(date: Date()),
                    "sourceLetterId": letterId
                ])
            }
            try await hideLetter(letterId)

            await MainActor.run {
                if let realAuthorId = letter.authorId {
                    self.blockedUserIds.insert(realAuthorId)
                }
                self.hiddenLetterIds.insert(letterId)
                self.applySafetyFilters()
            }
        } catch {
            print("Block author error: \(error)")
        }
    }

    private func hideLetter(_ letterId: String) async throws {
        guard let uid = userId else { return }
        try await db.collection("users").document(uid).collection("hiddenLetters").document(letterId).setData([
            "createdAt": Timestamp(date: Date())
        ])
        await MainActor.run {
            self.hiddenLetterIds.insert(letterId)
            self.applySafetyFilters()
        }
    }

    private func dateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = .current
        return f.string(from: date)
    }
}
