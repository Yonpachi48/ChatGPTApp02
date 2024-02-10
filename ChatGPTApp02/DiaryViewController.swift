//
//  DiaryViewController.swift
//  ChatGPTApp02
//
//  Created by Yudai Takahashi on 2023/11/28.
//

import UIKit
//import OpenAISwift

class DiaryViewController: UIViewController {
    var imageURL: String!
    var diaryText: String!
    let key = "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"
    
    @IBOutlet var diaryImageView: UIImageView!
    @IBOutlet var diaryLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadImage(from: imageURL)
        
        diaryLabel.text = diaryText ?? ""
        // Do any additional setup after loading the view.
    }
    
    private func loadImage(from imageUrl: String) {
        Task {
            if let url = URL(string: imageUrl) {
                do {
                    let image = try await fetchImage(from: url)
                    DispatchQueue.main.async {
                        self.diaryImageView.image = image
                    }
                } catch {
                    print("Error fetching image: \(error)")
                }
            }
        }
    }
    
    @IBAction func backButtonPusshed () {
        self.dismiss(animated: false)
    }
    
    
    
}
