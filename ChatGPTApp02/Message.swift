//
//  Message.swift
//  ChatGPTApp02
//
//  Created by Yudai Takahashi on 2023/12/05.
//

import Foundation
import MessageKit
import UIKit

// 送信者
struct ChatSender: SenderType {
    var senderId: String  // 送信者ID
    var displayName: String  // 表示名
    var iconName: String  // アイコン名

    // 自分のSenderType
    static var me: ChatSender {
        return ChatSender(senderId: "0", displayName: "me", iconName: "cat")
    }

    // 他人のSenderType
    static var other: ChatSender {
        return ChatSender(senderId: "1", displayName: "chatGPT", iconName: "bear")
    }
}

// メッセージ
struct Message: MessageType {
    var sender: SenderType  // 送信者
    var messageId: String  // メッセージID
    var kind: MessageKind  // メッセージ種別
    var sentDate: Date  // 送信日時

    // メッセージの生成
    static func new(sender: SenderType, message: String) -> Message {
        return Message(
            sender: sender,
            messageId: UUID().uuidString,
            kind: .attributedText(NSAttributedString(
                string: message,
                attributes: [
                    .font: UIFont.systemFont(ofSize: 14.0),
                    .foregroundColor: sender.senderId == "0" ? UIColor.white : UIColor.label
                ]
            )),
            sentDate: Date())
    }
}
