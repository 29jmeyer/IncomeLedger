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
        GeometryReader { geo in
            // Use available size from parent
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // ---- JAR IMAGE (updated to jarlid) ----
                Image("jarlid")
                    .resizable()
                    .scaledToFit()
                    // Fill width, keep aspect
                    .frame(width: w)
                    .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)

                // ---- NAME INSIDE JAR ----
                VStack {
                    // Position roughly at the visual center of the jar.
                    // Use a proportion of the total height so it scales with size.
                    Spacer().frame(height: h * 0.46)
                    Text(clampedName)
                        .font(.system(size: max(10, w * 0.06), weight: .semibold)) // scale font with width
                        .foregroundColor(.black.opacity(0.75))
                        .shadow(color: .white.opacity(0.9), radius: 4)  // makes text readable on glass
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                    Spacer()
                }
                .allowsHitTesting(false)

                // ---- RED TRASH BUTTON (top-right) ----
                if onDelete != nil {
                    VStack {
                        HStack {
                            Spacer()
                            Button {
                                onDelete?()
                            } label: {
                                Image(systemName: "trash.fill")
                                    .font(.system(size: max(10, w * 0.06), weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: max(20, w * 0.11), height: max(20, w * 0.11))
                                    .background(
                                        Circle().fill(Color.red)
                                    )
                                    .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 2)
                            }
                            .buttonStyle(.plain)
                            // Offset proportionally so it hugs the top-right of the jar consistently
                            .offset(x: -w * 0.14, y: h * 0.1)
                        }
                        Spacer()
                    }
                    .padding(6)
                    .allowsHitTesting(true)
                }
            }
            // Ensure the jar content scales within the proposed size
            .frame(width: w, height: h, alignment: .center)
        }
        // No fixed height here; parent controls size
    }
}

struct SavingsJarView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SavingsJarView(name: "Holiday", fillAmount: 0.25, onDelete: {})
                .frame(width: 200, height: 260)
                .padding()
                .previewLayout(.sizeThatFits)

            SavingsJarView(name: "Holiday", fillAmount: 0.25, onDelete: nil)
                .frame(width: 300, height: 360)
                .padding()
                .previewLayout(.sizeThatFits)
        }
    }
}
