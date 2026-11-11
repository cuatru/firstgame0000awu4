import SwiftUI

struct LiquidBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animate = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.025, green: 0.035, blue: 0.09),
                    Color(red: 0.02, green: 0.12, blue: 0.17),
                    Color(red: 0.12, green: 0.035, blue: 0.18)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color.cyan.opacity(0.22))
                .frame(width: 150, height: 150)
                .blur(radius: 30)
                .offset(
                    x: animate ? 48 : -42,
                    y: animate ? -60 : 35
                )

            Circle()
                .fill(Color.purple.opacity(0.20))
                .frame(width: 130, height: 130)
                .blur(radius: 28)
                .offset(
                    x: animate ? -50 : 45,
                    y: animate ? 60 : -35
                )
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(
                .easeInOut(duration: 8)
                .repeatForever(autoreverses: true)
            ) {
                animate = true
            }
        }
    }
}

struct GlassCard<Content: View>: View {
    private let radius: CGFloat
    private let content: Content

    init(radius: CGFloat = 18, @ViewBuilder content: () -> Content) {
        self.radius = radius
        self.content = content()
    }

    var body: some View {
        content
            .padding(12)
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: radius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.55),
                                .white.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
            }
            .shadow(color: .black.opacity(0.25), radius: 12, y: 5)
    }
}

struct ResultOverlay: View {
    let summary: RunSummary
    let best: Int
    let replay: () -> Void
    let exit: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.38).ignoresSafeArea()

            GlassCard {
                VStack(spacing: 7) {
                    Text(summary.cleared ? "FLOW COMPLETE" : "RUN OVER")
                        .font(.system(.headline, design: .rounded))
                        .multilineTextAlignment(.center)

                    Text("\(summary.score)")
                        .font(.system(size: 30, weight: .bold, design: .rounded))

                    Text(summary.detail)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Personal best  \(best)")
                        .font(.caption2)
                        .foregroundStyle(.cyan)

                    Button("Replay", action: replay)
                        .buttonStyle(.borderedProminent)
                        .tint(.cyan)

                    Button("Games", action: exit)
                        .buttonStyle(.borderless)
                }
            }
            .padding(12)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.94)))
    }
}
