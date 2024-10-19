import SwiftUI

struct ContentView: View {
    @State private var detectedEmotion = "Unknown"  // Emotion State Variable

    var body: some View {
        ZStack {
            // Camera view
            CameraView(detectedEmotion: $detectedEmotion) // Update: Removed closure
                .edgesIgnoringSafeArea(.all)

            VStack {
                HStack {
                    Button(action: {
                        // Toggle the camera in the CameraView
                        // Ensure the toggleCamera method works properly
                        if let cameraViewController = UIApplication.shared.windows.first?.rootViewController as? CameraViewController {
                            cameraViewController.toggleCamera()
                        }
                    }) {
                        Image(systemName: "camera.rotate")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding(.leading, 20)
                    .padding(.top, 40) // Adjust for notch and status bar height

                    Spacer()
                }
                Spacer()

                // Display detected emotion at the center of the screen
                Text(detectedEmotion)
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .clipShape(Capsule())
                    .padding(.bottom, 40) // Adjust the padding as needed

                // Bottom center donut-shaped button
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.2)) // Outer circle (donut shape)
                        .frame(width: 70, height: 70)

                    Circle()
                        .fill(Color.white) // Inner circle (empty space)
                        .frame(width: 50, height: 50)
                }
                .padding(.bottom, 40) // Adjust the padding as needed
            }
        }
    }
}

#Preview {
    ContentView()
}

