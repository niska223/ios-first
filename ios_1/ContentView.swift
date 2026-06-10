import SwiftUI
internal import Combine

struct ContentView: View {
    
    @State private var score = 0
    @State private var highScore = 0
    @State private var timeRemaining = 10
    @State private var isGameOver = false
    
    let gameTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    @State private var buttonColor: Color = .blue
    @State private var isBonusColor: Bool = true
    let colorTimer = Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack {
            if !isGameOver {
                
                VStack(spacing: 30) {
                    
                    HStack {
                        Text("Score: \(score)")
                            .font(.title)
                            .fontWeight(.bold)
                        Spacer()
                        Text("High Score: \(highScore)")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    
                    Spacer()
                    
                    Button(action: {
                        self.handleTap()
                    }) {
                        Text("TAP!")
                            .font(.largeTitle)
                            .fontWeight(.black)
                            .foregroundColor(.white)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 20)
                            .frame(width: 200 * buttonScaleFactor, height: 200 * buttonScaleFactor)
                            .background(buttonColor)
                            .clipShape(Circle())
                            .shadow(radius: 10)
                    }
                    .animation(.spring(), value: buttonScaleFactor)
                    .animation(.easeInOut, value: buttonColor)
                    
                    Spacer()
                    
                    Text("Time Remaining: \(timeRemaining)s")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(timeRemaining <= 3 ? .red : .primary)
                        .padding()
                }
                .onReceive(gameTimer) { _ in
                    self.decrementTimer()
                }
                .onReceive(colorTimer) { _ in
                    self.cycleButtonColor()
                }
                
            } else {
                
                VStack(spacing: 25) {
                    Text("Game Over")
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .foregroundColor(.red)
                    
                    if score == highScore && score > 0 {
                        Text("🎉 New High Score! 🎉")
                            .font(.title2)
                            .foregroundColor(.orange)
                            .fontWeight(.bold)
                    }
                    
                    Text("Final Score: \(score)")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Button(action: {
                        self.resetGame()
                    }) {
                        Text("Play Again")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                            .padding(.horizontal, 50)
                    }
                }
                .transition(.opacity)
            }
        }
        .padding()
    }
    
    
    private func handleTap() {
        
        if isBonusColor {
            score += 2
        } else {
            score = max(0, score - 1)
        }
    }
    
    private func decrementTimer() {
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            isGameOver = true
            if score > highScore {
                highScore = score
            }
        }
    }
    
    private func cycleButtonColor() {
        guard !isGameOver else { return }
        isBonusColor.toggle()
        buttonColor = isBonusColor ? .green : .gray
    }
    
    private var buttonScaleFactor: CGFloat {
        
        let progress = CGFloat(timeRemaining) / 10.0
        return max(0.4, progress)
    }
    
    private func resetGame() {
        score = 0
        timeRemaining = 10
        buttonColor = .green
        isBonusColor = true
        isGameOver = false
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
