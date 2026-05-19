import SwiftUI

struct ThumbnailView: View {
    let image: CGImage
    let onClick: () -> Void
    let onDismiss: () -> Void

    @State private var opacity: Double = 0
    @State private var yOffset: CGFloat = 14

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: onClick) {
                VStack(alignment: .leading, spacing: 10) {
                    Image(decorative: image, scale: 1.0)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 220, height: 138)
                        .background(Color.black.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(.white.opacity(0.22), lineWidth: 0.5)
                        }

                    HStack(spacing: 8) {
                        Image(systemName: "pencil.tip.crop.circle")
                            .symbolRenderingMode(.hierarchical)
                            .font(.system(size: 15, weight: .semibold))

                        VStack(alignment: .leading, spacing: 1) {
                            Text("Screenshot Saved")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Click to annotate")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 2)
                }
                .padding(10)
                .frame(width: 240)
                .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)

            Button(action: dismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 22, height: 22)
                    .background(.thinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .padding(7)
            .help("Dismiss")
        }
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.26), radius: 28, x: 0, y: 14)
                .shadow(color: .black.opacity(0.14), radius: 2, x: 0, y: 1)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.white.opacity(0.24), lineWidth: 0.5)
        }
        .opacity(opacity)
        .offset(y: yOffset)
        .onAppear {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
                opacity = 1
                yOffset = 0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                dismiss()
            }
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.22)) {
            opacity = 0
            yOffset = 8
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
            onDismiss()
        }
    }
}
