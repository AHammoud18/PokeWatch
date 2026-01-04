import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: TrackerViewModel

    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                header
                statusSummary
                listContent
            }
            .padding()
            .navigationTitle("PokeWatch")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { Task { await viewModel.manualRefresh() } }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityLabel("Refresh availability")
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text("Live Pokemon Card Tracker")
                .font(.headline)
            Text("Data sourced from nowinstock.net")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var statusSummary: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(summaryText)
                    .font(.title3)
                    .bold()
                if let updated = viewModel.lastUpdated {
                    Text("Last updated: \(updated.formatted(date: .abbreviated, time: .standard))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var listContent: some View {
        Group {
            if let error = viewModel.errorMessage {
                VStack(spacing: 12) {
                    Text("Unable to load tracker")
                        .font(.headline)
                    Text(error)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    Button("Try Again") {
                        Task { await viewModel.manualRefresh() }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                List(viewModel.entries) { entry in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(entry.store)
                                .font(.headline)
                            Spacer()
                            StatusBadge(status: entry.status)
                        }
                        if let lastChange = entry.lastChangeText {
                            Text(lastChange)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        if let link = entry.productURL {
                            Link("View listing", destination: link)
                                .font(.caption)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.insetGrouped)
            }
        }
    }

    private var summaryText: String {
        let inStockCount = viewModel.entries.filter { $0.status == .inStock }.count
        if inStockCount > 0 {
            return "\(inStockCount) stores have stock"
        } else if !viewModel.entries.isEmpty {
            return "No current stock"
        } else {
            return "Waiting for tracker data..."
        }
    }
}

private struct StatusBadge: View {
    let status: StockStatus

    var body: some View {
        Text(status.label)
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(status.color.opacity(0.15))
            .foregroundColor(status.color)
            .clipShape(Capsule())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let vm = TrackerViewModel(service: TrackerService(), notificationService: NotificationService.shared)
        vm.entries = [
            StockEntry(store: "Target", status: .inStock, productURL: URL(string: "https://example.com"), lastChangeText: "Updated just now"),
            StockEntry(store: "BestBuy", status: .outOfStock, productURL: nil, lastChangeText: "Updated 10m ago")
        ]
        return ContentView()
            .environmentObject(vm)
    }
}
