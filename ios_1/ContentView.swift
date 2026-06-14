import SwiftUI
import Combine

// MARK: - Models & Enums

enum GameMode: String {
    case tapFrenzy = "Tap Frenzy"
    case lightItUp = "Light It Up"
}

enum Level: Int, CaseIterable {
    case L1 = 1, L2, L3, L4
    
    var cardCount: Int {
        switch self {
        case .L1: return 3
        case .L2: return 4
        case .L3: return 6
        case .L4: return 9
        }
    }
    
    var litDuration: Double {
        switch self {
        case .L1: return 1.5
        case .L2: return 1.2
        case .L3: return 1.0
        case .L4: return 0.8
        }
    }
    
    var columns: [GridItem] {
        switch self {
        case .L1:
            return [GridItem(.adaptive(minimum: 80))]
        case .L2:
            return Array(repeating: GridItem(.flexible(), spacing: 15), count: 2)
        case .L3, .L4:
            return Array(repeating: GridItem(.flexible(), spacing: 15), count: 3)
        }
    }
    
    var glowColor: Color {
        switch self {
        case .L1: return .green
        case .L2: return .blue
        case .L3: return .orange
        case .L4: return .purple
        }
    }
}

struct Card: Identifiable {
    let id = UUID()
    var isLit: Bool = false
}

// MARK: - Main Home Screen

struct ContentView: View {
    @AppStorage("roundLengthSetting") private var roundLength: Int = 60
    @State private var showSettings = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    Text("Light It Up & Frenzy")
                        .font(.largeTitle)
                        .bold()
                        .multilineTextAlignment(.center)
                    
                    VStack(spacing: 20) {
                        NavigationLink(value: GameMode.tapFrenzy) {
                            MenuButton(title: "Play Tap Frenzy", subtitle: "Tap as fast as you can!", color: .orange)
                        }
                        
                        NavigationLink(value: GameMode.lightItUp) {
                            MenuButton(title: "Play Light It Up", subtitle: "Whack-a-mole style. Watch the glow!", color: .indigo)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    Button(action: { showSettings = true }) {
                        Label("Settings", systemImage: "gearshape.fill")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationDestination(for: GameMode.self) { mode in
                switch mode {
                case .tapFrenzy:
                    TapFrenzyView(totalRoundTime: Double(roundLength))
                case .lightItUp:
                    LightItUpView(totalRoundTime: Double(roundLength))
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsSheetView(roundLength: $roundLength)
            }
        }
    }
}

struct MenuButton: View {
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title2)
                .bold()
            Text(subtitle)
                .font(.subheadline)
                .opacity(0.8)
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color)
        .cornerRadius(15)
        .shadow(radius: 5)
    }
}

// MARK: - Settings Sheet

struct SettingsSheetView: View {
    @Binding var roundLength: Int
    @Environment(\.dismiss) var dismiss
    
    let options = [30, 60, 90]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Game Configuration")) {
                    // FIXED: Properly explicitly identified id keypath using \.self
                    Picker("Round Length", selection: $roundLength) {
                        ForEach(options, id: \.self) { length in
                            Text("\(length) Seconds")
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Game Mode 1: Tap Frenzy (Week 1 Code Wrapper)

struct TapFrenzyView: View {
    let totalRoundTime: Double
    @AppStorage("highScore_tapFrenzy") private var highScore: Int = 0
    
    @State private var score = 0
    @State private var timeRemaining: Double
    @State private var gameActive = true
    
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    init(totalRoundTime: Double) {
        self.totalRoundTime = totalRoundTime
        _timeRemaining = State(initialValue: totalRoundTime)
    }
    
    var body: some View {
        VStack(spacing: 40) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Score: \(score)")
                        .font(.title)
                        .bold()
                    Text("High Score: \(highScore)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(String(format: "Time: %.1fs", timeRemaining))
                    .font(.title2)
                    .monospacedDigit()
            }
            .padding()
            
            Spacer()
            
            if gameActive {
                Button(action: { score += 1 }) {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 200, height: 200)
                        .overlay(Text("TAP!").font(.largeTitle).bold().foregroundColor(.white))
                        .shadow(radius: 10)
                }
            } else {
                VStack(spacing: 20) {
                    Text("Game Over!")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.red)
                    
                    if score > highScore {
                        Text("New High Score 🎉")
                            .font(.title2)
                            .foregroundColor(.green)
                    }
                    
                    Button("Play Again") {
                        resetGame()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            
            Spacer()
        }
        .navigationTitle("Tap Frenzy")
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(timer) { _ in
            guard gameActive else { return }
            if timeRemaining > 0 {
                timeRemaining -= 0.1
            } else {
                gameActive = false
                timeRemaining = 0
                if score > highScore {
                    highScore = score
                }
            }
        }
    }
    
    func resetGame() {
        score = 0
        timeRemaining = totalRoundTime
        gameActive = true
    }
}

// MARK: - Game Mode 2: Light It Up View (Week 2 Assignment)

struct LightItUpView: View {
    let totalRoundTime: Double
    @AppStorage("highScore_lightItUp") private var highScore: Int = 0
    
    // Game States
    @State private var score = 0
    @State private var lives = 3
    @State private var timeElapsed: Double = 0.0
    @State private var currentLevel: Level = .L1
    @State private var cards: [Card] = []
    @State private var gameActive = true
    @State private var showLevelUpFlash = false
    
    // Core Tick Timers
    let masterTimer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    @State private var nextTickTime: Double = 0.0
    
    init(totalRoundTime: Double) {
        self.totalRoundTime = totalRoundTime
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                // Header HUD UI
                HStack {
                    VStack(alignment: .leading) {
                        Text("Score: \(score)")
                            .font(.title2).bold()
                        Text("High Score: \(highScore)")
                            .font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                    
                    VStack {
                        Text("Level \(currentLevel.rawValue)")
                            .font(.headline)
                            .foregroundColor(currentLevel.glowColor)
                        Text(String(format: "Time: %.1fs", max(0, totalRoundTime - timeElapsed)))
                            .font(.subheadline).monospacedDigit()
                    }
                    
                    Spacer()
                    
                    // FIXED: Explicit identity identifier provided to safely loop integers 0, 1, 2
                    HStack(spacing: 4) {
                        ForEach(0..<3, id: \.self) { index in
                            Image(systemName: index < lives ? "heart.fill" : "heart")
                                .foregroundColor(.red)
                                .font(.title3)
                        }
                    }
                }
                .padding()
                
                Spacer()
                
                // Whack-A-Mole Cards Adaptive Grid
                if gameActive {
                    LazyVGrid(columns: currentLevel.columns, spacing: 15) {
                        ForEach(cards) { card in
                            CardView(card: card, glowColor: currentLevel.glowColor) {
                                handleTap(on: card)
                            }
                        }
                    }
                    .padding(25)
                    .animation(.easeInOut, value: currentLevel)
                } else {
                    // Game Over Screen
                    VStack(spacing: 25) {
                        Text("Game Over")
                            .font(.largeTitle).bold()
                            .foregroundColor(.red)
                        
                        Text("Final Score: \(score)")
                            .font(.title2)
                        
                        if score > highScore {
                            Text("👑 New High Score! 👑")
                                .font(.headline)
                                .foregroundColor(.green)
                        }
                        
                        Button(action: { resetGame() }) {
                            Text("Try Again")
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: 200)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                }
                
                Spacer()
            }
            .blur(radius: showLevelUpFlash ? 3 : 0)
            
            // Level-up Flash Overlay
            if showLevelUpFlash {
                Color(currentLevel.glowColor)
                    .opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                    .overlay(
                        VStack {
                            Text("LEVEL UP!")
                                .font(.system(size: 44, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                                .shadow(radius: 10)
                            Text("Speeding Up...")
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.9))
                        }
                    )
                    .transition(.opacity)
            }
        }
        .navigationTitle("Light It Up")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { resetGame() }
        .onReceive(masterTimer) { _ in
            guard gameActive else { return }
            
            timeElapsed += 0.1
            
            if timeElapsed >= totalRoundTime || lives <= 0 {
                endGame()
                return
            }
            
            updateLevelProgression()
            
            if timeElapsed >= nextTickTime {
                processTick()
                nextTickTime = timeElapsed + currentLevel.litDuration
            }
        }
    }
    
    // MARK: - Game Sub-Systems
    
    private func resetGame() {
        score = 0
        lives = 3
        timeElapsed = 0.0
        currentLevel = .L1
        gameActive = true
        showLevelUpFlash = false
        setupCards()
        nextTickTime = 0.0
    }
    
    private func setupCards() {
        cards = (0..<currentLevel.cardCount).map { _ in Card() }
    }
    
    private func updateLevelProgression() {
        let percentage = timeElapsed / totalRoundTime
        let targetLevel: Level
        
        if percentage < 0.25 { targetLevel = .L1 }
        else if percentage < 0.50 { targetLevel = .L2 }
        else if percentage < 0.75 { targetLevel = .L3 }
        else { targetLevel = .L4 }
        
        if targetLevel != currentLevel {
            currentLevel = targetLevel
            setupCards()
            triggerLevelUpFlash()
        }
    }
    
    private func triggerLevelUpFlash() {
        withAnimation(.easeInOut(duration: 0.15)) { showLevelUpFlash = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.15)) { showLevelUpFlash = false }
        }
    }
    
    private func processTick() {
        let missedAny = cards.contains { $0.isLit }
        if missedAny && timeElapsed > currentLevel.litDuration {
            applyPenalty()
        }
        
        for i in 0..<cards.count { cards[i].isLit = false }
        
        guard !cards.isEmpty else { return }
        
        let litCount = currentLevel == .L4 ? 2 : 1
        var chosenIndices = Set<Int>()
        
        while chosenIndices.count < min(litCount, cards.count) {
            let randomIndex = Int.random(in: 0..<cards.count)
            chosenIndices.insert(randomIndex)
        }
        
        // FIXED: Swapped out broken .explicitSequence structure with standard robust Swift UI .easeIn layout blocks
        withAnimation(.easeIn(duration: 0.1)) {
            for index in chosenIndices {
                cards[index].isLit = true
            }
        }
    }
    
    private func handleTap(on card: Card) {
        guard gameActive, let index = cards.firstIndex(where: { $0.id == card.id }) else { return }
        
        if cards[index].isLit {
            score += 10
            withAnimation(.easeOut(duration: 0.1)) {
                cards[index].isLit = false
            }
        } else {
            applyPenalty()
        }
    }
    
    private func applyPenalty() {
        guard gameActive else { return }
        lives -= 1
        if lives <= 0 {
            endGame()
        }
    }
    
    private func endGame() {
        gameActive = false
        if score > highScore {
            highScore = score
        }
    }
}

// MARK: - Game Grid Component Block

struct CardView: View {
    let card: Card
    let glowColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            RoundedRectangle(cornerRadius: 12)
                .fill(card.isLit ? glowColor : Color(.secondarySystemFill))
                .aspectRatio(1.0, contentMode: .fit)
                .scaleEffect(card.isLit ? 1.04 : 1.0)
                .shadow(color: card.isLit ? glowColor.opacity(0.8) : Color.clear, radius: card.isLit ? 12 : 0)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(card.isLit ? Color.white.opacity(0.5) : Color.clear, lineWidth: 1.5)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Canvas Preview Preview
#Preview {
    ContentView()
}
