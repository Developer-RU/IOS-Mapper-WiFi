import CoreData
import CoreLocation
import Foundation

public struct RepositorySnapshot {
    public let networks: [WiFiNetworkSnapshot]
    public let observations: Int
}

public final class NetworkRepository {
    private let persistence: PersistenceController

    public init(persistence: PersistenceController) {
        self.persistence = persistence
    }

    public func startSession() async throws -> UUID {
        let context = persistence.newBackgroundContext()
        return try await context.performAsync {
            let session = ScanSessionEntity(context: context)
            let id = UUID()
            session.id = id
            session.startedAt = Date()
            session.isActive = true
            session.sampleCount = 0
            try context.save()
            return id
        }
    }

    public func stopSession(_ sessionID: UUID) async throws {
        let context = persistence.newBackgroundContext()
        _ = try await context.performAsync {
            let request = NSFetchRequest<ScanSessionEntity>(entityName: "ScanSessionEntity")
            request.fetchLimit = 1
            request.predicate = NSPredicate(format: "id == %@", sessionID as CVarArg)
            if let session = try context.fetch(request).first {
                session.endedAt = Date()
                session.isActive = false
                try context.save()
            }
            return ()
        }
    }

    public func upsert(snapshot: WiFiNetworkSnapshot, sessionID: UUID?) async throws -> WiFiNetworkSnapshot {
        let context = persistence.newBackgroundContext()
        return try await context.performAsync {
            let request = NSFetchRequest<NetworkRecordEntity>(entityName: "NetworkRecordEntity")
            request.fetchLimit = 1
            request.predicate = NSPredicate(format: "bssid == %@", snapshot.bssid)

            let entity = try context.fetch(request).first ?? NetworkRecordEntity(context: context)
            let now = snapshot.timestamp
            if entity.value(forKey: "id") == nil {
                entity.id = snapshot.id
                entity.firstSeen = now
            }
            entity.ssid = snapshot.ssid
            entity.bssid = snapshot.bssid
            entity.latitude = snapshot.latitude
            entity.longitude = snapshot.longitude
            entity.frequencyMHz = snapshot.frequencyMHz as NSNumber?
            entity.channel = snapshot.channel as NSNumber?
            entity.bandRaw = snapshot.band.rawValue
            entity.securityRaw = snapshot.security.rawValue
            entity.encryption = snapshot.encryption
            entity.encoding = snapshot.encoding
            entity.captivePortalHint = snapshot.captivePortalHint
            entity.authenticationHint = snapshot.authenticationHint
            entity.lastSeen = now
            entity.scanCount += 1

            let observation = ObservationEntity(context: context)
            observation.id = UUID()
            observation.timestamp = now
            observation.latitude = snapshot.latitude
            observation.longitude = snapshot.longitude
            observation.rssi = Int16(snapshot.rssi)
            observation.sessionID = sessionID
            observation.network = entity

            if let sessionID {
                let sessionRequest = NSFetchRequest<ScanSessionEntity>(entityName: "ScanSessionEntity")
                sessionRequest.fetchLimit = 1
                sessionRequest.predicate = NSPredicate(format: "id == %@", sessionID as CVarArg)
                if let session = try context.fetch(sessionRequest).first {
                    session.sampleCount += 1
                }
            }

            try context.save()
            return try self.map(entity, in: context)
        }
    }

    public func fetchNetworks(filter: NetworkFilter = .init()) async throws -> [WiFiNetworkSnapshot] {
        let context = persistence.newBackgroundContext()
        return try await context.performAsync {
            let request = NSFetchRequest<NetworkRecordEntity>(entityName: "NetworkRecordEntity")
            request.sortDescriptors = [NSSortDescriptor(key: "lastSeen", ascending: false)]
            let entities = try context.fetch(request)
            let snapshots = try entities.map { try self.map($0, in: context) }.filter(filter.matches)
            return self.sort(snapshots, by: filter.sortOrder)
        }
    }

    public func fetchNetwork(id: UUID) async throws -> WiFiNetworkSnapshot? {
        let context = persistence.newBackgroundContext()
        return try await context.performAsync {
            let request = NSFetchRequest<NetworkRecordEntity>(entityName: "NetworkRecordEntity")
            request.fetchLimit = 1
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            return try context.fetch(request).first.flatMap { try self.map($0, in: context) }
        }
    }

    public func delete(networkIDs: [UUID]) async throws {
        let context = persistence.newBackgroundContext()
        _ = try await context.performAsync {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "NetworkRecordEntity")
            request.predicate = NSPredicate(format: "id IN %@", networkIDs)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
            try context.execute(deleteRequest)
            try context.save()
            return ()
        }
    }

    public func analyticsSummary(filter: NetworkFilter = .init()) async throws -> AnalyticsSummary {
        let networks = try await fetchNetworks(filter: filter)
        let observations = networks.flatMap(\.history)
        let averageRSSI = observations.isEmpty ? -100 : Double(observations.map(\.rssi).reduce(0, +)) / Double(observations.count)
        let strongest = networks.max { $0.rssi < $1.rssi }?.ssid ?? "-"
        let bandGroups = Dictionary(grouping: networks, by: { $0.band.rawValue })
        let securityGroups = Dictionary(grouping: networks, by: { $0.security.rawValue })
        let channelGroups = Dictionary(grouping: networks.compactMap { network -> String? in
            guard let channel = network.channel else { return nil }
            return String(channel)
        }, by: { $0 })
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "MMM d"
        let dailyGroups = Dictionary(grouping: observations.filter { filter.dateScope.contains($0.timestamp) }, by: {
            Calendar.current.startOfDay(for: $0.timestamp)
        })
        var summary = AnalyticsSummary()
        summary.totalNetworks = networks.count
        summary.totalObservations = observations.count
        summary.openNetworks = networks.filter { $0.security == .open }.count
        summary.averageRSSI = averageRSSI
        summary.strongestSSID = strongest
        let scanCounts = networks.map(\.scanCount).reduce(0, +)
        summary.averageScanCount = networks.isEmpty ? 0 : Double(scanCounts) / Double(networks.count)
        summary.bandDistribution = bandGroups.map { AnalyticsSummary.DistributionItem(label: $0.key, value: $0.value.count) }.sorted { $0.label < $1.label }
        summary.securityDistribution = securityGroups.map { AnalyticsSummary.DistributionItem(label: $0.key, value: $0.value.count) }.sorted { $0.label < $1.label }
        summary.channelDistribution = channelGroups.map { AnalyticsSummary.DistributionItem(label: $0.key, value: $0.value.count) }.sorted { Int($0.label) ?? 0 < Int($1.label) ?? 0 }
        summary.dailyObservations = dailyGroups.map { AnalyticsSummary.DistributionItem(label: dayFormatter.string(from: $0.key), value: $0.value.count) }.sorted { $0.label < $1.label }
        return summary
    }

    public func compareArea(around center: CLLocationCoordinate2D, radiusMeters: Double = 150, recentWindow: TimeInterval = 86_400) async throws -> AreaHistoryComparison {
        let networks = try await fetchNetworks()
        let now = Date()
        let recentStart = now.addingTimeInterval(-recentWindow)

        var newItems: [AreaComparisonItem] = []
        var stableItems: [AreaComparisonItem] = []
        var disappearedItems: [AreaComparisonItem] = []

        for network in networks {
            let areaObservations = network.history.filter { observation in
                let observationLocation = CLLocation(latitude: observation.latitude, longitude: observation.longitude)
                let centerLocation = CLLocation(latitude: center.latitude, longitude: center.longitude)
                return observationLocation.distance(from: centerLocation) <= radiusMeters
            }

            guard !areaObservations.isEmpty else { continue }

            let recentObservations = areaObservations.filter { $0.timestamp >= recentStart }
            let previousObservations = areaObservations.filter { $0.timestamp < recentStart }
            let latestObservation = (recentObservations.last ?? previousObservations.last)

            guard let latestObservation else { continue }

            let item = AreaComparisonItem(
                id: network.id,
                ssid: network.ssid,
                bssid: network.bssid,
                state: recentObservations.isEmpty ? .disappeared : (previousObservations.isEmpty ? .new : .stable),
                rssi: latestObservation.rssi,
                lastSeen: latestObservation.timestamp
            )

            if recentObservations.isEmpty {
                disappearedItems.append(item)
            } else if previousObservations.isEmpty {
                newItems.append(item)
            } else {
                stableItems.append(item)
            }
        }

        var comparison = AreaHistoryComparison()
        comparison.centerDescription = "\(center.latitude.formatted(.number.precision(.fractionLength(4)))), \(center.longitude.formatted(.number.precision(.fractionLength(4))))"
        comparison.radiusMeters = radiusMeters
        comparison.newNetworks = newItems.sorted { $0.rssi > $1.rssi }
        comparison.stableNetworks = stableItems.sorted { $0.rssi > $1.rssi }
        comparison.disappearedNetworks = disappearedItems.sorted { $0.lastSeen > $1.lastSeen }
        return comparison
    }

    private func sort(_ snapshots: [WiFiNetworkSnapshot], by sortOrder: NetworkSortOrder) -> [WiFiNetworkSnapshot] {
        switch sortOrder {
        case .newest:
            return snapshots.sorted { $0.lastSeen > $1.lastSeen }
        case .strongest:
            return snapshots.sorted { $0.rssi > $1.rssi }
        case .mostSeen:
            return snapshots.sorted { $0.scanCount > $1.scanCount }
        case .ssid:
            return snapshots.sorted { $0.ssid.localizedCaseInsensitiveCompare($1.ssid) == .orderedAscending }
        }
    }

    private func map(_ entity: NetworkRecordEntity, in context: NSManagedObjectContext) throws -> WiFiNetworkSnapshot {
        let observationsRequest = NSFetchRequest<ObservationEntity>(entityName: "ObservationEntity")
        observationsRequest.predicate = NSPredicate(format: "network == %@", entity)
        observationsRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        let observations = try context.fetch(observationsRequest)
        let history = observations.map {
            WiFiObservation(
                id: $0.id,
                networkID: entity.id,
                timestamp: $0.timestamp,
                latitude: $0.latitude,
                longitude: $0.longitude,
                rssi: Int($0.rssi),
                sessionID: $0.sessionID
            )
        }

        let latest = history.last
        return WiFiNetworkSnapshot(
            id: entity.id,
            ssid: entity.ssid,
            bssid: entity.bssid,
            latitude: latest?.latitude ?? entity.latitude,
            longitude: latest?.longitude ?? entity.longitude,
            timestamp: latest?.timestamp ?? entity.lastSeen,
            rssi: latest?.rssi ?? -100,
            frequencyMHz: entity.frequencyMHz?.intValue,
            channel: entity.channel?.intValue,
            band: WiFiBand(rawValue: entity.bandRaw) ?? .unknown,
            security: WiFiSecurity(rawValue: entity.securityRaw) ?? .unknown,
            encryption: entity.encryption,
            encoding: entity.encoding,
            captivePortalHint: entity.captivePortalHint,
            authenticationHint: entity.authenticationHint,
            scanCount: Int(entity.scanCount),
            lastSeen: entity.lastSeen,
            history: history
        )
    }
}
