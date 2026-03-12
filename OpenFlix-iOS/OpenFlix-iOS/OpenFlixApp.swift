import SwiftUI
import UIKit

// MARK: - App Delegate (orientation lock)
class AppDelegate: NSObject, UIApplicationDelegate {
    static var orientationLock: UIInterfaceOrientationMask = .portrait

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
}

@main
struct OpenFlixApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var settingsViewModel = SettingsViewModel()
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environmentObject(authViewModel)
                    .environmentObject(settingsViewModel)
                    .preferredColorScheme(.dark)

                if showSplash {
                    LogoSplashView {
                        withAnimation(.easeOut(duration: 0.6)) {
                            showSplash = false
                        }
                    }
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
        }
    }
}

// MARK: - Logo Splash Screen

struct LogoSplashView: View {
    let onFinished: () -> Void

    @State private var logoScale: CGFloat = 0.75
    @State private var logoOpacity: Double = 0
    @State private var taglineOpacity: Double = 0
    @State private var glowRadius: CGFloat = 0

    private let accent = Color(red: 97/255, green: 56/255, blue: 245/255)
    private let bg = Color(red: 10/255, green: 6/255, blue: 24/255)

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            RadialGradient(
                colors: [accent.opacity(0.25), .clear],
                center: .center,
                startRadius: 0,
                endRadius: glowRadius
            )
            .ignoresSafeArea()
            .animation(.easeOut(duration: 1.2), value: glowRadius)

            VStack(spacing: 14) {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(accent)
                            .frame(width: 52, height: 52)
                        Image(systemName: "play.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .offset(x: 2)
                    }

                    Text("OpenFlix")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                Text("Your media. Anywhere.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.45))
                    .tracking(1.5)
                    .opacity(taglineOpacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.72)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 1.2)) {
                glowRadius = 260
            }
            withAnimation(.easeIn(duration: 0.5).delay(0.4)) {
                taglineOpacity = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                onFinished()
            }
        }
    }
}
