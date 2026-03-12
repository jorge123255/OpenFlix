import SwiftUI

struct RadarScanView: View {
    let statusText: String
    var isScanning: Bool = true

    @State private var scanPulse = false

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(OpenFlixColors.primary.opacity(0.3), lineWidth: 2)
                        .frame(width: 60 + CGFloat(i * 30), height: 60 + CGFloat(i * 30))
                        .scaleEffect(isScanning && scanPulse ? 1.2 : 1.0)
                        .opacity(isScanning && scanPulse ? 0 : 0.5)
                        .animation(
                            .easeOut(duration: 1.5)
                                .repeatForever(autoreverses: false)
                                .delay(Double(i) * 0.3),
                            value: scanPulse
                        )
                }

                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 28))
                    .foregroundColor(OpenFlixColors.primary)
            }
            .frame(height: 120)
            .onAppear {
                if isScanning {
                    scanPulse = true
                }
            }
            .onChange(of: isScanning) { _, newValue in
                scanPulse = newValue
            }

            Text(statusText)
                .font(.subheadline)
                .foregroundColor(OpenFlixColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    RadarScanView(statusText: "Searching your network...", isScanning: true)
        .padding()
        .background(OpenFlixColors.background)
}
