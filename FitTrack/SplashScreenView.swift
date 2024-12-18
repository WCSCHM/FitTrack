import SwiftUI

struct SplashScreenView: View {
    @Binding var isActive: Bool
    @State private var animate = false
    
    var body: some View {
        ZStack {
            // 动态背景 - 多层渐变和动态粒子
            DynamicBackground()
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // 图形动画 - 旋转的多边形
                RotatingShape()
                    .frame(width: 100, height: 100)
                    .rotationEffect(Angle(degrees: animate ? 360 : 0))
                    .animation(Animation.linear(duration: 4).repeatForever(autoreverses: false), value: animate)
                
                // “Fit Track” 字样
                Text("Fit Track")
                    .font(.system(size: 50, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
                    .scaleEffect(animate ? 1.2 : 1.0)
                    .animation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: animate)
            }
        }
        .onAppear {
            self.animate = true
            // 在动画完成后延迟进入主界面
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                withAnimation {
                    self.isActive = false
                }
            }
        }
    }
}

// 动态背景视图，包含颜色渐变和粒子效果
struct DynamicBackground: View {
    @State private var animateGradient = false
    
    var body: some View {
        ZStack {
            // 渐变背景动画
            LinearGradient(gradient: Gradient(colors: animateGradient ? [Color.blue, Color.purple] : [Color.purple, Color.blue]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .animation(Animation.linear(duration: 10).repeatForever(autoreverses: true), value: animateGradient)
                .onAppear {
                    animateGradient.toggle()
                }
            
            // 粒子效果
            ParticleEmitterView()
                .blendMode(.overlay)
                .opacity(0.3)
        }
    }
}

// 粒子发射器视图
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

// 粒子模型
struct Particle: Identifiable {
    let id: UUID
    var position: CGPoint
    var velocity: CGVector
    var size: CGFloat
    var opacity: Float
    var blur: CGFloat
    var color: Color
}

// 自定义旋转图形视图
struct RotatingShape: View {
    var body: some View {
        ZStack {
            ForEach(0..<6) { i in
                Triangle()
                    .fill(Color.yellow.opacity(0.7))
                    .frame(width: 20, height: 40)
                    .offset(y: -20)
                    .rotationEffect(Angle(degrees: Double(i) * 60))
            }
        }
    }
}

// 自定义三角形形状
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY)) // 顶点
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY)) // 右下角
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY)) // 左下角
        path.closeSubpath()
        return path
    }
}

struct SplashScreenView_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreenView(isActive: .constant(true))
    }
}
