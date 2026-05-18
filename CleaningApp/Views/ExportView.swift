import SwiftUI
import SwiftData
import CoreText
import UniformTypeIdentifiers

// MARK: - ExportView（データエクスポート）

struct ExportView: View {
    let home: Home
    @Environment(\.dismiss) private var dismiss
    @State private var exportType: ExportType = .taskHistory
    @State private var fileFormat: FileFormat = .csv
    @State private var isExporting = false
    @State private var exportedURL: URL? = nil
    @State private var showShareSheet = false
    @State private var errorMessage: String? = nil

    enum ExportType: String, CaseIterable {
        case taskHistory  = "タスク完了履歴"
        case inventory    = "消耗品在庫"
        case maintenance  = "設備メンテナンス記録"
        case allData      = "すべてのデータ"

        var icon: String {
            switch self {
            case .taskHistory:  return "checkmark.circle.fill"
            case .inventory:    return "shippingbox.fill"
            case .maintenance:  return "wrench.and.screwdriver.fill"
            case .allData:      return "square.and.arrow.up.fill"
            }
        }
    }

    enum FileFormat: String, CaseIterable {
        case csv = "CSV"
        case pdf = "PDF"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("エクスポートするデータ") {
                    ForEach(ExportType.allCases, id: \.self) { type in
                        Button { exportType = type } label: {
                            HStack(spacing: 12) {
                                Image(systemName: type.icon).foregroundStyle(.teal).frame(width: 24)
                                Text(type.rawValue).foregroundStyle(.primary)
                                Spacer()
                                if exportType == type {
                                    Image(systemName: "checkmark").foregroundStyle(.teal).fontWeight(.semibold)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section("ファイル形式") {
                    Picker("形式", selection: $fileFormat) {
                        ForEach(FileFormat.allCases, id: \.self) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                    Group {
                        if fileFormat == .csv {
                            Label("ExcelやNumbersで開けます", systemImage: "tablecells")
                                .font(.caption).foregroundStyle(.secondary)
                        } else {
                            Label("印刷・共有に適したPDF形式", systemImage: "doc.fill")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }

                Section("エクスポート対象") {
                    ExportPreviewRow(home: home, exportType: exportType)
                }

                Section {
                    Button {
                        Task { await doExport() }
                    } label: {
                        HStack {
                            Spacer()
                            if isExporting {
                                ProgressView().tint(.white)
                                Text("生成中...").foregroundStyle(.white)
                            } else {
                                Image(systemName: "square.and.arrow.up")
                                Text("\(fileFormat.rawValue)をエクスポート").fontWeight(.semibold)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4).foregroundStyle(.white)
                    }
                    .listRowBackground(Color.teal)
                    .disabled(isExporting)
                }

                if let error = errorMessage {
                    Section { Text(error).font(.caption).foregroundStyle(.red) }
                }
            }
            .navigationTitle("エクスポート")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("閉じる") { dismiss() } }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportedURL { ShareSheet(url: url) }
            }
        }
    }

    // MARK: - エクスポート実行

    private func doExport() async {
        isExporting = true
        errorMessage = nil
        defer { isExporting = false }
        do {
            let url: URL
            switch fileFormat {
            case .csv: url = try await generateCSV()
            case .pdf: url = try await generatePDF()
            }
            exportedURL = url
            showShareSheet = true
        } catch {
            errorMessage = "エクスポートに失敗しました: \(error.localizedDescription)"
        }
    }

    // MARK: - CSV生成

    private func generateCSV() async throws -> URL {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd HH:mm"
        dateFormatter.locale = Locale(identifier: "ja_JP")

        var csvString = ""
        switch exportType {
        case .taskHistory:  csvString = generateTaskHistoryCSV(dateFormatter: dateFormatter)
        case .inventory:    csvString = generateInventoryCSV(dateFormatter: dateFormatter)
        case .maintenance:  csvString = generateMaintenanceCSV(dateFormatter: dateFormatter)
        case .allData:
            csvString  = generateTaskHistoryCSV(dateFormatter: dateFormatter)
            csvString += "\n\n"
            csvString += generateInventoryCSV(dateFormatter: dateFormatter)
            csvString += "\n\n"
            csvString += generateMaintenanceCSV(dateFormatter: dateFormatter)
        }

        let fileName = "\(home.name)_\(exportType.rawValue)_\(DateFormatter.localizedString(from: .now, dateStyle: .short, timeStyle: .none).replacingOccurrences(of: "/", with: "-")).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try csvString.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private func generateTaskHistoryCSV(dateFormatter: DateFormatter) -> String {
        var rows = ["【タスク完了履歴】", "完了日時,部屋,タスク名,所要時間(分),メモ,使用パーツ"]
        for log in home.rooms.flatMap({ $0.tasks }).flatMap({ $0.logs }).sorted(by: { $0.completedAt > $1.completedAt }) {
            let parts = log.partUsages.map { "\($0.partName)×\($0.usedCount)" }.joined(separator: "・")
            rows.append("\(dateFormatter.string(from: log.completedAt)),\(log.task?.room?.name ?? ""),\(log.task?.title ?? "削除済みタスク"),\(log.durationMinutes),\(log.memo.replacingOccurrences(of: ",", with: "、")),\(parts)")
        }
        return rows.joined(separator: "\n")
    }

    private func generateInventoryCSV(dateFormatter: DateFormatter) -> String {
        var rows = ["【消耗品在庫】", "設備名,パーツ名,在庫数,単価,購入先,交換周期(月),最終交換日"]
        for part in home.rooms.flatMap({ $0.fixtures }).flatMap({ $0.parts }).sorted(by: { $0.name < $1.name }) {
            let last = part.lastReplacedAt.map { dateFormatter.string(from: $0) } ?? "未記録"
            rows.append("\(part.fixture?.name ?? ""),\(part.name),\(part.stockCount),\(part.unitPrice),\(part.purchaseStoreName),\(part.replacementMonths),\(last)")
        }
        return rows.joined(separator: "\n")
    }

    private func generateMaintenanceCSV(dateFormatter: DateFormatter) -> String {
        var rows = ["【設備メンテナンス記録】", "部屋,設備名,パーツ名,交換状況,最終交換日,次回交換予定"]
        for room in home.rooms {
            for fixture in room.fixtures {
                for part in fixture.parts {
                    let last   = part.lastReplacedAt.map { dateFormatter.string(from: $0) } ?? "未記録"
                    let next   = part.nextReplacementDate.map { dateFormatter.string(from: $0) } ?? "-"
                    rows.append("\(room.name),\(fixture.name),\(part.name),\(part.replacementStatus.label),\(last),\(next)")
                }
            }
        }
        return rows.joined(separator: "\n")
    }

    // MARK: - PDF生成（UIGraphicsPDFRenderer使用）

    private func generatePDF() async throws -> URL {
        let pageSize = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
        let renderer = UIGraphicsPDFRenderer(bounds: pageSize)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd HH:mm"
        dateFormatter.locale = Locale(identifier: "ja_JP")

        let data = renderer.pdfData { ctx in
            let margin: CGFloat = 40
            let lineH: CGFloat  = 16
            let width           = pageSize.width - margin * 2

            func newPage() {
                ctx.beginPage()
            }

            var y: CGFloat = margin
            newPage()

            func drawLine(_ text: String, fontSize: CGFloat = 10, bold: Bool = false, indent: CGFloat = 0, color: UIColor = .black) {
                if y + lineH > pageSize.height - margin { newPage(); y = margin }
                let font = bold ? UIFont.boldSystemFont(ofSize: fontSize) : UIFont.systemFont(ofSize: fontSize)
                let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
                text.draw(in: CGRect(x: margin + indent, y: y, width: width - indent, height: lineH * 2), withAttributes: attrs)
                y += lineH
            }

            func drawSectionHeader(_ text: String) {
                if y + lineH * 2 > pageSize.height - margin { newPage(); y = margin }
                UIColor.systemTeal.withAlphaComponent(0.15).setFill()
                UIRectFill(CGRect(x: margin, y: y, width: width, height: lineH + 4))
                drawLine(text, fontSize: 13, bold: true, color: UIColor(red: 0, green: 0.5, blue: 0.5, alpha: 1))
                y += 4
            }

            // タイトル
            drawLine("Pikari - \(exportType.rawValue)", fontSize: 18, bold: true)
            drawLine("エクスポート日時: \(dateFormatter.string(from: .now))  家: \(home.name)", fontSize: 9, color: .gray)
            y += 8

            switch exportType {
            case .taskHistory, .allData:
                drawSectionHeader("タスク完了履歴")
                let logs = home.rooms.flatMap { $0.tasks }.flatMap { $0.logs }.sorted { $0.completedAt > $1.completedAt }
                if logs.isEmpty { drawLine("記録がありません", color: .gray) }
                for log in logs {
                    let dur = log.durationMinutes > 0 ? "\(log.durationMinutes)分" : "-"
                    drawLine("[\(dateFormatter.string(from: log.completedAt))] \(log.task?.room?.name ?? "") / \(log.task?.title ?? "削除済み")  \(dur)", fontSize: 9, indent: 8)
                }
                y += 8
                if exportType == .taskHistory { break }
                fallthrough
            case .inventory:
                drawSectionHeader("消耗品在庫")
                let parts = home.rooms.flatMap { $0.fixtures }.flatMap { $0.parts }
                if parts.isEmpty { drawLine("パーツが登録されていません", color: .gray) }
                for part in parts {
                    let last = part.lastReplacedAt.map { dateFormatter.string(from: $0) } ?? "未記録"
                    drawLine("\(part.fixture?.name ?? "") / \(part.name)  在庫:\(part.stockCount)個  最終交換:\(last)", fontSize: 9, indent: 8)
                }
                y += 8
                if exportType == .inventory { break }
                fallthrough
            case .maintenance:
                drawSectionHeader("設備メンテナンス記録")
                for room in home.rooms {
                    for fixture in room.fixtures {
                        drawLine("【\(room.name)】\(fixture.name)", fontSize: 10, bold: true)
                        for part in fixture.parts {
                            let last = part.lastReplacedAt.map { dateFormatter.string(from: $0) } ?? "未記録"
                            let next = part.nextReplacementDate.map { dateFormatter.string(from: $0) } ?? "-"
                            drawLine("\(part.name) - \(part.replacementStatus.label)  最終:\(last)  次回:\(next)", fontSize: 9, indent: 16)
                        }
                    }
                }
            }
        }

        let fileName = "\(home.name)_\(exportType.rawValue)_\(DateFormatter.localizedString(from: .now, dateStyle: .short, timeStyle: .none).replacingOccurrences(of: "/", with: "-")).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try data.write(to: url)
        return url
    }
}

// MARK: - ExportPreviewRow

struct ExportPreviewRow: View {
    let home: Home
    let exportType: ExportView.ExportType

    var body: some View {
        let logs     = home.rooms.flatMap { $0.tasks }.flatMap { $0.logs }.count
        let parts    = home.rooms.flatMap { $0.fixtures }.flatMap { $0.parts }.count
        let fixtures = home.rooms.flatMap { $0.fixtures }.count

        switch exportType {
        case .taskHistory: LabeledContent("完了記録", value: "\(logs)件")
        case .inventory:   LabeledContent("消耗品パーツ", value: "\(parts)個")
        case .maintenance: LabeledContent("設備", value: "\(fixtures)台")
        case .allData:
            VStack(alignment: .leading, spacing: 4) {
                LabeledContent("完了記録", value: "\(logs)件")
                LabeledContent("消耗品パーツ", value: "\(parts)個")
                LabeledContent("設備", value: "\(fixtures)台")
            }
        }
    }
}

// MARK: - ShareSheet

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
