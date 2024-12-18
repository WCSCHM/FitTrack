// DirectionView.swift

import SwiftUI
import CoreLocation

struct DirectionView: View {
    @StateObject private var directionManager = DirectionManager()
    
    var body: some View {
        NavigationView {
            ZStack {
                // 动态背景 - 多层渐变和动态粒子
                DynamicBackground()
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    if directionManager.isHeadingAvailable {
                        #if targetEnvironment(simulator)
                        // 模拟器环境，使用 simulatedHeading
                        EnhancedCompassView(heading: directionManager.simulatedHeading)
                        #else
                        // 真实设备环境，使用 heading.trueHeading
                        if let heading = directionManager.heading {
                            EnhancedCompassView(heading: heading.trueHeading)
                        } else {
                            Text("正在获取方向数据...")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.5))
                                .cornerRadius(10)
                        }
                        #endif
                    } else {
                        VStack {
                            Text("设备不支持方向传感器或权限被拒绝。")
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding()
                                .background(Color.red.opacity(0.7))
                                .cornerRadius(15)
                                .shadow(radius: 10)
                            
                            #if !targetEnvironment(simulator)
                            if directionManager.authorizationStatus == .denied || directionManager.authorizationStatus == .restricted {
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
                        .animation(.easeInOut, value: directionManager.isHeadingAvailable)
                    }
                }
                .navigationTitle("方向")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Image(systemName: "location.north.fill")
                            .foregroundColor(.white)
                            .font(.title2)
                            .shadow(radius: 5)
                            .rotationEffect(Angle(degrees: directionManager.isHeadingAvailable ? (getCurrentHeading() - 0) : 0))
                            .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: getCurrentHeading())
                    }
                }
            }
            .onAppear {
                #if targetEnvironment(simulator)
                // 模拟器中不需要额外的操作
                #else
                // 在真实设备上，权限请求已在 DirectionManager 的 init 中调用
                #endif
            }
            .onDisappear {
                #if targetEnvironment(simulator)
                directionManager.stopSimulatedHeadingUpdates()
                #else
                // 可选：在视图消失时停止方向更新
                // directionManager.locationManager.stopUpdatingHeading()
                #endif
            }
        }
    }
    
    /// 获取当前的方向值
    private func getCurrentHeading() -> Double {
        #if targetEnvironment(simulator)
        return directionManager.simulatedHeading
        #else
        return directionManager.heading?.trueHeading ?? 0.0
        #endif
    }
    
    /// 动态背景视图
    struct DynamicBackground: View {
        @State private var animate = false
        
        var body: some View {
            ZStack {
                // 多层径向渐变
                RadialGradient(gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.8)]),
                               center: .center,
                               startRadius: 200,
                               endRadius: 700)
                    .animation(Animation.linear(duration: 20).repeatForever(autoreverses: true), value: animate)
                    .onAppear {
                        animate.toggle()
                    }
                
                // 动态粒子效果
                ParticleEmitterView()
                    .blendMode(.overlay)
                    .opacity(0.3)
            }
        }
    }
    
    /// 粒子发射器视图
    struct ParticleEmitterView: View {
        @State private var particles: [Particle] = []
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
                let newParticle = Particle(
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
    
    /// 粒子模型
    struct Particle: Identifiable {
        let id: UUID
        var position: CGPoint
        var velocity: CGVector
        var size: CGFloat
        var opacity: Float
        var blur: CGFloat
        var color: Color
    }
    
    /// 增强型指南针视图
    struct EnhancedCompassView: View {
        var heading: Double
        
        @State private var animateRotation = false
        
        var body: some View {
            VStack {
                Text("当前方向")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(.bottom, 20)
                    .shadow(radius: 5)
                
                ZStack {
                    // 装饰性圆环
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 10)
                        .frame(width: 300, height: 300)
                        .blur(radius: 2)
                    
                    // 背景圆盘
                    Circle()
                        .fill(LinearGradient(gradient: Gradient(colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)]),
                                             startPoint: .topLeading,
                                             endPoint: .bottomTrailing))
                        .frame(width: 250, height: 250)
                        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    // 方向标签
                    VStack {
                        Text("N")
                            .font(.title)
                            .foregroundColor(.white)
                            .offset(y: -130)
                        Spacer()
                        Text("S")
                            .font(.title)
                            .foregroundColor(.white)
                            .offset(y: 130)
                    }
                    HStack {
                        Text("W")
                            .font(.title)
                            .foregroundColor(.white)
                            .offset(x: -130)
                        Spacer()
                        Text("E")
                            .font(.title)
                            .foregroundColor(.white)
                            .offset(x: 130)
                    }
                    
                    // 指南针针
                    Image(systemName: "arrow.up.circle.fill")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundColor(Color.red)
                        .shadow(color: Color.red.opacity(0.7), radius: 10, x: 0, y: 0)
                        .rotationEffect(Angle(degrees: heading))
                        .animation(.easeInOut(duration: 0.7), value: heading)
                    
                    // 中心装饰
                    Circle()
                        .fill(Color.red)
                        .frame(width: 20, height: 20)
                        .shadow(radius: 5)
                    
                    // 较大的指示箭头
                    LargeIndicatorArrow()
                        .rotationEffect(Angle(degrees: heading))
                        .animation(.easeInOut(duration: 0.7), value: heading)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .fill(Color.black.opacity(0.2))
                        .blur(radius: 15)
                        .overlay(
                            RoundedRectangle(cornerRadius: 30)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
                .shadow(color: Color.black.opacity(0.5), radius: 20, x: 0, y: 10)
                
                Text(String(format: "%.2f°", heading))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 30)
                    .shadow(radius: 5)
                    .transition(.scale)
                    .animation(.easeInOut, value: heading)
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color.black.opacity(0.3))
                    .blur(radius: 10)
                    .shadow(radius: 10)
            )
            .padding()
        }
    }
    
    /// 较大的指示箭头视图
    struct LargeIndicatorArrow: View {
        var body: some View {
            Image(systemName: "arrowtriangle.up.fill")
                .resizable()
                .frame(width: 60, height: 60)
                .foregroundColor(Color.yellow.opacity(0.8))
                .shadow(color: Color.yellow.opacity(0.7), radius: 10, x: 0, y: 0)
                .offset(y: -15) // 调整箭头位置，使其位于中心稍上方
        }
    }
    
    struct DirectionView_Previews: PreviewProvider {
        static var previews: some View {
            DirectionView()
        }
    }
}
