import SwiftUI
import Observation

// MARK: - Appearance

struct Appearance: Codable {
    var accentHex: String
    var theme: ThemeKind

    static let defaultValue = Appearance(accentHex: "#B6A6E9", theme: .cosmic)
}

enum ThemeKind: String, Codable, CaseIterable {
    case cosmic = "Vũ trụ"
    case dawn   = "Bình minh"
}

// MARK: - Store

@Observable
final class AppStore {
    var profile: Profile
    var letters: [Letter]
    var appearance: Appearance

    private let storeKey  = "mai.state.v1"
    private let appearKey = "mai.appearance.v1"

    init() {
        struct SavedState: Codable { var profile: Profile; var letters: [Letter] }
        let dec = JSONDecoder()
        if let data = UserDefaults.standard.data(forKey: "mai.state.v1"),
           let s = try? dec.decode(SavedState.self, from: data) {
            profile = s.profile
            letters = s.letters
        } else {
            profile = .seed
            letters  = makeSeedLetters()
        }
        if let data = UserDefaults.standard.data(forKey: "mai.appearance.v1"),
           let a = try? dec.decode(Appearance.self, from: data) {
            appearance = a
        } else {
            appearance = .defaultValue
        }
    }

    func save() {
        struct SavedState: Codable { var profile: Profile; var letters: [Letter] }
        let enc = JSONEncoder()
        if let data = try? enc.encode(SavedState(profile: profile, letters: letters)) {
            UserDefaults.standard.set(data, forKey: storeKey)
        }
        if let data = try? enc.encode(appearance) {
            UserDefaults.standard.set(data, forKey: appearKey)
        }
    }

    func markOpened(_ id: String) {
        guard let i = letters.firstIndex(where: { $0.id == id }) else { return }
        letters[i].opened = true
        letters[i].openedAtISO = toISO(Date())
        save()
    }

    func createLetter(_ letter: Letter) {
        letters.insert(letter, at: 0)
        save()
    }

    func resetAll() {
        UserDefaults.standard.removeObject(forKey: storeKey)
        UserDefaults.standard.removeObject(forKey: appearKey)
        profile    = .seed
        letters    = makeSeedLetters()
        appearance = .defaultValue
    }
}
