import SwiftUI

struct CameraView: UIViewControllerRepresentable {
    class Coordinator: NSObject {
        var parent: CameraView

        init(parent: CameraView) {
            self.parent = parent
        }

        func toggleCamera() {
            parent.cameraViewController?.toggleCamera()
        }

        func updateEmotion(_ emotion: String) {
            // Update the detectedEmotion binding directly
            DispatchQueue.main.async {
                self.parent.detectedEmotion = emotion
            }
        }
    }

    @Binding var detectedEmotion: String
    @State private var cameraViewController: CameraViewController? // Change to @State

    init(detectedEmotion: Binding<String>) {
        self._detectedEmotion = detectedEmotion // Binding
        self._cameraViewController = State(initialValue: CameraViewController()) // Initialize cameraViewController here
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> CameraViewController {
        cameraViewController?.emotionUpdateHandler = { emotion in
            context.coordinator.updateEmotion(emotion) // Call the update function
        }
        return cameraViewController!
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        // No need to update the controller for now.
    }
}

#Preview {
    // Use a constant for preview
    CameraView(detectedEmotion: .constant("Unknown"))
}
