// SoundManager.swift

import Foundation
import AVFoundation
import SwiftUI
import Combine

class SoundManager: NSObject, ObservableObject {
    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    
    @Published var soundLevel: Double = 0.0
    @Published var isSoundAvailable: Bool = false
    @Published var authorizationStatus: AVAudioSession.RecordPermission = .undetermined
    @Published var isRecording: Bool = false // 录音状态
    
    override init() {
        super.init()
        #if targetEnvironment(simulator)
        // 模拟器环境
        isSoundAvailable = true
        startSimulatedSoundUpdates()
        startSimulatedRecording()
        #else
        // 真实设备环境
        checkSoundAvailability()
        requestPermission()
        #endif
    }
    
    deinit {
        stopSoundUpdates()
        stopRecording()
    }
    
    #if !targetEnvironment(simulator)
    private func checkSoundAvailability() {
        let session = AVAudioSession.sharedInstance()
        isSoundAvailable = session.isInputAvailable
    }
    
    private func requestPermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                self?.authorizationStatus = AVAudioSession.sharedInstance().recordPermission
                self?.isSoundAvailable = granted && AVAudioSession.sharedInstance().isInputAvailable
                if granted {
                    self?.startSoundUpdates()
                    self?.startRecording()
                }
            }
        }
    }
    
    private func startSoundUpdates() {
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatAppleLossless),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: getRecordingURL(), settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()
            isRecording = true
            
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                self?.audioRecorder?.updateMeters()
                if let averagePower = self?.audioRecorder?.averagePower(forChannel: 0) {
                    // 转换为线性音量 (0.0 - 1.0)
                    let linearLevel = pow(10, averagePower / 20)
                    DispatchQueue.main.async {
                        self?.soundLevel = linearLevel
                    }
                }
            }
        } catch {
            print("无法启动音频录制: \(error.localizedDescription)")
            isSoundAvailable = false
        }
    }
    
    private func stopSoundUpdates() {
        timer?.invalidate()
        timer = nil
        stopRecording()
    }
    
    func startRecording() {
        guard let recorder = audioRecorder, !recorder.isRecording else { return }
        recorder.record()
        isRecording = true
    }
    
    func stopRecording() {
        guard let recorder = audioRecorder, recorder.isRecording else { return }
        recorder.stop()
        isRecording = false
    }
    
    private func getRecordingURL() -> URL {
        let fileName = "recording_\(Date().timeIntervalSince1970).m4a"
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsDirectory.appendingPathComponent(fileName)
    }
    #else
    // 模拟器环境下定义空的 stopRecording 和 stopSoundUpdates 方法
    func stopRecording() {
        // 模拟停止录音
        stopSimulatedRecording()
    }
    
    func stopSoundUpdates() {
        timer?.invalidate()
        timer = nil
        stopRecording()
    }
    #endif
    
    // MARK: - 模拟器中的声音更新与录音
    #if targetEnvironment(simulator)
    private func startSimulatedSoundUpdates() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            // 生成模拟音量数据 (0.0 - 1.0)，使用正弦波
            let simulatedLevel = (sin(Date().timeIntervalSince1970 * 2) + 1) / 2
            DispatchQueue.main.async {
                self.soundLevel = simulatedLevel
            }
        }
    }
    
    private func startSimulatedRecording() {
        // 模拟录音状态
        isRecording = true
    }
    
    private func stopSimulatedRecording() {
        // 模拟停止录音
        isRecording = false
    }
    #endif
}
