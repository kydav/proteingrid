import SwiftUI

struct ContentView: View {
    @StateObject private var store = ProteinStore()
    @State private var showingCustomLog = false

    private var progress: Double {
        guard store.dailyGoal > 0 else { return 0 }
        return min(store.todayTotal / store.dailyGoal, 1.0)
    }

    var body: some View {
        if store.isUnlocked {
            ScrollView {
                VStack(spacing: 14) {
                    progressRing
                    if store.streak > 0 { streakBadge }
                    quickLogButtons
                    customButton
                }
                .padding(.horizontal, 4)
                .padding(.top, 8)
            }
            .sheet(isPresented: $showingCustomLog) {
                CustomLogView(store: store)
            }
        } else {
            VStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 28))
                Text("Unlock in the\nProteinGrid app")
                    .multilineTextAlignment(.center)
                    .font(.system(size: 12))
                Divider()
                Text("session: \(store.debugSessionState)")
                    .font(.system(size: 9, design: .monospaced))
                Text("ctx: \(store.debugContextKeys)")
                    .font(.system(size: 9, design: .monospaced))
                Text("ud: \(store.debugDefaultsValue)")
                    .font(.system(size: 9, design: .monospaced))
                Button("Request State") { store.requestStateFromPhone() }
                    .font(.system(size: 10))
            }
            .foregroundColor(.gray)
        }
    }

    // MARK: - Sub-views

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(Color.green.opacity(0.18), lineWidth: 9)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color.green,
                    style: StrokeStyle(lineWidth: 9, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.4), value: progress)
            VStack(spacing: 1) {
                Text("\(Int(store.todayTotal))g")
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(.green)
                Text("/ \(Int(store.dailyGoal))g")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.gray)
            }
        }
        .frame(width: 110, height: 110)
    }

    private var streakBadge: some View {
        Label("\(store.streak) day streak", systemImage: "flame.fill")
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.orange)
    }

    private var quickLogButtons: some View {
        HStack(spacing: 6) {
            QuickLogButton(label: "+30g") { store.log(grams: 30) }
            QuickLogButton(label: "+40g") { store.log(grams: 40) }
            QuickLogButton(label: "+50g") { store.log(grams: 50) }
        }
    }

    private var customButton: some View {
        Button("Custom amount") { showingCustomLog = true }
            .font(.system(size: 13))
            .foregroundColor(.green)
            .padding(.bottom, 4)
    }
}

// MARK: - Quick log button

struct QuickLogButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(Color.green)
                .cornerRadius(9)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Custom log sheet

struct CustomLogView: View {
    @ObservedObject var store: ProteinStore
    @State private var grams: Int = 25
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 10) {
            Text("Log protein")
                .font(.headline)
                .padding(.top, 8)

            Picker("Grams", selection: $grams) {
                ForEach(stride(from: 5, through: 250, by: 5).map { $0 }, id: \.self) { g in
                    Text("\(g)g").tag(g)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 90)

            Button("Log \(grams)g") {
                store.log(grams: Double(grams))
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .foregroundColor(.black)
        }
        .padding(.horizontal)
    }
}

#Preview {
    ContentView()
}
