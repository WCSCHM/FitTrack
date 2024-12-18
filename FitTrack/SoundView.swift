// SoundView.swift

import SwiftUI

struct SoundView: View {
    @EnvironmentObject var soundManager: SoundManager
    
    var body: some View {
        ZStack {
            // 动态背景
            SoundDynamicBackground()
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                // 声音图形动画
                SoundWaveView(soundLevel: soundManager.soundLevel)
                    .frame(height: 200)
                    .padding()
                
                // "Sound Sensor" 标题
                Text("Sound Sensor")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
                    .scaleEffect(soundManager.soundLevel > 0.5 ? 1.2 : 1.0)
                    .animation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: soundManager.soundLevel)
                
                // 当前音量显示
                Text(String(format: "Volume: %.2f", soundManager.soundLevel))
                    .font(.title)
                    .foregroundColor(.white)
                    .shadow(radius: 5)
                
                Spacer()
            }
            .padding()
            
            // 权限提示
            if !soundManager.isSoundAvailable {
                VStack {
                    Text("麦克风不可用或权限被拒绝。")
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color.red.opacity(0.7))
                        .cornerRadius(15)
                        .shadow(radius: 10)
                    
                    #if !targetEnvironment(simulator)
                    if soundManager.authorizationStatus == .denied || soundManager.authorizationStatus == .restricted {
                        Button(action: {
                            // 引导用户打开设置
                            if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                                if UIApplication.shared.canOpenURL(appSettings) {
                                    UIApplication.shared.open(appSettings)
                                }
                            }
                        }) {
                            HStack {
                                Image(systemName: "gearshape.fill")
                                Text("打开设置")
                            }
                            .foregroundColor(.blue)
                            .padding()
                            .background(Color.white.opacity(0.3))
                            .cornerRadius(10)
                            .shadow(radius: 5)
                        }
                        .padding(.top, 10)
                    }
                    #endif
                }
                .padding()
                .transition(.opacity)
                .animation(.easeInOut, value: soundManager.isSoundAvailable)
            }
        }
        .navigationTitle("声音")
    }
}

struct SoundView_Previews: PreviewProvider {
    static var previews: some View {
        SoundView()
            .environmentObject(SoundManager())
    }
}

// 动态背景视图
struct SoundDynamicBackground: View {
    @State private var animateGradient = false
    
    var body: some View {
        ZStack {
            // 渐变背景动画
            LinearGradient(gradient: Gradient(colors: animateGradient ? [Color.orange, Color.pink] : [Color.pink, Color.orange]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .animation(Animation.linear(duration: 10).repeatForever(autoreverses: true), value: animateGradient)
                .onAppear {
                    animateGradient.toggle()
                }
            
            // 粒子效果
            SoundParticleEmitterView()
                .blendMode(.overlay)
                .opacity(0.3)
        }
    }
}

// 粒子发射器视图
struct SoundParticleEmitterView: View {
    @State private var particles: [SoundParticle] = []
    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color.opacity(Double(particle.opacity)))
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .blur(radius: particle.blur)
                }
            }
            .onReceive(timer) { _ in
                updateParticles(in: geometry.size)
            }
        }
    }
    
    func updateParticles(in size: CGSize) {
        // 添加新粒子
        if particles.count < 100 {
            let newParticle = SoundParticle(
                id: UUID(),
                position: CGPoint(x: CGFloat.random(in: 0...size.width), y: CGFloat.random(in: 0...size.height)),
                velocity: CGVector(dx: CGFloat.random(in: -1...1), dy: CGFloat.random(in: -1...1)),
                size: CGFloat.random(in: 2...6),
                opacity: Float.random(in: 0.5...1.0),
                blur: CGFloat.random(in: 0...2),
                color: Color.white
            )
            particles.append(newParticle)
        }
        
        // 更新现有粒子
        for index in particles.indices.reversed() {
            particles[index].position.x += particles[index].velocity.dx
            particles[index].position.y += particles[index].velocity.dy
            particles[index].opacity -= 0.01
            if particles[index].opacity <= 0 {
                particles.remove(at: index)
            }
        }
    }
}

// 粒子模型
struct SoundParticle: Identifiable {
    let id: UUID
    var position: CGPoint
    var velocity: CGVector
    var size: CGFloat
    var opacity: Float
    var blur: CGFloat
    var color: Color
}

// 声波动画视图
struct SoundWaveView: View {
    var soundLevel: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<5) { i in
                    Circle()
                        .stroke(Color.white.opacity(0.5), lineWidth: 2)
                        .frame(width: CGFloat(100 + i * 40) * CGFloat(soundLevel + 0.1),
                               height: CGFloat(100 + i * 40) * CGFloat(soundLevel + 0.1))
                        .animation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: soundLevel)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
