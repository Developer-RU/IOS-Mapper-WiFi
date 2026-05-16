
import MapKit
import SwiftUI
import WiFiMapperCore
struct MapViewRepresentable: UIViewRepresentable {
    var networks: [WiFiNetworkSnapshot]
    var route: [CLLocationCoordinate2D]
    var selectedStyle: MapPresentationStyle
    var activeLayers: Set<MapLayer>
    var followUser = true
    var userLocation: CLLocationCoordinate2D?
    var selectionHandler: (WiFiNetworkSnapshot) -> Void

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.pointOfInterestFilter = .includingAll
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: "Network")
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: "Cluster")
        mapView.isPitchEnabled = true
        mapView.isRotateEnabled = true
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        context.coordinator.parent = self
        applyStyle(to: mapView)
        mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })
        mapView.removeOverlays(mapView.overlays)

        let annotations = networks.map(NetworkAnnotation.init)
        if activeLayers.contains(.points) {
            mapView.addAnnotations(annotations)
        }

        if activeLayers.contains(.heatmap), !networks.isEmpty {
            mapView.addOverlay(WiFiIntensityOverlay(networks: networks, mode: .signal), level: .aboveLabels)
        }

        if activeLayers.contains(.congestion), !networks.isEmpty {
            mapView.addOverlay(WiFiIntensityOverlay(networks: networks, mode: .congestion), level: .aboveLabels)
        }

        if activeLayers.contains(.route), route.count > 1 {
            let polyline = MKPolyline(coordinates: route, count: route.count)
            mapView.addOverlays([polyline])
        }

        if followUser, let userLocation {
            let camera = MKMapCamera(lookingAtCenter: userLocation, fromDistance: 300, pitch: 45, heading: 0)
            mapView.setCamera(camera, animated: true)
        } else if !networks.isEmpty {
            mapView.showAnnotations(annotations, animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    private func applyStyle(to mapView: MKMapView) {
        switch selectedStyle {
        case .standard:
            let configuration = MKStandardMapConfiguration(elevationStyle: .realistic)
            configuration.pointOfInterestFilter = .includingAll
            configuration.showsTraffic = false
            mapView.preferredConfiguration = configuration
        case .hybrid:
            mapView.preferredConfiguration = MKHybridMapConfiguration()
        case .imagery:
            mapView.preferredConfiguration = MKImageryMapConfiguration()
        }
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewRepresentable

        init(parent: MapViewRepresentable) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor.systemBlue.withAlphaComponent(0.7)
                renderer.lineWidth = 5
                return renderer
            }

            if overlay is WiFiIntensityOverlay {
                let renderer = WiFiIntensityOverlayRenderer(overlay: overlay)
                return renderer
            }

            return MKOverlayRenderer(overlay: overlay)
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if let cluster = annotation as? MKClusterAnnotation {
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: "Cluster", for: cluster) as? MKMarkerAnnotationView
                view?.glyphText = "\(cluster.memberAnnotations.count)"
                view?.markerTintColor = .systemIndigo
                view?.displayPriority = .defaultHigh
                return view
            }

            guard let annotation = annotation as? NetworkAnnotation else { return nil }
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: "Network", for: annotation) as? MKMarkerAnnotationView
            view?.glyphText = annotation.network.band == .band24 ? "2.4" : annotation.network.band == .band5 ? "5" : annotation.network.band == .band6 ? "6" : "Wi"
            view?.markerTintColor = annotation.tintColor
            view?.canShowCallout = false
            view?.clusteringIdentifier = "wifi"
            view?.displayPriority = .defaultLow
            return view
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let annotation = view.annotation as? NetworkAnnotation else { return }
            parent.selectionHandler(annotation.network)
        }
    }
}

final class NetworkAnnotation: NSObject, MKAnnotation {
    let network: WiFiNetworkSnapshot
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?
    let clusterIdentifier: String? = "wifi"

    init(network: WiFiNetworkSnapshot) {
        self.network = network
        self.coordinate = network.coordinate
        self.title = network.ssid
        self.subtitle = "\(network.rssi) dBm"
    }

    var tintColor: UIColor {
        switch network.band {
        case .band24: return .systemBlue
        case .band5: return .systemGreen
        case .band6: return .systemOrange
        case .unknown: return .systemGray
        }
    }
}
