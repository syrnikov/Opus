import SwiftUI

struct HomeScreenView: View {
    var onCreateCanvas: () -> Void

    private let templates = CanvasTemplate.defaults
    private let recents = RecentDocument.samples

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(nsColor: .windowBackgroundColor), Color(.sRGB, white: 0.92, opacity: 1.0)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 32) {
                header

                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 24)], spacing: 24) {
                        NewCanvasTile(onCreateCanvas: onCreateCanvas)

                        ForEach(recents) { document in
                            HomeDocumentThumbnail(document: document, onOpen: onCreateCanvas)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(40)
        }
        .navigationTitle("Gallery")
        .toolbarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Opus Studio")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                    Text("Create a new masterpiece or continue where you left off.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                creationMenu
            }

            templateStrip
        }
    }

    private var creationMenu: some View {
        Menu {
            ForEach(templates) { template in
                Button(template.menuTitle) {
                    onCreateCanvas()
                }
            }
            Divider()
            Button("Custom Size…") {
                onCreateCanvas()
            }
        } label: {
            Label("New Canvas", systemImage: "plus.circle.fill")
                .labelStyle(.titleAndIcon)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(.ultraThickMaterial, in: Capsule())
        }
        .menuStyle(.borderlessButton)
    }

    private var templateStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(templates) { template in
                    VStack(alignment: .leading, spacing: 6) {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(template.previewGradient)
                            .frame(width: 160, height: 110)
                            .overlay(alignment: .bottomTrailing) {
                                Text(template.shortDescription)
                                    .font(.caption)
                                    .padding(8)
                                    .background(.thinMaterial, in: Capsule())
                                    .padding(8)
                            }
                        Text(template.name)
                            .font(.headline)
                        Text(template.detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 160)
                    .padding(14)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
            }
            .padding(.vertical, 4)
        }
    }
}

private struct NewCanvasTile: View {
    var onCreateCanvas: () -> Void

    var body: some View {
        Button(action: onCreateCanvas) {
            VStack(spacing: 18) {
                Image(systemName: "sparkles")
                    .font(.system(size: 44))
                    .foregroundStyle(.white)
                    .padding(26)
                    .background(
                        LinearGradient(colors: [Color.accentColor, Color.accentColor.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: Circle()
                    )

                Text("Start a blank canvas")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)

                Text("Jump straight into a fresh white canvas. You can always pick a template from the menu above.")
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 260)
            .padding(24)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
        .buttonStyle(.plain)
        .shadow(color: .black.opacity(0.12), radius: 18, x: 0, y: 10)
    }
}

private struct HomeDocumentThumbnail: View {
    let document: RecentDocument
    var onOpen: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(colors: [document.accent, document.accent.opacity(0.65)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .frame(maxWidth: .infinity)
                .aspectRatio(4 / 3, contentMode: .fit)
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(document.name)
                            .font(.headline)
                        Text(document.subtitle)
                            .font(.caption)
                    }
                    .padding(12)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .padding(12)
                }

            HStack {
                Label(document.modifiedDescription, systemImage: "clock")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Open", action: onOpen)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
        .padding(22)
        .frame(minHeight: 260)
        .background(.thickMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 12)
    }
}

private struct CanvasTemplate: Identifiable {
    let id = UUID()
    let name: String
    let detail: String
    let shortDescription: String
    let colors: [Color]

    var menuTitle: String { "New \(name) Canvas" }

    var previewGradient: LinearGradient {
        LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static let defaults: [CanvasTemplate] = [
        CanvasTemplate(name: "Square", detail: "2048 × 2048 px", shortDescription: "1:1", colors: [.indigo, .blue]),
        CanvasTemplate(name: "HD", detail: "1920 × 1080 px", shortDescription: "16:9", colors: [.pink, .purple]),
        CanvasTemplate(name: "Poster", detail: "3300 × 5100 px", shortDescription: "11×17", colors: [.orange, .red]),
        CanvasTemplate(name: "Concept", detail: "4096 × 3072 px", shortDescription: "4:3", colors: [.mint, .teal])
    ]
}

private struct RecentDocument: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String
    let lastModified: Date
    let accent: Color

    var modifiedDescription: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: lastModified, relativeTo: .now)
    }

    static let samples: [RecentDocument] = [
        RecentDocument(name: "Mountain Study", subtitle: "Procreate Import", lastModified: .now.addingTimeInterval(-3600), accent: .cyan),
        RecentDocument(name: "Portrait 202", subtitle: "From iPad", lastModified: .now.addingTimeInterval(-86400 * 2), accent: .purple),
        RecentDocument(name: "Poster Concepts", subtitle: "From Cloud", lastModified: .now.addingTimeInterval(-86400 * 5), accent: .orange)
    ]
}
