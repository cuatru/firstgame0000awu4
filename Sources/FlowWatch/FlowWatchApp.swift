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

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        haloBest = defaults.integer(forKey: "best.halo")
        currentBest = defaults.integer(forKey: "best.current")
    }

    func record(_ game: GameID, score: Int) {
        switch game {
        case .halo where score > haloBest:
            haloBest = score
            defaults.set(score, forKey: "best.halo")
        case .current where score > currentBest:
            currentBest = score
            defaults.set(score, forKey: "best.current")
        default:
            break
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

                    NavigationLink {
                        HaloView()
                    } label: {
                        GameCard(
                            title: "HALO",
                            subtitle: "Tap the moving light",
                            icon: "circle.dotted.circle",
                            best: scores.haloBest
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
                            best: scores.currentBest
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
                    Text("Best  \(best)")
                        .font(.caption2)
                        .foregroundStyle(.cyan)
                }

                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct HaloView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var scores: ScoreStore
    @State private var scene = HaloScene()
    @State private var result: RunSummary?

    var body: some View {
        ZStack {
            LiquidBackground()

            SpriteView(
                scene: scene,
                preferredFramesPerSecond: 60,
                options: [.allowsTransparency]
            )
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .onTapGesture {
                scene.tap()
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
                        scene.restart()
                    },
                    exit: { dismiss() }
                )
            }
        }
        .onAppear {
            scene.isPaused = false
            scene.onFinish = { summary in
                scores.record(.halo, score: summary.score)
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    result = summary
                }
            }
        }
        .onDisappear {
            scene.isPaused = true
        }
    }
}

struct CurrentView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var scores: ScoreStore
    @State private var scene = CurrentScene()
    @State private var result: RunSummary?

    var body: some View {
        ZStack {
            LiquidBackground()

            SpriteView(
                scene: scene,
                preferredFramesPerSecond: 60,
                options: [.allowsTransparency]
            )
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in scene.holdingChanged(true) }
                    .onEnded { _ in scene.holdingChanged(false) }
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
                        scene.restart()
                    },
                    exit: { dismiss() }
                )
            }
        }
        .onAppear {
            scene.isPaused = false
            scene.onFinish = { summary in
                scores.record(.current, score: summary.score)
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    result = summary
                }
            }
        }
        .onDisappear {
            scene.holdingChanged(false)
            scene.isPaused = true
        }
    }
}
