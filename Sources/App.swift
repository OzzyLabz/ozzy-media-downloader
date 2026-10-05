import AppKit
import CoreText

@main
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, NSTextFieldDelegate {
    private var window: NSWindow!
    private var linkField: NSTextField!
    private var preview: NSImageView!
    private var previewTitle: NSTextField!
    private var formatScroll: NSScrollView!
    private var estimateLabel: NSTextField!
    private var cancelAllButton: NSButton!
    private var subtitleCheck: NSButton!
    private var subtitleStateLabel: NSTextField!
    private var subtitlePopup: NSPopUpButton!
    private var embedCheck: NSButton!
    private var folderField: NSTextField!
    private var downloadButton: NSButton!
    private var analyzeButton: NSButton!
    private var taskScroll: NSScrollView!
    private var statusItem: NSStatusItem?
    private var statusMenu: NSMenu!
    private var estimateTimer: Timer?
    private let manager = DownloadManager()
    private var media: MediaInfo?
    private var selectedVariantIndex = 0
    private var destination: URL?
    private let destinationKey = "lastDownloadFolder"
    private var analysisToken = UUID()
    private var analysisTimer: Timer?
    private var analysisStartedAt: Date?
    private var analysisPhase = "Соединяемся с источником"
    private var analysisAttempt = 1
    private var isAnalyzing = false
    private var analysisFailed = false
    private var connectionFailure = false

    static func main() {
        let application = NSApplication.shared
        let delegate = AppDelegate()
        application.delegate = delegate
        application.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.appearance = NSAppearance(named: .darkAqua)
        registerBundledFont()
        makeMainMenu()
        makeWindow()
        restoreDestination()
        makeStatusMenu()
        manager.onChange = { [weak self] in
            self?.rebuildTasks()
            self?.updateStatusTooltip()
            self?.updateEstimate()
        }
        showFallbackPreview()
        rebuildFormats()
        rebuildTasks()
        updateEstimate()
        estimateTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateEstimate()
        }
        let available = NSScreen.main?.visibleFrame.insetBy(dx: 24, dy: 24)
        let size = NSSize(
            width: min(ReferenceLayout.initialSize.width, available?.width ?? ReferenceLayout.initialSize.width),
            height: min(ReferenceLayout.initialSize.height, available?.height ?? ReferenceLayout.initialSize.height)
        )
        window.setContentSize(size)
        window.center()
        window.makeKeyAndOrderFront(nil)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.window.setContentSize(size)
            self.window.center()
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if manager.hasUnfinishedTasks {
            let alert = NSAlert()
            alert.messageText = "Загрузки ещё выполняются"
            alert.informativeText = "Если закрыть программу, текущие загрузки будут остановлены. Закрытие только окна оставит их работающими."
            alert.addButton(withTitle: "Остаться")
            alert.addButton(withTitle: "Закрыть программу")
            alert.alertStyle = .warning
            if alert.runModal() != .alertSecondButtonReturn { return .terminateCancel }
            manager.cancelAll()
        }
        return .terminateNow
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        window.orderOut(nil)
        showStatusItem()
        NSApp.setActivationPolicy(.accessory)
        return false
    }

    private func makeWindow() {
        let style: NSWindow.StyleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
        window = NSWindow(contentRect: NSRect(origin: .zero, size: ReferenceLayout.initialSize), styleMask: style, backing: .buffered, defer: false)
        window.title = "Программа скачивания"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.backgroundColor = ReferenceLayout.background
        window.isOpaque = false
        window.minSize = ReferenceLayout.minimumSize
        window.collectionBehavior.insert(.fullScreenPrimary)
        window.center()
        window.delegate = self

        let root = GradientBorderView()
        root.wantsLayer = true
        root.layer?.backgroundColor = ReferenceLayout.background.cgColor
        window.contentView = root

        let main = NSStackView()
        main.orientation = .vertical
        main.spacing = ReferenceLayout.gap
        main.alignment = .leading
        main.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(main)
        NSLayoutConstraint.activate([
            main.topAnchor.constraint(equalTo: root.topAnchor, constant: 46),
            main.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: ReferenceLayout.margin),
            main.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -ReferenceLayout.margin),
            main.bottomAnchor.constraint(equalTo: root.bottomAnchor, constant: -ReferenceLayout.margin)
        ])

        let link = makeLinkPanel()
        let middle = makeMiddlePanels()
        let options = makeOptionsPanels()
        let tasks = makeTasksPanel()
        [link, middle, options, tasks].forEach { main.addArrangedSubview($0) }
        NSLayoutConstraint.activate([
            link.widthAnchor.constraint(equalTo: main.widthAnchor), link.heightAnchor.constraint(equalToConstant: 70),
            middle.widthAnchor.constraint(equalTo: main.widthAnchor), middle.heightAnchor.constraint(equalToConstant: 240),
            options.widthAnchor.constraint(equalTo: main.widthAnchor), options.heightAnchor.constraint(equalToConstant: 110),
            tasks.widthAnchor.constraint(equalTo: main.widthAnchor)
        ])
    }

    private func makeLinkPanel() -> NSView {
        let panel = DarkPanel()
        let label = makeLabel("Ссылка", size: 18, bold: true)
        linkField = NSTextField()
        linkField.placeholderString = "Вставьте ссылку на видео или аудио..."
        styleInput(linkField)
        linkField.target = self
        linkField.action = #selector(analyzeFromField)
        linkField.delegate = self
        linkField.menu = makeEditActionsMenu()
        let clear = makeButton("Очистить", action: #selector(clearLink))
        let paste = makeButton("Вставить", action: #selector(pasteLink), accent: true)
        [label, linkField!, clear, paste].forEach { panel.addSubview($0); $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 20), label.centerYAnchor.constraint(equalTo: panel.centerYAnchor), label.widthAnchor.constraint(equalToConstant: 72),
            linkField.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 8), linkField.centerYAnchor.constraint(equalTo: panel.centerYAnchor), linkField.heightAnchor.constraint(equalToConstant: 38),
            clear.leadingAnchor.constraint(equalTo: linkField.trailingAnchor, constant: 10), clear.centerYAnchor.constraint(equalTo: panel.centerYAnchor), clear.widthAnchor.constraint(equalToConstant: 105), clear.heightAnchor.constraint(equalToConstant: 40),
            paste.leadingAnchor.constraint(equalTo: clear.trailingAnchor, constant: 10), paste.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -18), paste.centerYAnchor.constraint(equalTo: panel.centerYAnchor), paste.widthAnchor.constraint(equalToConstant: 110), paste.heightAnchor.constraint(equalToConstant: 40)
        ])
        return panel
    }

    private func makeMiddlePanels() -> NSView {
        let row = NSView()
        let previewPanel = DarkPanel()
        let formatsPanel = DarkPanel()
        [previewPanel, formatsPanel].forEach { row.addSubview($0); $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            previewPanel.leadingAnchor.constraint(equalTo: row.leadingAnchor), previewPanel.topAnchor.constraint(equalTo: row.topAnchor), previewPanel.bottomAnchor.constraint(equalTo: row.bottomAnchor),
            previewPanel.widthAnchor.constraint(equalTo: row.widthAnchor, multiplier: ReferenceLayout.previewWidthRatio),
            formatsPanel.leadingAnchor.constraint(equalTo: previewPanel.trailingAnchor, constant: ReferenceLayout.gap), formatsPanel.trailingAnchor.constraint(equalTo: row.trailingAnchor), formatsPanel.topAnchor.constraint(equalTo: row.topAnchor), formatsPanel.bottomAnchor.constraint(equalTo: row.bottomAnchor)
        ])

        let previewHeading = makeLabel("▣  Превью", size: 16, bold: true)
        preview = NSImageView()
        preview.imageScaling = .scaleProportionallyUpOrDown
        preview.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        preview.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        preview.setContentHuggingPriority(.defaultLow, for: .horizontal)
        preview.setContentHuggingPriority(.defaultLow, for: .vertical)
        preview.wantsLayer = true
        preview.layer?.cornerRadius = 10
        preview.layer?.masksToBounds = true
        previewTitle = makeLabel("", size: 12)
        previewTitle.textColor = ReferenceLayout.muted
        previewTitle.lineBreakMode = .byTruncatingTail
        previewTitle.maximumNumberOfLines = 1
        previewTitle.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        [previewHeading, preview!, previewTitle!].forEach { previewPanel.addSubview($0); $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            previewHeading.topAnchor.constraint(equalTo: previewPanel.topAnchor, constant: 15), previewHeading.leadingAnchor.constraint(equalTo: previewPanel.leadingAnchor, constant: 16),
            preview.leadingAnchor.constraint(equalTo: previewPanel.leadingAnchor, constant: 16), preview.trailingAnchor.constraint(equalTo: previewPanel.trailingAnchor, constant: -16), preview.topAnchor.constraint(equalTo: previewHeading.bottomAnchor, constant: 12), preview.bottomAnchor.constraint(equalTo: previewTitle.topAnchor, constant: -8),
            previewTitle.leadingAnchor.constraint(equalTo: preview.leadingAnchor), previewTitle.trailingAnchor.constraint(equalTo: preview.trailingAnchor), previewTitle.bottomAnchor.constraint(equalTo: previewPanel.bottomAnchor, constant: -12), previewTitle.heightAnchor.constraint(equalToConstant: 18)
        ])

        let formatsHeading = makeLabel("◉  Форматы", size: 16, bold: true)
        analyzeButton = makeButton("Анализировать", action: #selector(analyzeFromField))
        downloadButton = makeButton("Скачать", action: #selector(enqueueDownload), accent: true)
        downloadButton.isEnabled = false
        formatScroll = makeScrollView()
        [formatsHeading, analyzeButton!, downloadButton!, formatScroll!].forEach { formatsPanel.addSubview($0); $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            formatsHeading.topAnchor.constraint(equalTo: formatsPanel.topAnchor, constant: 15), formatsHeading.leadingAnchor.constraint(equalTo: formatsPanel.leadingAnchor, constant: 16),
            analyzeButton.centerYAnchor.constraint(equalTo: formatsHeading.centerYAnchor), analyzeButton.trailingAnchor.constraint(equalTo: downloadButton.leadingAnchor, constant: -8), analyzeButton.widthAnchor.constraint(equalToConstant: 116), analyzeButton.heightAnchor.constraint(equalToConstant: 32),
            downloadButton.centerYAnchor.constraint(equalTo: formatsHeading.centerYAnchor), downloadButton.trailingAnchor.constraint(equalTo: formatsPanel.trailingAnchor, constant: -16), downloadButton.widthAnchor.constraint(equalToConstant: 100), downloadButton.heightAnchor.constraint(equalToConstant: 32),
            formatScroll.topAnchor.constraint(equalTo: formatsHeading.bottomAnchor, constant: 12), formatScroll.leadingAnchor.constraint(equalTo: formatsPanel.leadingAnchor, constant: 16), formatScroll.trailingAnchor.constraint(equalTo: formatsPanel.trailingAnchor, constant: -16), formatScroll.bottomAnchor.constraint(equalTo: formatsPanel.bottomAnchor, constant: -12)
        ])
        return row
    }

    private func makeOptionsPanels() -> NSView {
        let row = NSView()
        let estimate = DarkPanel(), subs = DarkPanel(), logo = DarkPanel(), folder = DarkPanel()
        [estimate, subs, logo, folder].forEach { row.addSubview($0); $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            estimate.leadingAnchor.constraint(equalTo: row.leadingAnchor), estimate.topAnchor.constraint(equalTo: row.topAnchor), estimate.bottomAnchor.constraint(equalTo: row.bottomAnchor), estimate.widthAnchor.constraint(equalTo: row.widthAnchor, multiplier: ReferenceLayout.previewWidthRatio),
            subs.leadingAnchor.constraint(equalTo: estimate.trailingAnchor, constant: ReferenceLayout.gap), subs.topAnchor.constraint(equalTo: row.topAnchor), subs.bottomAnchor.constraint(equalTo: row.bottomAnchor), subs.widthAnchor.constraint(equalTo: row.widthAnchor, multiplier: 0.21),
            logo.leadingAnchor.constraint(equalTo: subs.trailingAnchor, constant: ReferenceLayout.gap), logo.topAnchor.constraint(equalTo: row.topAnchor), logo.bottomAnchor.constraint(equalTo: row.bottomAnchor), logo.widthAnchor.constraint(equalTo: row.widthAnchor, multiplier: 0.11),
            folder.leadingAnchor.constraint(equalTo: logo.trailingAnchor, constant: ReferenceLayout.gap), folder.trailingAnchor.constraint(equalTo: row.trailingAnchor), folder.topAnchor.constraint(equalTo: row.topAnchor), folder.bottomAnchor.constraint(equalTo: row.bottomAnchor)
        ])
        let estimateHeading = makeLabel("◷  Осталось до завершения", size: 15, bold: true)
        estimateLabel = makeLabel("Загрузок пока нет", size: 12)
        estimateLabel.textColor = ReferenceLayout.muted
        estimateLabel.lineBreakMode = .byWordWrapping
        estimateLabel.maximumNumberOfLines = 2
        estimateLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        cancelAllButton = makeButton("Отменить все", action: #selector(cancelAllDownloads))
        styleCancelButton(cancelAllButton, enabled: false)
        [estimateHeading, estimateLabel!, cancelAllButton!].forEach { estimate.addSubview($0); $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            estimateHeading.topAnchor.constraint(equalTo: estimate.topAnchor, constant: 16), estimateHeading.leadingAnchor.constraint(equalTo: estimate.leadingAnchor, constant: 16),
            estimateLabel.topAnchor.constraint(equalTo: estimateHeading.bottomAnchor, constant: 10), estimateLabel.leadingAnchor.constraint(equalTo: estimate.leadingAnchor, constant: 16), estimateLabel.trailingAnchor.constraint(equalTo: cancelAllButton.leadingAnchor, constant: -8), estimateLabel.bottomAnchor.constraint(lessThanOrEqualTo: estimate.bottomAnchor, constant: -10),
            cancelAllButton.trailingAnchor.constraint(equalTo: estimate.trailingAnchor, constant: -14), cancelAllButton.centerYAnchor.constraint(equalTo: estimateLabel.centerYAnchor), cancelAllButton.widthAnchor.constraint(equalToConstant: 105), cancelAllButton.heightAnchor.constraint(equalToConstant: 32)
        ])
        let sLabel = makeLabel("▣  Субтитры", size: 15, bold: true)
        subtitleCheck = SubtitleToggleButton(title: "", target: self, action: #selector(subtitleChanged))
        subtitleStateLabel = makeLabel("Выкл.", size: 13)
        subtitlePopup = NSPopUpButton()
        subtitlePopup.font = interfaceFont(12)
        subtitlePopup.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        subtitlePopup.cell?.lineBreakMode = .byTruncatingTail
        embedCheck = NSButton(checkboxWithTitle: "Встроить в видео", target: nil, action: nil)
        embedCheck.font = interfaceFont(12)
        [sLabel, subtitleCheck!, subtitleStateLabel!, subtitlePopup!, embedCheck!].forEach { subs.addSubview($0); $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            sLabel.topAnchor.constraint(equalTo: subs.topAnchor, constant: 13), sLabel.leadingAnchor.constraint(equalTo: subs.leadingAnchor, constant: 16),
            subtitleCheck.leadingAnchor.constraint(equalTo: subs.leadingAnchor, constant: 16), subtitleCheck.topAnchor.constraint(equalTo: sLabel.bottomAnchor, constant: 9), subtitleCheck.widthAnchor.constraint(equalToConstant: 44), subtitleCheck.heightAnchor.constraint(equalToConstant: 24),
            subtitleStateLabel.leadingAnchor.constraint(equalTo: subtitleCheck.trailingAnchor, constant: 8), subtitleStateLabel.centerYAnchor.constraint(equalTo: subtitleCheck.centerYAnchor), subtitleStateLabel.widthAnchor.constraint(equalToConstant: 38),
            subtitlePopup.leadingAnchor.constraint(equalTo: subtitleStateLabel.trailingAnchor, constant: 6), subtitlePopup.trailingAnchor.constraint(equalTo: subs.trailingAnchor, constant: -14), subtitlePopup.centerYAnchor.constraint(equalTo: subtitleCheck.centerYAnchor),
            embedCheck.leadingAnchor.constraint(equalTo: subs.leadingAnchor, constant: 16), embedCheck.topAnchor.constraint(equalTo: subtitleCheck.bottomAnchor, constant: 6)
        ])
        let fLabel = makeLabel("▱  Папка", size: 15, bold: true)
        folderField = NSTextField()
        folderField.placeholderString = "Выберите папку сохранения"
        styleInput(folderField)
        folderField.isEditable = false
        let browse = makeButton("Выбрать…", action: #selector(chooseFolder))
        [fLabel, folderField!, browse].forEach { folder.addSubview($0); $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            fLabel.topAnchor.constraint(equalTo: folder.topAnchor, constant: 16), fLabel.leadingAnchor.constraint(equalTo: folder.leadingAnchor, constant: 16),
            folderField.topAnchor.constraint(equalTo: fLabel.bottomAnchor, constant: 12), folderField.leadingAnchor.constraint(equalTo: folder.leadingAnchor, constant: 16), folderField.heightAnchor.constraint(equalToConstant: 35),
            browse.leadingAnchor.constraint(equalTo: folderField.trailingAnchor, constant: 8), browse.trailingAnchor.constraint(equalTo: folder.trailingAnchor, constant: -16), browse.centerYAnchor.constraint(equalTo: folderField.centerYAnchor), browse.widthAnchor.constraint(equalToConstant: 92), browse.heightAnchor.constraint(equalToConstant: 35)
        ])
        subtitleCheck.isEnabled = false
        subtitlePopup.isEnabled = false
        embedCheck.isEnabled = false
        let authorButton = NeonLogoButton(frame: .zero)
        authorButton.target = self
        authorButton.action = #selector(showAuthor)
        authorButton.setAccessibilityLabel("Об авторе программы")
        if let path = Bundle.main.path(forResource: "oleg", ofType: "png"),
           let original = NSImage(contentsOfFile: path),
           let source = original.cgImage(forProposedRect: nil, context: nil, hints: nil),
           let cropped = source.cropping(to: CGRect(x: 324, y: 247, width: 976, height: 432)) {
            authorButton.image = NSImage(cgImage: cropped, size: NSSize(width: cropped.width, height: cropped.height))
        }
        logo.addSubview(authorButton)
        authorButton.translatesAutoresizingMaskIntoConstraints = false
        let logoEdges = [
            authorButton.leadingAnchor.constraint(equalTo: logo.leadingAnchor, constant: 8),
            authorButton.trailingAnchor.constraint(equalTo: logo.trailingAnchor, constant: -8),
            authorButton.topAnchor.constraint(equalTo: logo.topAnchor, constant: 8),
            authorButton.bottomAnchor.constraint(equalTo: logo.bottomAnchor, constant: -8)
        ]
        NSLayoutConstraint.activate(logoEdges)
        authorButton.setEdgeConstraints(logoEdges)
        return row
    }

    private func makeTasksPanel() -> NSView {
        let panel = DarkPanel()
        let heading = makeLabel("⇩  Скачивание", size: 16, bold: true)
        taskScroll = makeScrollView()
        [heading, taskScroll!].forEach { panel.addSubview($0); $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            heading.topAnchor.constraint(equalTo: panel.topAnchor, constant: 13), heading.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 17),
            taskScroll.topAnchor.constraint(equalTo: heading.bottomAnchor, constant: 10), taskScroll.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 15), taskScroll.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -15), taskScroll.bottomAnchor.constraint(equalTo: panel.bottomAnchor, constant: -12)
        ])
        return panel
    }

    private func makeScrollView() -> NSScrollView {
        let scroll = NSScrollView()
        scroll.drawsBackground = false
        scroll.hasVerticalScroller = true
        scroll.borderType = .noBorder
        scroll.documentView = FlippedView()
        return scroll
    }

    private func makeLabel(_ text: String, size: CGFloat, bold: Bool = false) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.textColor = ReferenceLayout.text
        label.font = interfaceFont(size, fallbackBold: bold)
        return label
    }

    private func registerBundledFont() {
        guard let url = Bundle.main.url(forResource: "Bellota-Bold", withExtension: "ttf", subdirectory: "Fonts") else { return }
        var error: Unmanaged<CFError>?
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
    }

    private func interfaceFont(_ size: CGFloat, fallbackBold: Bool = false) -> NSFont {
        NSFont(name: "Bellota-Bold", size: size)
            ?? (fallbackBold ? .boldSystemFont(ofSize: size) : .systemFont(ofSize: size))
    }

    private func makeButton(_ text: String, action: Selector, accent: Bool = false) -> NSButton {
        let button = NSButton(title: text, target: self, action: action)
        button.isBordered = false
        button.font = interfaceFont(13, fallbackBold: true)
        button.wantsLayer = true
        button.layer?.backgroundColor = (accent ? ReferenceLayout.accent : ReferenceLayout.panelBorder).cgColor
        button.layer?.cornerRadius = 9
        button.contentTintColor = .white
        return button
    }

    private func styleCancelButton(_ button: NSButton, enabled: Bool) {
        button.isEnabled = enabled
        let red = NSColor(srgbRed: 0.97, green: 0.28, blue: 0.36, alpha: 1)
        button.layer?.backgroundColor = enabled
            ? NSColor(srgbRed: 0.24, green: 0.055, blue: 0.095, alpha: 1).cgColor
            : ReferenceLayout.panelBorder.withAlphaComponent(0.42).cgColor
        button.layer?.borderColor = red.withAlphaComponent(0.78).cgColor
        button.layer?.borderWidth = enabled ? 1.2 : 0
        button.attributedTitle = NSAttributedString(
            string: button.title,
            attributes: [.font: interfaceFont(13, fallbackBold: true),
                         .foregroundColor: enabled ? red : ReferenceLayout.muted]
        )
    }

    private func styleInput(_ field: NSTextField) {
        let placeholder = field.placeholderString
        field.cell = VerticallyCenteredTextFieldCell(textCell: field.stringValue)
        field.placeholderString = placeholder
        field.isSelectable = true
        field.isEditable = true
        field.isBezeled = false
        field.drawsBackground = true
        field.backgroundColor = ReferenceLayout.background
        field.textColor = ReferenceLayout.text
        field.font = interfaceFont(14)
        field.wantsLayer = true
        field.layer?.cornerRadius = 8
        field.layer?.borderWidth = 1
        field.layer?.borderColor = ReferenceLayout.panelBorder.cgColor
    }

    private func makeMainMenu() {
        let menu = NSMenu()
        let appItem = NSMenuItem()
        let appMenu = NSMenu(title: "Программа скачивания")
        let quitItem = NSMenuItem(title: "Закрыть программу", action: #selector(quitFromMenu), keyEquivalent: "q")
        quitItem.target = self
        appMenu.addItem(quitItem)
        appItem.submenu = appMenu
        menu.addItem(appItem)

        let editItem = NSMenuItem()
        editItem.submenu = makeEditActionsMenu()
        menu.addItem(editItem)
        NSApp.mainMenu = menu
    }

    private func makeEditActionsMenu() -> NSMenu {
        let menu = NSMenu(title: "Правка")
        for (title, action, key) in [
            ("Вырезать", #selector(NSText.cut(_:)), "x"),
            ("Копировать", #selector(NSText.copy(_:)), "c"),
            ("Вставить", #selector(NSText.paste(_:)), "v"),
            ("Выбрать всё", #selector(NSText.selectAll(_:)), "a")
        ] {
            menu.addItem(NSMenuItem(title: title, action: action, keyEquivalent: key))
        }
        return menu
    }

    @objc private func pasteLink() {
        linkField.stringValue = NSPasteboard.general.string(forType: .string) ?? ""
        resetAnalysisForNewLink()
    }

    func controlTextDidChange(_ notification: Notification) {
        guard (notification.object as? NSTextField) === linkField else { return }
        resetAnalysisForNewLink()
    }

    private func resetAnalysisForNewLink() {
        analysisTimer?.invalidate()
        analysisTimer = nil
        analysisToken = UUID()
        isAnalyzing = false
        analysisFailed = false
        connectionFailure = false
        media = nil
        analyzeButton.isEnabled = true
        previewTitle.stringValue = ""
        showFallbackPreview()
        rebuildFormats()
    }

    @objc private func clearLink() {
        linkField.stringValue = ""
        resetAnalysisForNewLink()
        selectedVariantIndex = 0
    }

    @objc private func analyzeFromField() {
        guard let url = URL(string: linkField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)), MediaAnalyzer.isValidURL(url) else {
            showError("Вставьте корректную ссылку.")
            return
        }
        let token = UUID()
        analysisToken = token
        isAnalyzing = true
        analysisFailed = false
        connectionFailure = false
        analysisPhase = "Соединяемся с источником"
        analysisAttempt = 1
        analysisStartedAt = Date()
        analysisTimer?.invalidate()
        analysisTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard self?.isAnalyzing == true else { return }
            self?.rebuildFormats()
        }
        media = nil
        previewTitle.stringValue = "Анализ ссылки…"
        analyzeButton.isEnabled = false
        downloadButton.isEnabled = false
        rebuildFormats()
        MediaAnalyzer.analyze(url, progress: { [weak self] update in
            guard let self, self.analysisToken == token else { return }
            if self.analysisAttempt != update.attempt {
                self.analysisAttempt = update.attempt
                self.analysisStartedAt = Date()
            }
            self.analysisPhase = update.phase
            self.rebuildFormats()
        }) { [weak self] result in
            guard let self, self.analysisToken == token else { return }
            self.analysisTimer?.invalidate()
            self.analysisTimer = nil
            self.isAnalyzing = false
            self.analyzeButton.isEnabled = true
            switch result {
            case .success(let info):
                self.media = info
                self.selectedVariantIndex = 0
                self.previewTitle.stringValue = info.title
                self.showPreview(for: info)
                self.rebuildFormats()
            case .failure(let error):
                self.analysisFailed = true
                self.connectionFailure = error.isConnectionFailure
                self.previewTitle.stringValue = error.localizedDescription
                self.showFallbackPreview()
                self.rebuildFormats()
            }
        }
    }

    private func showFallbackPreview() {
        let path = Bundle.main.path(forResource: "отсудствие превью", ofType: "png")
        preview.image = path.flatMap(NSImage.init(contentsOfFile:))
    }

    private func showPreview(for info: MediaInfo) {
        showFallbackPreview()
        guard let url = info.thumbnailURL else { return }
        let expected = info.id
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data, let image = NSImage(data: data) else { return }
            DispatchQueue.main.async {
                guard self?.media?.id == expected else { return }
                self?.preview.image = image
            }
        }.resume()
    }

    private func rebuildFormats() {
        let width = max(300, formatScroll.contentSize.width - 4)
        let variants = media?.variants ?? []
        let document = FlippedView(frame: NSRect(x: 0, y: 0, width: width, height: max(200, CGFloat(variants.count) * 48)))
        if variants.isEmpty {
            let elapsed = min(MediaAnalyzer.timeoutSeconds, Int(Date().timeIntervalSince(analysisStartedAt ?? Date())))
            let message = isAnalyzing
                ? "Попытка \(analysisAttempt) из \(MediaAnalyzer.maxAttempts): \(analysisPhase) · \(elapsed) из \(MediaAnalyzer.timeoutSeconds) с"
                : (analysisFailed ? "Форматы недоступны. Подробности — под превью." : "Вставьте ссылку и нажмите «Анализировать».")
            let empty = makeLabel(message, size: 14)
            empty.textColor = ReferenceLayout.muted
            empty.frame = NSRect(x: 10, y: 16, width: width - 20, height: 25)
            document.addSubview(empty)
            if connectionFailure {
                let advice = makeLabel("Для более устойчивого соединения можно попробовать удобный вам VPN.", size: 13)
                advice.textColor = ReferenceLayout.muted
                advice.frame = NSRect(x: 10, y: 48, width: width - 20, height: 40)
                advice.lineBreakMode = .byWordWrapping
                document.addSubview(advice)
            }
        }
        for (index, variant) in variants.enumerated() {
            let button = makeButton("", action: #selector(selectVariant))
            button.tag = index
            button.setAccessibilityLabel(variant.label)
            button.frame = NSRect(x: 2, y: CGFloat(index) * 48, width: width - 10, height: 42)
            button.autoresizingMask = .width
            button.layer?.backgroundColor = (index == selectedVariantIndex ? ReferenceLayout.accent.withAlphaComponent(0.30) : ReferenceLayout.background).cgColor
            button.layer?.borderWidth = 1
            button.layer?.borderColor = (index == selectedVariantIndex ? ReferenceLayout.accent : ReferenceLayout.panelBorder).cgColor
            button.layer?.cornerRadius = 10
            button.layer?.shadowColor = NSColor.black.cgColor
            button.layer?.shadowOpacity = 0.22
            button.layer?.shadowRadius = 4
            button.layer?.shadowOffset = CGSize(width: 0, height: -2)
            let circle = FormatOverlayLabel(labelWithString: index == selectedVariantIndex ? "◉" : "○")
            circle.font = .systemFont(ofSize: 19)
            circle.textColor = index == selectedVariantIndex ? ReferenceLayout.accent : ReferenceLayout.muted
            circle.frame = NSRect(x: 18, y: 10, width: 24, height: 23)
            let name = FormatOverlayLabel(labelWithString: variant.label)
            name.font = interfaceFont(14, fallbackBold: true)
            name.textColor = ReferenceLayout.text
            name.frame = NSRect(x: 52, y: 11, width: width - 76, height: 22)
            name.autoresizingMask = .width
            button.addSubview(circle)
            button.addSubview(name)
            document.addSubview(button)
        }
        formatScroll.documentView = document
        downloadButton.isEnabled = !variants.isEmpty
        subtitlePopup.removeAllItems()
        media?.subtitles.forEach { subtitlePopup.addItem(withTitle: $0.label) }
        updateSubtitleControls()
    }

    @objc private func selectVariant(_ sender: NSButton) {
        selectedVariantIndex = sender.tag
        rebuildFormats()
    }

    @objc private func subtitleChanged() { updateSubtitleControls() }

    private func updateSubtitleControls() {
        let video = media?.variants.indices.contains(selectedVariantIndex) == true && media?.variants[selectedVariantIndex].kind == .video
        let available = video && !(media?.subtitles.isEmpty ?? true)
        subtitleCheck.isEnabled = available
        if !available { subtitleCheck.state = .off }
        subtitleStateLabel.stringValue = subtitleCheck.state == .on ? "Вкл." : "Выкл."
        subtitleStateLabel.textColor = available ? ReferenceLayout.text : ReferenceLayout.muted
        subtitleCheck.needsDisplay = true
        subtitlePopup.isEnabled = available && subtitleCheck.state == .on
        embedCheck.isEnabled = available && subtitleCheck.state == .on
    }

    @objc private func chooseFolder() {
        let picker = NSOpenPanel()
        picker.canChooseDirectories = true
        picker.canChooseFiles = false
        picker.allowsMultipleSelection = false
        picker.prompt = "Выбрать"
        picker.beginSheetModal(for: window) { [weak self] response in
            guard let self, response == .OK, let url = picker.url else { return }
            self.destination = url
            self.folderField.stringValue = url.path
            UserDefaults.standard.set(url.path, forKey: self.destinationKey)
        }
    }

    private func restoreDestination() {
        guard let path = UserDefaults.standard.string(forKey: destinationKey) else { return }
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory), isDirectory.boolValue else {
            UserDefaults.standard.removeObject(forKey: destinationKey)
            return
        }
        destination = URL(fileURLWithPath: path, isDirectory: true)
        folderField.stringValue = path
    }

    @objc private func enqueueDownload() {
        guard let info = media, info.variants.indices.contains(selectedVariantIndex) else { return }
        guard let destination else { showError("Сначала выберите папку сохранения."); return }
        let variant = info.variants[selectedVariantIndex]
        let subtitleIndex = subtitlePopup.indexOfSelectedItem
        let subtitle = subtitleCheck.state == .on && info.subtitles.indices.contains(subtitleIndex) ? info.subtitles[subtitleIndex] : nil
        let selection = DownloadSelection(info: info, variant: variant, subtitle: subtitle, embedSubtitle: subtitle != nil && embedCheck.state == .on)
        guard !manager.hasUnfinishedDownload(for: info) else {
            showError("Это медиа уже скачивается или ожидает в очереди.")
            return
        }
        manager.enqueue(selection: selection, destination: destination)
        clearLink()
    }

    private func rebuildTasks() {
        guard let taskScroll else { return }
        let width = max(400, taskScroll.contentSize.width - 4)
        let height = max(100, CGFloat(manager.tasks.count) * 88)
        let document = FlippedView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        if manager.tasks.isEmpty {
            let empty = makeLabel("Загрузок пока нет", size: 13)
            empty.textColor = ReferenceLayout.muted
            empty.frame = NSRect(x: 8, y: 4, width: 300, height: 24)
            document.addSubview(empty)
        }
        for (index, task) in manager.tasks.enumerated() {
            let row = DarkPanel(frame: NSRect(x: 2, y: CGFloat(index) * 88, width: width - 12, height: 80))
            row.autoresizingMask = .width
            let title = makeLabel(task.selection.info.title, size: 13, bold: true)
            title.lineBreakMode = .byTruncatingMiddle
            let number = makeLabel("\(task.number)", size: 15, bold: true)
            number.alignment = .center
            number.textColor = ReferenceLayout.accent
            let progress = DownloadProgressView()
            progress.fraction = task.fraction ?? 0
            let details = [
                task.selection.variant.label,
                task.state.label,
                task.fraction.map { "\(Int($0 * 100))%" },
                task.downloadedBytes > 0 ? "\(ByteCountFormatter.string(fromByteCount: Int64(task.downloadedBytes), countStyle: .file))\(task.expectedBytes.map { " из \(ByteCountFormatter.string(fromByteCount: Int64($0), countStyle: .file))" } ?? "")" : nil,
                task.state == .downloading ? task.speed.map { "\(ByteCountFormatter.string(fromByteCount: Int64($0), countStyle: .file))/с" } : nil
            ].compactMap { $0 }.joined(separator: "  •  ")
            let state = makeLabel(details, size: 12)
            state.textColor = ReferenceLayout.muted
            state.lineBreakMode = .byTruncatingTail
            let cancel = makeButton("Отмена", action: #selector(cancelTask))
            cancel.identifier = NSUserInterfaceItemIdentifier(task.id.uuidString)
            styleCancelButton(cancel, enabled: task.state == .queued || task.state.isActive)
            [title, number, progress, state, cancel].forEach { row.addSubview($0); $0.translatesAutoresizingMaskIntoConstraints = false }
            NSLayoutConstraint.activate([
                title.topAnchor.constraint(equalTo: row.topAnchor, constant: 7), title.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 42), title.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -15),
                number.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 10), number.centerYAnchor.constraint(equalTo: progress.centerYAnchor), number.widthAnchor.constraint(equalToConstant: 28),
                progress.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 8), progress.leadingAnchor.constraint(equalTo: number.trailingAnchor, constant: 6), progress.trailingAnchor.constraint(equalTo: cancel.leadingAnchor, constant: -14), progress.heightAnchor.constraint(equalToConstant: 11),
                cancel.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -12), cancel.centerYAnchor.constraint(equalTo: progress.centerYAnchor), cancel.widthAnchor.constraint(equalToConstant: 76), cancel.heightAnchor.constraint(equalToConstant: 29),
                state.topAnchor.constraint(equalTo: progress.bottomAnchor, constant: 5), state.leadingAnchor.constraint(equalTo: progress.leadingAnchor), state.trailingAnchor.constraint(equalTo: progress.trailingAnchor)
            ])
            document.addSubview(row)
        }
        taskScroll.documentView = document
    }

    @objc private func cancelTask(_ sender: NSButton) {
        guard let value = sender.identifier?.rawValue, let id = UUID(uuidString: value) else { return }
        manager.cancel(id)
    }

    @objc private func cancelAllDownloads() {
        manager.cancelAll()
    }

    private func updateEstimate() {
        guard let estimateLabel, let cancelAllButton else { return }
        let unfinished = manager.tasks.filter { $0.state == .queued || $0.state.isActive }
        styleCancelButton(cancelAllButton, enabled: !unfinished.isEmpty)
        guard !unfinished.isEmpty else {
            estimateLabel.stringValue = "Загрузок пока нет"
            return
        }
        guard let remaining = manager.estimatedRemainingTime, remaining.isFinite else {
            estimateLabel.stringValue = "Ожидаем размер и скорость всех задач"
            return
        }
        let seconds = Int(ceil(remaining))
        if seconds < 60 {
            estimateLabel.stringValue = "≈ \(max(1, seconds)) с"
        } else if seconds < 3600 {
            estimateLabel.stringValue = "≈ \(seconds / 60) мин \(seconds % 60) с"
        } else {
            estimateLabel.stringValue = "≈ \(seconds / 3600) ч \((seconds % 3600) / 60) мин"
        }
    }

    private func makeStatusMenu() {
        statusMenu = NSMenu()
        addMenuItem("Развернуть программу", #selector(showWindowFromMenu))
        addMenuItem("Показать загрузки", #selector(showDownloadsFromMenu))
        statusMenu.addItem(.separator())
        addMenuItem("Закрыть программу", #selector(quitFromMenu))
    }

    private func addMenuItem(_ title: String, _ action: Selector) {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        statusMenu.addItem(item)
    }

    private func showStatusItem() {
        guard statusItem == nil else { return }
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let path = Bundle.main.path(forResource: "Mask group-1", ofType: "png"), let image = NSImage(contentsOfFile: path) {
            image.size = NSSize(width: 18, height: 18)
            image.isTemplate = false
            item.button?.image = image
        } else { item.button?.title = "⇩" }
        item.menu = statusMenu
        statusItem = item
        updateStatusTooltip()
    }

    private func updateStatusTooltip() {
        guard let item = statusItem else { return }
        let active = manager.tasks.filter { $0.state.isActive }
        let queued = manager.tasks.filter { $0.state == .queued }
        if active.count == 1 && queued.isEmpty, let task = active.first {
            item.button?.toolTip = "\(task.selection.info.title)\n\(task.state.label)\(task.fraction.map { " — \(Int($0 * 100))%" } ?? "")"
        } else if let first = active.first {
            item.button?.toolTip = "Загружается: \(active.count), в очереди: \(queued.count)\n\(first.selection.info.title) — \(first.fraction.map { "\(Int($0 * 100))%" } ?? first.state.label)"
        } else {
            item.button?.toolTip = queued.isEmpty ? "Программа скачивания" : "В очереди: \(queued.count)"
        }
    }

    @objc private func showWindowFromMenu() {
        NSApp.setActivationPolicy(.regular)
        if let item = statusItem { NSStatusBar.system.removeStatusItem(item); statusItem = nil }
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func showDownloadsFromMenu() {
        showWindowFromMenu()
        taskScroll.contentView.scroll(to: .zero)
        window.makeFirstResponder(taskScroll)
    }

    @objc private func quitFromMenu() { NSApp.terminate(nil) }

    @objc private func showAuthor() {
        let alert = NSAlert()
        if let iconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns") {
            alert.icon = NSImage(contentsOf: iconURL)
        }
        alert.messageText = "✕ Разработчик, автор программы ✕"
        alert.informativeText = "ツ  🎱"
        alert.addButton(withTitle: "Написать")

        let emailContainer = NSView(frame: NSRect(x: 0, y: 0, width: 320, height: 28))
        let email = NSTextField(labelWithString: "")
        email.translatesAutoresizingMaskIntoConstraints = false
        email.alignment = .center
        email.isEditable = false
        email.allowsEditingTextAttributes = true
        email.isSelectable = true
        email.drawsBackground = false
        email.isBezeled = false
        email.focusRingType = .none
        email.attributedStringValue = NSAttributedString(
            string: "samo.zlo.spb@gmail.com",
            attributes: [.link: URL(string: "mailto:samo.zlo.spb@gmail.com")!,
                         .foregroundColor: NSColor.linkColor,
                         .underlineStyle: NSUnderlineStyle.single.rawValue,
                         .font: NSFont.systemFont(ofSize: 14)]
        )
        emailContainer.addSubview(email)
        NSLayoutConstraint.activate([
            email.centerXAnchor.constraint(equalTo: emailContainer.centerXAnchor, constant: 26),
            email.centerYAnchor.constraint(equalTo: emailContainer.centerYAnchor),
            email.widthAnchor.constraint(equalToConstant: 220),
            email.heightAnchor.constraint(equalToConstant: 28)
        ])
        alert.accessoryView = emailContainer
        alert.addButton(withTitle: "Закрыть")
        if alert.runModal() == .alertFirstButtonReturn,
           let url = URL(string: "mailto:samo.zlo.spb@gmail.com") {
            NSWorkspace.shared.open(url)
        }
    }

    private func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Не удалось выполнить действие"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.beginSheetModal(for: window)
    }
}

private final class VerticallyCenteredTextFieldCell: NSTextFieldCell {
    private func centeredRect(_ rect: NSRect) -> NSRect {
        var result = rect
        let textHeight = min(cellSize(forBounds: rect).height, rect.height)
        result.origin.y += floor((rect.height - textHeight) / 2)
        result.size.height = textHeight
        return result
    }

    override func drawingRect(forBounds rect: NSRect) -> NSRect {
        centeredRect(super.drawingRect(forBounds: rect))
    }

    override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView) {
        super.drawInterior(withFrame: centeredRect(cellFrame), in: controlView)
    }

    override func edit(withFrame rect: NSRect, in controlView: NSView, editor textObj: NSText, delegate: Any?, event: NSEvent?) {
        super.edit(withFrame: centeredRect(rect), in: controlView, editor: textObj, delegate: delegate, event: event)
    }

    override func select(withFrame rect: NSRect, in controlView: NSView, editor textObj: NSText, delegate: Any?, start selStart: Int, length selLength: Int) {
        super.select(withFrame: centeredRect(rect), in: controlView, editor: textObj, delegate: delegate, start: selStart, length: selLength)
    }
}

private final class FormatOverlayLabel: NSTextField {
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}

private final class NeonLogoButton: NSButton {
    private var hovered = false
    private var edgeConstraints: [NSLayoutConstraint] = []

    func setEdgeConstraints(_ constraints: [NSLayoutConstraint]) {
        edgeConstraints = constraints
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: NSView.noIntrinsicMetric, height: NSView.noIntrinsicMetric)
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        isBordered = false
        imagePosition = .imageOnly
        imageScaling = .scaleProportionallyUpOrDown
        wantsLayer = true
        layer?.cornerRadius = 10
        updateAppearance()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas { removeTrackingArea(area) }
        addTrackingArea(NSTrackingArea(rect: .zero, options: [.activeAlways, .mouseEnteredAndExited, .inVisibleRect], owner: self, userInfo: nil))
    }

    override func mouseEntered(with event: NSEvent) {
        hovered = true
        updateAppearance()
    }

    override func mouseExited(with event: NSEvent) {
        hovered = false
        updateAppearance()
    }

    private func updateAppearance() {
        let glow = NSColor(srgbRed: 0.39, green: 0.28, blue: 1, alpha: 1)
        layer?.backgroundColor = glow.withAlphaComponent(hovered ? 0.14 : 0).cgColor
        layer?.borderColor = glow.cgColor
        layer?.borderWidth = hovered ? 1.2 : 0
        layer?.shadowColor = glow.cgColor
        layer?.shadowOpacity = hovered ? 0.85 : 0
        layer?.shadowRadius = hovered ? 16 : 0
        layer?.shadowOffset = .zero
        guard edgeConstraints.count == 4 else { return }
        let inset: CGFloat = hovered ? 4 : 8
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.16
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            edgeConstraints[0].animator().constant = inset
            edgeConstraints[1].animator().constant = -inset
            edgeConstraints[2].animator().constant = inset
            edgeConstraints[3].animator().constant = -inset
            superview?.layoutSubtreeIfNeeded()
        }
    }
}

private final class SubtitleToggleButton: NSButton {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setButtonType(.pushOnPushOff)
        isBordered = false
        setAccessibilityLabel("Субтитры")
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func draw(_ dirtyRect: NSRect) {
        let track = NSBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), xRadius: 11, yRadius: 11)
        (isEnabled && state == .on ? ReferenceLayout.accent : ReferenceLayout.panelBorder).setFill()
        track.fill()
        let knobX = state == .on ? bounds.width - 21 : 3
        NSColor.white.withAlphaComponent(isEnabled ? 1 : 0.55).setFill()
        NSBezierPath(ovalIn: NSRect(x: knobX, y: 3, width: 18, height: 18)).fill()
    }
}

private final class DownloadProgressView: NSView {
    var fraction: Double = 0 { didSet { needsLayout = true } }
    private let track = CALayer()
    private let fill = CAGradientLayer()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        track.backgroundColor = ReferenceLayout.panelBorder.cgColor
        track.cornerRadius = 5
        fill.colors = [ReferenceLayout.accent.cgColor, NSColor(srgbRed: 0.68, green: 0.29, blue: 0.98, alpha: 1).cgColor]
        fill.startPoint = CGPoint(x: 0, y: 0.5)
        fill.endPoint = CGPoint(x: 1, y: 0.5)
        fill.cornerRadius = 5
        layer?.addSublayer(track)
        layer?.addSublayer(fill)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layout() {
        super.layout()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        track.frame = bounds
        fill.frame = NSRect(x: 0, y: 0, width: bounds.width * CGFloat(min(1, max(0, fraction))), height: bounds.height)
        CATransaction.commit()
    }
}

private final class GradientBorderView: NSView {
    private let border = CAGradientLayer()
    private let borderMask = CAShapeLayer()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.cornerRadius = 19
        layer?.masksToBounds = true
        border.colors = [
            NSColor(srgbRed: 0.34, green: 0.17, blue: 0.95, alpha: 1).cgColor,
            NSColor(srgbRed: 0.48, green: 0.18, blue: 0.99, alpha: 1).cgColor,
            NSColor(srgbRed: 0.77, green: 0.15, blue: 0.64, alpha: 1).cgColor
        ]
        border.startPoint = CGPoint(x: 0, y: 1)
        border.endPoint = CGPoint(x: 1, y: 0)
        border.mask = borderMask
        layer?.addSublayer(border)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layout() {
        super.layout()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        border.frame = bounds
        borderMask.frame = bounds
        borderMask.fillColor = NSColor.clear.cgColor
        borderMask.strokeColor = NSColor.black.cgColor
        borderMask.lineWidth = 3
        borderMask.path = CGPath(roundedRect: bounds.insetBy(dx: 1.5, dy: 1.5), cornerWidth: 18, cornerHeight: 18, transform: nil)
        CATransaction.commit()
    }
}
