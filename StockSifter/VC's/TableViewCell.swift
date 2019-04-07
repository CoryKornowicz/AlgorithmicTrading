//
//  TableViewCell.swift
//  StockSifter
//
//  Created by Cory Kornowicz on 3/19/19.
//  Copyright © 2019 Cory Kornowicz. All rights reserved.
//

import UIKit

class TableViewCell: UITableViewCell {

    @IBOutlet weak var label: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.backgroundColor = .gray
        let newFrame = self.layer.frame.inset(by: UIEdgeInsets(top: 15, left: 10, bottom: 15, right: 10))
        self.layer.frame = newFrame
        self.layer.cornerRadius = 15
        self.clipsToBounds = true
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
}
