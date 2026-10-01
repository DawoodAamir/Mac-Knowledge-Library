import Foundation
import Testing

@testable import KnowledgeCore

@Test func retrievalKeepsPageAndBounds() {
  let doc = LibraryDocument(
    title: "Handover",
    pages: [
      SourcePage(
        number: 3,
        text: "Export the approved PDF.\n"
          + String(repeating: "Artwork permissions matter.\n", count: 500))
    ])
  let results = LibrarySearch.matches("artwork permissions", documents: [doc])
  #expect(results.count == 1)
  #expect(results[0].page.number == 3)
  #expect(results[0].excerpt.count <= 1400)
  var archived = doc
  archived.archived = true
  #expect(LibrarySearch.matches("artwork", documents: [archived]).isEmpty)
}
@Test func revisionsAndPersistence() async throws {
  let root = URL.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  defer { try? FileManager.default.removeItem(at: root) }
  let store = LibraryStore(root: root)
  var doc = LibraryDocument(
    title: "Guide", pages: [SourcePage(number: 1, text: "Original content")])
  _ = try await store.add(doc)
  doc.title = "Updated guide"
  _ = try await store.update(doc)
  await #expect(throws: LibraryError.stale) { _ = try await store.update(doc) }
  #expect(try await LibraryStore(root: root).load().first?.title == "Updated guide")
  try await store.rebuildSearchFiles()
  #expect(try FileManager.default.contentsOfDirectory(atPath: store.searchFolder.path).count == 1)
  var latest = try await store.load()[0]
  latest.archived = true
  _ = try await store.update(latest)
  try await store.rebuildSearchFiles()
  #expect(try FileManager.default.contentsOfDirectory(atPath: store.searchFolder.path).isEmpty)
}
@Test func corruptLibraryIsPreserved() async throws {
  let root = URL.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  defer { try? FileManager.default.removeItem(at: root) }
  try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
  let url = root.appendingPathComponent("Library.json")
  let data = Data("broken".utf8)
  try data.write(to: url)
  let store = LibraryStore(root: root)
  await #expect(throws: LibraryError.invalid) { _ = try await store.sample() }
  #expect(try Data(contentsOf: url) == data)
}
@Test func utf8ImportAndEmptyInput() async throws {
  let url = URL.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".md")
  defer { try? FileManager.default.removeItem(at: url) }
  try Data("# Review\nCheck the exported PDF.".utf8).write(to: url)
  #expect(try await DocumentImporter.read(url).pages[0].text.contains("PDF"))
  try Data(" \n".utf8).write(to: url)
  await #expect(throws: LibraryError.noText) { _ = try await DocumentImporter.read(url) }
}
