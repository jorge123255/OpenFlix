import SwiftUI

/// Overlay showing commercial skip countdown
struct CommercialSkipOverlay: View {
    @ObservedObject var manager: CommercialSkipManager

    var body: some View {
        VStack {
            Spacer()

            HStack {
                Spacer()

                skipIndicator
                    .padding(24)
            }
        }
    }

    @ViewBuilder
    private var skipIndicator: some View {
        switch manager.state {
        case .idle:
            EmptyView()

        case .inCommercial:
            // Manual skip mode (auto-skip disabled)
            HStack(spacing: 12) {
                Image(systemName: "forward.fill")
                    .foregroundColor(.white)
                Text("Press to Skip")
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.9))
            )

        case .countingDown(let seconds, _):
            HStack(spacing: 12) {
                // Animated circle countdown
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 3)
                        .frame(width: 40, height: 40)

                    Circle()
                        .trim(from: 0, to: CGFloat(seconds) / CGFloat(manager.skipDelay))
                        .stroke(Color.yellow, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 40, height: 40)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: seconds)

                    Text("\(seconds)")
                        .foregroundColor(.white)
                        .font(.system(size: 18, weight: .bold))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Skipping Commercial...")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .semibold))
                    Text("Press to cancel")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(size: 12))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.blue.opacity(0.95),
                                Color.purple.opacity(0.95)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)

        case .skipping:
            HStack(spacing: 12) {
                Image(systemName: "forward.fill")
                    .foregroundColor(.white)
                Text("Skipping...")
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.green.opacity(0.9))
            )
        }
    }
}

// MARK: - Preview

struct CommercialSkipOverlay_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black

            CommercialSkipOverlay(manager: {
                let manager = CommercialSkipManager()
                // Preview state
                return manager
            }())
        }
    }
}
