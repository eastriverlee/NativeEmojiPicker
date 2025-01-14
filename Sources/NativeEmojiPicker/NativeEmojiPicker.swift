import SwiftUI

public extension View {
    @ViewBuilder func nativeEmojiPicker(
        isPresented: Binding<Bool>,
        selectedEmoji: Binding<String?>,
        selectedGenmoji: Binding<NSAttributedString?>
    ) -> some View {
        self.overlay {
            EmojiPicker(
                emoji: selectedEmoji,
                genmoji: selectedGenmoji,
                isPresented: isPresented
            )
        }
    }
}

public struct EmojiPicker: View {
    public static var isAvailable: Bool {
        UITextInputMode.activeInputModes.map(\.primaryLanguage).contains("emoji")
    }
    
    @Binding var emoji: String?
    @Binding var genmoji: NSAttributedString?
    @Binding var isPresented: Bool
    public init(
        emoji: Binding<String?>,
        genmoji: Binding<NSAttributedString?> = .constant(nil),
        isPresented: Binding<Bool>,
        options: Options = Options()
    ) {
        self._emoji = emoji
        self._genmoji = genmoji
        self._isPresented = isPresented
        self.options = options
    }
    
    let options: Options
    var hasNothing: Bool { emoji == nil && genmoji == nil }
    
    public var body: some View {
        return Group {
            EmojiTextViewWrapper($emoji, $genmoji, $isPresented, options).opacity(0)
        }
        .frame(height: 0)
    }
    
    public class Options {
        let supportGenmoji: Bool
        let disableInputModeChange: Bool
        let onNonEmoji: ((String) -> Void)
        let shouldCloseOnNonEmoji: Bool
        public init(
            supportGenmoji: Bool = true,
            disableInputModeChange: Bool = false,
            shouldCloseOnNonEmoji: Bool = true,
            onNonEmoji: @escaping (String) -> Void = { _ in}
        ) {
            self.supportGenmoji = supportGenmoji
            self.disableInputModeChange = disableInputModeChange
            self.shouldCloseOnNonEmoji = shouldCloseOnNonEmoji
            self.onNonEmoji = onNonEmoji
        }
    }
}

extension Character {
    var isEmoji: Bool {
        guard let scalar = unicodeScalars.first else { return false }
        return !scalar.isASCII && scalar.properties.isEmoji
    }
}

struct EmojiTextViewWrapper: UIViewRepresentable {
    @Binding var emoji: String?
    @Binding var genmoji: NSAttributedString?
    @Binding var isPresented: Bool {
        didSet {
            if isPresented {
                if !textView.isFirstResponder {
                    textView.becomeFirstResponder()
                }
                if options.disableInputModeChange { addInputModeObserver() }
            } else {
                if textView.isFirstResponder {
                    textView.resignFirstResponder()
                }
                if options.disableInputModeChange { removeInputModeObserver() }
            }
        }
    }
    
    let textView = EmojiTextView()
    let options: EmojiPicker.Options

    init(_ emoji: Binding<String?>, _ genmoji: Binding<NSAttributedString?>, _ isShown: Binding<Bool>, _ options: EmojiPicker.Options) {
        self._emoji = emoji
        self._genmoji = genmoji
        self._isPresented = isShown
        self.options = options
    }

    class TextViewCoordinator: NSObject, UITextViewDelegate {
        var parent: EmojiTextViewWrapper

        init(_ parent: EmojiTextViewWrapper) {
            self.parent = parent
        }
        
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText string: String) -> Bool {
            if let original = textView.text {
                let isToDelete = string.isEmpty
                var updatedText = string.filter(\.isEmoji)
                updatedText = String(updatedText.suffix(1))
                if !isToDelete {
                    if updatedText.isEmpty {
                        defer {
                            parent.options.onNonEmoji(string)
                            if parent.options.shouldCloseOnNonEmoji {
                                parent.isPresented = false
                            }
                        }
                        updatedText = original.filter((\.isEmoji))
                    } else {
                        textView.resignFirstResponder()
                    }
                }
                textView.text = updatedText
                DispatchQueue.main.async {
                    self.parent.genmoji = nil
                    self.parent.emoji = updatedText.isEmpty ? nil : updatedText
                }
            }
            return true
        }
        
        func textViewDidChange(_ textView: UITextView) {
            if let genmoji = textView.getGenmoji() {
                DispatchQueue.main.async {
                    self.parent.genmoji = genmoji
                    self.parent.emoji = nil
                    self.parent.isPresented = false
                }
            }
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            parent.isPresented = false
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            parent.isPresented = true
        }
    }
    
    func makeCoordinator() -> TextViewCoordinator {
        TextViewCoordinator(self)
    }

    func inputModeDidChange(_ notification: Notification) {
        if let userInfo = notification.userInfo, textView.isFirstResponder {
            let textInputMode = userInfo["UITextInputFromInputModeKey"] as? UITextInputMode
            let primaryLanguage = textInputMode?.primaryLanguage
            let isEmoji = primaryLanguage == "emoji"
            guard isEmoji else { return }
            textView.resignFirstResponder()
        }
    }
    
    func addInputModeObserver() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NotificationCenter.default.addObserver(forName: UITextInputMode.currentInputModeDidChangeNotification, object: nil, queue: .main, using: self.inputModeDidChange)
        }
    }

    func removeInputModeObserver() {
        NotificationCenter.default.removeObserver(self, name: UITextInputMode.currentInputModeDidChangeNotification, object: nil)
    }

    func makeUIView(context: UIViewRepresentableContext<EmojiTextViewWrapper>) -> EmojiTextView {
        if !EmojiPicker.isAvailable {
            print("add Emoji keyboard")
        }
        if #available(iOS 18.0, *) {
            textView.supportsAdaptiveImageGlyph = options.supportGenmoji
        }
        textView.delegate = context.coordinator
        textView.text = emoji
        return textView
    }
    
    func updateUIView(_ textView: EmojiTextView, context: Context) {
        DispatchQueue.main.async {
            genmoji = textView.getGenmoji()
        }
    }
}


class EmojiTextView: UITextView {
    override var textInputContextIdentifier: String? { "" }

    override var textInputMode: UITextInputMode? {
        let textInputMode = UITextInputMode.activeInputModes.first {
            $0.primaryLanguage == "emoji"
        }
        guard let textInputMode else {
            self.resignFirstResponder()
            return nil
        }
        return textInputMode
    }
}

extension UITextView {
    func getGenmoji() -> NSAttributedString? {
        if #available(iOS 18.0, *) {
            guard let attributedText else { return nil }
            var genmoji: NSAttributedString?
            attributedText.enumerateAttribute(.adaptiveImageGlyph, in: NSMakeRange(0, attributedText.length)) { (value, range, stop) in
                if let adaptiveImageGlyph = value as? NSAdaptiveImageGlyph, genmoji == nil {
                    genmoji = NSAttributedString(adaptiveImageGlyph: adaptiveImageGlyph)
                }
            }
            return genmoji
        } else {
            return nil
        }
    }
}


@available(iOS 17.0, *)
#Preview {
    @Previewable @State var isPresented: Bool = false
    @Previewable @State var emoji: String? = "🤯"
    @Previewable @State var genmoji: NSAttributedString? = nil
    var hasNothing: Bool { emoji == nil && genmoji == nil }
    
    Button(action: { isPresented.toggle() }) {
        ZStack {
            Color.gray.opacity(0.1)
            Image(systemName: "circle.dashed")
                .padding(2)
                .foregroundStyle(.gray)
                .opacity(hasNothing ? 0.4 : 0)
            EmojiView(emoji, genmoji)
        }
        .clipShape(.circle)
    }
    .frame(width: 40, height: 40)
    .nativeEmojiPicker(
        isPresented: $isPresented,
        selectedEmoji: $emoji,
        selectedGenmoji: $genmoji
    )
}
