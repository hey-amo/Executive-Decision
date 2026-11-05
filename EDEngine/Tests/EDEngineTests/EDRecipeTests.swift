import Testing
@testable import EDEngine

@Suite("Finished-good recipes")
struct EDRecipeTests {
    @Test("Good A uses two XFine and one Fine")
    func goodARecipeMatchesRules() {
        #expect(EDRecipe.a.rawMaterials == [.extraFine, .extraFine, .fine])
    }

    @Test("Good B uses two Fine and one Standard")
    func goodBRecipeMatchesRules() {
        #expect(EDRecipe.b.rawMaterials == [.fine, .fine, .standard])
    }

    @Test("Good C uses one Fine and two Standard")
    func goodCRecipeMatchesRules() {
        #expect(EDRecipe.c.rawMaterials == [.fine, .standard, .standard])
    }

    @Test("Each recipe contains exactly three raw-material units")
    func everyRecipeRequiresThreeUnits() {
        #expect(EDRecipe.allCases.count == 3)
        for recipe in EDRecipe.allCases {
            #expect(recipe.rawMaterials.count == 3)
        }
    }

    @Test("Allows only the two substitutions specified by the rules")
    func substitutionRulesMatchGameRules() {
        #expect(EDRecipe.canSubstitute(.extraFine, for: .fine))
        #expect(EDRecipe.canSubstitute(.fine, for: .standard))

        for suppliedGrade in EDRawMaterialGrade.allCases {
            for requiredGrade in EDRawMaterialGrade.allCases {
                let expected = (suppliedGrade == .extraFine && requiredGrade == .fine)
                    || (suppliedGrade == .fine && requiredGrade == .standard)
                #expect(
                    EDRecipe.canSubstitute(suppliedGrade, for: requiredGrade) == expected
                )
            }
        }
    }
}
