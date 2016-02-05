//
//  RoomListViewTableViewCell.swift
//  SyncApp
//
//  Created by Matt Ferri on 2/5/16.
//  Copyright © 2016 Matthew Ferri. All rights reserved.
//

import UIKit

class RoomListViewTableViewCell: UITableViewCell {
    
    @IBOutlet weak var roomImageView: UIImageView!
    @IBOutlet weak var roomTitleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
