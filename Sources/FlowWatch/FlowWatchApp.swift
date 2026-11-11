import SwiftUI
import SpriteKit
import Combine

@main
struct FlowWatchApp: App {
    @StateObject private var scores = ScoreStore()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                MenuView()
            }
            .environmentObject(scores)
            .tint(.cyan)
        }
    }
}

enum GameID: String {
    case halo
    case current
}

@MainActor
final class ScoreStore: ObservableObject {
    @Published private(set) var haloBest: Int
    @Published private(set) var currentBest: Int
    @Published private(set) var haloBestCombo: Int
    @Published private(set) var currentBestSurvival: Double
    @Published private(set) var runsToday: Int

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        haloBest = defaults.integer(forKey: "best.halo")
        currentBest = defaults.integer(forKey: "best.current")
        haloBestCombo = defaults.integer(forKey: "best.combo.halo")
        currentBestSurvival = defaults.double(forKey: "best.survival.current")

        let today = Self.dayStamp()
        if defaults.string(forKey: "runs.date") == today {
            runsToday = defaults.integer(forKey: "runs.count")
        } else {
            runsToday = 0
            defaults.set(today, forKey: "runs.date")
            defaults.set(0, forKey: "runs.count")
        }
    }

    private static func dayStamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    var haloMedals: [Bool] {
        GameRules.haloMedalCombos.map { haloBestCombo >= $0 }
    }

    var currentMedals: [Bool] {
        GameRules.currentMedalSurvival.map { currentBestSurvival >= $0 }
    }

    var dailyMissionDone: Bool {
        runsToday >= GameRules.dailyMissionRuns
    }

    func record(_ game: GameID, summary: RunSummary) {
        runsToday += 1
        defaults.set(runsToday, forKey: "runs.count")

        switch game {
        case .halo:
            if summary.score > haloBest {
                haloBest = summary.score
                defaults.set(summary.score, forKey: "best.halo")
            }
            if summary.bestCombo > haloBestCombo {
                haloBestCombo = summary.bestCombo
                defaults.set(summary.bestCombo, forKey: "best.combo.halo")
            }
        case .current:
            if summary.score > currentBest {
                currentBest = summary.score
                defaults.set(summary.score, forKey: "best.current")
            }
            if summary.elapsed > currentBestSurvival {
                currentBestSurvival = summary.elapsed
                defaults.set(summary.elapsed, forKey: "best.survival.current")
            }
        }
    }
}

struct MenuView: View {
    @EnvironmentObject private var scores: ScoreStore

    var body: some View {
        ZStack {
            LiquidBackground()

            ScrollView {
                VStack(spacing: 12) {
                    VStack(spacing: 2) {
                        Text("FLOW")
                            .font(.system(.title, design: .rounded).weight(.bold))
                        Text("Two focused micro-games")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    // Misión diaria: 3 runs (metas intermedias, feedback Agente C)
                    HStack(spacing: 6) {
                        Image(systemName: scores.dailyMissionDone
                              ? "checkmark.circle.fill" : "target")
                            .foregroundStyle(scores.dailyMissionDone ? .green : .cyan)
                        Text("Daily: \(min(scores.runsToday, GameRules.dailyMissionRuns))/\(GameRules.dailyMissionRuns) runs")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    NavigationLink {
                        HaloView()
                    } label: {
                        GameCard(
                            title: "HALO",
                            subtitle: "Tap at the top",
                            icon: "circle.dotted.circle",
                            best: scores.haloBest,
                            medals: scores.haloMedals
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        CurrentView()
                    } label: {
                        GameCard(
                            title: "CURRENT",
                            subtitle: "Hold, release, flow",
                            icon: "drop.circle",
                            best: scores.currentBest,
                            medals: scores.currentMedals
                        )
                    }
                    .buttonStyle(.plain)

                    Label(
                        "No ads, streak pressure, or tracking.",
                        systemImage: "checkmark.shield"
                    )
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                }
                .padding(.horizontal, 8)
            }
        }
    }
}

struct GameCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let best: Int
    let medals: [Bool]

    var body: some View {
        GlassCard {
            HStack(spacing: 9) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.cyan)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(.headline, design: .rounded))
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 4) {
                        Text("Best  \(best)")
                            .font(.caption2)
                            .foregroundStyle(.cyan)
                        ForEach(0..<medals.count, id: \.self) { index in
                            Circle()
                                .fill(medals[index] ? Color.cyan : Color.gray.opacity(0.3))
                                .frame(width: 6, height: 6)
                        }
                    }
                }

                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// Modelos contenedores: la SKScene no se construye en el init del View (auditoría runtime)
@MainActor
final class HaloModel: ObservableObject {
    let scene = HaloScene()
}

@MainActor
final class CurrentModel: ObservableObject {
    let scene = CurrentScene()
}

struct HaloView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var scores: ScoreStore
    @StateObject private var model = HaloModel()
    @State private var result: RunSummary?

    var body: some View {
        ZStack {
            LiquidBackground()

            SpriteView(scene: model.scene)
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .onTapGesture {
                model.scene.tap()
            }
            .accessibilityLabel("Halo timing game")

            if let result {
                ResultOverlay(
                    summary: result,
                    best: scores.haloBest,
                    replay: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            self.result = nil
                        }
                        model.scene.restart()
                        model.scene.isPaused = false
                    },
                    exit: { dismiss() }
                )
            }
        }
        .onAppear {
            model.scene.isPaused = false
            model.scene.onFinish = { summary in
                scores.record(.halo, summary: summary)
                model.scene.isPaused = true   // pausar bajo el overlay (auditoría runtime)
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    result = summary
                }
            }
        }
        .onDisappear {
            model.scene.isPaused = true
        }
        .onChange(of: scenePhase) { _, phase in
            // always-on / muñeca bajada: pausar siempre (auditoría perf B1)
            if phase != .active {
                model.scene.isPaused = true
            } else if result == nil {
                model.scene.isPaused = false
            }
        }
    }
}

struct CurrentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var scores: ScoreStore
    @StateObject private var model = CurrentModel()
    @State private var result: RunSummary?

    var body: some View {
        ZStack {
            LiquidBackground()

            SpriteView(scene: model.scene)
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in model.scene.holdingChanged(true) }
                    .onEnded { _ in model.scene.holdingChanged(false) }
            )
            .accessibilityLabel("Current hold and release game")

            if let result {
                ResultOverlay(
                    summary: result,
                    best: scores.currentBest,
                    replay: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            self.result = nil
                        }
                        model.scene.restart()
                        model.scene.isPaused = false
                    },
                    exit: { dismiss() }
                )
            }
        }
        .onAppear {
            model.scene.isPaused = false
            model.scene.onFinish = { summary in
                scores.record(.current, summary: summary)
                model.scene.isPaused = true
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    result = summary
                }
            }
        }
        .onDisappear {
            model.scene.holdingChanged(false)
            model.scene.isPaused = true
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                model.scene.holdingChanged(false)   // dedo fantasma en background (auditoría runtime)
                model.scene.isPaused = true
            } else if result == nil {
                model.scene.isPaused = false
            }
        }
    }
}
