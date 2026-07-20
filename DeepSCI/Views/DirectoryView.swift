import SwiftUI
import UIKit

struct DirectoryView: View {
    @EnvironmentObject var manager: SpamManager
    @State private var searchText: String = ""
    @State private var selectedCategory: String = "All"
    @State private var selectedTier: Int = 0 // 0 = All, 1 = Tier 1, 2 = Tier 2, 3 = Tier 3
    @State private var sortBy: SortOption = .recency
    @State private var showManualReportSheet: Bool = false
    
    // Version 1.1 State variables for Global Search Lookup
    @State private var isSearchingGlobally: Bool = false
    @State private var showingPurchasePrompt: Bool = false
    @State private var globalLookupResult: SpamNumber? = nil
    @State private var showingResultAlert: Bool = false
    
    enum SortOption {
        case volume, recency, number
    }
    
    let categories = ["All", "My Tags", "Scam", "Robocall", "Marketing", "Safe"]
    
    var filteredNumbers: [SpamNumber] {
        let cleanSearch = searchText.filter { $0.isNumber }
        
        return manager.spamNumbers.filter { num in
            let cleanNum = num.phoneNumber.filter { $0.isNumber }
            
            // Search Match: matches digits format-insensitively, or exact string, or caller name
            let searchMatch = searchText.isEmpty || 
                (!cleanSearch.isEmpty && cleanNum.contains(cleanSearch)) ||
                num.phoneNumber.contains(searchText) ||
                (num.callerName?.localizedCaseInsensitiveContains(searchText) ?? false)
            
            // Category Match
            let categoryMatch: Bool
            if selectedCategory == "All" {
                categoryMatch = true
            } else if selectedCategory == "My Tags" {
                categoryMatch = num.isUserFlagged
            } else if selectedCategory == "Safe" {
                categoryMatch = num.primaryCategory == "Not Spam"
            } else {
                let dbKey: String
                switch selectedCategory {
                case "Scam": dbKey = "Scam/Fraud"
                case "Marketing": dbKey = "Spam/Telemarketing"
                default: dbKey = selectedCategory // "Robocall"
                }
                categoryMatch = num.categoryBreakdown[dbKey] != nil
            }
            
            // Tier Match
            let tierMatch = selectedTier == 0 || 
                num.threatTier(threshold: manager.escalationThreshold) == selectedTier
            
            return searchMatch && categoryMatch && tierMatch
        }
        .sorted { (lhs, rhs) -> Bool in
            switch sortBy {
            case .volume:
                return lhs.totalTags > rhs.totalTags
            case .recency:
                return lhs.lastUpdated > rhs.lastUpdated
            case .number:
                return lhs.phoneNumber < rhs.phoneNumber
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                // MARK: - Search & Filters Header
                VStack(spacing: 12) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search number or company...", text: $searchText)
                            .keyboardType(.namePhonePad)
                            .autocorrectionDisabled()
                        
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(10)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Category Chips (Horizontal Scroll to prevent vertical wrapping)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(categories, id: \.self) { cat in
                                Button(action: {
                                    selectedCategory = cat
                                }) {
                                    Text(cat)
                                        .font(.system(size: 12, weight: .semibold))
                                        .lineLimit(1)
                                        .fixedSize(horizontal: true, vertical: false)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(selectedCategory == cat ? Color.red : Color.white.opacity(0.05))
                                        .foregroundColor(selectedCategory == cat ? .white : .secondary)
                                        .cornerRadius(16)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Tier & Sort Selection Row
                    HStack {
                        // Threat level filter
                        Menu {
                            Picker("Threat Level", selection: $selectedTier) {
                                Text("All Levels").tag(0)
                                Text("Tier 1: Suspected").tag(1)
                                Text("Tier 2: Silenced").tag(2)
                                Text("Tier 3: Blocked").tag(3)
                            }
                        } label: {
                            HStack {
                                Text(tierFilterLabel)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 8))
                            }
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(8)
                        }
                        
                        Spacer()
                        
                        // Sort selector
                        Menu {
                            Picker("Sort By", selection: $sortBy) {
                                Text("Tag Volume").tag(SortOption.volume)
                                Text("Last Active").tag(SortOption.recency)
                                Text("Phone Number").tag(SortOption.number)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "arrow.up.arrow.down")
                                    .font(.system(size: 10))
                                Text(sortLabel)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 6)
                .background(Color(.systemBackground).opacity(0.8))
                
                // MARK: - Directory List
                if filteredNumbers.isEmpty {
                    VStack(spacing: 24) {
                        if isSearchTextAPhoneNumber {
                            VStack(spacing: 16) {
                                Image(systemName: "magnifyingglass.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.red)
                                
                                Text("Search Global Spam Registry")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text("This number is not in your local database. You can perform a real-time carrier lookup.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                                
                                VStack(spacing: 4) {
                                    Text("Free Monthly Lookups: \(manager.freeLookupsLeft)")
                                    Text("Purchased Credits: \(manager.purchasedCredits)")
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 4)
                                
                                if isSearchingGlobally {
                                    ProgressView("Querying CNAM Registry...")
                                        .tint(.red)
                                        .foregroundColor(.white)
                                        .padding()
                                } else {
                                    Button(action: {
                                        performGlobalSearchLookup()
                                    }) {
                                        Text("Lookup Globally")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 24)
                                            .padding(.vertical, 12)
                                            .background(Color.red)
                                            .cornerRadius(10)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.04))
                            .cornerRadius(16)
                            .padding(.horizontal)
                        } else {
                            Image(systemName: "phone.slash")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            Text("No Flagged Numbers Found")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredNumbers) { num in
                            NavigationLink(value: num) {
                                DirectoryRowView(number: num, threshold: manager.escalationThreshold)
                            }
                            .listRowBackground(Color.white.opacity(0.02))
                            .listRowSeparatorTint(Color.white.opacity(0.08))
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Spam Directory")
            .navigationDestination(for: SpamNumber.self) { num in
                NumberDetailView(number: num)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showManualReportSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(.red)
                    }
                }
            }
            .sheet(isPresented: $showManualReportSheet) {
                ManualReportSheet { phone, category in
                    // Clean and submit
                    manager.tagNumber(phoneNumber: phone, category: category, geoRegion: "Manual")
                }
                .presentationDetents([.fraction(0.65)])
            }
            .alert("Search Results Found", isPresented: $showingResultAlert, presenting: globalLookupResult) { num in
                Button("View Details") {
                    searchText = num.phoneNumber
                }
                Button("Done", role: .cancel) { }
            } message: { num in
                Text("Number: \(num.phoneNumber)\nCaller: \(num.callerName ?? "Unknown")\nCarrier: \(num.carrier ?? "Unknown")\n\nThis number has been added to your local database directory.")
            }
            .sheet(isPresented: $showingPurchasePrompt) {
                VStack(spacing: 24) {
                    Image(systemName: "creditcard.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.red)
                    
                    Text("Out of Lookup Credits")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("You have used all your free monthly lookups. Purchase a 10-lookup credit pack to continue checking numbers globally.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    
                    Button(action: {
                        manager.buyCreditPack()
                        showingPurchasePrompt = false
                    }) {
                        Text("Buy 10 Credits for $0.99")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(12)
                    }
                    
                    Button("Cancel", role: .cancel) {
                        showingPurchasePrompt = false
                    }
                    .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGray6))
                .presentationDetents([.fraction(0.45)])
            }
        }
    }
    
    private var tierFilterLabel: String {
        switch selectedTier {
        case 3: return "Tier 3 Only"
        case 2: return "Tier 2 Only"
        case 1: return "Tier 1 Only"
        default: return "All Tiers"
        }
    }
    
    private var sortLabel: String {
        switch sortBy {
        case .volume: return "Sort: Volume"
        case .recency: return "Sort: Recent"
        case .number: return "Sort: Number"
        }
    }
    
    // MARK: - Version 1.1 Global Search Helpers
    
    private var isSearchTextAPhoneNumber: Bool {
        let clean = searchText.filter { $0.isNumber }
        return clean.count >= 7
    }
    
    private func performGlobalSearchLookup() {
        guard manager.freeLookupsLeft > 0 || manager.purchasedCredits > 0 else {
            showingPurchasePrompt = true
            return
        }
        
        isSearchingGlobally = true
        manager.performGlobalLookup(phoneNumber: searchText) { result in
            DispatchQueue.main.async {
                self.isSearchingGlobally = false
                switch result {
                case .success(let number):
                    self.globalLookupResult = number
                    self.showingResultAlert = true
                case .failure(let error):
                    print("Global lookup error: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - List Row Subview

struct DirectoryRowView: View {
    let number: SpamNumber
    let threshold: Int
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(formatPhoneNumber(number.phoneNumber))
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if number.dnoMatched {
                        Text("DNO")
                            .font(.system(size: 8, weight: .bold))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                }
                
                HStack(spacing: 6) {
                    Text(number.callerName ?? "Self-Reported Spammer")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(number.carrier ?? "Unknown Carrier")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(number.totalTags) tags")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(colorForTier(number.threatTier(threshold: threshold)))
                
                Text(tierName(number.threatTier(threshold: threshold)))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func colorForTier(_ tier: Int) -> Color {
        switch tier {
        case 3: return .red
        case 2: return .orange
        case 1: return .yellow
        default: return .secondary
        }
    }
    
    private func tierName(_ tier: Int) -> String {
        switch tier {
        case 3: return "Blocked"
        case 2: return "Silenced"
        case 1: return "Suspected"
        default: return "Low Risk"
        }
    }
}

// MARK: - Manual Report Sheet Subview

struct ManualReportSheet: View {
    @State private var phoneNumber: String = ""
    @State private var selectedCategory: String = "Scam/Fraud"
    @Environment(\.dismiss) private var dismiss
    
    let categories = [
        ("Scam / Fraud", "Scam/Fraud", Color.red, "xmark.shield.fill"),
        ("Robocall", "Robocall", Color.purple, "cpu"),
        ("Telemarketing", "Spam/Telemarketing", Color.orange, "phone.bubble.left.fill"),
        ("Not Spam", "Not Spam", Color.green, "checkmark.shield.fill")
    ]
    
    var onTagSubmitted: (String, String) -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Text("Enter the phone number that called you to tag and add it to the Deep SCI spam database.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 12)
                    
                    // Phone Number Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Phone Number")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Image(systemName: "phone.fill")
                                .foregroundColor(.secondary)
                            TextField("+1 (555) 000-0000", text: $phoneNumber)
                                .keyboardType(.phonePad)
                                .foregroundColor(.white)
                                .autocorrectionDisabled()
                        }
                        .padding()
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(12)
                    }
                    
                    // Category Picker
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Select Spam Category")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(categories, id: \.1) { name, key, color, icon in
                                Button(action: {
                                    selectedCategory = key
                                }) {
                                    HStack {
                                        Image(systemName: icon)
                                        Text(name)
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(selectedCategory == key ? color.opacity(0.2) : Color.white.opacity(0.05))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(selectedCategory == key ? color : Color.white.opacity(0.1), lineWidth: 1.5)
                                    )
                                }
                            }
                        }
                    }
                    
                    Spacer(minLength: 20)
                    
                    // Submit Button
                    Button(action: {
                        let cleaned = phoneNumber.filter { $0.isNumber || $0 == "+" }
                        guard !cleaned.isEmpty else { return }
                        onTagSubmitted(cleaned, selectedCategory)
                        dismiss()
                    }) {
                        Text("Submit Report")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(phoneNumber.filter { $0.isNumber }.isEmpty ? Color.gray.opacity(0.3) : Color.red)
                            .cornerRadius(12)
                    }
                    .disabled(phoneNumber.filter { $0.isNumber }.isEmpty)
                    .padding(.bottom, 24)
                }
                .padding()
            }
            .background(Color(.systemGray6))
            .navigationTitle("Report Spammer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.red)
                }
            }
            .onAppear {
                if UIPasteboard.general.hasStrings {
                    if let copied = UIPasteboard.general.string {
                        // Accept number if it contains between 7 and 18 digits (standard phone number range)
                        let clean = copied.filter { $0.isNumber }
                        if clean.count >= 7 && clean.count <= 18 {
                            self.phoneNumber = copied
                            print("📋 [ManualReportSheet] Auto-filled clipboard phone number: \(copied)")
                        }
                    }
                }
            }
        }
    }
}
