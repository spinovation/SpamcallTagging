import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var manager: SpamManager
    @State private var showingResetAlert = false
    @State private var userId: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                
                // MARK: - Escalation Settings
                Section("Escalation Parameters") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Escalation Threshold")
                                .foregroundColor(.white)
                            Spacer()
                            Text("\(manager.escalationThreshold) Tags")
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                        }
                        
                        Slider(
                            value: Binding(
                                get: { Double(manager.escalationThreshold) },
                                set: { manager.updateThreshold(Int($0)) }
                            ),
                            in: 3...30,
                            step: 1
                        )
                        .tint(.red)
                        
                        Text("Number of unique user reports required to silence a number (Tier 2). Lower thresholds are more aggressive. Default is 10.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Color.white.opacity(0.02))
                
                // MARK: - CallKit Extension Info
                Section("iOS System Blocklist") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundColor(.green)
                            Text("SpamCallDirectory Extension")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        
                        Text("To enable system-level blocking, you must turn on the extension in your iPhone Settings:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("1. Open Settings app")
                            Text("2. Navigate to Phone")
                            Text("3. Tap Call Blocking & Identification")
                            Text("4. Toggle 'Deep SCI' to ENABLED")
                        }
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.vertical, 4)
                        
                        Button(action: {
                            manager.reloadCallDirectoryExtension()
                        }) {
                            Text("Refresh CallKit Extension")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Color.white.opacity(0.02))
                
                // MARK: - Privacy & Identity
                Section("Tagger Profile") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pseudonymous User ID")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        HStack {
                            Text(userId)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Button(action: {
                                UIPasteboard.general.string = userId
                            }) {
                                Image(systemName: "doc.on.doc.fill")
                                    .foregroundColor(.red)
                            }
                        }
                        
                        Text("This ID is generated locally and stored securely in the iOS Keychain. It keeps your submissions anonymous and prevents spam-farm flooding.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Color.white.opacity(0.02))
                
                // MARK: - Diagnostic Data / Reset
                Section("Diagnostics") {
                    HStack {
                        Text("Cached Spam Entries")
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(manager.spamNumbers.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("User Tags Logged")
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(manager.userTags.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Sync with Network Now") {
                        manager.syncData()
                    }
                    .foregroundColor(.red)
                    
                    Button("Clear Database Cache", role: .destructive) {
                        showingResetAlert = true
                    }
                }
                .listRowBackground(Color.white.opacity(0.02))
            }
            .navigationTitle("Settings")
            .onAppear {
                userId = KeychainManager.shared.getOrCreateUserId()
            }
            .alert("Confirm Clear Cache", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    resetDatabase()
                }
            } message: {
                Text("This will wipe all cached spam reports and user tags from this device. The directory will re-seed on next sync.")
            }
        }
    }
    
    private func resetDatabase() {
        DatabaseManager.shared.saveSpamNumbers([])
        DatabaseManager.shared.saveUserTags([])
        manager.loadLocalData()
        manager.calculateUserReputation()
        manager.reloadCallDirectoryExtension()
    }
}
