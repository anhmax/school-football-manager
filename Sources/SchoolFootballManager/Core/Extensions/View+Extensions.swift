import SwiftUI

// MARK: - Card Style

extension View {
    func cardStyle(
        backgroundColor: Color = .backgroundSecondary,
        cornerRadius: CGFloat = 12,
        shadowRadius: CGFloat = 4
    ) -> some View {
        self
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .shadow(color: .black.opacity(0.1), radius: shadowRadius, x: 0, y: 2)
    }

    func compactCardStyle() -> some View {
        self.cardStyle(cornerRadius: 8, shadowRadius: 2)
    }

    func prominentCardStyle() -> some View {
        self.cardStyle(cornerRadius: 16, shadowRadius: 8)
    }
}

// MARK: - Loading State

extension View {
    func loading(_ isLoading: Bool) -> some View {
        self.overlay(
            Group {
                if isLoading {
                    LoadingOverlay()
                }
            }
        )
    }
}

// MARK: - Error Handling

extension View {
    func errorAlert(_ error: Binding<String?>) -> some View {
        self.alert("エラー", isPresented: .constant(error.wrappedValue != nil)) {
            Button("OK") {
                error.wrappedValue = nil
            }
        } message: {
            Text(error.wrappedValue ?? "")
        }
    }
}

// MARK: - Navigation

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    func navigationBarTitleColor(_ color: Color) -> some View {
        self.onAppear {
            let appearance = UINavigationBarAppearance()
            appearance.titleTextAttributes = [.foregroundColor: UIColor(color)]
            appearance.largeTitleTextAttributes = [.foregroundColor: UIColor(color)]
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().compactAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

// MARK: - Conditional Modifiers

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        if: (Self) -> TrueContent,
        else: (Self) -> FalseContent
    ) -> some View {
        if condition {
            `if`(self)
        } else {
            `else`(self)
        }
    }
}

// MARK: - Haptic Feedback

extension View {
    func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) -> some View {
        self.onTapGesture {
            let impact = UIImpactFeedbackGenerator(style: style)
            impact.impactOccurred()
        }
    }

    func successFeedback() -> some View {
        self.onTapGesture {
            let feedback = UINotificationFeedbackGenerator()
            feedback.notificationOccurred(.success)
        }
    }

    func errorFeedback() -> some View {
        self.onTapGesture {
            let feedback = UINotificationFeedbackGenerator()
            feedback.notificationOccurred(.error)
        }
    }

    func warningFeedback() -> some View {
        self.onTapGesture {
            let feedback = UINotificationFeedbackGenerator()
            feedback.notificationOccurred(.warning)
        }
    }
}

// MARK: - Custom Shapes

extension View {
    func roundedCorner(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    let radius: CGFloat
    let corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Badge Modifier

extension View {
    func badge(_ count: Int, color: Color = .red) -> some View {
        self.overlay(
            Group {
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(minWidth: 16, minHeight: 16)
                        .background(color)
                        .clipShape(Circle())
                        .offset(x: 8, y: -8)
                }
            },
            alignment: .topTrailing
        )
    }
}

// MARK: - Shimmer Effect

extension View {
    func shimmer(isActive: Bool = true) -> some View {
        self.modifier(ShimmerModifier(isActive: isActive))
    }
}

struct ShimmerModifier: ViewModifier {
    let isActive: Bool
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if isActive {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [.clear, .white.opacity(0.6), .clear],
                                    startPoint: .init(x: phase, y: 0),
                                    endPoint: .init(x: phase + 0.3, y: 0)
                                )
                            )
                            .onAppear {
                                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                                    phase = 1
                                }
                            }
                    }
                }
            )
            .clipped()
    }
}

// MARK: - Floating Action Button

extension View {
    func floatingActionButton<Content: View>(
        _ content: Content,
        position: FloatingActionButtonPosition = .bottomTrailing,
        action: @escaping () -> Void
    ) -> some View {
        self.overlay(
            Button(action: action) {
                content
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.accentColor)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(),
            alignment: position.alignment
        )
    }
}

enum FloatingActionButtonPosition {
    case bottomTrailing
    case bottomLeading
    case topTrailing
    case topLeading

    var alignment: Alignment {
        switch self {
        case .bottomTrailing: return .bottomTrailing
        case .bottomLeading: return .bottomLeading
        case .topTrailing: return .topTrailing
        case .topLeading: return .topLeading
        }
    }
}

// MARK: - Safe Area Extensions

extension View {
    func safeAreaPadding(_ edges: Edge.Set = .all, _ length: CGFloat = 16) -> some View {
        self.padding(edges, length)
    }
}

// MARK: - Keyboard Responsive

extension View {
    func keyboardAware() -> some View {
        self.modifier(KeyboardAwareModifier())
    }
}

struct KeyboardAwareModifier: ViewModifier {
    @State private var keyboardHeight: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .padding(.bottom, keyboardHeight)
            .animation(.easeInOut, value: keyboardHeight)
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    keyboardHeight = keyboardFrame.height
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                keyboardHeight = 0
            }
    }
}

// MARK: - Pull to Refresh

extension View {
    func pullToRefresh(action: @escaping () async -> Void) -> some View {
        self.refreshable {
            await action()
        }
    }
}

// MARK: - Empty State

extension View {
    func emptyState<EmptyContent: View>(
        isEmpty: Bool,
        @ViewBuilder emptyContent: () -> EmptyContent
    ) -> some View {
        Group {
            if isEmpty {
                emptyContent()
            } else {
                self
            }
        }
    }
}