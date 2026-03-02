import SwiftUI

// MARK: - tvOS Compatibility Extensions
// Provides no-op versions of tvOS-only modifiers for iOS builds

#if os(iOS)

extension View {
    /// No-op focusSection for iOS (tvOS-only API)
    @ViewBuilder
    func focusSection() -> some View {
        self
    }
    
    /// No-op onExitCommand for iOS (tvOS-only API)
    @ViewBuilder
    func onExitCommand(perform action: (() -> Void)?) -> some View {
        self
    }
    
    /// No-op onPlayPauseCommand for iOS (tvOS-only API)
    @ViewBuilder
    func onPlayPauseCommand(perform action: @escaping () -> Void) -> some View {
        self
    }
    
    /// No-op onFocusChange for iOS (tvOS-only API)
    @ViewBuilder
    func onFocusChange(_ action: @escaping (Bool) -> Void) -> some View {
        self
    }
    
    /// No-op onMoveCommand for iOS (tvOS-only API)
    @ViewBuilder
    func onMoveCommand(perform action: ((MoveCommandDirection) -> Void)?) -> some View {
        self
    }
    
    /// No-op prefersDefaultFocus for iOS (tvOS-only API)
    @ViewBuilder
    func prefersDefaultFocus(_ prefersDefaultFocus: Bool = true, in namespace: Namespace.ID) -> some View {
        self
    }
}

// Stub for MoveCommandDirection on iOS
enum MoveCommandDirection {
    case up, down, left, right
}

/// tvOS card button style - provides focus-like scaling for iOS
struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == CardButtonStyle {
    static var card: CardButtonStyle { CardButtonStyle() }
}

#endif
