import AVFoundation

@Observable
final class SoundManager {
    private var expensePlayer: AVAudioPlayer?
    private var incomePlayer: AVAudioPlayer?
    var isSoundEnabled: Bool {
        didSet { UserDefaults.standard.set(isSoundEnabled, forKey: "soundEnabled") }
    }

    init() {
        isSoundEnabled = UserDefaults.standard.object(forKey: "soundEnabled") as? Bool ?? true
        loadSounds()
    }

    private func loadSounds() {
        if let expenseURL = Bundle.main.url(forResource: "expense_ding", withExtension: "m4a") {
            expensePlayer = try? AVAudioPlayer(contentsOf: expenseURL)
            expensePlayer?.prepareToPlay()
        }
        if let incomeURL = Bundle.main.url(forResource: "income_ding", withExtension: "m4a") {
            incomePlayer = try? AVAudioPlayer(contentsOf: incomeURL)
            incomePlayer?.prepareToPlay()
        }
    }

    func playExpenseSound() {
        guard isSoundEnabled else { return }
        expensePlayer?.currentTime = 0
        expensePlayer?.play()
    }

    func playIncomeSound() {
        guard isSoundEnabled else { return }
        incomePlayer?.currentTime = 0
        incomePlayer?.play()
    }
}
