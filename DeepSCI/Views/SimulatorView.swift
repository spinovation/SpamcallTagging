import SwiftUI

struct MockCall: Identifiable {
    let id = UUID()
    let phoneNumber: String
    let callerName: String?
    let carrier: String
    let callType: CallType
    let timeAgo: String
    
    enum CallType {
        case incoming, missed, outgoing
    }
}

struct SimulatorView: View {
    @EnvironmentObject var manager: SpamManager
    @State private var mockCalls: [MockCall] = []
    @State private var selectedCallForTagging: MockCall? = nil
    @State private var showConfirmation: Bool = false
    @State private var confirmedCategory: String = ""
    @State private var showRateLimitAlert: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack {
                // Info banner explaining the sandbox limitation
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text("iOS Sandbox Simulation")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    Text("iOS prevents apps from reading your system call history directly. This simulator demonstrates how the one-tap tagging and CallKit identification works in a production flow.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(nil)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
                .padding()
                
                // Call log list
                if mockCalls.isEmpty {
                    ProgressView()
                        .onAppear(perform: loadMockCalls)
                } else {
                    List {
                        ForEach(mockCalls) { call in
                            HStack(spacing: 16) {
                                // Call type icon
                                Image(systemName: iconForCallType(call.callType))
                                    .foregroundColor(colorForCallType(call.callType))
                                    .frame(width: 24, height: 24)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(formatPhoneNumber(call.phoneNumber))
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    HStack(spacing: 6) {
                                        if let name = call.callerName {
                                            Text(name)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Text("•")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Text(call.carrier)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 8) {
                                    Text(call.timeAgo)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    
                                    // Quick Tag Button
                                    Button(action: {
                                        selectedCallForTagging = call
                                    }) {
                                        Text("Tag Call")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.red.opacity(0.8))
                                            .cornerRadius(8)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 4)
                            .listRowBackground(Color.white.opacity(0.02))
                            .listRowSeparatorTint(Color.white.opacity(0.08))
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Call Log Simulator")
            .sheet(item: $selectedCallForTagging) { call in
                TaggingSheet(phoneNumber: call.phoneNumber) { category in
                    submitTag(for: call.phoneNumber, category: category)
                }
                .presentationDetents([.fraction(0.45)])
            }
            .overlay {
                if showConfirmation {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.green)
                        
                        Text("Tag Submitted Successfully")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Tagged as \(confirmedCategory). Database and CallKit blocklists have been refreshed.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(24)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                    .shadow(radius: 10)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .alert("Already Tagged", isPresented: $showRateLimitAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("You have already reported this phone number within the last 24 hours. To prevent abuse, each number can only be tagged once per day.")
            }
        }
    }
    
    private func loadMockCalls() {
        mockCalls = [
            MockCall(
                phoneNumber: "+12065550121",
                callerName: "Amazon Order Security",
                carrier: "Sinclaire Telecom",
                callType: .missed,
                timeAgo: "2m ago"
            ),
            MockCall(
                phoneNumber: "+18005550199",
                callerName: "IRS Tax Administration",
                carrier: "Bandwidth.com",
                callType: .incoming,
                timeAgo: "15m ago"
            ),
            MockCall(
                phoneNumber: "+15105550187",
                callerName: "Oakland Delivery",
                carrier: "T-Mobile",
                callType: .incoming,
                timeAgo: "1h ago"
            ),
            MockCall(
                phoneNumber: "+13125550155",
                callerName: "Auto Warranty Center",
                carrier: "Twilio",
                callType: .missed,
                timeAgo: "3h ago"
            ),
            MockCall(
                phoneNumber: "+16505550149",
                callerName: "Palo Alto Dental",
                carrier: "AT&T Wireless",
                callType: .outgoing,
                timeAgo: "Yesterday"
            ),
            MockCall(
                phoneNumber: "+19175550130",
                callerName: nil,
                carrier: "Verizon Wireless",
                callType: .missed,
                timeAgo: "2 days ago"
            )
        ]
    }
    
    private func iconForCallType(_ type: MockCall.CallType) -> String {
        switch type {
        case .incoming: return "phone.arrow.down.left"
        case .missed: return "phone.arrow.down.left.fill"
        case .outgoing: return "phone.arrow.up.right"
        }
    }
    
    private func colorForCallType(_ type: MockCall.CallType) -> Color {
        switch type {
        case .incoming: return .green
        case .missed: return .red
        case .outgoing: return .blue
        }
    }
    
    private func submitTag(for phoneNumber: String, category: String) {
        // Submit Tag and check if it was accepted or rate-limited
        let didSubmit = manager.tagNumber(phoneNumber: phoneNumber, category: category, geoRegion: "206")
        
        selectedCallForTagging = nil
        
        if didSubmit {
            // Show overlay confirmation
            confirmedCategory = category
            
            withAnimation(.spring()) {
                showConfirmation = true
            }
            
            // Hide confirmation after 2.5s
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation {
                    showConfirmation = false
                }
            }
        } else {
            // Trigger rate limit alert
            showRateLimitAlert = true
        }
    }
}

// MARK: - Tagging Sheet Subview

struct TaggingSheet: View {
    let phoneNumber: String
    let onTagSelected: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Tag Number")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.red)
            }
            .padding(.top)
            
            Text("Select a category for \(phoneNumber):")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    CategoryButton(title: "Scam / Fraud", icon: "xmark.shield.fill", color: .red) {
                        onTagSelected("Scam/Fraud")
                    }
                    
                    CategoryButton(title: "Robocall", icon: "cpu", color: .purple) {
                        onTagSelected("Robocall")
                    }
                }
                
                HStack(spacing: 12) {
                    CategoryButton(title: "Telemarketing", icon: "phone.bubble.left.fill", color: .orange) {
                        onTagSelected("Spam/Telemarketing")
                    }
                    
                    CategoryButton(title: "Not Spam / Clean", icon: "checkmark.shield.fill", color: .green) {
                        onTagSelected("Not Spam")
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
    }
}

struct CategoryButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color.opacity(0.15))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
    }
}
