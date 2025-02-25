import SwiftUI

struct RoundIconButton: View {
    let systemImageName: String
    let action: () -> Void
    let size: CGFloat
    let fontSize: CGFloat
    let backgroundColor: Color
    let foregroundColor: Color

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImageName)
                .font(.system(size: fontSize))
                .foregroundColor(foregroundColor)
                .frame(width: size, height: size)
                .background(backgroundColor)
                .clipShape(Circle())
        }
    }
}
