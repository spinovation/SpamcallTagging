import SwiftUI

struct DirectoryView: View {
    @EnvironmentObject var manager: SpamManager
    @State private var searchText: String = ""
    @State private var selectedCategory: String = "All"
    @State private var selectedTier: Int = 0 // 0 = All, 1 = Tier 1, 2 = Tier 2, 3 = Tier 3
    @State private var sortBy: SortOption = .volume
    
    enum SortOption {
        case volume, recency, number
    }
    
    let categories = ["All", "Scam/Fraud", "Robocall", "Spam/Telemarketing", "Not Spam"]
    
    var filteredNumbers: [SpamNumber] {
        manager.spamNumbers.filter { num in
            // Search Match
            let searchMatch = searchText.isEmpty || 
                num.phoneNumber.contains(searchText) || 
                (num.callerName?.localizedCaseInsensitiveContains(searchText) ?? false)
            
            // Category Match
            let categoryMatch = selectedCategory == "All" || 
                num.categoryBreakdown[selectedCategory] != nil || 
                (selectedCategory == "Not Spam" && num.primaryCategory == "Not Spam")
            
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
                    
                    // Category Chips (Horizontal Scroll)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(categories, id: \.self) { cat in
                                Button(action: {
                                    selectedCategory = cat
                                }) {
                                    Text(cat == "Spam/Telemarketing" ? "Telemarketing" : cat)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 12)
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
                    VStack(spacing: 12) {
                        Image(systemName: "phone.slash")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No Flagged Numbers Found")
                            .font(.headline)
                            .foregroundColor(.secondary)
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
}

// MARK: - List Row Subview

struct DirectoryRowView: View {
    let number: SpamNumber
    let threshold: Int
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(number.phoneNumber)
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
