//
//  FlowLayout.swift
//  StockSifter
//
//  Created by Cory Kornowicz on 3/21/19.
//  Copyright © 2019 Cory Kornowicz. All rights reserved.
//

import UIKit

class FlowLayout: UICollectionViewFlowLayout {

    let innerSpace: CGFloat = 10.0
    
    override init() {
        super.init()
        self.minimumLineSpacing = innerSpace
        self.minimumInteritemSpacing = innerSpace
        self.scrollDirection = .vertical
    }
    
    required init?(coder aDecoder: NSCoder) {
        //fatalError("init(coder:) has not been implemented")
        super.init(coder: aDecoder)
    }
    
    
//    func itemWidth() -> CGFloat {
//        return (collectionView!.frame.size.width/self.numberOfCellsOnRow)-self.innerSpace
//    }
//
//    func itemHeight() -> CGFloat {
//        return 60
//    }
//
//    override var itemSize: CGSize {
//        set {
//            self.itemSize = CGSize(width:itemWidth(), height:itemHeight())
//        }
//        get {
//            return CGSize(width:itemWidth(),height:itemHeight())
//        }
//    }
    
}
