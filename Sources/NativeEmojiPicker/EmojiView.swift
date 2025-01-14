//
//  EmojiView.swift
//  NativeEmojiPicker
//
//  Created by lee on 1/14/25.
//
import SwiftUI

public struct EmojiView: View {
    var emoji: String?
    var genmoji: NSAttributedString?
    
    public init (_ emoji: String?, _ genmoji: NSAttributedString? = nil) {
        self.emoji = emoji
        self.genmoji = genmoji
    }
    public var body: some View {
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
