import SwiftUI
import UIKit
import PhotosUI
import CoreImage.CIFilterBuiltins

enum AppAsset: String, CaseIterable {
    case brandLogoHorizontal = "brand_logo_horizontal"
    case brandLogoVertical = "brand_logo_vertical"
    case authBackgroundPattern = "auth_background_pattern"
    case welcomeBannerBackground = "welcome_banner_background"
    case calculatorOrb = "calculator_orb"
    case qrFrameDecoration = "qr_frame_decoration"
}

enum AssetScaleMode {
    case cover
    case contain
    case fill
}

struct AssetSlotView: View {
    let name: String
    var mode: AssetScaleMode = .contain

    var body: some View {
        GeometryReader { proxy in
            if UIImage(named: name) != nil {
                Image(name)
                    .resizable()
                    .modifier(AssetScaleModifier(mode: mode))
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
            } else {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.quaternary)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(.secondary.opacity(0.25), style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
                    }
                    .overlay {
                        Text(name)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.55)
                            .lineLimit(3)
                            .padding(10)
                    }
            }
        }
        .accessibilityLabel("Afbeeldingsruimte \(name)")
    }
}

private struct AssetScaleModifier: ViewModifier {
    let mode: AssetScaleMode

    func body(content: Content) -> some View {
        switch mode {
        case .cover:
            content.scaledToFill()
        case .contain:
            content.scaledToFit()
        case .fill:
            content
        }
    }
}

struct BrandCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.orange.opacity(0.22), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
    }
}

struct EmptyStateView: View {
    let systemName: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: systemName)
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(.orange)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
    }
}

struct LoadingButton: View {
    let title: String
    let systemName: String
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: systemName)
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .disabled(isLoading)
        .accessibilityLabel(title)
    }
}

struct QRCodeView: View {
    let text: String

    var body: some View {
        if let image = makeImage(from: text) {
            Image(uiImage: image)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .padding(18)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .accessibilityLabel("QR-code voor bonusactivatie")
        } else {
            EmptyStateView(systemName: "qrcode", title: "QR-code niet beschikbaar", message: "Probeer het later opnieuw.")
        }
    }

    private func makeImage(from text: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onComplete: () -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onComplete: onComplete)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onComplete: () -> Void

        init(onComplete: @escaping () -> Void) {
            self.onComplete = onComplete
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            picker.dismiss(animated: true) {
                self.onComplete()
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

struct TicketScanImporter: ViewModifier {
    @Binding var scannerSource: UIImagePickerController.SourceType?
    @Binding var showScanFailure: Bool

    func body(content: Content) -> some View {
        content
            .confirmationDialog("Lot scannen", isPresented: Binding(
                get: { scannerSource == .camera || scannerSource == .photoLibrary },
                set: { if !$0 { scannerSource = nil } }
            )) {
                EmptyView()
            }
            .sheet(item: Binding(
                get: { scannerSource.map(SourceBox.init(sourceType:)) },
                set: { if $0 == nil { scannerSource = nil } }
            )) { box in
                ImagePicker(sourceType: box.sourceType) {
                    scannerSource = nil
                    showScanFailure = true
                }
            }
            .alert("Lot niet herkend", isPresented: $showScanFailure) {
                Button("Handmatig toevoegen", role: .none) {}
                Button("OK", role: .cancel) {}
            } message: {
                Text("De afbeelding kon niet betrouwbaar worden gelezen. Voeg het lot handmatig toe.")
            }
    }
}

struct SourceBox: Identifiable {
    let id = UUID()
    let sourceType: UIImagePickerController.SourceType
}
