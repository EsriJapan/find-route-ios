//
//  TableViewController.swift
//  FindRoute
//
//  Created by esrij on H30/10/11.
//  Copyright © 平成30年 esrij. All rights reserved.
//

import UIKit

class BookmarkTableViewController: UITableViewController {
    
    var keyArray:[String] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        //self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        self.navigationItem.title = "お気に入りルートを表示"

        // UserDefaults に保存されているデータの一覧を取得して、キーの値を配列に追加
        let appDomain = Bundle.main.bundleIdentifier
        let dictionary = UserDefaults.standard.persistentDomain(forName: appDomain!)
        if dictionary?.keys != nil {
            self.keyArray = [String](dictionary!.keys)
            
            // "bookmark" が含まれるキー名のみ追加する
            let keyword = "bookmark_"
            keyArray = keyArray.filter {
                $0.contains(keyword)
            }
        }
    }
    

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.keyArray.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        // UserDefaults からキー名を指定してデータを取得
        let keyText:String = self.keyArray[indexPath.row]
        let boolmarkArray = UserDefaults.standard.array(forKey: keyText)
        // データ（訪問地点とブックマーク名の配列）からブックマーク名を取得してセルのラベルに設定する
        let bookmarkName:String = boolmarkArray?.last as! String
        cell.textLabel?.text = bookmarkName
        
        // 訪問地点の名称をセルの詳細ラベルに表示
        var spotNameArray = boolmarkArray as! [String]
        spotNameArray.removeLast()
        let spotNameArrayStr:String = spotNameArray.joined(separator: ", ")
        
        cell.detailTextLabel?.adjustsFontSizeToFitWidth = true
        cell.detailTextLabel?.numberOfLines = 0
        cell.detailTextLabel?.text = spotNameArrayStr

        
        return cell
    }
    
    
    // セルが選択された場合
    override func tableView(_ table: UITableView, didSelectRowAt indexPath: IndexPath) {

        // UserDefaults のデータから訪問地点の配列を取得する
        let keyText:String = self.keyArray[indexPath.row]
        let bookmarkArray = UserDefaults.standard.array(forKey: keyText)
        // 配列に含まれているブックマーク名を削除
        var spotListArray = bookmarkArray
        spotListArray?.removeLast()
        
        // ルート検索対象用の配列を新しく作成する
        let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.currentSpotList = spotListArray as! [String]
        
        // MapViewController を表示
        performSegue(withIdentifier: "toMapViewController",sender: nil)
        
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    
    // Override to support editing the table view.
    // セルを削除した場合
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            
            // UserDefaults のデータからキー名を指定してデータを削除
            let keyText:String = self.keyArray[indexPath.row]
            UserDefaults.standard.removeObject(forKey: keyText)
            // セルの削除後に TableView がリロードされるので keyArray からも要素を削除
            self.keyArray.remove(at: indexPath.row)
            
            // セルを削除
            tableView.deleteRows(at: [indexPath], with: .fade)
            
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
        
        
    }
    

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        
        if (segue.identifier == "toMapViewController") {
            let mapVC: MapViewController = (segue.destination as? MapViewController)!
            // MapViewController の画面表示フラグの設定
            mapVC.bookmarkFlag = true
        }
    }
    

}
