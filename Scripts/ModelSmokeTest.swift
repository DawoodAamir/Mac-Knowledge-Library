import Foundation
import FoundationModels

@main struct LibrarySmokeTest {
  static func main() async throws {
    guard SystemLanguageModel.default.availability == .available else {
      print("SKIP: on-device model unavailable")
      return
    }
    let document = LibraryDocument(
      title: "Sample: Studio handover",
      pages: [
        SourcePage(
          number: 1,
          text:
            "Export approved artwork as PDF. Keep the editable original with its project. Check fonts and image permissions before handover."
        )
      ])
    let matches = LibrarySearch.matches("artwork handover", documents: [document])
    guard let match = matches.first else { throw LibraryError.noText }
    let prompt =
      "Question: How should I hand over artwork?\nDocument: \(match.document.title), page \(match.page.number)\n\(match.excerpt)"
    let session = LanguageModelSession(profile: LibraryProfile(searchFolder: nil))
    let response = try await session.respond(to: prompt)
    guard response.content.count >= 50, response.content.count <= 4000,
      response.content.localizedCaseInsensitiveContains("PDF")
    else { throw LibraryError.invalid }
    print(
      "PASS: production library profile returned a bounded draft mentioning the source's PDF export step (\(response.content.count) characters)."
    )
  }
}
