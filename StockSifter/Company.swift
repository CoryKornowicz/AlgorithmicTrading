//
//  Company.swift
//  StockSifter
//
//  Created by Cory Kornowicz on 7/20/18.
//  Copyright © 2018 Cory Kornowicz. All rights reserved.
//

import Foundation
import RealmSwift

class Company: Object {
    @objc dynamic var exchange: String!
    
    @objc dynamic var symbol: String = ""
    @objc dynamic var name: String = ""
    var lastSale = RealmOptional<Double>()
    var marketCap = RealmOptional<Double>()
    var ipoYear = RealmOptional<Int>()
    @objc dynamic var sector: String = ""
    @objc dynamic var industry: String = ""
    @objc dynamic var summaryQuote: String = ""
    
    @objc dynamic var macd: MACD?
    var obv = RealmOptional<Double>()
    var movingAverage200 = RealmOptional<Double>()
    var movingAverage100 = RealmOptional<Double>()
    var movingAverage50 = RealmOptional<Double>()
    var rsi = RealmOptional<Double>()
    
    override static func primaryKey() -> String? {
        return "symbol"
    }
}

class MACD: Object {
    var values = List<MACDDataValues>()
}

class MACDDataValues: Object {
    @objc dynamic var time: String?
    var MACD_Hist = RealmOptional<Double>()
    var MACD_Signal = RealmOptional<Double>()
    var MACD = RealmOptional<Double>()
}
