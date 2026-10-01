import SwiftUI
import UniformTypeIdentifiers

@main struct LibraryApp: App {
  @State private var model: LibraryModel
  init() {
    let name =
      ProcessInfo.processInfo.environment["LIBRARY_TEST_STORE"].map { "WorkflowTests-" + $0 }
      ?? "Mac Knowledge Library"
    let root = URL.applicationSupportDirectory.appendingPathComponent(name, isDirectory: true)
    _model = State(initialValue: LibraryModel(root: root))
  }
  var body: some Scene {
    WindowGroup { LibraryView(model: model).frame(minWidth: 850, minHeight: 580) }
      .defaultSize(width: 1120, height: 760)
  }
}
struct LibraryView: View {
  @Bindable var model: LibraryModel
  @State private var selection: UUID?
  @State private var filter = ""
  @State private var importing = false
  @State private var details = false
  @State private var showArchived = false
  @State private var importTask: Task<Void, Never>?
  private var selected: LibraryDocument? { model.documents.first { $0.id == selection } }
  var body: some View {
    NavigationSplitView {
      List(selection: $selection) {
        ForEach(
          model.documents.filter {
            ($0.archived == showArchived)
              && (filter.isEmpty || $0.title.localizedCaseInsensitiveContains(filter))
          }
        ) { doc in
          NavigationLink(value: doc.id) {
            Label {
              VStack(alignment: .leading, spacing: 4) {
                Text(doc.title)
                Text("\(doc.pages.count) text pages").font(.caption).foregroundStyle(.secondary)
              }
            } icon: {
              Image(systemName: "doc.text")
            }
          }
        }
      }.navigationTitle("Library").searchable(text: $filter, prompt: "Document titles")
        .navigationSplitViewColumnWidth(min: 230, ideal: 270)
        .toolbar {
          Button("Import document", systemImage: "square.and.arrow.down") { importing = true }
            .keyboardShortcut("o")
          Menu("Library options", systemImage: "ellipsis.circle") {
            Toggle("Show archived", isOn: $showArchived)
            Button("Load sample document") { Task { await model.sample() } }
          }
        }
      VStack(alignment: .leading, spacing: 8) {
        Toggle(
          "Include in Spotlight",
          isOn: Binding(
            get: { model.spotlightEnabled },
            set: { enabled in Task { await model.setSpotlight(enabled) } })
        ).disabled(model.indexing)
        Text(
          "Off at launch. Enabling this copies imported text to an app-owned search folder and makes these documents discoverable in system search."
        ).font(.caption).foregroundStyle(.secondary)
      }.padding()
    } detail: {
      VStack(alignment: .leading, spacing: 0) {
        HStack {
          Text("Ask your library").font(.title2.bold())
          Spacer()
          if model.busy { Button("Stop", systemImage: "stop.circle") { model.cancel() } }
        }.padding()
        HStack(alignment: .top) {
          TextField("Question", text: $model.question, axis: .vertical).lineLimit(2...4)
            .textFieldStyle(.roundedBorder).accessibilityIdentifier("question")
            .onChange(of: model.question) { _, value in
              if value.count > 1000 { model.question = String(value.prefix(1000)) }
              model.cancel()
              model.answer = ""
              model.sources = []
            }
          Button("Find passages") { model.find() }.disabled(
            model.question.trimmingCharacters(in: .whitespaces).isEmpty)
          Button("Draft answer") { model.ask() }.disabled(
            model.busy || model.question.trimmingCharacters(in: .whitespaces).isEmpty)
        }.padding(.horizontal).padding(.bottom)
        Divider()
        ScrollView {
          LazyVStack(alignment: .leading, spacing: 24) {
            if !model.answer.isEmpty {
              VStack(alignment: .leading, spacing: 10) {
                Label("Draft · review against sources", systemImage: "sparkles").font(.headline)
                Text(model.answer).textSelection(.enabled)
              }
            }
            if !model.sources.isEmpty {
              Text("Source passages").font(.headline)
              ForEach(model.sources) { match in
                GroupBox {
                  VStack(alignment: .leading, spacing: 10) {
                    Button("\(match.document.title) · page \(match.page.number)") {
                      selection = match.document.id
                      details = true
                    }.buttonStyle(.link)
                    Text(match.excerpt).textSelection(.enabled).frame(
                      maxWidth: .infinity, alignment: .leading)
                  }.padding(4)
                }
              }
            } else if let selected {
              Text(selected.title).font(.title2.bold())
              ForEach(selected.pages) { page in
                VStack(alignment: .leading, spacing: 8) {
                  Text("Page \(page.number)").font(.headline).foregroundStyle(.secondary)
                  Text(String(page.text.prefix(20_000))).textSelection(.enabled)
                  if page.text.count > 20_000 {
                    Text(
                      "Preview limited to the first 20,000 characters. Search still includes the complete imported text."
                    ).font(.caption).foregroundStyle(.secondary)
                  }
                }
              }
            } else {
              ContentUnavailableView(
                "Your sources, in one place", systemImage: "books.vertical",
                description: Text(
                  "Import text PDFs, plain text, or Markdown. Search passages directly, or review an on-device draft alongside its sources."
                ))
            }
          }.padding(24).frame(maxWidth: .infinity, alignment: .leading)
        }
      }.navigationTitle("Mac Knowledge Library")
        .toolbar {
          Button("Document details", systemImage: "sidebar.right") { details.toggle() }.disabled(
            selected == nil)
        }
        .inspector(isPresented: $details) {
          if let selected {
            DocumentDetails(document: selected) { updated in Task { await model.update(updated) } }
          }
        }
    }
    .task { await model.load() }
    .onDisappear {
      model.cancel()
      importTask?.cancel()
    }
    .fileImporter(
      isPresented: $importing,
      allowedContentTypes: [.pdf, .plainText, UTType(filenameExtension: "md") ?? .plainText]
    ) { result in
      do {
        let url = try result.get()
        importTask?.cancel()
        importTask = Task { await model.importFile(url) }
      } catch { model.error = error.localizedDescription }
    }
    .alert(
      "Couldn't finish",
      isPresented: Binding(get: { model.error != nil }, set: { if !$0 { model.error = nil } })
    ) {
      Button("OK") { model.error = nil }
    } message: {
      Text(model.error ?? "")
    }
  }
}
struct DocumentDetails: View {
  let document: LibraryDocument
  let save: (LibraryDocument) -> Void
  @State private var title = ""
  var body: some View {
    Form {
      TextField("Title", text: $title).onChange(of: title) { _, value in
        if value.count > 200 { title = String(value.prefix(200)) }
      }
      LabeledContent(
        "Imported", value: document.imported.formatted(date: .abbreviated, time: .shortened))
      LabeledContent("Text pages", value: String(document.pages.count))
      Button("Save title") {
        var next = document
        next.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        save(next)
      }.disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      Button(document.archived ? "Restore to library" : "Archive document") {
        var next = document
        next.archived.toggle()
        save(next)
      }
      Text(
        "Imported text is stored locally. Original files are never changed. Archived documents remain recoverable and are excluded from answers and Spotlight."
      ).font(.caption).foregroundStyle(.secondary)
    }.formStyle(.grouped).onAppear { title = document.title }.onChange(of: document) { _, value in
      title = value.title
    }
  }
}
