// DirectionManager.swift

import Foundation
import CoreLocation
import SwiftUI

class DirectionManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private var locationManager: CLLocationManager
    
    // Published properties to update the UI
    @Published var heading: CLHeading?
    @Published var isHeadingAvailable: Bool = false
    @Published var simulatedHeading: Double = 0.0 // 仅用于模拟器
    
    private var headingTimer: Timer?
    
    override init() {
        self.locationManager = CLLocationManager()
        super.init()
        
        #if targetEnvironment(simulator)
        // 模拟器环境
        self.isHeadingAvailable = true // 修改为 true 以显示模拟数据
        startSimulatedHeadingUpdates()
        #else
        // 真实设备环境
        self.locationManager.delegate = self
        self.locationManager.headingFilter = kCLHeadingFilterNone
        self.locationManager.headingOrientation = .portrait
        checkHeadingAvailability()
        requestAuthorization()
        #endif
    }
    
    /// 请求位置和运动传感器权限（仅真实设备）
    #if !targetEnvironment(simulator)
    func requestAuthorization() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.locationManager.requestWhenInUseAuthorization()
        }
    }
    #endif
    
    /// 检查设备是否支持方向传感器（仅真实设备）
    #if !targetEnvironment(simulator)
    private func checkHeadingAvailability() {
        DispatchQueue.main.async { [weak self] in
            if CLLocationManager.headingAvailable() {
                self?.isHeadingAvailable = true
            } else {
                self?.isHeadingAvailable = false
                print("Heading data is not available.")
            }
        }
    }
    #endif
    
    // MARK: - CLLocationManagerDelegate Methods (仅真实设备)
    #if !targetEnvironment(simulator)
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                if CLLocationManager.headingAvailable() {
                    self?.locationManager.startUpdatingHeading()
                    DispatchQueue.main.async {
                        self?.isHeadingAvailable = true
                    }
                } else {
                    DispatchQueue.main.async {
                        self?.isHeadingAvailable = false
                        print("Heading data is not available.")
                    }
                }
            case .denied, .restricted:
                DispatchQueue.main.async {
                    self?.isHeadingAvailable = false
                    print("Location access denied or restricted.")
                }
            case .notDetermined:
                print("Location access not determined.")
            @unknown default:
                print("Unknown authorization status.")
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        DispatchQueue.main.async {
            self.heading = newHeading
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            print("Failed to get heading data: \(error.localizedDescription)")
        }
    }
    #endif
    
    // MARK: - Simulated Heading Updates (仅模拟器)
    #if targetEnvironment(simulator)
    func startSimulatedHeadingUpdates() {
        headingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.simulatedHeading += 1.0
            if self.simulatedHeading >= 360.0 {
                self.simulatedHeading = 0.0
            }
            // 在模拟器中，heading 属性不再使用，我们仅使用 simulatedHeading 来驱动指南针
        }
    }
    
    func stopSimulatedHeadingUpdates() { // 已将访问级别修改为 internal
        headingTimer?.invalidate()
        headingTimer = nil
    }
    #endif
}
