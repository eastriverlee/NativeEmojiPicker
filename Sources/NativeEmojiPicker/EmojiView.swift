//
//  EmojiView.swift
//  NativeEmojiPicker
//
//  Created by lee on 1/14/25.
//
import SwiftUI

struct EmojiView: View {
    var emoji: String?
    var genmoji: NSAttributedString?
    
    init (_ emoji: String?, _ genmoji: NSAttributedString? = nil) {
        self.emoji = emoji
        self.genmoji = genmoji
    }
    var body: some View {
        Group {
            if let genmoji {
                Text(AttributedString(genmoji))
            } else if let emoji {
                Text(emoji)
            }
        }
    }
}

#Preview {
    EmojiView("🤯")
}
