import Foundation
import PDFKit

public struct SourcePage: Codable, Sendable, Identifiable, Equatable {
  public var id: Int { number }
  public let number: Int
  public let text: String
}
public struct LibraryDocument: Codable, Sendable, Identifiable, Equatable {
  public let id: UUID
  public var title: String
  public let imported: Date
  public let pages: [SourcePage]
  public var archived = false
  public var revision = 0
  public init(title: String, pages: [SourcePage]) {
    id = UUID()
    self.title = title
    self.pages = pages
    imported = Date()
  }
}
public struct SourceMatch: Sendable, Identifiable {
  public var id: String { document.id.uuidString + "-" + String(page.number) }
  public let document: LibraryDocument
  public let page: SourcePage
  public let excerpt: String
}
public enum LibraryError: Error, LocalizedError {
  case invalid, tooLarge, noText, stale
  public var errorDescription: String? {
    switch self {
    case .invalid:
      "This library or document has an unsupported format. The existing file was preserved."
    case .tooLarge: "Use files up to 20 MB, 500 PDF pages, and two million text characters."
    case .noText: "No selectable text was found. Scanned PDFs need OCR before import."
    case .stale: "This document changed. Reopen its details before saving."
    }
  }
}
public enum LibrarySearch {
  public static func matches(_ query: String, documents: [LibraryDocument], limit: Int = 8)
    -> [SourceMatch]
  {
    let words = Set(
      query.lowercased().split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init)
        .filter { $0.count > 2 })
    guard !words.isEmpty else { return [] }
    return documents.filter { !$0.archived }.flatMap { doc in
      doc.pages.compactMap { page -> (Int, SourceMatch)? in
        let lower = page.text.lowercased()
        let score = words.filter { lower.contains($0) }.count
        guard score > 0 else { return nil }
        let paragraphs = page.text.components(separatedBy: "\n").filter { line in
          words.contains { line.localizedCaseInsensitiveContains($0) }
        }
        let passage = paragraphs.joined(separator: "\n")
        return (
          score, SourceMatch(document: doc, page: page, excerpt: String(passage.prefix(1400)))
        )
      }
    }.sorted { lhs, rhs in
      if lhs.0 != rhs.0 { return lhs.0 > rhs.0 }
      if lhs.1.document.title != rhs.1.document.title {
        return lhs.1.document.title < rhs.1.document.title
      }
      return lhs.1.page.number < rhs.1.page.number
    }.prefix(max(0, min(limit, 12))).map(\.1)
  }
}
public actor LibraryStore {
  private struct Record: Codable {
    var version = 1
    var documents: [LibraryDocument]
  }
  private let root: URL
  public nonisolated let searchFolder: URL
  public init(root: URL) {
    self.root = root
    searchFolder = root.appendingPathComponent("Search Sources", isDirectory: true)
  }
  private var recordURL: URL { root.appendingPathComponent("Library.json") }
  public func load() throws -> [LibraryDocument] {
    guard FileManager.default.fileExists(atPath: recordURL.path) else { return [] }
    guard (try recordURL.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0) <= 30_000_000 else {
      throw LibraryError.tooLarge
    }
    do {
      let record = try JSONDecoder().decode(Record.self, from: Data(contentsOf: recordURL))
      guard record.version == 1, record.documents.count <= 100,
        Set(record.documents.map(\.id)).count == record.documents.count,
        record.documents.allSatisfy({ valid($0) })
      else { throw LibraryError.invalid }
      return record.documents
    } catch { throw LibraryError.invalid }
  }
  private func valid(_ doc: LibraryDocument) -> Bool {
    !doc.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && doc.title.count <= 200
      && !doc.pages.isEmpty && doc.pages.count <= 500
      && doc.pages.reduce(0, { $0 + $1.text.count }) <= 2_000_000
      && Set(doc.pages.map(\.number)).count == doc.pages.count
      && doc.pages.allSatisfy { $0.number > 0 }
  }
  private func save(_ documents: [LibraryDocument]) throws {
    guard documents.count <= 100, documents.allSatisfy({ valid($0) }) else {
      throw LibraryError.tooLarge
    }
    let data = try JSONEncoder().encode(Record(documents: documents))
    guard data.count <= 30_000_000 else { throw LibraryError.tooLarge }
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    try data.write(to: recordURL, options: .atomic)
  }
  public func add(_ doc: LibraryDocument) throws -> [LibraryDocument] {
    var all = try load()
    all.insert(doc, at: 0)
    try save(all)
    return all
  }
  public func update(_ doc: LibraryDocument) throws -> [LibraryDocument] {
    var all = try load()
    guard let index = all.firstIndex(where: { $0.id == doc.id }),
      all[index].revision == doc.revision
    else { throw LibraryError.stale }
    var next = doc
    next.revision += 1
    all[index] = next
    try save(all)
    return all
  }
  public func rebuildSearchFiles() throws {
    let docs = try load().filter { !$0.archived }
    try FileManager.default.createDirectory(at: searchFolder, withIntermediateDirectories: true)
    let files = try FileManager.default.contentsOfDirectory(
      at: searchFolder, includingPropertiesForKeys: nil)
    let wanted = Set(docs.map { $0.id.uuidString + ".txt" })
    for file in files where !wanted.contains(file.lastPathComponent) && file.pathExtension == "txt"
    {
      try FileManager.default.removeItem(at: file)
    }
    for doc in docs {
      let text =
        "Document: \(doc.title)\n"
        + doc.pages.map { "Page \($0.number)\n\($0.text)" }.joined(separator: "\n\n")
      try Data(text.utf8).write(
        to: searchFolder.appendingPathComponent(doc.id.uuidString + ".txt"), options: .atomic)
    }
  }
  public func clearSearchFiles() throws {
    guard FileManager.default.fileExists(atPath: searchFolder.path) else { return }
    for file in try FileManager.default.contentsOfDirectory(
      at: searchFolder, includingPropertiesForKeys: nil) where file.pathExtension == "txt"
    {
      try FileManager.default.removeItem(at: file)
    }
  }
  public func sample() throws -> [LibraryDocument] {
    let all = try load()
    guard !all.contains(where: { $0.title == "Sample: Studio handover" }) else { return all }
    return try add(
      LibraryDocument(
        title: "Sample: Studio handover",
        pages: [
          SourcePage(
            number: 1,
            text:
              "Studio handover\nExport approved artwork as PDF. Keep the editable original with its project.\nBefore handover, check fonts, image permissions, and the client's preferred dimensions."
          ),
          SourcePage(
            number: 2,
            text:
              "Review checklist\nAsk a second reviewer to inspect the exported PDF at actual size.\nRecord the approval date and reviewer in the project notes."
          ),
        ]))
  }
}
public enum DocumentImporter {
  @concurrent public static func read(_ url: URL) async throws -> LibraryDocument {
    let scoped = url.startAccessingSecurityScopedResource()
    defer { if scoped { url.stopAccessingSecurityScopedResource() } }
    guard (try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0) <= 20_000_000 else {
      throw LibraryError.tooLarge
    }
    let data = try Data(contentsOf: url)
    guard data.count <= 20_000_000 else { throw LibraryError.tooLarge }
    var pages: [SourcePage] = []
    if url.pathExtension.lowercased() == "pdf" {
      guard let pdf = PDFDocument(data: data), pdf.pageCount <= 500 else {
        throw LibraryError.tooLarge
      }
      var count = 0
      for index in 0..<pdf.pageCount {
        try Task.checkCancellation()
        let text = pdf.page(at: index)?.string ?? ""
        count += text.count
        guard count <= 2_000_000 else { throw LibraryError.tooLarge }
        if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          pages.append(SourcePage(number: index + 1, text: text))
        }
      }
    } else {
      guard let text = String(data: data, encoding: .utf8), text.count <= 2_000_000 else {
        throw LibraryError.invalid
      }
      if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        pages = [SourcePage(number: 1, text: text)]
      }
    }
    guard !pages.isEmpty else { throw LibraryError.noText }
    return LibraryDocument(
      title: String(url.deletingPathExtension().lastPathComponent.prefix(200)), pages: pages)
  }
}
