//
//  TableCell.swift
//  StockSifter
//
//  Created by Cory Kornowicz on 7/20/18.
//  Copyright © 2018 Cory Kornowicz. All rights reserved.
//

import Foundation
import UIKit

class TableViewCell : UITableViewCell {
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: "stockCell")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
