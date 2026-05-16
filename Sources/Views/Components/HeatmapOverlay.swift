
import MapKit
import UIKit
import WiFiMapperCore
struct HeatmapSample {
    let coordinate: CLLocationCoordinate2D
    let weight: Double
    let band: WiFiBand
    let sampleCount: Int
    let channelDiversity: Int
}

final class WiFiIntensityOverlay: NSObject, MKOverlay {
    enum Mode {
        case signal
        case congestion
    }

    let coordinate: CLLocationCoordinate2D
    let boundingMapRect: MKMapRect
    let samples: [HeatmapSample]
    let mode: Mode

    init(networks: [WiFiNetworkSnapshot], mode: Mode) {
        self.mode = mode

        let buckets = Self.makeBuckets(from: networks)
        self.samples = buckets.map { bucket in
            let averageWeight = bucket.networks.map(\.signalQuality).reduce(0, +) / Double(bucket.networks.count)
            let dominantBand = Dictionary(grouping: bucket.networks, by: \.band)
                .max { $0.value.count < $1.value.count }?
                .key ?? .unknown
            let channels = Set(bucket.networks.compactMap(\.channel))
            let congestionWeight = min(1, (Double(bucket.networks.count) / 6) + (Double(channels.count) / 12))
            return HeatmapSample(
                coordinate: bucket.coordinate,
                weight: mode == .signal ? averageWeight : congestionWeight,
                band: dominantBand,
                sampleCount: bucket.networks.count,
                channelDiversity: channels.count
            )
        }

        let rect = self.samples.reduce(MKMapRect.null) { partialResult, sample in
            let point = MKMapPoint(sample.coordinate)
            let sampleRect = MKMapRect(x: point.x - 160, y: point.y - 160, width: 320, height: 320)
            return partialResult.union(sampleRect)
        }

        self.boundingMapRect = rect.isNull ? MKMapRect.world : rect
        self.coordinate = self.boundingMapRect.isNull
            ? CLLocationCoordinate2D(latitude: 0, longitude: 0)
            : MKMapPoint(x: self.boundingMapRect.midX, y: self.boundingMapRect.midY).coordinate
    }

    private static func makeBuckets(from networks: [WiFiNetworkSnapshot]) -> [Bucket] {
        let cellSize: Double = 120
        var grouped: [String: [WiFiNetworkSnapshot]] = [:]

        for network in networks {
            let point = MKMapPoint(network.coordinate)
            let xBucket = Int(point.x / cellSize)
            let yBucket = Int(point.y / cellSize)
            grouped["\(xBucket):\(yBucket)", default: []].append(network)
        }

        return grouped.values.compactMap { networks in
            guard !networks.isEmpty else { return nil }
            let latitude = networks.map(\.latitude).reduce(0, +) / Double(networks.count)
            let longitude = networks.map(\.longitude).reduce(0, +) / Double(networks.count)
            return Bucket(
                coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                networks: networks
            )
        }
    }

    private struct Bucket {
        let coordinate: CLLocationCoordinate2D
        let networks: [WiFiNetworkSnapshot]
    }
}

final class WiFiIntensityOverlayRenderer: MKOverlayRenderer {
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        guard let overlay = overlay as? WiFiIntensityOverlay else { return }

        context.saveGState()
        context.setBlendMode(.plusLighter)

        for sample in overlay.samples {
            let point = point(for: MKMapPoint(sample.coordinate))
            let radius: CGFloat
            switch overlay.mode {
            case .signal:
                radius = CGFloat((34 + (sample.weight * 86)) / Double(max(zoomScale, 0.6)))
                drawGradient(at: point, radius: radius, color: color(for: sample.band, alpha: 0.48), in: context)
            case .congestion:
                radius = CGFloat((24 + (sample.weight * 70)) / Double(max(zoomScale, 0.6)))
                let congestionColor = UIColor(
                    hue: CGFloat(max(0, 0.16 - (sample.weight * 0.16))),
                    saturation: 0.88,
                    brightness: 0.98,
                    alpha: 0.38
                )
                drawGradient(at: point, radius: radius, color: congestionColor, in: context)
                drawLabel(sample: sample, at: point, radius: radius, in: context)
            }
        }

        context.restoreGState()
    }

    private func drawGradient(at point: CGPoint, radius: CGFloat, color: UIColor, in context: CGContext) {
        let colors = [
            color.cgColor,
            color.withAlphaComponent(0.24).cgColor,
            color.withAlphaComponent(0.02).cgColor,
            UIColor.clear.cgColor
        ] as CFArray

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let locations: [CGFloat] = [0, 0.35, 0.7, 1]
        guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) else { return }

        context.drawRadialGradient(
            gradient,
            startCenter: point,
            startRadius: 0,
            endCenter: point,
            endRadius: radius,
            options: [.drawsAfterEndLocation]
        )
    }

    private func drawLabel(sample: HeatmapSample, at point: CGPoint, radius: CGFloat, in context: CGContext) {
        let text = "\(sample.sampleCount) / \(sample.channelDiversity)ch"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: max(10, min(14, radius / 5)), weight: .semibold),
            .foregroundColor: UIColor.label.withAlphaComponent(0.78)
        ]
        let size = text.size(withAttributes: attributes)
        let rect = CGRect(
            x: point.x - (size.width / 2),
            y: point.y - (size.height / 2),
            width: size.width,
            height: size.height
        )
        text.draw(in: rect, withAttributes: attributes)
    }

    private func color(for band: WiFiBand, alpha: CGFloat) -> UIColor {
        switch band {
        case .band24:
            return UIColor.systemBlue.withAlphaComponent(alpha)
        case .band5:
            return UIColor.systemGreen.withAlphaComponent(alpha)
        case .band6:
            return UIColor.systemOrange.withAlphaComponent(alpha)
        case .unknown:
            return UIColor.systemTeal.withAlphaComponent(alpha)
        }
    }
}
