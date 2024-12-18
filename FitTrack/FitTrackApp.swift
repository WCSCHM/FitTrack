// FitTrackApp.swift

import SwiftUI

@main
struct FitTrackApp: App {
    @StateObject private var soundManager = SoundManager()
    @Environment(\.scenePhase) var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(soundManager)
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .active:
                #if !targetEnvironment(simulator)
                soundManager.startRecording()
                cameraManager.startSession()
                #endif
            case .inactive:
                break
            case .background:
                #if !targetEnvironment(simulator)
                soundManager.stopRecording()
                cameraManager.stopSession()
                #endif
            @unknown default:
                break
            }
        }
    }
}
