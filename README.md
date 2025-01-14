# NativeEmojiPicker

this little SwiftUI library is an emoji picker.

it uses native emoji keyboard that apple gave us,  
instead of other emoji pickers that are missing important features such as:
- multilingual emoji search
- **genmoji** support

<img width="568" alt="Screenshot 2025-01-15 at 00 41 09" src="https://github.com/user-attachments/assets/a20f92ac-362d-4c35-a0e0-b2010a2a5a37" />

## example
```swift
import SwiftUI
import NativeEmojiPicker

struct EmojiPicker: View {
    @State var isPresented: Bool = false
    @State var emoji: String? = "🤯"
    @State var genmoji: NSAttributedString? = nil
    var hasNothing: Bool { emoji == nil && genmoji == nil }
    
    var body: some View {
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
}
```

## features
- closes down when user types non emoji key
- closes keyboard when user changes language (however it's also triggered by emoji search, so it's turned off by default)
- multilingual emoji search
- genmoji support (simulator is not supported as of now; Jan 2025)
- all emojis with all color combinations
- all future emojis
- simple and small codebase
