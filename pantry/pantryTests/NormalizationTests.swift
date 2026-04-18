import Testing
@testable import pantry

@Suite("Ingredient name normalization")
struct NormalizationTests {
    @Test func lowercases() {
        #expect(IngredientName.normalize("Tomato") == "tomato")
        #expect(IngredientName.normalize("ROMA TOMATO") == "roma tomato")
    }

    @Test func trimsEdgeWhitespace() {
        #expect(IngredientName.normalize("  flour  ") == "flour")
        #expect(IngredientName.normalize("\tchicken\n") == "chicken")
    }

    @Test func collapsesInternalWhitespace() {
        #expect(IngredientName.normalize("olive  oil") == "olive oil")
        #expect(IngredientName.normalize("olive\t\toil") == "olive oil")
    }

    @Test func preservesHyphens() {
        // "half-and-half" should not be split into tokens.
        #expect(IngredientName.normalize("Half-and-Half") == "half-and-half")
    }
}
