import XCTest
@testable import EsmaltesAmanda

final class FilterStateTests: XCTestCase {
    func testFiltersApplyQueryAndCategoryTogether() {
        var filters = PolishFilters()
        filters.query = "nude"
        filters.finish = .transparente

        let result = filters.apply(to: PreviewFixtures.seedPolishes())

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.name, "Nude Sereno")
    }

    func testFiltersSortByBrandName() {
        var filters = PolishFilters()
        filters.sort = .brandAscending

        let result = filters.apply(to: PreviewFixtures.seedPolishes())

        XCTAssertEqual(result.first?.brandDisplayName, "Impala")
    }
}

