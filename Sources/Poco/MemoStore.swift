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
        purgeOldArchivedMemos()

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

    func createMemo(content: String, color: String = "#FFF9C4") {
        let memo = MemoEntity(context: context)
        memo.id = UUID()
        memo.content = content
        memo.status = "active"
        memo.color = color
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

    // MARK: - Complete from Archive window

    func completeMemoFromArchive(_ memo: MemoEntity) {
        memo.status = "archived"
        memo.completedAt = Date()
        persistence.save()
    }

    // MARK: - Update Content

    func updateContent(_ memo: MemoEntity, content: String) {
        memo.content = content
        persistence.save()
    }

    // MARK: - Delete

    func deleteMemo(_ memo: MemoEntity) {
        context.delete(memo)
        persistence.save()
    }

    // MARK: - Auto Purge

    func purgeOldArchivedMemos(olderThan days: Int = 30) {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let toDelete = archivedMemos.filter {
            ($0.completedAt ?? Date.distantPast) < cutoff
        }
        toDelete.forEach { context.delete($0) }
        if !toDelete.isEmpty { persistence.save() }
    }

    // MARK: - Helpers

    private func defaultPosition() -> (x: Double, y: Double) {
        guard let screen = NSScreen.main else {
            return (100, 100)
        }
        let noteW: Double = 260
        let noteH: Double = 72
        let margin: Double = 16

        // 画面右上から下に向けて配置
        let startX = screen.visibleFrame.maxX - noteW - margin
        let startY = screen.visibleFrame.maxY - noteH - margin

        // 既存の active メモの位置を収集
        let occupiedRects = activeMemos.map {
            CGRect(x: $0.positionX, y: $0.positionY, width: noteW, height: noteH)
        }

        // 重ならない位置を探す（右端から下に向かって）
        var y = startY
        while y > screen.visibleFrame.minY {
            let candidate = CGRect(x: startX, y: y, width: noteW, height: noteH)
            if !occupiedRects.contains(where: { $0.intersects(candidate) }) {
                return (startX, y)
            }
            y -= noteH + margin
        }
        // 全部埋まっていたらオフセット付きでランダム配置
        return (startX - Double.random(in: 0...100), startY - Double.random(in: 0...200))
    }
}
