import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct FavoritesBackupView: View {
    @Environment(\.modelContext) private var context
    @Query private var threads: [FavoriteThread]
    @Query private var generals: [RecurringFavorite]
    @Query private var replies: [SavedReply]
    @State private var document = FavoritesBackupDocument()
    @State private var exporting = false
    @State private var importing = false
    @State private var confirmingImport = false
    @State private var pendingBackup: FavoritesBackup?
    @State private var message = ""
    @State private var showingMessage = false

    var body: some View {
        Form {
            Section {
                LabeledContent("Saved threads", value: "\(threads.count)")
                LabeledContent("Named generals", value: "\(generals.count)")
                LabeledContent("Saved replies", value: "\(replies.count)")
            } footer: {
                Text("Back up saved thread links, named generals, and saved reply text. Media files, settings, and reading progress are not included.")
            }
            Section {
                Button("Export Favorites", systemImage: "square.and.arrow.up", action: exportFavorites)
                    .disabled(threads.isEmpty && generals.isEmpty && replies.isEmpty)
                    .accessibilityIdentifier("Export Favorites")
                Button("Import Favorites", systemImage: "square.and.arrow.down") { importing = true }
                    .accessibilityIdentifier("Import Favorites")
            } footer: {
                Text("Save a backup in Files or share it with another device. Importing adds missing favorites and keeps your existing names.")
            }
        }
        .navigationTitle("Favorites Backup")
        .navigationBarTitleDisplayMode(.inline)
        .fileExporter(isPresented: $exporting, document: document, contentType: .json, defaultFilename: "Swiftchan Favorites") { result in
            if case .failure(let error) = result { report(error.localizedDescription) }
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            do {
                let url = try result.get()
                let scoped = url.startAccessingSecurityScopedResource()
                defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                let handle = try FileHandle(forReadingFrom: url)
                defer { try? handle.close() }
                let data = try handle.read(upToCount: FavoritesBackup.maximumBytes + 1) ?? Data()
                pendingBackup = try FavoritesBackup.decode(data)
                confirmingImport = true
            } catch {
                pendingBackup = nil
                report(error.localizedDescription)
            }
        }
        .confirmationDialog("Import favorites?", isPresented: $confirmingImport, titleVisibility: .visible) {
            Button("Import", action: importFavorites)
            Button("Cancel", role: .cancel) { pendingBackup = nil }
        } message: {
            if let backup = pendingBackup {
                Text("This backup contains \(backup.threads.count) threads, \(backup.generals.count) named generals, and \(backup.replies?.count ?? 0) saved replies. Existing favorites will be kept.")
            }
        }
        .alert("Favorites Backup", isPresented: $showingMessage) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(message)
        }
    }

    private func exportFavorites() {
        do {
            document = FavoritesBackupDocument(data: try FavoritesBackupStore.export(from: context).encoded())
            exporting = true
        } catch {
            report(error.localizedDescription)
        }
    }

    private func importFavorites() {
        guard let backup = pendingBackup else { return }
        pendingBackup = nil
        do {
            let plan = try FavoritesBackupStore.restore(backup, in: context)
            report("Imported \(plan.threads.count) threads, \(plan.generals.count) named generals, and \(plan.replies.count) saved replies. Skipped \(plan.skipped) duplicates.")
        } catch {
            report(error.localizedDescription)
        }
    }

    private func report(_ text: String) {
        message = text
        showingMessage = true
    }
}

struct FavoritesBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    let data: Data

    init(data: Data = Data()) { self.data = data }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else { throw FavoritesBackup.BackupError.invalidFile }
        self.data = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
