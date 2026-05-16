
import SwiftUI
import WiFiMapperCore
struct SplashView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var animate = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: colorScheme == .dark
                    ? [Color(red: 0.06, green: 0.09, blue: 0.12), Color(red: 0.08, green: 0.11, blue: 0.14), Color(red: 0.07, green: 0.10, blue: 0.12)]
                    : [Color(red: 0.82, green: 0.92, blue: 1.0), Color.white, Color(red: 0.84, green: 0.96, blue: 0.93)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill((colorScheme == .dark ? Color.white.opacity(0.14) : Color.white.opacity(0.55)))
                        .frame(width: 132, height: 132)
                        .blur(radius: 1)
                    Image(systemName: "dot.radiowaves.left.and.right")
                        .font(.system(size: 50, weight: .semibold))
                        .foregroundStyle(.blue.gradient)
                        .rotationEffect(.degrees(animate ? 6 : -6))
                }
                .scaleEffect(animate ? 1 : 0.86)
                .animation(.bouncy(duration: 1.1, extraBounce: 0.18).repeatForever(autoreverses: true), value: animate)

                Text("splash.title")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(colorScheme == .dark ? Color.white : Color(red: 0.09, green: 0.15, blue: 0.18))
                Text("splash.subtitle")
                    .font(.headline)
                    .foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.76) : Color(red: 0.24, green: 0.31, blue: 0.34))
            }
        }
        .onAppear {
            animate = true
        }
    }
}
