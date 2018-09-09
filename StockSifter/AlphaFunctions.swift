//
//  AlphaFunctions.swift
//  StockSifter
//
//  Created by Cory Kornowicz on 7/24/18.
//  Copyright © 2018 Cory Kornowicz. All rights reserved.
//

import Foundation
import UIKit

enum Function: String {
    case MACD = "MACD"
    case OBV = "OBV"
    case SMA = "SMA"
    case EMA = "EMA"
    case RSI = "RSI"
}

struct Symbol {
    var symbol : String!
    
    init(symbol: String) {
        self.symbol = symbol
    }
}

enum Interval: String{
    case oneMin = "1min"
    case fiveMin = "5min"
    case fifteenMin = "15min"
    case thrityMin = "30min"
    case sixtyMin = "60min"
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
}

enum SeriesType: String, RawRepresentable{
    case close, open, high, low
}

enum DataType : String {
    case csv = "csv"
    case json = "json"
}

struct AlphaURLGenerator {
    
    var function: Function!
    var symbol: String = ""
    var interval: Interval!
    var seriesType: SeriesType!
    var fastperiod: Int?
    var slowperiod: Int?
    var signalperiod: Int?
    var dataType: DataType!
    
    init(function: Function!, symbol: String, interval: Interval!, seriesType: SeriesType!, fastperiod: Int?, slowperiod: Int?, signalperiod: Int?, dataType: DataType!, apiKey: String!) {
        self.function = function
        self.symbol = symbol
        self.interval = interval
        self.seriesType = seriesType
        self.fastperiod = fastperiod
        self.slowperiod = slowperiod
        self.signalperiod = signalperiod
        self.dataType = dataType
    }
    
    init(companySymbol: String) {
        self.symbol = companySymbol
    }
    
    func baseMACDString() -> String {
        return "https://www.alphavantage.co/query?function=MACD&symbol=\(self.symbol)&interval=daily&series_type=open&datatype=csv&apikey=9L22P6H1QOKKJ7AY"
    }
    
    func toStringMACD() -> String {
        return "https://www.alphavantage.co/query?function=\(function.rawValue)&symbol=\(symbol)&interval=\(interval.rawValue)&series_type=\(seriesType.rawValue)&fastperiod=\((fastperiod != nil) ? fastperiod! : 12)&slowperiod=\((slowperiod != nil) ? slowperiod! : 26)&signlaperiod=\((signalperiod != nil) ? signalperiod! : 9)&datatype=\(dataType.rawValue)&apikey=\(apiKey)"
    }
    
}




