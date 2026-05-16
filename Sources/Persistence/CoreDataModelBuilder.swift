import CoreData
import Foundation

@objc(NetworkRecordEntity)
final class NetworkRecordEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var ssid: String
    @NSManaged var bssid: String
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var frequencyMHz: NSNumber?
    @NSManaged var channel: NSNumber?
    @NSManaged var bandRaw: String
    @NSManaged var securityRaw: String
    @NSManaged var encryption: String?
    @NSManaged var encoding: String?
    @NSManaged var captivePortalHint: String?
    @NSManaged var authenticationHint: String?
    @NSManaged var firstSeen: Date
    @NSManaged var lastSeen: Date
    @NSManaged var scanCount: Int32
    @NSManaged var observations: Set<ObservationEntity>
}

@objc(ObservationEntity)
final class ObservationEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var timestamp: Date
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var rssi: Int16
    @NSManaged var sessionID: UUID?
    @NSManaged var network: NetworkRecordEntity
}

@objc(ScanSessionEntity)
final class ScanSessionEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var startedAt: Date
    @NSManaged var endedAt: Date?
    @NSManaged var isActive: Bool
    @NSManaged var sampleCount: Int32
}

enum CoreDataModelBuilder {
    static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let network = NSEntityDescription()
        network.name = "NetworkRecordEntity"
        network.managedObjectClassName = NSStringFromClass(NetworkRecordEntity.self)

        let observation = NSEntityDescription()
        observation.name = "ObservationEntity"
        observation.managedObjectClassName = NSStringFromClass(ObservationEntity.self)

        let session = NSEntityDescription()
        session.name = "ScanSessionEntity"
        session.managedObjectClassName = NSStringFromClass(ScanSessionEntity.self)

        network.properties = [
            attribute("id", type: .UUIDAttributeType),
            attribute("ssid", type: .stringAttributeType),
            attribute("bssid", type: .stringAttributeType),
            attribute("latitude", type: .doubleAttributeType),
            attribute("longitude", type: .doubleAttributeType),
            optionalAttribute("frequencyMHz", type: .integer32AttributeType),
            optionalAttribute("channel", type: .integer16AttributeType),
            attribute("bandRaw", type: .stringAttributeType),
            attribute("securityRaw", type: .stringAttributeType),
            optionalAttribute("encryption", type: .stringAttributeType),
            optionalAttribute("encoding", type: .stringAttributeType),
            optionalAttribute("captivePortalHint", type: .stringAttributeType),
            optionalAttribute("authenticationHint", type: .stringAttributeType),
            attribute("firstSeen", type: .dateAttributeType),
            attribute("lastSeen", type: .dateAttributeType),
            attribute("scanCount", type: .integer32AttributeType)
        ]

        observation.properties = [
            attribute("id", type: .UUIDAttributeType),
            attribute("timestamp", type: .dateAttributeType),
            attribute("latitude", type: .doubleAttributeType),
            attribute("longitude", type: .doubleAttributeType),
            attribute("rssi", type: .integer16AttributeType),
            optionalAttribute("sessionID", type: .UUIDAttributeType)
        ]

        session.properties = [
            attribute("id", type: .UUIDAttributeType),
            attribute("startedAt", type: .dateAttributeType),
            optionalAttribute("endedAt", type: .dateAttributeType),
            attribute("isActive", type: .booleanAttributeType),
            attribute("sampleCount", type: .integer32AttributeType)
        ]

        let observationsRelation = NSRelationshipDescription()
        observationsRelation.name = "observations"
        observationsRelation.destinationEntity = observation
        observationsRelation.minCount = 0
        observationsRelation.maxCount = 0
        observationsRelation.deleteRule = .cascadeDeleteRule
        observationsRelation.isOrdered = false

        let networkRelation = NSRelationshipDescription()
        networkRelation.name = "network"
        networkRelation.destinationEntity = network
        networkRelation.minCount = 1
        networkRelation.maxCount = 1
        networkRelation.deleteRule = .nullifyDeleteRule

        observationsRelation.inverseRelationship = networkRelation
        networkRelation.inverseRelationship = observationsRelation

        network.properties.append(observationsRelation)
        observation.properties.append(networkRelation)

        network.uniquenessConstraints = [["bssid"]]
        session.uniquenessConstraints = [["id"]]
        observation.uniquenessConstraints = [["id"]]

        model.entities = [network, observation, session]
        return model
    }

    private static func attribute(_ name: String, type: NSAttributeType) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = false
        return attribute
    }

    private static func optionalAttribute(_ name: String, type: NSAttributeType) -> NSAttributeDescription {
        let attribute = attribute(name, type: type)
        attribute.isOptional = true
        return attribute
    }
}
