import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    configureScreenshotFrameIfNeeded()

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }

  private func configureScreenshotFrameIfNeeded() {
    let environment = ProcessInfo.processInfo.environment
    guard
      let widthRaw = environment["MEMASTER_SCREENSHOT_WIDTH"],
      let heightRaw = environment["MEMASTER_SCREENSHOT_HEIGHT"],
      let width = Double(widthRaw),
      let height = Double(heightRaw)
    else {
      return
    }

    let targetSize = NSSize(width: width, height: height)
    setContentSize(targetSize)
    center()
  }
}
