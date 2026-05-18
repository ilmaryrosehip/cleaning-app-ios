import SwiftUI
import SwiftData
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
                // エクスポートするデータの種類
                Section("エクスポートするデータ") {
                    ForEach(ExportType.allCases, id: \.self) { type in
                        Button {
                            exportType = type
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: type.icon)
                                    .foregroundStyle(.teal)
                                    .frame(width: 24)
                                Text(type.rawValue)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if exportType == type {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.teal)
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                // ファイル形式
                Section("ファイル形式") {
                    Picker("形式", selection: $fileFormat) {
                        ForEach(FileFormat.allCases, id: \.self) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)

                    // 形式の説明
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

                // プレビュー情報
                Section("エクスポート対象") {
                    ExportPreviewRow(home: home, exportType: exportType)
                }

                // エクスポートボタン
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
                                Text("\(fileFormat.rawValue)をエクスポート")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                        .foregroundStyle(.white)
                    }
                    .listRowBackground(Color.teal)
                    .disabled(isExporting)
                }

                if let error = errorMessage {
                    Section {
                        Text(error).font(.caption).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("エクスポート")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportedURL {
                    ShareSheet(url: url)
                }
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
            case .csv:
                url = try await generateCSV()
            case .pdf:
                url = try await generatePDF()
            }
            exportedURL = url
            showShareSheet = true
        } catch {
            errorMessage = "エクスポートに失敗しました: \(error.localizedDescription)"
        }
    }

    // MARK: - CSV生成

    private func generateCSV() async throws -> URL {
        var csvString = ""
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd HH:mm"
        dateFormatter.locale = Locale(identifier: "ja_JP")

        switch exportType {
        case .taskHistory:
            csvString = generateTaskHistoryCSV(dateFormatter: dateFormatter)
        case .inventory:
            csvString = generateInventoryCSV(dateFormatter: dateFormatter)
        case .maintenance:
            csvString = generateMaintenanceCSV(dateFormatter: dateFormatter)
        case .allData:
            csvString = generateTaskHistoryCSV(dateFormatter: dateFormatter)
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
        let logs = home.rooms.flatMap { $0.tasks }.flatMap { $0.logs }
            .sorted { $0.completedAt > $1.completedAt }
        for log in logs {
            let date = dateFormatter.string(from: log.completedAt)
            let room = log.task?.room?.name ?? ""
            let title = log.task?.title ?? "削除済みタスク"
            let duration = "\(log.durationMinutes)"
            let memo = log.memo.replacingOccurrences(of: ",", with: "、")
            let parts = log.partUsages.map { "\($0.partName)×\($0.usedCount)" }.joined(separator: "・")
            rows.append("\(date),\(room),\(title),\(duration),\(memo),\(parts)")
        }
        return rows.joined(separator: "\n")
    }

    private func generateInventoryCSV(dateFormatter: DateFormatter) -> String {
        var rows = ["【消耗品在庫】", "設備名,パーツ名,在庫数,単価,購入先,交換周期(月),最終交換日"]
        let parts = home.rooms.flatMap { $0.fixtures }.flatMap { $0.parts }
            .sorted { $0.name < $1.name }
        for part in parts {
            let fixture = part.fixture?.name ?? ""
            let lastReplaced = part.lastReplacedAt.map { dateFormatter.string(from: $0) } ?? "未記録"
            rows.append("\(fixture),\(part.name),\(part.stockCount),\(part.unitPrice),\(part.purchaseStoreName),\(part.replacementMonths),\(lastReplaced)")
        }
        return rows.joined(separator: "\n")
    }

    private func generateMaintenanceCSV(dateFormatter: DateFormatter) -> String {
        var rows = ["【設備メンテナンス記録】", "部屋,設備名,パーツ名,交換状況,最終交換日,次回交換予定"]
        let fixtures = home.rooms.flatMap { fixture -> [(Room, Fixture)] in
            fixture.fixtures.map { (fixture, $0) }
        }
        for (room, fixture) in fixtures {
            for part in fixture.parts {
                let lastReplaced = part.lastReplacedAt.map { dateFormatter.string(from: $0) } ?? "未記録"
                let nextDate = part.nextReplacementDate.map { dateFormatter.string(from: $0) } ?? "-"
                let status = part.replacementStatus.label
                rows.append("\(room.name),\(fixture.name),\(part.name),\(status),\(lastReplaced),\(nextDate)")
            }
        }
        return rows.joined(separator: "\n")
    }

    // MARK: - PDF生成

    private func generatePDF() async throws -> URL {
        let renderer = PDFRenderer(home: home, exportType: exportType)
        let data = renderer.render()

        let fileName = "\(home.name)_\(exportType.rawValue)_\(DateFormatter.localizedString(from: .now, dateStyle: .short, timeStyle: .none).replacingOccurrences(of: "/", with: "-")).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try data.write(to: url)
        return url
    }
}

// MARK: - ExportPreviewRow（対象データのプレビュー）

struct ExportPreviewRow: View {
    let home: Home
    let exportType: ExportView.ExportType

    private var counts: (tasks: Int, logs: Int, parts: Int, fixtures: Int) {
        let logs = home.rooms.flatMap { $0.tasks }.flatMap { $0.logs }
        let parts = home.rooms.flatMap { $0.fixtures }.flatMap { $0.parts }
        let fixtures = home.rooms.flatMap { $0.fixtures }
        return (home.rooms.flatMap { $0.tasks }.count, logs.count, parts.count, fixtures.count)
    }

    var body: some View {
        let c = counts
        switch exportType {
        case .taskHistory:
            LabeledContent("完了記録", value: "\(c.logs)件")
        case .inventory:
            LabeledContent("消耗品パーツ", value: "\(c.parts)個")
        case .maintenance:
            LabeledContent("設備", value: "\(c.fixtures)台")
        case .allData:
            VStack(alignment: .leading, spacing: 4) {
                LabeledContent("完了記録", value: "\(c.logs)件")
                LabeledContent("消耗品パーツ", value: "\(c.parts)個")
                LabeledContent("設備", value: "\(c.fixtures)台")
            }
        }
    }
}

// MARK: - PDFRenderer

struct PDFRenderer {
    let home: Home
    let exportType: ExportView.ExportType

    func render() -> Data {
        let pageWidth: CGFloat  = 595.2   // A4幅(pt)
        let pageHeight: CGFloat = 841.8   // A4高さ(pt)
        let margin: CGFloat     = 40.0
        let contentWidth        = pageWidth - margin * 2

        var pdfData = Data()
        var consumer: CGDataConsumer?
        var context: CGContext?

        pdfData.withUnsafeMutableBytes { ptr in
            var cfData = CFDataCreateMutableCopy(kCFAllocatorDefault, 0, Data() as CFData)!
            consumer = CGDataConsumer(data: cfData as CFMutableData)
        }

        // CFDataConsumer経由でPDF生成
        var mediaBox = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let cfData = NSMutableData()
        let consumer2 = CGDataConsumer(data: cfData)!
        context = CGContext(consumer: consumer2, mediaBox: &mediaBox, nil)!

        drawPDF(context: context!, pageWidth: pageWidth, pageHeight: pageHeight,
                margin: margin, contentWidth: contentWidth)

        context?.flush()
        return cfData as Data
    }

    private func drawPDF(context: CGContext, pageWidth: CGFloat, pageHeight: CGFloat,
                         margin: CGFloat, contentWidth: CGFloat) {
        var mediaBox = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        context.beginPage(mediaBox: &mediaBox)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd HH:mm"
        dateFormatter.locale = Locale(identifier: "ja_JP")

        var yPosition = pageHeight - margin

        // タイトル
        drawText(context: context,
                 text: "Pikari - \(exportType.rawValue)",
                 x: margin, y: &yPosition,
                 fontSize: 18, bold: true, width: contentWidth)
        drawText(context: context,
                 text: "エクスポート日時: \(dateFormatter.string(from: .now))  家: \(home.name)",
                 x: margin, y: &yPosition,
                 fontSize: 10, bold: false, width: contentWidth)
        yPosition -= 10

        // 区切り線
        context.setStrokeColor(CGColor(gray: 0.7, alpha: 1))
        context.setLineWidth(0.5)
        context.move(to: CGPoint(x: margin, y: yPosition))
        context.addLine(to: CGPoint(x: pageWidth - margin, y: yPosition))
        context.strokePath()
        yPosition -= 16

        switch exportType {
        case .taskHistory:
            drawTaskHistory(context: context, x: margin, y: &yPosition,
                            width: contentWidth, pageHeight: pageHeight,
                            margin: margin, formatter: dateFormatter)
        case .inventory:
            drawInventory(context: context, x: margin, y: &yPosition,
                          width: contentWidth, pageHeight: pageHeight,
                          margin: margin, formatter: dateFormatter)
        case .maintenance:
            drawMaintenance(context: context, x: margin, y: &yPosition,
                            width: contentWidth, pageHeight: pageHeight,
                            margin: margin, formatter: dateFormatter)
        case .allData:
            drawTaskHistory(context: context, x: margin, y: &yPosition,
                            width: contentWidth, pageHeight: pageHeight,
                            margin: margin, formatter: dateFormatter)
            drawInventory(context: context, x: margin, y: &yPosition,
                          width: contentWidth, pageHeight: pageHeight,
                          margin: margin, formatter: dateFormatter)
            drawMaintenance(context: context, x: margin, y: &yPosition,
                            width: contentWidth, pageHeight: pageHeight,
                            margin: margin, formatter: dateFormatter)
        }

        context.endPage()
    }

    private func drawTaskHistory(context: CGContext, x: CGFloat, y: inout CGFloat,
                                  width: CGFloat, pageHeight: CGFloat, margin: CGFloat,
                                  formatter: DateFormatter) {
        drawSectionTitle(context: context, text: "タスク完了履歴", x: x, y: &y, width: width)
        let logs = home.rooms.flatMap { $0.tasks }.flatMap { $0.logs }
            .sorted { $0.completedAt > $1.completedAt }
        if logs.isEmpty {
            drawText(context: context, text: "記録がありません", x: x, y: &y, fontSize: 10, bold: false, width: width)
        }
        for log in logs {
            let date  = formatter.string(from: log.completedAt)
            let room  = log.task?.room?.name ?? ""
            let title = log.task?.title ?? "削除済みタスク"
            let dur   = log.durationMinutes > 0 ? "\(log.durationMinutes)分" : "-"
            drawText(context: context,
                     text: "[\(date)] \(room) / \(title)  所要:\(dur)  \(log.memo)",
                     x: x + 8, y: &y, fontSize: 9, bold: false, width: width - 8)
            if y < margin + 60 {
                context.endPage()
                var box = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
                context.beginPage(mediaBox: &box)
                y = pageHeight - margin
            }
        }
        y -= 8
    }

    private func drawInventory(context: CGContext, x: CGFloat, y: inout CGFloat,
                                width: CGFloat, pageHeight: CGFloat, margin: CGFloat,
                                formatter: DateFormatter) {
        drawSectionTitle(context: context, text: "消耗品在庫", x: x, y: &y, width: width)
        let parts = home.rooms.flatMap { $0.fixtures }.flatMap { $0.parts }
        if parts.isEmpty {
            drawText(context: context, text: "パーツが登録されていません", x: x, y: &y, fontSize: 10, bold: false, width: width)
        }
        for part in parts {
            let fixture = part.fixture?.name ?? ""
            let last = part.lastReplacedAt.map { formatter.string(from: $0) } ?? "未記録"
            drawText(context: context,
                     text: "\(fixture) / \(part.name)  在庫:\(part.stockCount)個  最終交換:\(last)",
                     x: x + 8, y: &y, fontSize: 9, bold: false, width: width - 8)
        }
        y -= 8
    }

    private func drawMaintenance(context: CGContext, x: CGFloat, y: inout CGFloat,
                                  width: CGFloat, pageHeight: CGFloat, margin: CGFloat,
                                  formatter: DateFormatter) {
        drawSectionTitle(context: context, text: "設備メンテナンス記録", x: x, y: &y, width: width)
        for room in home.rooms {
            for fixture in room.fixtures {
                drawText(context: context, text: "【\(room.name)】\(fixture.name)",
                         x: x, y: &y, fontSize: 10, bold: true, width: width)
                for part in fixture.parts {
                    let last = part.lastReplacedAt.map { formatter.string(from: $0) } ?? "未記録"
                    let next = part.nextReplacementDate.map { formatter.string(from: $0) } ?? "-"
                    let status = part.replacementStatus.label
                    drawText(context: context,
                             text: "  \(part.name) - \(status)  最終:\(last)  次回:\(next)",
                             x: x + 8, y: &y, fontSize: 9, bold: false, width: width - 8)
                }
            }
        }
    }

    private func drawSectionTitle(context: CGContext, text: String, x: CGFloat, y: inout CGFloat, width: CGFloat) {
        context.setFillColor(CGColor(red: 0, green: 0.6, blue: 0.6, alpha: 0.15))
        context.fill(CGRect(x: x, y: y - 16, width: width, height: 18))
        drawText(context: context, text: text, x: x + 4, y: &y, fontSize: 12, bold: true, width: width)
        y -= 4
    }

    private let pageWidth: CGFloat = 595.2
    private let pageHeight: CGFloat = 841.8

    private func drawText(context: CGContext, text: String, x: CGFloat, y: inout CGFloat,
                          fontSize: CGFloat, bold: Bool, width: CGFloat) {
        let font = bold
            ? CTFontCreateWithName("HiraKakuProN-W6" as CFString, fontSize, nil)
            : CTFontCreateWithName("HiraKakuProN-W3" as CFString, fontSize, nil)

        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: CGColor(gray: 0.1, alpha: 1)
        ]
        let attrStr = NSAttributedString(string: text, attributes: attrs)
        let framesetter = CTFramesetterCreate(attrStr, CFRangeMake(0, 0))

        let estimatedSize = CTFramesetterSuggestFrameSizeWithConstraints(
            framesetter, CFRangeMake(0, 0),
            nil, CGSize(width: width, height: CGFloat.greatestFiniteMagnitude), nil
        )
        let lineHeight = max(estimatedSize.height, fontSize + 4)

        let framePath = CGPath(rect: CGRect(x: x, y: y - lineHeight, width: width, height: lineHeight), transform: nil)
        let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), framePath, nil)

        context.saveGState()
        context.translateBy(x: 0, y: pageHeight)
        context.scaleBy(x: 1, y: -1)
        CTFrameDraw(frame, context)
        context.restoreGState()

        y -= lineHeight + 2
    }
}

// MARK: - ShareSheet（共有シート）

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
