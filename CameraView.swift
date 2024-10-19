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
    }

    var cameraViewController: CameraViewController? = CameraViewController()

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> CameraViewController {
        return cameraViewController!
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        // No need to update the controller for now.
    }
    
    // Method to toggle the camera from ContentView
    func toggleCamera() {
        cameraViewController?.toggleCamera()
    }
}

#Preview {
    CameraView()
}
