//
//  URLParseProcedure.swift
//  Experimental Testing
//
//  Created by Cory Kornowicz on 8/18/18.
//  Copyright © 2018 Cory Kornowicz. All rights reserved.
//

import Foundation
import ProcedureKit
import RealmSwift

//make it return an array of Company objects
//make URLSessions ephermeral

class NetworkCompanyReturnProcedure: Procedure, OutputProcedure {
    
    var output: Pending<ProcedureResult<[Company]>> = .pending

    var siteURLs = [URL]()
    
    var outputArray = [Company]()
    
    var strings = [String]()
    
    convenience init(urls: [URL]) {
        self.init()
        self.siteURLs = urls
    }
    
    override func execute() {
        
        returnStrings(urls: siteURLs) { (strings) in
            
            if ((strings?.isEmpty)!){
                self.output = .ready(.success(self.outputArray))
                self.finish()
            }
            
            strings?.forEach({ (str) in
                let cvs = CSwiftV(with: str)
                let rows = cvs.keyedRows
                rows?.forEach({ (row) in
                    let newCompany = Company()
                    for (_,_) in row {
                        //print("\(key) = \(value)")
                        var exch = ""
                        if (strings?.firstIndex(of: str) == 0) {
                            exch = "NASDAQ"
                        } else if (strings?.firstIndex(of: str) == 1) {
                            exch = "NYSE"
                        } else if (strings?.firstIndex(of: str) == 2) {
                            exch = "AMEX"
                        }
                        newCompany.exchange = exch
                        newCompany.name = row["Name"]!
                        newCompany.symbol = row["Symbol"]!
                        newCompany.lastSale = RealmOptional.init(NSString(string: row["LastSale"]!).doubleValue)
                        newCompany.ipoYear = RealmOptional.init(Int(NSString(string: row["IPOyear"]!).intValue))
                        newCompany.marketCap = RealmOptional.init(NSString(string: row["MarketCap"]!).doubleValue)
                        newCompany.sector = row["Sector"]!
                        newCompany.industry = row["Industry"]!
                        newCompany.summaryQuote = row["Summary Quote"]!
                    }
                    self.outputArray.append(newCompany)
                })
            })
            
            self.output = .ready(.success(self.outputArray))
            //print(self.outputArray.count)
            self.finish()
        }

    }
    
    func returnStrings(urls: [URL], completion: @escaping ([String]?) -> Void){
        URLSession.shared.get(urls) { (results) in
            var strings = [String]()
            
            results.forEach({ (result) in
                strings.append(result.string!)
            })
            
            completion(strings)
        }
    }
    
}

class FilterProcedure: Procedure, OutputProcedure {
    
    typealias Output = ([Company], [String])
    
    var input : ([Company], [String])!
    var output: Pending<ProcedureResult<FilterProcedure.Output>> = .pending
    
    convenience init(inputValues: ([Company], [String])) {
        self.init()
        self.input = inputValues
    }
    
    override func execute() {
        guard let values = input else { return }
        filterCompanies(companiesToKeepInput: values.0, companiesFromRealmInput: values.1) { (com1, com2) in
            let outputValue = (com1, com2)
            self.output = .ready(.success(outputValue))
            self.finish()
        }
    }
    
    func filterCompanies(companiesToKeepInput: [Company], companiesFromRealmInput: [String], completetion: @escaping ([Company], [String]) -> Void) {
        
        //self.companies == keep
        //self.companiesFromRealm == remove
        
        var companiesToKeep = companiesToKeepInput
        var companiesToRemove = [String]()
        let companiesFromRealm = companiesFromRealmInput
        
        let strOfCompaniesToKeep = companiesToKeep.map { (company) -> String in
            company.symbol
        }
        
        let strOfCompaniesToRemove = companiesFromRealm
        
        print("hitting the results calculation")
        
        let results = Array<String>().filterTwoArrays(arrayOne: strOfCompaniesToKeep, arrayTwo: strOfCompaniesToRemove)
        
        print(results)
        
        companiesToKeep = [Company]()
        
        results.0.forEach { (str) in
            guard let company = companiesToKeepInput.filter({ $0.symbol == str }).first else {return}
//            print("Keep this one " + company.symbol)
            companiesToKeep.append(company)
        }
        
        results.1.forEach { (str) in
            guard let company = companiesFromRealm.filter({ $0 == str }).first else {return}
//            print("Remove this one " + company.symbol)
            companiesToRemove.append(company)
        }

        completetion(companiesToKeep, companiesToRemove)
    }
    
}

class DataFetchTaskProcedure: Procedure, OutputProcedure {
    
    typealias Output = MACD
    
    var output: Pending<ProcedureResult<DataFetchTaskProcedure.Output>> = .pending
    
    var task : (String?, NetworkTask, IndexPath?)!
    
    convenience init(taskInput: (String?, NetworkTask, IndexPath?)) {
        self.init()
        self.task = taskInput
    }
    
    override func execute() {
        taskFunction { (macd) in
            self.output = .ready(.success(macd))
            self.finish()
        }
    }
    
    func taskFunction(completion: @escaping (MACD) -> Void) {
        if task.1.function == Function.MACD {
            guard let urlKey = URL(string: task.0!) else {
                print("Invalid URL with company " + ((task.2?.row.description)!))
                return
            }
                URLSession.shared.dataTask(with: urlKey) { (data, res, err) in
                    if err == nil {
                        let s = String(data: data!, encoding: .utf8)
                        let cvs = CSwiftV(with: s!)
                        let rows = cvs.keyedRows
                        let values = List<MACDDataValues>()
                        rows?.forEach({ (row) in
                            //can throw emptiness
                            //print(row)
                            let newMACDValue = MACDDataValues()
                            newMACDValue.time = (row["time"] != nil) ? row["time"] : "No Time"
                            newMACDValue.MACD = RealmOptional.init(NSString(string: (row["MACD"] != nil) ? row["MACD"]! : "0.0").doubleValue)
                            newMACDValue.MACD_Hist = RealmOptional.init(NSString(string: (row["MACD_Hist"] != nil) ? row["MACD_Hist"]! : "0.0").doubleValue)
                            newMACDValue.MACD_Signal = RealmOptional.init(NSString(string: (row["MACD_Signal"] != nil) ? row["MACD_Signal"]! : "0.0").doubleValue)
                            values.append(newMACDValue)
                        })
                        let newMACD = MACD()
                        newMACD.values = values
                        //print("-------------------------------------------------------------------------------------------")
                        completion(newMACD)
                        print("done with fetching task")
                    } else {
                        print(err!)
                    }
                }.resume()
            }
    }
    
}
    


extension Array where Element: Equatable {
    mutating func remove(_ obj: Element) {
        self = self.filter { $0 != obj }
    }
    
    func filterTwoArrays(arrayOne: [String], arrayTwo: [String]) -> ([String], [String]){
        
        var arrayOneCast = arrayOne
        var arryTwoCast = arrayTwo
        
        arrayOne.forEach { (str) in
            arryTwoCast.remove(str)
        }
        
        arrayTwo.forEach { (str) in
            arrayOneCast.remove(str)
        }
        
        return (arrayOneCast, arryTwoCast)
    }
}

struct NetworkTask {
    
    var company : Company
    var function: Function!
    
    init(company: Company, function: Function) {
        self.company = company
        self.function = function
    }
    
}

//extension String {
//
//    func toDate(dateString: String, dateFormat: String) -> Date {
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = dateFormat
//        return dateFormatter.date(from: dateString) as Date
//    }
//
//}
