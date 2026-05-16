
import Combine
import CoreLocation
import Foundation
import Network
import WiFiMapperCore
@MainActor
final class PermissionService: ObservableObject {
    enum LocalNetworkStatus: String {
        case unknown
        case granted
        case denied
    }

    @Published private(set) var localNetworkStatus: LocalNetworkStatus = .unknown

    private var browser: NWBrowser?

    func requestLocation(using locationService: LocationService) {
        locationService.requestPermissions()
    }

    func requestLocalNetwork() {
        let parameters = NWParameters()
        parameters.includePeerToPeer = true
        let browser = NWBrowser(for: .bonjour(type: "_http._tcp", domain: nil), using: parameters)
        self.browser = browser
        browser.stateUpdateHandler = { [weak self] state in
            Task { @MainActor in
                switch state {
                case .ready:
                    self?.localNetworkStatus = .granted
                    self?.browser?.cancel()
                case .failed:
                    self?.localNetworkStatus = .denied
                    self?.browser?.cancel()
                default:
                    break
                }
            }
        }
        browser.start(queue: .global(qos: .utility))
    }
}
