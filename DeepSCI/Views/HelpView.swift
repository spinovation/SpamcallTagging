import SwiftUI

struct HelpView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // MARK: - Banner Header
                    VStack(spacing: 12) {
                        Image(systemName: "questionmark.key.ring.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.red)
                            .padding(.top)
                        
                        Text("How Can We Help?")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Deep SCI Support Guide & FAQs")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white.opacity(0.02))
                    .cornerRadius(16)
                    
                    // MARK: - Quick Guide Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Quick Start Guide")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        GuideRow(step: "1", title: "Enable Extension", desc: "Go to iOS Settings > Phone > Call Blocking & Identification and enable 'Deep SCI'.")
                        GuideRow(step: "2", title: "Sync Data", desc: "Open Settings tab and tap 'Sync with Network Now' to load the latest global spam blocklist.")
                        GuideRow(step: "3", title: "Flag Spammers", desc: "Use the Simulator or the manual '+' button in the Directory to report new spam numbers.")
                    }
                    .padding()
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(16)
                    
                    // MARK: - FAQ Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Frequently Asked Questions")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        FaqRow(q: "How does silent blocking work?", a: "Calls from spammers that cross the report threshold are automatically silenced by iOS and sent to voicemail without ringing.")
                        FaqRow(q: "Is my privacy protected?", a: "Yes. Deep SCI never uploads your contacts, reads your SMS, or scans call audio. Tagging is 100% metadata-only and pseudonymous.")
                        FaqRow(q: "How do I report a false positive?", a: "Locate the number in the Directory, tap into it, and select 'Submit Unblock/Dispute Request' at the bottom.")
                    }
                    .padding()
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(16)
                    
                    // MARK: - Contact Section
                    VStack(spacing: 16) {
                        Text("Need Further Assistance?")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("If you have any questions, feedback, or need support with the app, we are here to help.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            // Primary Web Support Form
                            Link(destination: URL(string: "https://docs.google.com/forms/d/13CRQ9jmb16aVFZFT4Td5FRRR6nxrHa7VjW0rJk5YhE0/viewform")!) {
                                HStack(spacing: 8) {
                                    Image(systemName: "safari.fill")
                                    Text("Open Support Form")
                                        .fontWeight(.bold)
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                            
                            // Secondary Email Support
                            Link(destination: URL(string: "mailto:sridhargs@gmail.com?subject=Deep%20SCI%20Feedback%20%26%20Support")!) {
                                HStack(spacing: 8) {
                                    Image(systemName: "envelope.fill")
                                    Text("Send Email Support")
                                        .fontWeight(.semibold)
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(16)
                    .padding(.bottom, 20)
                }
                .padding()
            }
            .navigationTitle("Help & Support")
        }
    }
}

struct GuideRow: View {
    let step: String
    let title: String
    let desc: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(step)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color.red)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                Text(desc)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct FaqRow: View {
    let q: String
    let a: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(q)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.red)
            Text(a)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
