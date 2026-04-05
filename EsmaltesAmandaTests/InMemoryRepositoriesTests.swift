import XCTest
@testable import EsmaltesAmanda

final class InMemoryRepositoriesTests: XCTestCase {
    func testRepositoryCreatesAndDeletesPolish() async throws {
        let repository = InMemoryPolishRepository(seedPolishes: [])
        let userID = PreviewFixtures.primaryUser.id
        var draft = PolishDraft()
        draft.name = "Lilas de Teste"
        draft.brandName = "Colorama"
        draft.colorFamily = .roxo
        draft.tone = .medio
        draft.finish = .cintilante
        draft.tagsText = "novo, teste"

        let created = try await repository.upsertPolish(id: UUID(), draft: draft, userID: userID)
        let allAfterCreate = try await repository.fetchPolishes(for: userID)

        XCTAssertEqual(created.name, "Lilas de Teste")
        XCTAssertEqual(allAfterCreate.count, 1)
        XCTAssertEqual(allAfterCreate.first?.tags.count, 2)

        try await repository.deletePolish(id: created.id, userID: userID)

        let allAfterDelete = try await repository.fetchPolishes(for: userID)
        XCTAssertTrue(allAfterDelete.isEmpty)
    }
}

