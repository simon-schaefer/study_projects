import Foundation
import UIKit
import CoreMotion
import simd


struct SensorData {
    var roll: Double = 0.0
    var pitch: Double = 0.0
    var yaw: Double = 0.0
    var rotationRateX: Double = 0.0
    var rotationRateY: Double = 0.0
    var rotationRateZ: Double = 0.0
    var accelerationX: Double = 0.0
    var accelerationY: Double = 0.0
    var accelerationZ: Double = 0.0
    var timestamp: Double = 0.0
}
let SensorDataDescription = "roll, pitch, yaw, rot_rate_X, rot_rate_Y, rot_rate_Z, acc_X, acc_Y, acc_Z, timestamp\n"
let NumSensorSamples = 100


class RecorderVI: UIViewController {

    var motionManager: CMMotionManager? = CMMotionManager()
    
    var data: [SensorData] = []
    var count: Int!
    var imageCount: Int!
    
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var walkingIcon: UIImageView!
    @IBOutlet weak var statusLabel: UILabel!
    
    // Do any additional setup after loading the view, typically from a nib.
    override func viewDidLoad() {
        super.viewDidLoad()
        self.resetMeasurement()
        button.isEnabled = true
        self.statusLabel.text = "..."
    }
    
    
    /*
    //////////////////////////////////////////////////////////////////////////
    // IMU Reading
    //////////////////////////////////////////////////////////////////////////
    */
    func startMeasurement() {
        // If device motion NOT available, then don't start the imu reader.
        guard let motion = motionManager, motion.isDeviceMotionAvailable else {
            return
        }
        
        // Set imu capturing options.
        motion.deviceMotionUpdateInterval = 1.0 / 60.0
        // motion.showsDeviceMovementDisplay = true
        
        // Start motion capturing logging loop.
        motion.startDeviceMotionUpdates(
            // using: .xMagneticNorthZVertical, // Get the attitude relative to the magnetic north reference frame.
            to: .main,
            withHandler: { (data, error) in // TODO: main queue not recommended, self.queue
                // Make sure the data is valid before accessing it.
                if let validData = data {
                    let sensor_data = SensorData(
                        roll: validData.attitude.roll,
                        pitch: validData.attitude.pitch,
                        yaw: validData.attitude.yaw,
                        rotationRateX: validData.rotationRate.x,
                        rotationRateY: validData.rotationRate.y,
                        rotationRateZ: validData.rotationRate.z,
                        accelerationX: validData.userAcceleration.x,
                        accelerationY: validData.userAcceleration.y,
                        accelerationZ: validData.userAcceleration.z,
                        timestamp: validData.timestamp.magnitude
                    )
                    self.data.append(sensor_data)
                    self.count = self.count + 1
                    self.imageCount = self.imageCount + 1
                    if self.imageCount >= 6 {
                        self.imageCount = 1
                    }
                    
                    if self.count % 6 == 0 {
                        let image = String(format:"walking%d", self.imageCount)
                        self.walkingIcon.image = UIImage(named: image)
                    }
                    
                    if self.count > NumSensorSamples {
                        self.stopMeasurement()
                    }
                }
        })
    }
    
    func stopMeasurement() {
        guard let motion = motionManager, motion.isDeviceMotionAvailable else { return }
        motion.stopDeviceMotionUpdates()
        self.process()
    }
    
    func resetMeasurement() {
        self.count = 0
        self.imageCount = 1
        self.data.removeAll()
    }
    
    /*
    //////////////////////////////////////////////////////////////////////////
    // Processing
    //////////////////////////////////////////////////////////////////////////
    */
    
    func process() {
        self.walkingIcon.image = UIImage(named: "processing")
        self.statusLabel.text = "processing ..."
        
        let user_identified: Bool = true
        let user_name: String = "Simon"
        if user_identified {
            self.statusValid(name: user_name)
        } else {
            self.statusInvalid()
        }
    }
    
    func statusValid(name: String) {
        self.walkingIcon.image = UIImage(named: "check")
        self.statusLabel.text = String(format: "Hello %@ !", name)
    }

    func statusInvalid() {
        self.walkingIcon.image = UIImage(named: "warning")
        self.statusLabel.text = "Invalid User !"
    }

    /*
    //////////////////////////////////////////////////////////////////////////
    // User Interface
    //////////////////////////////////////////////////////////////////////////
    */
    
    @IBAction func start(_ sender: UIButton) {
        button.isEnabled = false
        self.statusLabel.text = "measuring ..."
        self.startMeasurement()
    }
    
    func writeSensorData() -> URL! {
         var fileURL: URL!
         if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
             
             do {
                 fileURL = dir.appendingPathComponent("data.txt")
                 FileManager.default.createFile(atPath: fileURL.path, contents: nil, attributes: nil)
                 let file: FileHandle? = try FileHandle(forWritingTo: fileURL)
                 file!.write(SensorDataDescription.data(using: .utf8, allowLossyConversion: false)!)
                 for i in 0 ..< self.count {
                     let line = String(format:"%.20g,%.20g,%.20g,%.20g,%.20g,%.20g,%.20g,%.20g,%.20g,%.20g",
                                       data[i].roll, data[i].pitch, data[i].yaw,
                                       data[i].rotationRateX, data[i].rotationRateY, data[i].rotationRateZ,
                                       data[i].accelerationX, data[i].accelerationY, data[i].accelerationZ,
                                       data[i].timestamp)
                     file!.write(line.data(using: .utf8, allowLossyConversion: false)!)
                 }
                 file!.closeFile()
             } catch {
                 print("Error when creating FileHandle")
             }
         }
         return fileURL
     }
    
//    @IBAction func share(_ sender: UIButton) {
//        status.text = "Sharing..."
//
//        let fileURL = self.imu_reader.writeSensorData()
//
//        let documentToShare = NSData(contentsOfFile: fileURL!.path)
//        let activityViewController = UIActivityViewController(activityItems: [documentToShare!], applicationActivities: nil)
//        activityViewController.completionWithItemsHandler = {(activityType: UIActivity.ActivityType?, completed: Bool, returnedItems: [Any]?, error: Error?) in
//            if !completed {
//                // User canceled
//                self.status.text = "Sharing cancelled"
//                return
//            }
//            // User completed activity
//            self.status.text = "Sharing completed"
//        }
//        activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
//
//        // Present the view controller.
//        self.present(activityViewController, animated: true, completion: nil)
//    }

}
