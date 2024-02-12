//
//  ChatViewController.swift
//  ChatGPTApp02
//
//  Created by Yudai Takahashi on 2023/11/14.
//

import UIKit
import Foundation
import MessageKit
import InputBarAccessoryView

class ChatViewController: MessagesViewController {
    
    // OpenAIのAPIキー
    let key = API().api
    
    // 会話終了かどうかを表す値
    var diaryFinished: Bool = false
    
    var inputText = ""
    var imageURL = ""
    var diaryText = ""
    
    // ChatGPTに投げる時の会話記録
    var chatMessages : [ChatMessage] = []
    
    // チャット表示させるための会話記録
    private var messageList: [Message] = [] {
        didSet {
            messagesCollectionView.reloadData()
            messagesCollectionView.scrollToLastItem(at: .bottom, animated: true)
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupGPT()
        
        messagesCollectionView.backgroundColor = UIColor.secondarySystemBackground
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        
        // messageInputBar
        messageInputBar.delegate = self
        messageInputBar.sendButton.title = nil
        messageInputBar.sendButton.image = UIImage(systemName: "paperplane")
        
    }
    override func viewWillAppear(_ animated: Bool) {
        DispatchQueue.main.async {
            // メッセージリストの初期化
            self.messageList = [
                Message.new(sender: ChatSender.other, message: "今日見た夢を教えてください。")
            ]
            
            self.setupGPT()
        }
    }
    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toDiaryVC" {
            let next = segue.destination as? DiaryViewController
            next?.imageURL = self.imageURL
            next?.diaryText = diaryText
        }
    }
    
    /*
     chatGPTに会話を投げかけるメソッド
     resut: chatGPTからの返答
     
     */
    private func generatedAnswer(from chatMessages: [ChatMessage]) async throws -> String {
        let openAI = OpenAISwift(config: OpenAISwift.Config.makeDefaultOpenAI(apiKey: key))
        let result = try await openAI.sendChat(with: chatMessages, model: .gpt4(.gpt4))
        self.chatMessages.append(ChatMessage(role: .assistant, content: result.choices?.first?.message.content ?? ""))
        
        // 会話が終了した時は、画像生成のプロンプトを出力させて、画像生成を行い、画面遷移。
        if diaryFinished {
            diaryText = result.choices?.first?.message.content ?? ""
            self.chatMessages.append(ChatMessage(role: .user, content: "画像を生成してください"))
            let promptResult = try await openAI.sendChat(with: chatMessages, model: .gpt4(.gpt4))
            messageList.append(Message.new(sender: ChatSender.other, message: "画像生成中です。"))
            // 生成された画像のURL
            self.imageURL = await genarateImage(from: promptResult.choices?.first?.message.content ?? "")
            self.performSegue(withIdentifier: "toDiaryVC", sender: self)
        } else {
            
            if messageList.count != 1 {
                messageList.append(Message.new(sender: ChatSender.other, message: result.choices?.first?.message.content ?? "出力に失敗しました。"))
            }
        }
        
        print("ChatMessage: \(self.chatMessages)")
        return result.choices?.first?.message.content ?? ""
    }
    
    /*
     ・画像生成を行うメソッド
     ・プロンプト分を引数にする
     ・生成された画像のURLを返す
     */
    private func genarateImage(from promptMessage: String) async -> String{
        let openAI = OpenAISwift(config: OpenAISwift.Config.makeDefaultOpenAI(apiKey: key))
        do {
            // プロンプト分に以下の内容を加えるとアニメ調でファンタジーな感じになる
            let success = try await openAI.sendImages(with: "\(promptMessage), 4K Anime, --niji 5, like a dream world, fantasy", numImages: 1, size: .size1024)
            return success.data?.first?.url ?? ""
        } catch {
            print(error.localizedDescription)
            return ""
        }
    }
    
    /*
     ・ChatGPTに初期条件を与えるメソッド
     ・.systemが前提条件を入力する役割を担う→この文章が超重要
     */
    private func setupGPT() {
        Task {
            do {
                chatMessages = [
                    ChatMessage(role: .system, content:
                                    "前提：あなたには以下の条件に沿って夢(寝ている時に見る情景)にまつわる絵日記の作成を手伝っていただきます。条件1： 私が夢の内容(文章)を送りますので、その日記から画像を生成するためのプロンプトを英語で生成してください。条件2： また、画像生成に必要なプロンプトが不足する場合は必要な情報を聞いてください。(私のイメージに限りなく近い画像を生成することを心がけてください。)条件3： 必要な情報が揃ったら、出てきた情報のまとめを日記の形(200文字以内)で出力してください。条件4：私が”OK” と返したら先ほどまとめた日記のみを返してください。(絶対に日記以外の要素を含まないでください。)条件5： 私が”画像を生成してください”と返したら画像生成に用いる英語のプロンプトのみを返してください。(絶対にプロンプト以外の要素を含まないでください。)条件6：英語のプロンプト文章ではなく、より精密な画像を作るためのプロンプトにしてください。"
                               )
                ]
                let answer = try await generatedAnswer(from: chatMessages)
                print(answer)
            } catch {
                // Some Error Handling
                print("Error: \(error)")
            }
        }
    }
    
}

// MessagesDataSource
extension ChatViewController: MessagesDataSource {
    // 現在の送信者
    var currentSender: SenderType {
        return ChatSender.me
    }
    
    // メッセージ数
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messageList.count
    }
    
    // IndexPathに応じたメッセージ
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messageList[indexPath.section]
    }
    
    // messageTopLabelの属性テキスト
    func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        return NSAttributedString(
            string: messageList[indexPath.section].sender.displayName,
            attributes: [.font: UIFont.systemFont(ofSize: 12.0), .foregroundColor: UIColor.systemBlue])
    }
    
    // messageBottomLabelの属性テキスト
    func messageBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = DateFormatter.dateFormat(
            fromTemplate: "HH:mm", options: 0, locale: Locale(identifier: "ja_JP"))
        return NSAttributedString(
            string: dateFormatter.string(from: messageList[indexPath.section].sentDate),
            attributes: [.font: UIFont.systemFont(ofSize: 12.0), .foregroundColor: UIColor.secondaryLabel])
    }
}

// MessagesDisplayDelegate
extension ChatViewController: MessagesDisplayDelegate {
    // 背景色
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? UIColor.systemBlue : UIColor.systemBackground
    }
    
    // メッセージスタイル
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
        return .bubbleTail(corner, .curved)
    }
    
    // avaterViewの設定
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        let sender = messageList[indexPath.section].sender as! ChatSender
        avatarView.image =  UIImage(named: sender.iconName)
    }
}

// MessagesLayoutDelegate
extension ChatViewController: MessagesLayoutDelegate {
    // messageTopLabelの高さ
    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 24
    }
    
    // messageBottomLabelの高さ
    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 24
    }
    
    // headerViewのサイズ
    func headerViewSize(for section: Int, in messagesCollectionView: MessagesCollectionView) -> CGSize {
        return CGSize.zero
    }
}

// InputBarAccessoryViewDelegate
extension ChatViewController: InputBarAccessoryViewDelegate {
    // InputBarAccessoryViewの送信ボタン押下時に呼ばれる
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        inputText = text
        if inputText == "OK" {
            diaryFinished = true
        } else {
            diaryFinished = false
        }
        chatMessages.append(ChatMessage(role: .user, content: inputText))
        messageList.append(Message.new(sender: ChatSender.me, message: text))
        Task {
            do {
                let answer = try await generatedAnswer(from: chatMessages)
                print(answer)
            } catch {
                // Some Error Handling
                print("Error: \(error)")
            }
        }
        messageInputBar.inputTextView.text = String()
    }
}


