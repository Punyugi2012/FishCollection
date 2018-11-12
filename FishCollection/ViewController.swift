//
//  ViewController.swift
//  FishCollection
//
//  Created by punyawee  on 3/11/2561 BE.
//  Copyright © 2561 Punyugi. All rights reserved.
//

import UIKit
import AVFoundation

class FishModel {
    var fishNameEng: String
    var fishNameTh: String
    var imageURL: String
    var textureURLs: [String]
    var modelURL: String
    init(nameEng: String, nameTh: String, imageURL: String, textureURLs: [String], modelURL: String) {
        fishNameEng = nameEng
        fishNameTh = nameTh
        self.imageURL = imageURL
        self.textureURLs = textureURLs
        self.modelURL = modelURL
    }
}


class ViewController: UIViewController {
    
    @IBOutlet weak var myTableView: UITableView!
    
    var fishModels: [FishModel] = []
    
    let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    
    var progressView: UIProgressView?
    
    var loadingView: LoadDataView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        myTableView.dataSource = self
        myTableView.delegate = self
        navigationController?.navigationBar.layer.zPosition = -1
        
        let localDataURL = documentURL.appendingPathComponent("data1.json")
        print(localDataURL.path)
        
        if !FileManager.default.fileExists(atPath: localDataURL.path) {
            if let loadingView = Bundle.main.loadNibNamed("LoadDataView", owner: self, options: nil)?.first as? LoadDataView {
                progressView = loadingView.progressView
                self.loadingView = loadingView
                progressView?.progress = 0.0
                loadingView.frame = view.bounds
                view.addSubview(loadingView)
                downloadData()
                
            }
        }
        else {
            DispatchQueue.global(qos: .userInteractive).async {
                self.fishModels = self.loadFromLocal()
                DispatchQueue.main.async {
                    self.myTableView.reloadData()
                    self.navigationController?.navigationBar.layer.zPosition = 99
                    print("โหลดข้อมูลจากในเครื่องแล้ว")
                }
            }
        }
    }
    
    func downloadData() {
        downloadDataFromServer { (result) in
            if result {
                print("โหลดสำเร็จแล้วจาก server")
                DispatchQueue.main.async {
                    self.loadingView?.removeFromSuperview()
                    self.myTableView.reloadData()
                    self.navigationController?.navigationBar.layer.zPosition = 99
                }
            }
            else {
                let alertController = UIAlertController(title: "ดาวน์โหลดไม่สำเร็จ", message: "ตรวจสอบการเชื่อมต่อInternetของท่านแล้วกดดาวน์โหลดอีกครั้ง", preferredStyle: .alert)
                let resetAction = UIAlertAction(title: "ดาวน์โหลดอีกครั้ง", style: .default, handler: { (action) in
                    self.progressView?.progress = 0.0
                    self.clearLocalData()
                    self.downloadData()
                })
                alertController.addAction(resetAction)
                self.present(alertController, animated: true, completion: nil)
                print("โหลดข้อมูลไม่สำเร็จ จาก server")
            }
        }
    }
    
    func clearLocalData() {
        fishModels = loadFromLocal()
        let localDataURL = documentURL.appendingPathComponent("data1.json")
        try? FileManager.default.removeItem(at: localDataURL)
        for fishModel in fishModels {
            if let imageURL = URL(string: fishModel.imageURL) {
                let localImageURL = documentURL.appendingPathComponent(imageURL.lastPathComponent)
                try? FileManager.default.removeItem(at: localImageURL)
            }
            if let modelURL = URL(string: fishModel.modelURL) {
                let localModelURL = documentURL.appendingPathComponent(modelURL.lastPathComponent)
                try? FileManager.default.removeItem(at: localModelURL)
            }
            for texture in fishModel.textureURLs {
                if let textureURL = URL(string: texture) {
                    let localTextureURL = documentURL.appendingPathComponent(textureURL.lastPathComponent)
                    try? FileManager.default.removeItem(at: localTextureURL)
                }
            }
        }
    }
    
    func loadFromLocal() -> [FishModel] {
        let localDataURL = documentURL.appendingPathComponent("data1.json")
        var fishModels: [FishModel] = []
        do {
            let data = try Data(contentsOf: localDataURL)
            let foundationData = try JSONSerialization.jsonObject(with: data, options: [])
            if let raws1 = foundationData as? [[String:Any]] {
                for raw in raws1 {
                    if
                        let nameEng = raw["name_eng"] as? String,
                        let nameTh = raw["name_th"] as? String,
                        let imageURL = raw["image_url"] as? String,
                        let textureURLs = raw["texture_urls"] as? [String],
                        let modelURL = raw["model_url"] as? String
                    {
                        let fishModel = FishModel(nameEng: nameEng, nameTh: nameTh, imageURL: imageURL, textureURLs: textureURLs, modelURL: modelURL)
                        fishModels.append(fishModel)
                    }
                }
            }
        }
        catch {
            print(error.localizedDescription)
        }
        return fishModels
    }
    
    func updateProgressView(from: Float, to: Float) {
        DispatchQueue.main.async {
            self.progressView?.progress = from / to
        }
    }
    
    
    func downloadDataFromServer(completeHandler: @escaping (_ result: Bool) -> Void) {
        DispatchQueue.global(qos: .userInteractive).async {
            let dataPath = "https://raw.githubusercontent.com/AmAdevs/dae/master/data1.json"
            if let dataURL = URL(string: dataPath) {
                let localDataURL = self.documentURL.appendingPathComponent(dataURL.lastPathComponent)
                print(self.documentURL.path)
                URLSession.shared.downloadTask(with: dataURL, completionHandler: { (location, response, error) in
                    if error == nil, let response = response as? HTTPURLResponse, response.statusCode == 200 {
                        do {
                            try FileManager.default.moveItem(at: location!, to: localDataURL)
                            self.fishModels = self.loadFromLocal()
                            var countForDownload: Float = 0
                            for fishModel in self.fishModels {
                                if !fishModel.imageURL.isEmpty {
                                    countForDownload += 1
                                }
                                if !fishModel.modelURL.isEmpty {
                                    countForDownload += 1
                                }
                                for texture in fishModel.textureURLs where !texture.isEmpty {
                                    countForDownload += 1
                                }
                            }
                            var countForFinished: Float = 0
                            let dispatchGroup = DispatchGroup()
                            for fishModel in self.fishModels {
                                
                                if let imageURL = URL(string: fishModel.imageURL) {
                                    dispatchGroup.enter()
                                    let localImageURL = self.documentURL.appendingPathComponent(imageURL.lastPathComponent)
                                    URLSession.shared.downloadTask(with: imageURL, completionHandler: { (location, response, error) in
                                        if
                                            error == nil,
                                            let response = response as? HTTPURLResponse, response.statusCode == 200,
                                            let location = location
                                        {
                                            do {
                                                try FileManager.default.moveItem(at: location, to: localImageURL)
                                                countForFinished += 1
                                                self.updateProgressView(from: countForFinished, to: countForDownload)
                                            } catch {
                                                print(error.localizedDescription)
                                            }
                                            dispatchGroup.leave()
                                        }
                                    }).resume()
                                }
                                
                                if let modelURL = URL(string: fishModel.modelURL) {
                                    dispatchGroup.enter()
                                    let localModelURL = self.documentURL.appendingPathComponent(modelURL.lastPathComponent)
                                    URLSession.shared.downloadTask(with: modelURL, completionHandler: { (location, response, error) in
                                        if
                                            error == nil,
                                            let response = response as? HTTPURLResponse, response.statusCode == 200,
                                            let location = location
                                        {
                                            do {
                                                try FileManager.default.moveItem(at: location, to: localModelURL)
                                                countForFinished += 1
                                                self.updateProgressView(from: countForFinished, to: countForDownload)
                                            } catch {
                                                print(error.localizedDescription)
                                            }
                                            dispatchGroup.leave()
                                        }
                                    }).resume()
                                }
                                
                                for textureURL in fishModel.textureURLs {
                                    if let textureURL = URL(string: textureURL) {
                                        dispatchGroup.enter()
                                        let localTextureURL = self.documentURL.appendingPathComponent(textureURL.lastPathComponent)
                                        URLSession.shared.downloadTask(with: textureURL, completionHandler: { (location, response, error) in
                                            if
                                                error == nil,
                                                let response = response as? HTTPURLResponse, response.statusCode == 200,
                                                let location = location
                                            {
                                                do {
                                                    try FileManager.default.moveItem(at: location, to: localTextureURL)
                                                    countForFinished += 1
                                                    self.updateProgressView(from: countForFinished, to: countForDownload)
                                                } catch {
                                                    print(error.localizedDescription)
                                                }
                                                dispatchGroup.leave()
                                            }
                                        }).resume()
                                    }
                                }
                                
                            }
                            dispatchGroup.notify(queue: .main, execute: {
                                completeHandler(true)
                            })
                        }
                        catch {
                            print(error.localizedDescription)
                            completeHandler(false)
                        }
                    }
                    else {
                        print("พบปัญหาหลังจากเรียกใช้api ของ data")
                        completeHandler(false)
                    }
                }).resume()
            }
            else {
                print("ไม่สามารถเเปลงเป็นURLได้ ของ data")
                completeHandler(false)
            }
        }
    }
    
    var selectedFishModel: FishModel?
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowARMode" {
            if let destinationVC = segue.destination as? ShowARViewController {
                destinationVC.getFishModel = selectedFishModel
            }
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fishModels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let fishModelCell = tableView.dequeueReusableCell(withIdentifier: "FishModelCell") as? FishModelTableViewCell {
            let fishModel = fishModels[indexPath.row]
            fishModelCell.setupCell(fishImageURL: fishModel.imageURL, fishEngName: fishModel.fishNameEng, fishThName: fishModel.fishNameTh)
            return fishModelCell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedFishModel = fishModels[indexPath.row]
        if AVCaptureDevice.authorizationStatus(for: .video) ==  .authorized {
            performSegue(withIdentifier: "ShowARMode", sender: self)
        } else {
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted: Bool) in
                if granted {
                    self.performSegue(withIdentifier: "ShowARMode", sender: self)
                } 
            })
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}

