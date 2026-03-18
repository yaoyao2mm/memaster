import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private let minimumContentSize = NSSize(width: 1180, height: 900)

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    if !configureScreenshotFrameIfNeeded() {
      configureMinimumWindowSize()
    }

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }

  private func configureMinimumWindowSize() {
    contentMinSize = minimumContentSize

    let currentSize = contentLayoutRect.size
    let targetSize = NSSize(
      width: max(currentSize.width, minimumContentSize.width),
      height: max(currentSize.height, minimumContentSize.height)
    )

    if targetSize != currentSize {
      setContentSize(targetSize)
      center()
    }
  }

  @discardableResult
  private func configureScreenshotFrameIfNeeded() -> Bool {
    let environment = ProcessInfo.processInfo.environment
    guard
      let widthRaw = environment["MEMASTER_SCREENSHOT_WIDTH"],
      let heightRaw = environment["MEMASTER_SCREENSHOT_HEIGHT"],
      let width = Double(widthRaw),
      let height = Double(heightRaw)
    else {
      return false
    }

    let targetSize = NSSize(width: width, height: height)
    setContentSize(targetSize)
    center()
    return true
  }
}
