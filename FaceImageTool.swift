import UIKit
import CoreImage
import CoreML

class FaceImageTool {
    
    // Function to process the captured face image
    func processFaceImage(pixelBuffer: CVPixelBuffer) -> (UIImage?, MLMultiArray?) {
        // Convert pixel buffer to UIImage
        guard let image = imageFromPixelBuffer(pixelBuffer) else {
            return (nil, nil)
        }
        
        // Step 1: Convert to Grayscale
        guard let grayscaleImage = convertToGrayscale(image: image) else {
            return (nil, nil)
        }
        
        // Step 2: Resize Image
        guard let resizedImage = resizeImage(image: grayscaleImage, targetSize: CGSize(width: 48, height: 48)) else {
            return (nil, nil)
        }
        
        // Step 3: Normalize Image
        let normalizedImage = normalizeImage(image: resizedImage)
        
        // Convert the normalized image to MLMultiArray for the model
        let inputArray = multiArrayFromImage(normalizedImage)
        
        return (resizedImage, inputArray)
    }
    
    // Convert CVPixelBuffer to UIImage
    // Convert CVPixelBuffer to UIImage
    private func imageFromPixelBuffer(_ pixelBuffer: CVPixelBuffer) -> UIImage? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        
        // Create CGImage from CIImage
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        
        // Convert CGImage to UIImage
        return UIImage(cgImage: cgImage)
    }

    // Convert UIImage to Grayscale
    private func convertToGrayscale(image: UIImage) -> UIImage? {
        let ciImage = CIImage(image: image)
        let grayscaleFilter = CIFilter(name: "CIColorControls")
        grayscaleFilter?.setValue(ciImage, forKey: kCIInputImageKey)
        grayscaleFilter?.setValue(0.0, forKey: kCIInputSaturationKey) // 0 for grayscale
        
        if let outputImage = grayscaleFilter?.outputImage {
            let context = CIContext() // Remove optional binding here
            let cgImage = context.createCGImage(outputImage, from: outputImage.extent)
            return cgImage.map { UIImage(cgImage: $0) } // Use map to unwrap
        }
        
        return nil
    }

    
    // Resize Image to target size
    private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: targetSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }
    
    // Normalize Image to 0-1 range
    private func normalizeImage(image: UIImage) -> UIImage {
        guard let pixelData = image.cgImage?.dataProvider?.data else {
            return image
        }
        
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        let width = image.cgImage!.width
        let height = image.cgImage!.height
        
        // Create a new context for the normalized image
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
        let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)
        
        // Drawing the grayscale image
        context?.draw(image.cgImage!, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        return UIImage(cgImage: context!.makeImage()!)
    }
    
    // Convert UIImage to MLMultiArray
    private func multiArrayFromImage(_ image: UIImage) -> MLMultiArray? {
        guard let cgImage = image.cgImage else { return nil }
        let width = 48
        let height = 48
        
        let multiArray = try? MLMultiArray(shape: [1, NSNumber(value: height), NSNumber(value: width), 1], dataType: .float32)
        
        guard let dataPointer = multiArray?.dataPointer.bindMemory(to: Float32.self, capacity: width * height) else {
            return nil
        }
        
        let context = CIContext(options: nil) // No optional binding needed here
        let ciImage = CIImage(cgImage: cgImage)
        
        guard let outputImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        
        guard let pixelData = outputImage.dataProvider?.data else { return nil }
        
        // Safely unwrap pixelBuffer
        guard let pixelBuffer = UnsafePointer<UInt8>(CFDataGetBytePtr(pixelData)) else {
            return nil
        }
        
        for y in 0..<height {
            for x in 0..<width {
                let pixelIndex = (y * width + x) * 4 // 4 for RGBA
                let grayValue = Float32(pixelBuffer[pixelIndex]) / 255.0 // Normalize to [0, 1]
                dataPointer[y * width + x] = grayValue
            }
        }
        
        return multiArray
    }



}
