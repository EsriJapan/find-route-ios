//
//  MapViewController.swift
//  FindRoute
//
//  Created by esrij on H30/10/11.
//  Copyright © 平成30年 esrij. All rights reserved.
//

import UIKit
import ArcGIS

class MapViewController: UIViewController , UITextFieldDelegate{
    
    var bookmarkFlag: Bool! //遷移元の画面の判定用
    
    @IBOutlet var saveMapBtn: UIButton!  // 保存ボタン
    @IBOutlet var saveView: UIView!  // ブックマークの登録画面
    @IBOutlet var bookmarkNameTextField: UITextField!  // ブックマーク名称の入力フィールド
    @IBOutlet var routeTime: UILabel!  // 検索ルートの移動時間
    
    @IBOutlet var mapView: AGSMapView!  // 地図表示用のビュー
    private var mapPackage:AGSMobileMapPackage!
    private var licenseKey = ""  // ArcGIS Runtime の Lite ライセンスキー
    
    private var markerGraphicsOverlay = AGSGraphicsOverlay()
    private var routeGraphicsOverlay = AGSGraphicsOverlay()
    private var labelGraphicsOverlay = AGSGraphicsOverlay()
    private var stopsArray: [AGSStop] = []
    
    private var startLoc = [141.970397, 39.626471]  // ルートの出発地点の経度・緯度（宮古港フェリーターミナル）
    
    private var routeTask:AGSRouteTask!
    private var routeParameters:AGSRouteParameters!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.navigationItem.title = "最適ルート"
        
        if self.bookmarkFlag == true {
            // お気に入りルートを表示の画面から遷移してきた場合
            // 保存ボタンを非表示
            self.saveMapBtn.isHidden = true
        } else {
            // スポットを選択の画面から遷移してきた場合
            // 保存ボタンを表示
            self.saveMapBtn.isHidden = false
            // TextField のデリゲートの設定
            self.bookmarkNameTextField.delegate = self
        }
        
        // 地図の表示
        self.showMap()
        
    }
    
    
    // MARK: - TextField のデリゲート

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // 確定ボタンが押されたらキーボードを閉じる
        self.bookmarkNameTextField.resignFirstResponder()
        
        return true
    }
    
    // MARK: - ブックマークの保存
    
    @IBAction func showBookmarkView(_ sender: UIButton) {
        // 保存ボタンを選択したらブックマークの登録画面を表示する
        self.saveView.isHidden = false
    }
    
    @IBAction func saveBookmark(_ sender: Any) {
        
        // OK ボタンを選択したら、UserDefaults にデータを保存
        let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
        let currentList = appDelegate.currentSpotList
        
        // キー名に bookmark_<現在の時刻> を設定
        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ja_JP")
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        let keyName = "bookmark_" + dateFormatter.string(from: now)
        
        // 訪問する観光地の名称とブックマーク名の配列を保存
        var bookmarkList = currentList
        bookmarkList.append(self.bookmarkNameTextField.text!)
        UserDefaults.standard.set(bookmarkList, forKey: keyName)
        
        // キーボードを閉じる
        self.bookmarkNameTextField.resignFirstResponder()
        // ブックマークの登録画面を非表示にする
        self.saveView.isHidden = true
        
    }
    
    @IBAction func cancelBookmark(_ sender: UIButton) {
        
        // キーボードを閉じる
        self.bookmarkNameTextField.resignFirstResponder()
        // ブックマークの登録画面を非表示にする
        self.saveView.isHidden = true
        
    }

    
    // MARK: - 地図表示・ルート検索
    
    
    private func showMap() {
        
        
        do {
            // ライセンスキーを設定して ArcGIS Runtime のライセンス認証を実行
            let result = try AGSArcGISRuntimeEnvironment.setLicenseKey(licenseKey)
            print("License Result: \(result.licenseStatus)")
        }
            
        catch let error as NSError {
            print(error.localizedDescription)
        }
 
        
        // モバイル マップ パッケージの初期化
        self.mapPackage = AGSMobileMapPackage(name: "miyako")
        
        // モバイル マップ パッケージのロード
        self.mapPackage.load { [weak self] (error: Error?) in
            if let error = error {
                print(error.localizedDescription)
            }
            else {
                if let weakSelf = self {
                    if weakSelf.mapPackage.maps.count > 0 {
                        // モバイル マップ パッケージに保存されているひとつめのマップを mapView 設定
                        weakSelf.mapView.map = weakSelf.mapPackage.maps[0]
                        weakSelf.mapView.map?.load(completion: { [weak self] (error:Error?) -> Void in
                            if let error = error {
                                self?.showError(str: error.localizedDescription)
                            }
                            else {
                                // マップの最少スケールを設定
                                self?.mapView.map?.minScale = 500000
                                // グラフィック オーバレイを mapView  に追加
                                self?.mapView.graphicsOverlays.addObjects(from: [self?.routeGraphicsOverlay, self?.markerGraphicsOverlay, self?.labelGraphicsOverlay])
                                
                                // ルート検索処理のセットアップ
                                weakSelf.setupRouteTask()
                            }
                        })
                        
                    }
                    else {
                        self?.showError(str: "モバイル マップ パッケージの中にマップがありません")
                    }
                }
            }
        }
    }
    
    
    
    
    private func setupRouteTask() {
        // モバイル マップ パッケージのマップの中にネットワーク データがある場合
        if self.mapView.map!.transportationNetworks.count > 0 {
            
            // ネットワーク データを設定して、RouteTask を作成
            self.routeTask = AGSRouteTask(dataset: self.mapView.map!.transportationNetworks[0])
            
            // デフォルトのルート検索パラメーターを取得
            self.getDefaultParameters()
        } else {
            self.showError(str: "ネットワーク データがありません")
        }
    }
    
    private func getDefaultParameters() {
        // デフォルトのルート検索パラメーターを取得
        self.routeTask.defaultRouteParameters { [weak self] (params: AGSRouteParameters?, error: Error?) -> Void in
            if let error = error {
                self?.showError(str: error.localizedDescription)
            }
            else {
                self?.routeParameters = params
                // ルートの経由地点の作成
                self?.addStop()
            }
        }
    }
    
    private func addStop() {
        
        // 観光地の名称と緯度経度が格納されている CSV ファイルを取得
        let csvPath:String = NSSearchPathForDirectoriesInDomains(.documentDirectory,Foundation.FileManager.SearchPathDomainMask.userDomainMask, true)[0] + "/spot.csv"
        
        do {
            
            // CSV の各行を要素として格納した配列を作成
            let csvStr = try String(contentsOfFile:csvPath, encoding:String.Encoding.utf8)
            let lineChange = csvStr.replacingOccurrences(of: "\r", with: "\n")
            let csvArray = lineChange.components(separatedBy: .newlines)
            
            // スポットを選択画面で選択された観光地名称の配列を取得
            let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
            let currentSpotList = appDelegate.currentSpotList
            
            // CSV から作成した配列から、選択画面で選択された観光地の要素のみをフィルタリング
            var searchArray :[String] = []
            for searchSpot in currentSpotList {
                let filteredSpot = csvArray.filter {
                    $0.contains(searchSpot)
                }
                searchArray.append(contentsOf: filteredSpot)
            }
            
            // ルート検索のスタート地点のポイントを設定し、経由地点の配列に追加
            let basePoint = AGSPoint(x:startLoc[0], y:startLoc[1], spatialReference: AGSSpatialReference.wgs84())
            // ポイントの空間参照（WGS84）を現在表示しているマップの空間参照に変更
            let baseMapPoint = AGSGeometryEngine.projectGeometry(basePoint, to: self.mapView.spatialReference!) as? AGSPoint
            let baseStop = AGSStop(point: baseMapPoint!)
            self.stopsArray.append(baseStop)
            
            
            // CSV のデータをフィルタリングした配列から各要素を取得
            for searchSpot in searchArray {
                
                // 取得した要素の文字列から、観光地の名称・緯度・経度を取得
                let spotStr = searchSpot.components(separatedBy: ",")
                let name = String(spotStr[0])
                let latitude = Double(spotStr[1])
                let longitude = Double(spotStr[2])
                // 経由地点（観光地）のポイントを作成
                let spotPoint = AGSPoint(x:longitude!, y: latitude!, spatialReference: AGSSpatialReference.wgs84())
                let mapPoint = AGSGeometryEngine.projectGeometry(spotPoint, to: self.mapView.spatialReference!) as? AGSPoint
                let stop = AGSStop(point: mapPoint!)
                // ポイントを経由地点の配列に追加
                self.stopsArray.append(stop)

                // 観光地の名称を表示するテキスト シンボルを作成
                let textSymbol = AGSTextSymbol(text: name, color: UIColor(red: 0, green: 0, blue: 230/255.0, alpha: 1), size: 18, horizontalAlignment: AGSHorizontalAlignment.left, verticalAlignment: AGSVerticalAlignment.top)
                // テキスト シンボルとジオメトリ（経由地点）を設定してグラフィックを作成
                let textGraphic = AGSGraphic(geometry: mapPoint, symbol: textSymbol, attributes: nil)
                // グラフィックをグラフィックス オーバレイに追加
                self.labelGraphicsOverlay.graphics.add(textGraphic)
                
            }
            
            // ルート検索のゴール地点（スタート地点に戻る）のポイントを設定し、経由地点の配列に追加
            self.stopsArray.append(baseStop)
            
        } catch let error as NSError {
            self.showError(str: error.localizedDescription)
        }
        
        // ルート検索の実行
        self.route()
        
    }

    
    
    private func route() {
        
        // 経由地点と検索パラメーターが存在する場合に処理を実行
        if self.stopsArray.count <= 1 || self.routeParameters == nil {
            return
        }
        
        // ルート検索パラメーターの設定
        self.routeParameters.setStops(self.stopsArray)  // 経由地点の追加
        self.routeParameters.returnStops = true  // 検索結果に経由地点の情報を返す
        self.routeParameters.findBestSequence = true  // 最短でま経由地点をまわれるように通過順序を変更する
        self.routeParameters.preserveFirstStop = true  // スタート地点を固定する
        self.routeParameters.preserveLastStop = true  // ゴール地点を固定する
        self.routeParameters.travelMode = self.routeTask.routeTaskInfo().travelModes[0] // 所要時間（自動車）を基準にルートを検索する
        
        // ルート検索を実行
        self.routeTask.solveRoute(with: self.routeParameters) {[weak self] (routeResult:AGSRouteResult?, error:Error?) in
            if let error = error {
                self?.showError(str: error.localizedDescription)
            }
            else {
                // 検索結果の取得
                if let route = routeResult?.routes[0] {
                    
                    // 通過順に経由地点のポイントを取得して、グラフィックを作成
                    for i in 0 ..< route.stops.count - 1 {
                        let stopMarkerGraphic = self!.graphicForPoint(route.stops[i].geometry!, isIndexRequired: true, index:i+1)
                        self!.markerGraphicsOverlay.graphics.add(stopMarkerGraphic)
                    }
                    
                    // 検索結果のルートのグラフィックを作成
                    let routeSymbol = AGSSimpleLineSymbol(style: .solid, color: .blue, width: 5)
                    let routeGraphic = AGSGraphic(geometry: route.routeGeometry, symbol: routeSymbol, attributes: nil)
                    self?.routeGraphicsOverlay.graphics.add(routeGraphic)
                    
                    
                    // 検索結果のルートの総移動時間の取得
                    let totalRouteTime = route.totalTime.rounded()
                    let totalRouteTimeStr = "".appendingFormat("%.0f", totalRouteTime)
                    self?.routeTime.text = "移動時間：" + totalRouteTimeStr + " 分"
                    
                }
            }
        }
    }
    
    
    // 経由地点ポイントのグラフィックを返す
    private func graphicForPoint(_ point:AGSPoint, isIndexRequired: Bool, index: Int?) -> AGSGraphic {
        let symbol = self.symbolForStopGraphic(isIndexRequired: isIndexRequired, index: index)
        let graphic = AGSGraphic(geometry: point, symbol: symbol, attributes: nil)
        return graphic
    }
    
    // 経由地点ポイントのシンボルを返す
    private func symbolForStopGraphic(isIndexRequired: Bool, index: Int?) -> AGSSymbol {
        
        // 通過する順番の数字を表示するシンボルを作成
        let markerImage = UIImage(named: "pin")!
        let markerSymbol = AGSPictureMarkerSymbol(image: markerImage)
        markerSymbol.offsetY = markerImage.size.height/2
        markerSymbol.leaderOffsetY = markerSymbol.offsetY
        
        if isIndexRequired && index != nil {
            let textSymbol = AGSTextSymbol(text: "\(index!)", color: .white, size: 20, horizontalAlignment: .center, verticalAlignment: .middle)
            textSymbol.offsetY = markerSymbol.offsetY
            
            let compositeSymbol = AGSCompositeSymbol(symbols: [markerSymbol, textSymbol])
            return compositeSymbol
        }
        
        return markerSymbol
    }

    
    
    
    private func showError(str:String) {
        // エラーのアラート表示
        let alert: UIAlertController = UIAlertController(title: "エラー", message: str, preferredStyle:  UIAlertController.Style.alert)
        let defaultAction: UIAlertAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil)
        alert.addAction(defaultAction)
        present(alert, animated: true, completion: nil)

    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(false)
        self.mapView.map = nil
    }
    
    
}
