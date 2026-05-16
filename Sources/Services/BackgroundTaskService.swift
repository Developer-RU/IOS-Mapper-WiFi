
import BackgroundTasks
import Foundation
import WiFiMapperCore
final class BackgroundTaskService {
    private let taskIdentifier = "com.pavelmasyukov.WiFiMapper.refresh"
    private weak var scannerService: WiFiScannerService?

    init(scannerService: WiFiScannerService) {
        self.scannerService = scannerService
    }

    func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { [weak self] task in
            guard let task = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            self?.handle(task: task)
        }
    }

    func scheduleRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }

    private func handle(task: BGAppRefreshTask) {
        scheduleRefresh()
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        Task {
            await scannerService?.performBackgroundRefresh()
            task.setTaskCompleted(success: true)
        }
    }
}
