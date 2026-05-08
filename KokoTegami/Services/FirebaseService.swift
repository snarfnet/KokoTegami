import Foundation
import FirebaseFirestore
import FirebaseAuth

final class FirebaseService: ObservableObject {
    private let db = Firestore.firestore()
    @Published var letters: [Letter] = []
    @Published var bonusCredits: Int = 0
    @Published var lastFreeDate: String = ""

    private var userId: String?
    private var listener: ListenerRegistration?

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

    private func listenLetters() {
        listener?.remove()
        listener = db.collection("letters").addSnapshotListener { [weak self] snapshot, error in
            guard let docs = snapshot?.documents else { return }
            let letters = docs.compactMap { try? $0.data(as: Letter.self) }
            DispatchQueue.main.async {
                self?.letters = letters
            }
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

        let letter = [
            "text": text,
            "latitude": latitude,
            "longitude": longitude,
            "createdAt": Timestamp(date: Date())
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

    private func dateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = .current
        return f.string(from: date)
    }
}
