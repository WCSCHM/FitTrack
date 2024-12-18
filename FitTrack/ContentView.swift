// ContentView.swift

import SwiftUI

struct ContentView: View {
    @State private var isActive = true
    
    var body: some View {
        ZStack {
            if isActive {
                SplashScreenView(isActive: $isActive)
            } else {
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 1.0), value: isActive)
    }
}

// 将原来的 TabView 移到一个新的视图中
struct MainTabView: View {
    var body: some View {
        TabView {
            MotionView()
                .tabItem {
                    Image(systemName: "figure.walk")
                    Text("移动")
                }
            
            LocationView()
                .tabItem {
                    Image(systemName: "map")
                    Text("位置")
                }
            
            DirectionView()
                .tabItem {
                    Image(systemName: "location.north.line")
                    Text("方向")
                }
            
            SoundView()
                .tabItem {
                    Image(systemName: "waveform.path.ecg")
                    Text("声音")
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
