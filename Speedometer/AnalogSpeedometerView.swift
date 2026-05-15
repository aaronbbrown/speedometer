import SwiftUI

// Analog speedometer gauge resembling a car speedometer.
// Draws a circular dial with tick marks at 10-unit increments, a rotating needle,
// and displays the digital speed value at the bottom center.
struct AnalogSpeedometerView: View {
    let speed: Double
    let maxSpeed: Double = 120  // Dial goes from 0 to 120
    let unit: SpeedUnit
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // Circular background for the gauge
                Circle()
                    .fill(Color(red: 0.12, green: 0.15, blue: 0.25))
                    .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 4)
                
                // Draw tick marks and numbers around the dial
                Canvas { context, size in
                    drawDialMarkings(context: context, size: size)
                }
                
                // Center circle for visual appeal
                Circle()
                    .fill(Color(red: 0.07, green: 0.1, blue: 0.18))
                    .frame(width: 20, height: 20)
                
                // Rotating needle based on current speed
                Needle(speed: speed, maxSpeed: maxSpeed)
                    .stroke(Color.white, lineWidth: 4)
            }
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: 280)
            
            // Digital speed value positioned at the bottom
            VStack(spacing: 4) {
                Text(String(format: "%.1f", speed))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                
                Text(unit.label)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.75))
            }
            .padding(.top, 20)
        }
    }
    
    // Draw the dial markings: tick marks and numbers at 10-unit increments
    private func drawDialMarkings(context: GraphicsContext, size: CGSize) {
        let radius: CGFloat = 135
        let center = CGPoint(x: 140, y: 140)
        let tickRadius: CGFloat = 120
        let numberRadius: CGFloat = 100
        
        // Draw from 0 to 120 in 10-unit increments
        for i in stride(from: 0, through: 12, by: 1) {
            let value = Double(i) * 10
            // Convert value to angle: 0 is at lower-left (135°), 120 is at bottom-right (45°)
            // Total range is 270° for values 0-120
            let angleProgress = value / maxSpeed
            let angle = 135 + angleProgress * 270  // 135° to 405° (sweeps clockwise over the top)
            let radians = CGFloat(angle * .pi / 180)
            
            let tickStart = CGPoint(
                x: center.x + tickRadius * cos(radians),
                y: center.y + tickRadius * sin(radians)
            )
            let tickEnd = CGPoint(
                x: center.x + radius * cos(radians),
                y: center.y + radius * sin(radians)
            )
            
            // Draw tick mark
            var path = Path()
            path.move(to: tickStart)
            path.addLine(to: tickEnd)
            context.stroke(path, with: .color(.white.opacity(0.7)), lineWidth: 2)
            
            // Draw number labels at every other tick (0, 20, 40, ..., 120)
            if i % 2 == 0 {
                let numberPoint = CGPoint(
                    x: center.x + numberRadius * cos(radians),
                    y: center.y + numberRadius * sin(radians)
                )
                
                let text = Text("\(Int(value))")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
                
                context.draw(text, at: numberPoint, anchor: .center)
            }
        }
    }
}

// Needle shape that rotates based on the current speed
private struct Needle: Shape {
    let speed: Double
    let maxSpeed: Double
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        
        // Calculate needle angle: 0 is at lower-left (135°), maxSpeed is at bottom-right (45°)
        let angleProgress = min(speed / maxSpeed, 1.0)  // Clamp to 0-1
        let angle = 135 + angleProgress * 270  // 135° to 405° (sweeps clockwise over the top)
        let radians = CGFloat(angle * .pi / 180)
        
        // Needle length
        let needleLength: CGFloat = 110
        let needleEnd = CGPoint(
            x: center.x + needleLength * cos(radians),
            y: center.y + needleLength * sin(radians)
        )
        
        // Create a thin needle
        var path = Path()
        path.move(to: center)
        path.addLine(to: needleEnd)
        
        return path
    }
}

// Preview for development
#Preview {
    ZStack {
        LinearGradient(
            colors: [Color(red: 0.07, green: 0.1, blue: 0.18), Color(red: 0.14, green: 0.18, blue: 0.3)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        
        AnalogSpeedometerView(speed: 45.3, unit: .mph)
            .padding()
    }
}
