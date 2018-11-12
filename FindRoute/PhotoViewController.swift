//
//  PhotoViewController.swift
//  FindRoute
//
//  Created by esrij on H30/10/11.
//  Copyright © 平成30年 esrij. All rights reserved.
//

import UIKit

class PhotoViewController: UIViewController ,UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    var photoItems :[String] = []
    var filePath:String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "スポットを選択"
        
        // ドキュメント フォルダのパスを取得
        self.filePath = NSSearchPathForDirectoriesInDomains(.documentDirectory,Foundation.FileManager.SearchPathDomainMask.userDomainMask, true)[0]
        
        if (FileManager.default.fileExists(atPath: "\(self.filePath)" + "/photo")) {
            // ドキュメント フォルダの下の photo フォルダの中にある写真の名前から配列を作成
            self.photoItems = try! FileManager.default.contentsOfDirectory(atPath: "\(self.filePath)" + "/photo")
            // photo フォルダの中にある .DS_Store ファイルを削除
            if let removeItemIndex = self.photoItems.index(of: ".DS_Store") {
                self.photoItems.remove(at: removeItemIndex)
            }
            print(photoItems)
        } else {
            print("photo フォルダが存在しません")
        }
        
        let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.currentSpotList.removeAll()

        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
        let testCell:UICollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        
        // Storyboard で設定した tag 番号から ImageView を作成
        let imageView = testCell.contentView.viewWithTag(1) as! UIImageView
        // 配列から写真の名前を取得してファイルのパスを作成
        let photoPath = "\(self.filePath)" + "/photo/" + photoItems[indexPath.row]
        // 写真を ImageView に表示
        let cellImage = UIImage(contentsOfFile: photoPath)
        imageView.contentMode = .scaleAspectFill
        imageView.image = cellImage
        
        // Storyboard で設定した tag 番号からラベルを作成
        let label = testCell.contentView.viewWithTag(2) as! UILabel
        
        // 拡張子を削除して、写真の名前をラベルに設定
        let photoFile = photoItems[indexPath.row]
        let fileNameWithoutExtension = photoFile.fileName()
        label.text = fileNameWithoutExtension
        
        return testCell
    }
    
    // UICollectionView のレイアウトの設定
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let horizontalSpace:CGFloat = 1
        let cellSize:CGFloat = self.view.bounds.width/2 - horizontalSpace
        return CGSize(width: cellSize, height: cellSize)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // 写真の数だけセルを表示
        return photoItems.count;
    }
    
    // セルが選択された場合
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        
        let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
        // セルのラベルの文字列を取得
        let spotName = cell?.contentView.viewWithTag(2) as! UILabel
        
        // セルの tag の値で選択/非選択を判別
        if cell?.tag != 1 {
            // ルート検索対象用の配列にラベルの文字列（写真の名前）を追加する
            appDelegate.currentSpotList.append(spotName.text!)
            
            // セルを選択状態にする
            cell?.layer.borderWidth = 200.0
            cell?.layer.borderColor = UIColor.init(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.4).cgColor
            cell?.tag = 1
            
        } else {
            // ルート検索対象用の配列からにラベルの文字列（写真の名前）を削除する
            appDelegate.currentSpotList.remove(at: appDelegate.currentSpotList.index(of: spotName.text!)!)
            
            // セルを非選択状態にする
            cell?.layer.borderWidth = 0.0
            cell?.tag = 0
        }
    }
    
    
}

extension String {
    
    func fileName() -> String {
        return NSURL(fileURLWithPath: self).deletingPathExtension?.lastPathComponent ?? ""
    }
    
}
