import UIKit
import AVFoundation
import Vision

class CameraViewController: UIViewController {
    
    private var drawings: [CAShapeLayer] = []
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let captureSession = AVCaptureSession()
    
    private lazy var previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)

    // Closure to handle detected emotions
    var emotionUpdateHandler: ((String) -> Void)?
    private var emotionalAnalyzer: EmotionalAnalyzer?
    
    // Start with the back camera
    private var currentCameraPosition: AVCaptureDevice.Position = .front
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emotionalAnalyzer = EmotionalAnalyzer() // Initialize the emotional analyzer
        addCameraInput()
        showCameraFeed()
        getCameraFrames()
        captureSession.startRunning()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = view.frame
    }
    
    private func addCameraInput() {
        captureSession.stopRunning()
        if let inputs = captureSession.inputs as? [AVCaptureInput] {
            for input in inputs {
                captureSession.removeInput(input)
            }
        }

        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInTrueDepthCamera, .builtInDualCamera, .builtInWideAngleCamera],
            mediaType: .video,
            position: currentCameraPosition)
        
        if let device = discoverySession.devices.first {
            do {
                let cameraInput = try AVCaptureDeviceInput(device: device)
                captureSession.addInput(cameraInput)
            } catch {
                print("Error creating camera input: \(error.localizedDescription)")
            }
        } else {
            print("No camera detected. Using a default video input or mock data.")
        }
    }

    private func showCameraFeed() {
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
    }
    
    private func getCameraFrames() {
        videoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString): NSNumber(value: kCVPixelFormatType_32BGRA)] as [String: Any]
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera_frame_processing_queue"))
        captureSession.addOutput(videoDataOutput)
        
        guard let connection = videoDataOutput.connection(with: .video), connection.isVideoOrientationSupported else {
            return
        }
        
        connection.videoOrientation = .portrait
    }
    
    func toggleCamera() {
        captureSession.stopRunning()
        clearDrawings()
        currentCameraPosition = (currentCameraPosition == .front) ? .back : .front
        addCameraInput()
        captureSession.startRunning()
    }

    private func detectFace(image: CVPixelBuffer) {
        let faceDetectionRequest = VNDetectFaceLandmarksRequest { vnRequest, error in
            DispatchQueue.main.async {
                if let results = vnRequest.results as? [VNFaceObservation], results.count > 0 {
                    self.handleFaceDetectionResults(observedFaces: results)
                    self.detectEmotion(image: image) // Call emotion detection after face detection
                } else {
                    self.clearDrawings()
                    self.emotionUpdateHandler?("Unknown") // No face detected
                }
            }
        }
        
        let imageResultHandler = VNImageRequestHandler(cvPixelBuffer: image, orientation: .leftMirrored, options: [:])
        try? imageResultHandler.perform([faceDetectionRequest])
    }

    private func handleFaceDetectionResults(observedFaces: [VNFaceObservation]) {
        clearDrawings()
        
        let facesBoundingBoxes: [CAShapeLayer] = observedFaces.map({ (observedFace: VNFaceObservation) -> CAShapeLayer in
            let faceBoundingBoxOnScreen = previewLayer.layerRectConverted(fromMetadataOutputRect: observedFace.boundingBox)
            let faceBoundingBoxPath = CGPath(rect: faceBoundingBoxOnScreen, transform: nil)
            let faceBoundingBoxShape = CAShapeLayer()
            faceBoundingBoxShape.path = faceBoundingBoxPath
            faceBoundingBoxShape.fillColor = UIColor.clear.cgColor
            faceBoundingBoxShape.strokeColor = UIColor.green.cgColor
            return faceBoundingBoxShape
        })
        
        facesBoundingBoxes.forEach { faceBoundingBox in
            view.layer.addSublayer(faceBoundingBox)
            drawings = facesBoundingBoxes
        }
    }
    
    private func clearDrawings() {
        drawings.forEach({ drawing in drawing.removeFromSuperlayer() })
    }
    
    private func detectEmotion(image: CVPixelBuffer) {
        // Use the EmotionalAnalyzer to analyze the captured frame
        if let detectedEmotion = emotionalAnalyzer?.analyzeEmotion(from: image) {
            // Update the emotion using the handler
            emotionUpdateHandler?(detectedEmotion.rawValue.capitalized)
        } else {
            emotionUpdateHandler?("Unknown") // Emotion could not be detected
        }
    }
}

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let frame = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            debugPrint("Unable to get image from the sample buffer")
            return
        }
        detectFace(image: frame)
    }
}
