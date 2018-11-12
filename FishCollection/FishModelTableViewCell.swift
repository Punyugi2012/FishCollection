//
//  FishModelTableViewCell.swift
//  FishCollection
//
//  Created by punyawee  on 3/11/2561 BE.
//  Copyright © 2561 Punyugi. All rights reserved.
//

import UIKit

class FishModelTableViewCell: UITableViewCell {

    @IBOutlet weak var fishImageView: UIImageView! {
        didSet {
            fishImageView.layer.cornerRadius = 10
            fishImageView.clipsToBounds = true
        }
    }
    @IBOutlet weak var fishEngLbl: UILabel!
    @IBOutlet weak var fishThLbl: UILabel!
    let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setupCell(fishImageURL: String, fishEngName: String, fishThName: String) {
        if let imageURL = URL(string: fishImageURL) {
            let localImageURL = documentURL.appendingPathComponent(imageURL.lastPathComponent)
            do {
                let data = try Data(contentsOf: localImageURL)
                fishImageView.image = UIImage(data: data)
            }catch {
                print("ใช้รูปไม่ได้")
                print(error.localizedDescription)
            }
        }
        fishEngLbl.text = fishEngName
        fishThLbl.text = fishThName
    }

}
