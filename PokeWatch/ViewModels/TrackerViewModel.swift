import Foundation
import Combine

@MainActor
final class TrackerViewModel: ObservableObject {
    @Published private(set) var entries: [StockEntry] = []
    @Published private(set) var lastUpdated: Date?
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let service: TrackerServicing
    private let notificationService: NotificationServiceProtocol
    private var refreshTask: Task<Void, Never>?

    init(service: TrackerServicing = TrackerService(), notificationService: NotificationServiceProtocol = NotificationService.shared) {
        self.service = service
        self.notificationService = notificationService
    }

    func startAutoRefresh() async {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            guard let self else { return }

            await self.manualRefresh()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))
                await self.manualRefresh()
            }
        }
    }

    func manualRefresh() async {
        isLoading = true
        errorMessage = nil

        do {
            let newEntries = try await service.fetchEntries()
            let previousEntries = entries

            entries = newEntries
            lastUpdated = Date()
            notifyForChanges(old: previousEntries, new: newEntries)
        } catch {
            errorMessage = "\(error.localizedDescription)"
        }

        isLoading = false
    }

    private func notifyForChanges(old: [StockEntry], new: [StockEntry]) {
        let newlyInStock = new.filter { entry in
            entry.status == .inStock && !(old.first { $0.store == entry.store }?.status == .inStock)
        }

        for entry in newlyInStock {
            notificationService.postStockAvailableNotification(for: entry)
        }
    }
}
