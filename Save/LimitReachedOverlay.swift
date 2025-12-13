import SwiftUI

struct LimitReachedOverlay: View {
    let title: String
    let message: String
    let buttonTitle: String
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            // Card
            VStack(spacing: 14) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 56, height: 56)
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.green)
                }
                .padding(.top, 6)

                // Title
                Text(title)
                    .font(.headline)
                    .multilineTextAlignment(.center)

                // Message
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 6)

                // Button
                Button {
                    onDismiss()
                } label: {
                    Text(buttonTitle)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.green)
                        )
                        .foregroundColor(.white)
                }
                .padding(.top, 6)
            }
            .padding(18)
            .frame(minWidth: 260, maxWidth: 360)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.15), radius: 16, x: 0, y: 10)
            )
            .padding(.horizontal, 24)
            .transition(.scale(scale: 0.95).combined(with: .opacity))
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: true)
    }
}

#Preview {
    LimitReachedOverlay(
        title: "Limit reached",
        message: "You can only have up to 3 jars.",
        buttonTitle: "OK",
        onDismiss: {}
    )
}
