import SwiftUI

struct NumberDetailView: View {
    let number: SpamNumber
    @EnvironmentObject var manager: SpamManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingAppealAlert: Bool = false
    @State private var isAppealing: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                // MARK: - Hero Header Card
                VStack(spacing: 12) {
                    Text(formatPhoneNumber(number.phoneNumber))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(number.callerName ?? "Unknown / Self-Reported Spammer")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        // Threat level badge
                        Text(number.threatLabel(threshold: manager.escalationThreshold))
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(colorForTier(number.threatTier(threshold: manager.escalationThreshold)))
                            .cornerRadius(12)
                        
                        // Carrier
                        Text(number.carrier ?? "Unknown Carrier")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(8)
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
                .cornerRadius(24)
                
                // MARK: - Action Detail Card
                VStack(alignment: .leading, spacing: 12) {
                    Text("Action Status")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 12) {
                        Image(systemName: systemActionIcon)
                            .font(.title2)
                            .foregroundColor(colorForTier(number.threatTier(threshold: manager.escalationThreshold)))
                        
                        Text(systemActionDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(12)
                }
                .padding()
                .background(Color.white.opacity(0.04))
                .cornerRadius(16)
                
                // MARK: - Category Breakdown
                VStack(alignment: .leading, spacing: 16) {
                    Text("Report Category Breakdown")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if number.categoryBreakdown.isEmpty {
                        Text("No specific categories reported yet.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(number.categoryBreakdown.sorted(by: { $0.value > $1.value }), id: \.key) { cat, count in
                            VStack(spacing: 8) {
                                HStack {
                                    Text(cat == "Spam/Telemarketing" ? "Telemarketing" : cat)
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text("\(count) tags (\(percentString(count)))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                // Progress bar
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(Color.white.opacity(0.05))
                                            .frame(height: 8)
                                        
                                        Capsule()
                                            .fill(colorForCategory(cat))
                                            .frame(width: CGFloat(count) / CGFloat(number.totalTags) * geo.size.width, height: 8)
                                    }
                                }
                                .frame(height: 8)
                            }
                        }
                    }
                }
                .padding()
                .background(Color.white.opacity(0.04))
                .cornerRadius(16)
                
                // MARK: - Campaign Timing Analyzer
                VStack(alignment: .leading, spacing: 12) {
                    Text("Call Campaign Timing")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 12) {
                        Image(systemName: "clock.badge.exclamationmark")
                            .font(.title2)
                            .foregroundColor(.purple)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Peak Anomaly Window")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            Text(mockBurstTimeDescription)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(12)
                }
                .padding()
                .background(Color.white.opacity(0.04))
                .cornerRadius(16)
                
                // MARK: - Geographic Signal
                VStack(alignment: .leading, spacing: 12) {
                    Text("Geographical Analysis")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 12) {
                        Image(systemName: "map.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Reporting Area Origin")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            Text("Coarse Location: \(coarseGeoLocation) Area Code")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(12)
                }
                .padding()
                .background(Color.white.opacity(0.04))
                .cornerRadius(16)
                
                // MARK: - Porting & Reassignment Integrity
                VStack(alignment: .leading, spacing: 12) {
                    Text("Telecom Carrier Porting Info")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("DNO List Match")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(number.dnoMatched ? "YES (Do-Not-Originate)" : "NO")
                                .font(.headline)
                                .foregroundColor(number.dnoMatched ? .red : .green)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 6) {
                            Text("Reassignment Registry")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(number.reassignmentStatus ?? "Unknown")
                                .font(.headline)
                                .foregroundColor(reassignmentColor)
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(12)
                }
                .padding()
                .background(Color.white.opacity(0.04))
                .cornerRadius(16)
                
                // MARK: - Dispute Appeal Section
                VStack(spacing: 12) {
                    Text("Are you the owner of this number?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        showingAppealAlert = true
                    }) {
                        if isAppealing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Submit Unblock/Dispute Request")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                    }
                    .disabled(isAppealing)
                }
                .padding()
                .background(Color.blue.opacity(0.08))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                )
            }
            .padding()
        }
        .navigationTitle("Caller Details")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Dispute Verification", isPresented: $showingAppealAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Submit Attestation", role: .none) {
                submitDispute()
            }
        } message: {
            Text("By submitting this unblock request, you verify that this number belongs to a legitimate business or service entity and has been wrongly flagged. An automated check will clear this number.")
        }
    }
    
    // MARK: - Calculations
    
    private func percentString(_ count: Int) -> String {
        guard number.totalTags > 0 else { return "0%" }
        let pct = (Double(count) / Double(number.totalTags)) * 100
        return String(format: "%.0f%%", pct)
    }
    
    private var coarseGeoLocation: String {
        // Simple extraction of area code
        let cleanNum = number.phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        if cleanNum.count >= 4 {
            let start = cleanNum.index(cleanNum.startIndex, offsetBy: 1)
            let end = cleanNum.index(cleanNum.startIndex, offsetBy: 4)
            let areaCode = String(cleanNum[start..<end])
            
            switch areaCode {
            case "800", "888", "877", "866", "855", "844", "833": return "Toll-Free (\(areaCode))"
            case "212": return "New York, NY (\(areaCode))"
            case "312": return "Chicago, IL (\(areaCode))"
            case "415": return "San Francisco, CA (\(areaCode))"
            case "206": return "Seattle, WA (\(areaCode))"
            case "617": return "Boston, MA (\(areaCode))"
            case "305": return "Miami, FL (\(areaCode))"
            case "702": return "Las Vegas, NV (\(areaCode))"
            default: return "United States (\(areaCode))"
            }
        }
        return "National Carrier Gateway"
    }
    
    private var mockBurstTimeDescription: String {
        // Create a realistic-looking time pattern description
        let hash = abs(number.phoneNumber.hashValue) % 3
        switch hash {
        case 0: return "High burst traffic observed between 9:00 AM - 11:30 AM (ET). Over 2,000 call attempts/min reported across carrier peers."
        case 1: return "Continuous calling pattern. Standard 15-minute rotation interval. Primarily active 1:00 PM - 5:00 PM (PT)."
        default: return "Isolated spikes on weekdays. Heavy telemarketing bursts between 12:00 PM - 2:00 PM."
        }
    }
    
    private var systemActionIcon: String {
        switch number.threatTier(threshold: manager.escalationThreshold) {
        case 3: return "shield.slash.fill"
        case 2: return "bell.slash.fill"
        case 1: return "phone.badge.exclamationmark"
        default: return "phone.fill"
        }
    }
    
    private var systemActionDescription: String {
        switch number.threatTier(threshold: manager.escalationThreshold) {
        case 3: return "Blocked network-side. Call is blocked by iOS CallKit and reported to carrier attestation databases."
        case 2: return "Silenced. Call will be sent directly to the silent spam folder without showing notifications."
        case 1: return "Warning labeled. System will display a 'Suspected Spam: \(number.primaryCategory)' banner on incoming screens."
        default: return "No active blocking. Call is allowed to ring normally."
        }
    }
    
    private var reassignmentColor: Color {
        switch number.reassignmentStatus {
        case "Verified Active": return .green
        case "Recycled": return .yellow
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
    
    private func colorForCategory(_ category: String) -> Color {
        switch category {
        case "Scam/Fraud": return .red
        case "Robocall": return .purple
        case "Spam/Telemarketing": return .orange
        case "Not Spam": return .green
        default: return .secondary
        }
    }
    
    private func submitDispute() {
        isAppealing = true
        manager.submitAppeal(for: number.phoneNumber)
        
        // Simulate completion delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isAppealing = false
            dismiss()
        }
    }
}
