import CoreData
import Foundation

// MARK: - MemoEntity

@objc(MemoEntity)
class MemoEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var content: String
    @NSManaged var status: String
    @NSManaged var color: String
    @NSManaged var positionX: Double
    @NSManaged var positionY: Double
    @NSManaged var createdAt: Date
    @NSManaged var completedAt: Date?
}

extension MemoEntity {
    static func fetchRequest() -> NSFetchRequest<MemoEntity> {
        NSFetchRequest<MemoEntity>(entityName: "MemoEntity")
    }
}

// MARK: - PersistenceController

class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    private init() {
        container = NSPersistentContainer(name: "Poco", managedObjectModel: Self.buildModel())
        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Core Data failed to load: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    var viewContext: NSManagedObjectContext { container.viewContext }

    func save() {
        let context = viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Core Data save error: \(error)")
            }
        }
    }

    // MARK: - Programmatic Model

    private static func buildModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let entity = NSEntityDescription()
        entity.name = "MemoEntity"
        entity.managedObjectClassName = "MemoEntity"

        let idAttr = makeAttr("id", type: .UUIDAttributeType)
        let contentAttr = makeAttr("content", type: .stringAttributeType, default: "")
        let statusAttr = makeAttr("status", type: .stringAttributeType, default: "active")
        let colorAttr = makeAttr("color", type: .stringAttributeType, default: "#FFF9C4")
        let posXAttr = makeAttr("positionX", type: .doubleAttributeType, default: 100.0)
        let posYAttr = makeAttr("positionY", type: .doubleAttributeType, default: 100.0)
        let createdAtAttr = makeAttr("createdAt", type: .dateAttributeType)
        let completedAtAttr = makeAttr("completedAt", type: .dateAttributeType, optional: true)

        entity.properties = [
            idAttr, contentAttr, statusAttr, colorAttr,
            posXAttr, posYAttr, createdAtAttr, completedAtAttr
        ]
        model.entities = [entity]
        return model
    }

    private static func makeAttr(
        _ name: String,
        type: NSAttributeType,
        optional: Bool = false,
        default defaultValue: Any? = nil
    ) -> NSAttributeDescription {
        let attr = NSAttributeDescription()
        attr.name = name
        attr.attributeType = type
        attr.isOptional = optional
        if let v = defaultValue {
            attr.defaultValue = v
        }
        return attr
    }
}
