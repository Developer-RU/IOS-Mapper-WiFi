
import Combine
import CoreLocation
import Foundation
import UIKit
import WiFiMapperCore
@MainActor
final class LocationService: NSObject, ObservableObject {
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var currentLocation: CLLocation?
    @Published private(set) var route: [CLLocationCoordinate2D] = []
    @Published private(set) var accuracyDescription = AppStrings.localized("location.status.unknown")

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.activityType = .fitness
        manager.distanceFilter = 5
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.pausesLocationUpdatesAutomatically = true
        configureBackgroundBehavior(for: manager.authorizationStatus)
    }

    func requestPermissions() {
        manager.requestWhenInUseAuthorization()
        manager.requestAlwaysAuthorization()
    }

    func start(highAccuracy: Bool) {
        manager.desiredAccuracy = highAccuracy ? kCLLocationAccuracyBestForNavigation : kCLLocationAccuracyNearestTenMeters
        configureBackgroundBehavior(for: manager.authorizationStatus)
        manager.startUpdatingLocation()
        manager.startMonitoringSignificantLocationChanges()
    }

    func stop() {
        manager.stopUpdatingLocation()
        manager.stopMonitoringSignificantLocationChanges()
    }

    private func configureBackgroundBehavior(for status: CLAuthorizationStatus) {
        let backgroundModes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String] ?? []
        let supportsBackgroundLocation = backgroundModes.contains("location")
        let canStayUp = status == .authorizedAlways && supportsBackgroundLocation

        if UIApplication.shared.applicationState == .background && !canStayUp {
            manager.allowsBackgroundLocationUpdates = false
            return
        }

        manager.allowsBackgroundLocationUpdates = canStayUp
    }
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
            configureBackgroundBehavior(for: manager.authorizationStatus)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        Task { @MainActor in
            currentLocation = latest
            route.append(latest.coordinate)
            if route.count > 1500 {
                route.removeFirst(route.count - 1500)
            }
            accuracyDescription = AppStrings.localized("location.accuracy.format %d", Int(max(0, latest.horizontalAccuracy.rounded())))
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            accuracyDescription = AppStrings.localized("location.status.unknown")
        }
    }
}
