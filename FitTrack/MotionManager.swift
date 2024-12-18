import Foundation
import CoreMotion
import SwiftUI

class MotionManager: ObservableObject {
    private var motionManager: CMMotionManager
    private var queue: OperationQueue
    
    // Published properties to update the UI
    @Published var accelerationX: Double = 0.0
    @Published var accelerationY: Double = 0.0
    @Published var accelerationZ: Double = 0.0
    
    @Published var rotationRateX: Double = 0.0
    @Published var rotationRateY: Double = 0.0
    @Published var rotationRateZ: Double = 0.0
    
    // 模拟数据开关（可选）
    @Published var useSimulatedData: Bool = true
    
    private var accelerometerTimer: Timer?
    private var gyroscopeTimer: Timer?
    
    init() {
        self.motionManager = CMMotionManager()
        self.queue = OperationQueue()
        self.queue.name = "MotionQueue"
        self.queue.qualityOfService = .userInitiated
        startUpdates()
    }
    
    deinit {
        stopUpdates()
    }
    
    /// 检测是否在模拟器中运行
    func isSimulator() -> Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    func startUpdates() {
        if isSimulator() || useSimulatedData {
            // 使用模拟数据
            startSimulatedAccelerometerUpdates()
            startSimulatedGyroscopeUpdates()
        } else {
            // 真实设备上的传感器数据获取
            startRealAccelerometerUpdates()
            startRealGyroscopeUpdates()
        }
    }
    
    func stopUpdates() {
        if isSimulator() || useSimulatedData {
            accelerometerTimer?.invalidate()
            accelerometerTimer = nil
            gyroscopeTimer?.invalidate()
            gyroscopeTimer = nil
        } else {
            if motionManager.isAccelerometerActive {
                motionManager.stopAccelerometerUpdates()
            }
            if motionManager.isGyroActive {
                motionManager.stopGyroUpdates()
            }
        }
    }
    
    /// 启动模拟加速度计数据
    private func startSimulatedAccelerometerUpdates() {
        accelerometerTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.accelerationX = Double.random(in: -2.0...2.0)
            self.accelerationY = Double.random(in: -2.0...2.0)
            self.accelerationZ = Double.random(in: -2.0...2.0)
        }
    }
    
    /// 启动模拟陀螺仪数据
    private func startSimulatedGyroscopeUpdates() {
        gyroscopeTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.rotationRateX = Double.random(in: -5.0...5.0)
            self.rotationRateY = Double.random(in: -5.0...5.0)
            self.rotationRateZ = Double.random(in: -5.0...5.0)
        }
    }
    
    /// 启动真实设备上的加速度计数据
    private func startRealAccelerometerUpdates() {
        guard motionManager.isAccelerometerAvailable else {
            print("Accelerometer not available.")
            return
        }
        
        motionManager.accelerometerUpdateInterval = 1.0 / 60.0 // 60 Hz
        motionManager.startAccelerometerUpdates(to: queue) { [weak self] data, error in
            if let data = data {
                DispatchQueue.main.async {
                    self?.accelerationX = data.acceleration.x
                    self?.accelerationY = data.acceleration.y
                    self?.accelerationZ = data.acceleration.z
                }
            }
            if let error = error {
                print("Accelerometer Error: \(error.localizedDescription)")
            }
        }
    }
    
    /// 启动真实设备上的陀螺仪数据
    private func startRealGyroscopeUpdates() {
        guard motionManager.isGyroAvailable else {
            print("Gyroscope not available.")
            return
        }
        
        motionManager.gyroUpdateInterval = 1.0 / 60.0 // 60 Hz
        motionManager.startGyroUpdates(to: queue) { [weak self] data, error in
            if let data = data {
                DispatchQueue.main.async {
                    self?.rotationRateX = data.rotationRate.x
                    self?.rotationRateY = data.rotationRate.y
                    self?.rotationRateZ = data.rotationRate.z
                }
            }
            if let error = error {
                print("Gyroscope Error: \(error.localizedDescription)")
            }
        }
    }
}
