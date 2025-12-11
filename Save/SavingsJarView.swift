import SwiftUI

struct SavingsJarView: View {
    let name: String
    let fillAmount: Double   // (We will use this later when you animate money rising)

    // Parent supplies this to trigger delete flow
    var onDelete: (() -> Void)? = nil

    // Defensive clamp: ensure we never show more than 13 characters in the jar
    private var clampedName: String {
        String(name.prefix(13))
    }

    var body: some View {
        ZStack {
            // ---- JAR IMAGE ----
            Image("jar")
                .resizable()
                .scaledToFit()
                .frame(width: 200)       // Adjust size here if needed
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)

            // ---- NAME INSIDE JAR ----
            VStack {
                Spacer().frame(height: 120) // moves text down to the jar center
                Text(clampedName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.black.opacity(0.75))
                    .shadow(color: .white.opacity(0.9), radius: 4)  // makes text readable on glass
                Spacer()
            }
            .allowsHitTesting(false) // Jar remains tappable later for animations

            // ---- RED TRASH BUTTON (top-right) ----
            VStack {
                HStack {
                    Spacer()
                    Button {
                        onDelete?()
                    } label: {
                        Image(systemName: "trash.fill")   // <- changed from "xmark" to trash icon
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 22, height: 22)
                            .background(
                                Circle().fill(Color.red)
                            )
                            .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                    // Fine-tune position: closer to the jar's top-right edge
                    .offset(x: -25, y: 25)          // +x moves right, -y moves up
                    .padding(.trailing, 2)        // small inset from right edge
                    .padding(.top, 2)             // small inset from top edge
                }
                Spacer()
            }
            // You can also reduce or adjust these if you want it even tighter overall:
            .padding(6) // keep the button inset from the edge
            .allowsHitTesting(true)
        }
        .frame(height: 260)
    }
}

struct SavingsJarView_Previews: PreviewProvider {
    static var previews: some View {
        SavingsJarView(name: "Holiday", fillAmount: 0.25, onDelete: {})
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
