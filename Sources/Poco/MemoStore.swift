import CoreData
import Foundation
import Combine
import AppKit

class MemoStore: ObservableObject {
    @Published var activeMemos: [MemoEntity] = []
    @Published var archivedMemos: [MemoEntity] = []

    private let persistence: PersistenceController
    private var context: NSManagedObjectContext { persistence.viewContext }

    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
        fetchMemos()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(contextDidChange),
            name: .NSManagedObjectContextObjectsDidChange,
            object: persistence.viewContext
        )
    }

    @objc private func contextDidChange(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            self?.fetchMemos()
        }
    }

    // MARK: - Fetch

    func fetchMemos() {
        let request = MemoEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]

        do {
            let all = try context.fetch(request)
            activeMemos = all.filter { $0.status == "active" }
            archivedMemos = all
                .filter { $0.status == "archived" }
                .sorted { ($0.completedAt ?? Date.distantPast) > ($1.completedAt ?? Date.distantPast) }
        } catch {
            print("Fetch error: \(error)")
        }
    }

    // MARK: - Create

    func createMemo(content: String) {
        let memo = MemoEntity(context: context)
        memo.id = UUID()
        memo.content = content
        memo.status = "active"
        memo.color = "#FFF9C4"
        memo.createdAt = Date()

        let position = defaultPosition()
        memo.positionX = position.x
        memo.positionY = position.y

        persistence.save()
    }

    // MARK: - Complete (archive)

    func completeMemo(_ memo: MemoEntity) {
        memo.status = "archived"
        memo.completedAt = Date()
        persistence.save()
    }

    // MARK: - Restore

    func restoreMemo(_ memo: MemoEntity) {
        memo.status = "active"
        memo.completedAt = nil

        let position = defaultPosition()
        memo.positionX = position.x
        memo.positionY = position.y

        persistence.save()
    }

    // MARK: - Update Color

    func updateColor(_ memo: MemoEntity, color: String) {
        memo.color = color
        persistence.save()
    }

    // MARK: - Update Position

    func updatePosition(_ memo: MemoEntity, x: Double, y: Double) {
        memo.positionX = x
        memo.positionY = y
        persistence.save()
    }

    // MARK: - Delete

    func deleteMemo(_ memo: MemoEntity) {
        context.delete(memo)
        persistence.save()
    }

    // MARK: - Helpers

    private func defaultPosition() -> (x: Double, y: Double) {
        let offset = Double(activeMemos.count) * 30
        guard let screen = NSScreen.main else {
            return (100 + offset, 100 + offset)
        }
        let screenHeight = screen.frame.height
        return (100 + offset, screenHeight - 200 - 140 - offset)
    }
}
