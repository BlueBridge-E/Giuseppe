import AVFoundation
#if os(iOS)
import UIKit
#endif

@Observable
final class SoundManager {
    private var expensePlayer: AVAudioPlayer?
    private var incomePlayer: AVAudioPlayer?
    var isSoundEnabled: Bool {
        didSet { UserDefaults.standard.set(isSoundEnabled, forKey: "soundEnabled") }
    }

    #if os(iOS)
    /// 触觉反馈生成器，静音时仍给反馈
    private let expenseHaptic = UIImpactFeedbackGenerator(style: .medium)
    private let incomeHaptic = UIImpactFeedbackGenerator(style: .light)
    #endif

    init() {
        let enabled = UserDefaults.standard.object(forKey: "soundEnabled")
        isSoundEnabled = (enabled as? Bool) ?? true
        configureAudioSession()
        loadSounds()
        #if os(iOS)
        expenseHaptic.prepare()
        incomeHaptic.prepare()
        #endif
    }

    /// 配置 AVAudioSession，确保真机音效播放
    private func configureAudioSession() {
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: .mixWithOthers)
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
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

    /// 播放支出反馈（始终触觉，音效仅在开启时播放）
    func playExpenseSound() {
        #if os(iOS)
        expenseHaptic.impactOccurred()
        #endif
        guard isSoundEnabled else { return }
        expensePlayer?.currentTime = 0
        expensePlayer?.play()
    }

    /// 播放收入反馈（始终触觉，音效仅在开启时播放）
    func playIncomeSound() {
        #if os(iOS)
        incomeHaptic.impactOccurred()
        #endif
        guard isSoundEnabled else { return }
        incomePlayer?.currentTime = 0
        incomePlayer?.play()
    }
}
