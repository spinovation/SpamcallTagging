import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var manager: SpamManager
    @State private var isSpinning: Bool = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // MARK: - Header Title & Tagline
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Deep SCI")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("Deep Spam Call Identifier")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
                    .padding(.top, 8)
                    
                    // MARK: - Reputation Meter Card
                    VStack(spacing: 16) {
                        Text("Tagger Trust Level")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        ZStack {
                            // Track
                            Circle()
                                .stroke(Color.white.opacity(0.08), lineWidth: 14)
                                .frame(width: 140, height: 140)
                            
                            // Progress
                            Circle()
                                .trim(from: 0.0, to: CGFloat(manager.taggerReputation))
                                .stroke(
                                    LinearGradient(
                                        colors: [.orange, .red],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                                )
                                .frame(width: 140, height: 140)
                                .rotationEffect(Angle(degrees: -90))
                                .animation(.easeOut(duration: 1.0), value: manager.taggerReputation)
                            
                            // Text
                            VStack(spacing: 4) {
                                Text("\(Int(manager.taggerReputation * 100))%")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                Text("Trust Score")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Text(reputationStatusText)
                            .font(.caption)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.15))
                            .clipShape(Capsule())
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial)
                    .cornerRadius(24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    
                    // MARK: - Stats Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        StatCard(
                            title: "Total Flagged",
                            value: "\(manager.spamNumbers.count)",
                            icon: "phone.down.fill",
                            color: .red
                        )
                        
                        StatCard(
                            title: "Silenced (T2/T3)",
                            value: "\(manager.spamNumbers.filter { $0.threatTier(threshold: manager.escalationThreshold) >= 2 }.count)",
                            icon: "bell.slash.fill",
                            color: .orange
                        )
                        
                        StatCard(
                            title: "Your Tags",
                            value: "\(manager.userTags.count)",
                            icon: "tag.fill",
                            color: .blue
                        )
                        
                        StatCard(
                            title: "Escalation Target",
                            value: "\(manager.escalationThreshold) Tags",
                            icon: "slider.horizontal.3",
                            color: .purple
                        )
                    }
                    
                    // MARK: - Recent Global Activity
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Recent Reports Feed")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button(action: {
                                manager.syncData()
                            }) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.subheadline)
                                    .foregroundColor(.red)
                                    .rotationEffect(Angle(degrees: manager.isSyncing ? 360 : 0))
                                    .animation(manager.isSyncing ? .linear(duration: 1.0).repeatForever(autoreverses: false) : .default, value: manager.isSyncing)
                            }
                            .disabled(manager.isSyncing)
                        }
                        
                        if manager.spamNumbers.isEmpty {
                            VStack {
                                Text("No recent data. Tap Sync to retrieve.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, minHeight: 100)
                        } else {
                            // Sort by last updated
                            let recentFeed = manager.spamNumbers
                                .sorted(by: { $0.lastUpdated > $1.lastUpdated })
                                .prefix(5)
                            
                            ForEach(recentFeed) { num in
                                NavigationLink(value: num) {
                                    HStack(spacing: 16) {
                                        // Category Badge
                                        Image(systemName: iconForCategory(num.primaryCategory))
                                            .font(.title3)
                                            .foregroundColor(.white)
                                            .frame(width: 44, height: 44)
                                            .background(colorForCategory(num.primaryCategory).opacity(0.8))
                                            .clipShape(Circle())
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(num.phoneNumber)
                                                .font(.headline)
                                                .foregroundColor(.white)
                                            Text(num.callerName ?? "Unknown Name")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing, spacing: 4) {
                                            Text("\(num.totalTags) tags")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(colorForTier(num.threatTier(threshold: manager.escalationThreshold)).opacity(0.2))
                                                .cornerRadius(8)
                                            
                                            Text(timeAgo(num.lastUpdated))
                                                .font(.system(size: 10))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(16)
                                    .background(Color.white.opacity(0.04))
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                                    )
                                }
                            }
                        }
                    }
                    .padding(.top, 8)
                }
                .padding()
            }
            .navigationTitle("")
            .navigationDestination(for: SpamNumber.self) { num in
                NumberDetailView(number: num)
            }
        }
    }
    
    private var reputationStatusText: String {
        if manager.taggerReputation >= 0.90 {
            return "Elite Contributor"
        } else if manager.taggerReputation >= 0.80 {
            return "Trusted Member"
        } else if manager.taggerReputation >= 0.50 {
            return "Standard Account"
        } else {
            return "Low Trust (Under Review)"
        }
    }
    
    private func iconForCategory(_ category: String) -> String {
        switch category {
        case "Scam/Fraud": return "xmark.shield.fill"
        case "Robocall": return "cpu"
        case "Spam/Telemarketing": return "phone.bubble.left.fill"
        case "Not Spam": return "checkmark.shield.fill"
        default: return "questionmark.circle.fill"
        }
    }
    
    private func colorForCategory(_ category: String) -> Color {
        switch category {
        case "Scam/Fraud": return .red
        case "Robocall": return .purple
        case "Spam/Telemarketing": return .orange
        case "Not Spam": return .green
        default: return .secondary
        }
    }
    
    private func colorForTier(_ tier: Int) -> Color {
        switch tier {
        case 3: return .red
        case 2: return .orange
        case 1: return .yellow
        default: return .secondary
        }
    }
    
    private func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Subviews

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.04))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}
