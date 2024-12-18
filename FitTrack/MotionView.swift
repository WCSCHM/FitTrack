import SwiftUI
import Charts

struct MotionView: View {
    @StateObject private var motionManager = MotionManager()
    
    // 数据数组用于图表展示
    @State private var accelerationData: [Double] = Array(repeating: 0.0, count: 60)
    @State private var rotationData: [Double] = Array(repeating: 0.0, count: 60)
    
    var body: some View {
        NavigationView {
            ZStack {
                // 动态背景
                AnimatedBackground()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // 加速度计数据卡片及图表
                        SensorCardView(
                            title: "加速度计数据",
                            icon: "arrow.up.arrow.down",
                            backgroundColor: Color.blue.opacity(0.2),
                            data: [
                                ("X", motionManager.accelerationX),
                                ("Y", motionManager.accelerationY),
                                ("Z", motionManager.accelerationZ)
                            ]
                        )
                        .overlay(
                            AccelerationChartView(data: accelerationData)
                                .frame(height: 150)
                                .clipShape(RoundedRectangle(cornerRadius: 15))
                                .padding([.top, .horizontal], 10),
                            alignment: .bottom
                        )
                        
                        // 陀螺仪数据卡片及图表
                        SensorCardView(
                            title: "陀螺仪数据",
                            icon: "gyroscope",
                            backgroundColor: Color.green.opacity(0.2),
                            data: [
                                ("X", motionManager.rotationRateX),
                                ("Y", motionManager.rotationRateY),
                                ("Z", motionManager.rotationRateZ)
                            ]
                        )
                        .overlay(
                            GyroscopeChartView(data: rotationData)
                                .frame(height: 150)
                                .clipShape(RoundedRectangle(cornerRadius: 15))
                                .padding([.top, .horizontal], 10),
                            alignment: .bottom
                        )
                        
                        // 装饰性图形
                        DecorativeShapesView()
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("移动")
            .onReceive(motionManager.$accelerationX) { _ in
                updateChartData()
            }
            .onAppear {
                motionManager.startUpdates()
            }
            .onDisappear {
                motionManager.stopUpdates()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // 更新图表数据
    private func updateChartData() {
        accelerationData.append(motionManager.accelerationX)
        if accelerationData.count > 60 {
            accelerationData.removeFirst()
        }
        
        rotationData.append(motionManager.rotationRateX)
        if rotationData.count > 60 {
            rotationData.removeFirst()
        }
    }
}

struct SensorCardView: View {
    var title: String
    var icon: String
    var backgroundColor: Color
    var data: [(String, Double)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.primary)
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            
            ForEach(data, id: \.0) { item in
                HStack {
                    Text("\(item.0):")
                        .font(.body)
                        .fontWeight(.medium)
                    Spacer()
                    Text(String(format: "%.2f", item.1))
                        .font(.body)
                        .foregroundColor(.secondary)
                        .animation(.easeInOut(duration: 0.5), value: item.1)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(backgroundColor)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
}

struct AccelerationChartView: View {
    var data: [Double]
    
    var body: some View {
        Chart {
            ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                LineMark(
                    x: .value("Time", index),
                    y: .value("Acceleration", value)
                )
                .interpolationMethod(.catmullRom)
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .foregroundStyle(Color.blue)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.3))
        )
    }
}

struct GyroscopeChartView: View {
    var data: [Double]
    
    var body: some View {
        Chart {
            ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                LineMark(
                    x: .value("Time", index),
                    y: .value("Rotation", value)
                )
                .interpolationMethod(.catmullRom)
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .foregroundStyle(Color.green)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.3))
        )
    }
}

struct DecorativeShapesView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            // 中心旋转的多边形
            PolygonShape(sides: 6)
                .stroke(LinearGradient(
                    gradient: Gradient(colors: [Color.purple, Color.blue]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ), lineWidth: 2)
                .frame(width: 100, height: 100)
                .rotationEffect(.degrees(animate ? 360 : 0))
                .animation(Animation.linear(duration: 10).repeatForever(autoreverses: false), value: animate)
                .onAppear {
                    animate = true
                }
            
            // 环绕的圆环
            Circle()
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [Color.red, Color.orange, Color.red]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 120, height: 120)
                .rotationEffect(.degrees(animate ? 360 : 0))
                .animation(Animation.linear(duration: 15).repeatForever(autoreverses: false), value: animate)
        }
        .padding()
    }
}

// 自定义多边形形状
struct PolygonShape: Shape {
    var sides: Int
    
    func path(in rect: CGRect) -> Path {
        guard sides >= 3 else { return Path() }
        
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let angle = (2 * Double.pi) / Double(sides)
        let radius = min(rect.width, rect.height) / 2
        
        var path = Path()
        for i in 0..<sides {
            let x = center.x + CGFloat(cos(Double(i) * angle - Double.pi / 2)) * radius
            let y = center.y + CGFloat(sin(Double(i) * angle - Double.pi / 2)) * radius
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        return path
    }
}

// 动态背景动画
struct AnimatedBackground: View {
    @State private var animate = false
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color("BackgroundTop"), Color("BackgroundMiddle"), Color("BackgroundBottom")]),
            startPoint: animate ? .topLeading : .bottomTrailing,
            endPoint: animate ? .bottomTrailing : .topLeading
        )
        .animation(Animation.linear(duration: 20).repeatForever(autoreverses: true), value: animate)
        .onAppear {
            animate = true
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct MotionView_Previews: PreviewProvider {
    static var previews: some View {
        MotionView()
            .preferredColorScheme(.light) // 预览浅色模式
        MotionView()
            .preferredColorScheme(.dark) // 预览深色模式
    }
}

