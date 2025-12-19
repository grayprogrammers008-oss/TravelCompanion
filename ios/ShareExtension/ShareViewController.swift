import UIKit
import Social
import MobileCoreServices
import UniformTypeIdentifiers

class ShareViewController: SLComposeServiceViewController {

    let hostAppBundleIdentifier = "com.pathio.travel"
    let sharedKey = "ShareKey"
    var sharedText: [String] = []
    let urlContentType = UTType.url.identifier
    let textContentType = UTType.text.identifier

    override func isContentValid() -> Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let content = extensionContext?.inputItems.first as? NSExtensionItem {
            if let contents = content.attachments {
                for (index, attachment) in contents.enumerated() {
                    // Handle URL type
                    if attachment.hasItemConformingToTypeIdentifier(urlContentType) {
                        handleUrl(content: content, attachment: attachment, index: index)
                    }
                    // Handle Text type
                    else if attachment.hasItemConformingToTypeIdentifier(textContentType) {
                        handleText(content: content, attachment: attachment, index: index)
                    }
                }
            }
        }
    }

    override func didSelectPost() {
        print("didSelectPost")
    }

    override func configurationItems() -> [Any]! {
        return []
    }

    private func handleText(content: NSExtensionItem, attachment: NSItemProvider, index: Int) {
        attachment.loadItem(forTypeIdentifier: textContentType, options: nil) { [weak self] data, error in
            if error == nil, let item = data as? String, let this = self {
                this.sharedText.append(item)

                if index == (content.attachments?.count ?? 0) - 1 {
                    this.saveAndRedirect()
                }
            }
        }
    }

    private func handleUrl(content: NSExtensionItem, attachment: NSItemProvider, index: Int) {
        attachment.loadItem(forTypeIdentifier: urlContentType, options: nil) { [weak self] data, error in
            if error == nil, let item = data as? URL, let this = self {
                this.sharedText.append(item.absoluteString)

                if index == (content.attachments?.count ?? 0) - 1 {
                    this.saveAndRedirect()
                }
            }
        }
    }

    private func saveAndRedirect() {
        let userDefaults = UserDefaults(suiteName: "group.\(hostAppBundleIdentifier)")

        if !sharedText.isEmpty {
            let jsonText = sharedText.joined(separator: ",")
            userDefaults?.set(jsonText, forKey: sharedKey)
        }

        userDefaults?.synchronize()
        redirectToHostApp()
    }

    private func redirectToHostApp() {
        // Build the URL scheme to open the main app
        let urlString = "\(hostAppBundleIdentifier)://share"

        if let url = URL(string: urlString) {
            var responder: UIResponder? = self as UIResponder
            let selector = sel_registerName("openURL:")

            while responder != nil {
                if responder?.responds(to: selector) == true {
                    responder?.perform(selector, with: url)
                }
                responder = responder?.next
            }
        }

        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}
