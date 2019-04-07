//
//  ViewController.swift
//  StockSifter
//
//  Created by Cory Kornowicz on 7/19/18.
//  Copyright © 2018 Cory Kornowicz. All rights reserved.
//
//use a loading indication while this is happening
//build array of empty companies
//parse each exchange file
//then start to creat companies from given data
//then add data to them until all fields are filled
//save the data
//parse csv files from the internet of all available companies
//then filter each company with data parsed from alphavantage
// Moving Averages
// MACD
// RSI
// OBV
//then we can gather a list of all companies that would be good investments

//Fix the selecting cell which presents four smaller views to each graph

//fix
//after refreshing it crashed because object was deleted and the table view was not refreshed
//fix background not having a smoo myvKif-camqyf-wyrti4th transition

//remove toolbar

import UIKit
import RealmSwift
import ProcedureKit

public var apiKey = "9L22P6H1QOKKJ7AY"

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating {

    var companies: [Company] = [Company]()
    var filteredCompanies: [Company] = []
    
    var definedMarkets = ["AMEX": URL(string: "https://www.nasdaq.com/screening/companies-by-industry.aspx?exchange=AMEX&render=download"),
                          "NASDAQ": URL(string: "https://www.nasdaq.com/screening/companies-by-industry.aspx?exchange=NASDAQ&render=download"),
                          "NYSE": URL(string: "https://www.nasdaq.com/screening/companies-by-industry.aspx?exchange=NYSE&render=download")]
    
//    var nasdaqURL = URL(string: "https://www.nasdaq.com/screening/companies-by-industry.aspx?exchange=NASDAQ&render=download")
//    var nyseURL = URL(string: "https://www.nasdaq.com/screening/companies-by-industry.aspx?exchange=NYSE&render=download")
//    var amexURL = URL(string: "https://www.nasdaq.com/screening/companies-by-industry.aspx?exchange=AMEX&render=download")
    
    var markets: [String : URL]!
    var updateBool: Bool!
    
    var tableVC : UITableView = {
        let tempVC = UITableView()
        tempVC.translatesAutoresizingMaskIntoConstraints = false
        tempVC.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        tempVC.tableFooterView = UIView(frame: CGRect.zero)
        return tempVC
    }()

    var lastUpdated: Date?
    
    lazy var procedureQueue = ProcedureQueue()
    
    var groupQueue : ProcedureQueue = {
        let temp = ProcedureQueue()
        temp.maxConcurrentOperationCount = 1
        return temp
    }()
    
    var fireDate = Date()
    var timer : Timer!
    
    var arrOfDataPro = [DataFetchTaskProcedure]()
    var arrOfGroupedData = [GroupProcedure]()
    
    var search : UISearchController = {
        let temp = UISearchController(searchResultsController: nil)
        return temp
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(60.0), repeats: false, block: { (_) in
            self.groupQueue.isSuspended = false
        })
        
        self.updateBool = UserDefaults.standard.bool(forKey: "AutoUpdate")
        let markets = UserDefaults.standard.array(forKey: "Markets")
        
        if markets != nil {
            self.markets = getMarketDictFromArr(arr: markets as! [String])
        }
        
        setupView()

        //Update
    
        if updateBool {
            
            lastUpdated = UserDefaults.standard.object(forKey: "lastUpdated") as? Date
            //let needsToBeUpdated = true
            let currentDate = Date()
            
            if lastUpdated == nil || currentDate > (lastUpdated?.addingTimeInterval(1800))!{
                //update
                print("needs to update")
                self.initilaize(reloadTableView: true)
                self.performUpdate()
                lastUpdated = currentDate
                UserDefaults.standard.setValue(lastUpdated, forKeyPath: "lastUpdated")
            } else {
                print("does not need to update")
                //do not update
                DispatchQueue.main.async {
                    self.initilaize(reloadTableView: true)
                }
            }
        
        }else {
            print("Do not auto-update")
            DispatchQueue.main.async {
                self.initilaize(reloadTableView: true)
            }
        }
        
    }

    override func viewWillAppear(_ animated: Bool) {
        self.updateBool = UserDefaults.standard.bool(forKey: "AutoUpdate")
        let markets = UserDefaults.standard.array(forKey: "Markets")
        
        if markets != nil {
            self.markets = getMarketDictFromArr(arr: markets as! [String])

        }
        
        let wiped = UserDefaults.standard.bool(forKey: "Wiped Data")
        
        if wiped {
            DispatchQueue.main.async {
                self.initilaize(reloadTableView: true)
            }
            UserDefaults.standard.set(false, forKey: "Wiped Data")
        }

    }
    
    @objc func performUpdate() {
        self.refreshItem?.isEnabled = false
        
        var urls = [URL]()
        
        self.markets.forEach { (arg0) in
            let (_, _) = arg0
            urls.append(arg0.value)
        }
        
        let networkCompanyParse = NetworkCompanyReturnProcedure(urls: urls)

        networkCompanyParse.addWillExecuteBlockObserver { (_, _) in
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
                self.refreshItem?.isEnabled = false
                print("will execute network function")
            }
        }

        networkCompanyParse.addDidFinishBlockObserver { (pro, _) in
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                print("done executing network function")
                if pro.output.value?.value!.count == 0 {
                    self.initilaize(reloadTableView: true)
                    self.refreshItem?.isEnabled = true
                    return
                }else {
                    self.companies = (pro.output.value?.value)!
                    self.filterCompanies()
                }
                self.refreshItem?.isEnabled = true
            }
        }

        procedureQueue.addOperation(networkCompanyParse)
    }
    
    func initilaize(reloadTableView: Bool) {
        self.companies = Array(self.retrieveObjectsFromRealm()).sorted(by: { (com1, com2) -> Bool in
            return com1.name.localizedCaseInsensitiveCompare(com2.name) == ComparisonResult.orderedAscending
        })
        self.filteredCompanies = self.companies
        print("\(self.companies.count) " + "companies left and reloaded the table view")
        
        if (search.isActive){
            self.updateSearchResults(for: search)
        }
        
        if (reloadTableView){
            self.tableVC.reloadData()
        }
    }
    
    var refreshItem : UIBarButtonItem?
    var queueItem: UIBarButtonItem?
    
    func setupView() {
    
        self.navigationController?.navigationBar.barStyle = UIBarStyle.default
        self.definesPresentationContext = true
        
        self.navigationController?.navigationBar.topItem?.title = "Companies"
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.black]
        self.navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.black]
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationController?.navigationBar.barTintColor = UIColor.white
        self.navigationController?.navigationBar.isTranslucent = false
        
        search.searchResultsUpdater = self
        self.navigationItem.searchController = search
        search.obscuresBackgroundDuringPresentation = false
        search.searchBar.placeholder = "Search for a company"
        search.searchBar.tintColor = UIColor.black
        search.searchBar.searchBarStyle = .default
        
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = convertToNSAttributedStringKeyDictionary([NSAttributedString.Key.foregroundColor.rawValue: UIColor.black])
        
        tableVC.dataSource = self
        tableVC.delegate = self
        tableVC.backgroundColor = .white
        tableVC.separatorInset = UIEdgeInsets.zero
        tableVC.separatorColor = .clear
        tableVC.register(UINib(nibName: "TableViewCell", bundle: nil), forCellReuseIdentifier: "cell")
        
        view.addSubview(tableVC)
        
        refreshItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(performUpdate))
        queueItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(queueCompanies))
        
        refreshItem?.tintColor = .black
        queueItem?.tintColor = .black
        
        navigationItem.rightBarButtonItems = [refreshItem!, queueItem!]
    
        let guide = view.safeAreaLayoutGuide
        
        NSLayoutConstraint.activate([
            
            tableVC.widthAnchor.constraint(equalTo: guide.widthAnchor),
            tableVC.heightAnchor.constraint(equalTo: guide.heightAnchor),
            tableVC.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            tableVC.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            tableVC.centerXAnchor.constraint(equalTo: guide.centerXAnchor),
            tableVC.centerYAnchor.constraint(equalTo: guide.centerYAnchor),
        
        ])
    }
    
    @objc func queueCompanies() {
        
        self.queueItem?.isEnabled = false
        
        var lastIndex = 0;
        
        //create procedures to fetch multiple parseCompanies (5) and then compare the date and if it exceeds 1 minute call again, else create a timer for the difference in time and fire it
        
        for index in 0...self.filteredCompanies.count - 1 {
            let company = self.filteredCompanies[index]
            if company.macd == nil {
                let iPath = IndexPath(row: index, section: 0)
                arrOfDataPro.append(parseCompanyInformationReturnProcedure(company: company, index: iPath))
            }
        }
        
        var newGroup = GroupProcedure()
        
        for i in stride(from: 5, through: arrOfDataPro.count, by: 5){
            var proceduresToAdd = [DataFetchTaskProcedure]()
            proceduresToAdd = Array(arrOfDataPro[lastIndex..<i])
            newGroup.addChildren(proceduresToAdd)
            arrOfGroupedData.append(newGroup)
            newGroup = GroupProcedure()
            lastIndex=i
        }
        
        print(lastIndex)
        print(arrOfDataPro.count)
        
        if (lastIndex < arrOfDataPro.count){
            print(String(arrOfDataPro.count - lastIndex) + " companies remaining")
            
            var proceduresToAdd = [DataFetchTaskProcedure]()
            proceduresToAdd = Array(arrOfDataPro[lastIndex...arrOfDataPro.count-1])
            newGroup.addChildren(proceduresToAdd)
            arrOfGroupedData.append(newGroup)
            
        }

        print(arrOfGroupedData.count)
        
        arrOfGroupedData.forEach { (group) in
            
            group.addWillExecuteBlockObserver { (_, _) in
                //uiloader update and setting the date
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = true
                }
            }
            
            group.addDidFinishBlockObserver { (_, _) in
                //date comparison and loading the next group onto the global queue
                self.groupQueue.isSuspended = true
                self.timer.fire()
                
                if self.groupQueue.operationCount == 0 {
                    self.queueItem?.isEnabled = true
                }
                
            }
            
        }
        
        groupQueue.addOperations(arrOfGroupedData)
        
        
        arrOfDataPro = [DataFetchTaskProcedure]()
        arrOfGroupedData = [GroupProcedure]()
    
        print("Finished Successfully")
        
        //Work on timing functions or process data from outside server that I host and update on my own lesiure

    }
    
    func parseCompanyInformationReturnProcedure(company: Company, index: IndexPath?) -> DataFetchTaskProcedure {
        
        let companyMACD = AlphaURLGenerator.init(companySymbol: company.symbol).baseMACDString()
        
        let networkTask = NetworkTask(company: company, function: Function.MACD)
        
        let dataTask = DataFetchTaskProcedure(taskInput: (companyMACD, networkTask, index ?? nil))
        
        dataTask.addWillExecuteBlockObserver { (_, _) in
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            }
        }
        
        dataTask.addDidFinishBlockObserver { (procedure, err) in
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                let company = procedure.task.1.company
                let realm = try! Realm()
                try! realm.write {
                    company.macd = procedure.output.success
                    realm.add(company, update: true)
                }
                self.tableVC.reloadRows(at: [procedure.task.2!], with: .fade)
                self.initilaize(reloadTableView: false)
            }
        }
        
        return dataTask
    }
    
    
    func parseCompanyInformation(company: Company, index: IndexPath?, completion: (() -> Void)?) {

        let companyMACD = AlphaURLGenerator.init(companySymbol: company.symbol).baseMACDString()
        
        let networkTask = NetworkTask(company: company, function: Function.MACD)
        
        let dataTask = DataFetchTaskProcedure(taskInput: (companyMACD, networkTask, index ?? nil))
        
        dataTask.addWillExecuteBlockObserver { (_, _) in
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            }
        }
       
        dataTask.addDidFinishBlockObserver { (procedure, err) in
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                let company = procedure.task.1.company
                let realm = try! Realm()
                try! realm.write {
                    company.macd = procedure.output.success
                    realm.add(company, update: true)
                }
                self.tableVC.reloadRows(at: [procedure.task.2!], with: .fade)
                self.initilaize(reloadTableView: false)
                if (completion != nil){
                    completion!()
                }
            }
        }
        
        procedureQueue.addOperation(dataTask)
    }
    
    func filterCompanies() {
        
        //self.companies == keep
        //self.companiesFromRealm == remove

        DispatchQueue.main.async {
            
        let companiesToKeep = self.companies
        var companiesFromRealm = [String]()
            
        companiesFromRealm = Array(self.retrieveObjectsFromRealm()).map { (company) -> String in
            company.symbol
        }
    
        let input = (companiesToKeep, companiesFromRealm)
        
        let filterProcedure = FilterProcedure(inputValues: input)
        
        filterProcedure.addWillExecuteBlockObserver { (_, _) in
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
                print("will begin to filter the companies")
            }
        }
        
        filterProcedure.addDidFinishBlockObserver { (procedure, _) in
            DispatchQueue.main.async {
                
                //returns ([Company], [String])
                
                if (procedure.output.value?.value?.0.count == 0) && (procedure.output.value?.value?.1.count == 0) {
                    print("No Changes")
                    DispatchQueue.main.async {
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                        self.refreshItem?.isEnabled = true
                    }
                    return
                }
                
                guard let companiesToKeep = procedure.output.value?.value?.0 else {
                    print("no companies in memory")
                    return
                }
                
                guard let companiesToRemove = procedure.output.value?.value?.1 else {
                    print("no companies in memory")
                    return
                }
                
                print(companiesToKeep.count)
                print(companiesToRemove.count)
                
                let realm = try! Realm()

                try! realm.write {
                    realm.add(companiesToKeep, update: true)
                    var com = [Company]()
                    companiesToRemove.forEach({ (key) in
                        com.append(realm.object(ofType: Company.self, forPrimaryKey: key)!)
                    })
                    realm.delete(com)
                }

                realm.refresh()
                
//                self.pushObjectsToRealm(objects: companiesToKeep)
//                self.removeObjectsFromRealm(objects: companiesToRemove)
//
                
                do {
                    print("done filtering companies")
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    self.refreshItem?.isEnabled = true
                    self.initilaize(reloadTableView: true)
                }
                
            }
            
        }
        
            self.procedureQueue.addOperation(filterProcedure)
            
        }
        
    }

    func getMarketDictFromArr(arr: [String]) -> [String: URL]{
        var temp = [String: URL]()
        
        if !(arr.isEmpty){
            for index in arr {
                let str =  index.localizedUppercase
                temp.updateValue(definedMarkets[str]!!, forKey: str)
            }
        }
    
        return temp
    }
    
    
}

extension ViewController {
    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text, !searchText.isEmpty {
            filteredCompanies = companies.filter { company in
                return (company.name.lowercased().contains(searchText.lowercased()))
            }
            
        } else {
            filteredCompanies = companies
        }
        
        self.tableVC.reloadData()
    }
}

extension ViewController {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredCompanies.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! TableViewCell
        
        if filteredCompanies.count > 0 {
            
            cell.label.text = filteredCompanies[indexPath.row].symbol
            
            //cell.textLabel?.text = filteredCompanies[indexPath.row].name
            //cell.detailTextLabel?.text = filteredCompanies[indexPath.row].symbol
            
            if self.filteredCompanies[indexPath.row].macd != nil {
                cell.accessoryType = .checkmark
            }
            
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if self.filteredCompanies[indexPath.row].macd == nil {
            print("fetching MACD")
            self.parseCompanyInformation(company: self.filteredCompanies[indexPath.row], index: indexPath){
                let stockViewController = StockDataView()
                stockViewController.company = self.filteredCompanies[indexPath.row]
                self.navigationController?.pushViewController(stockViewController, animated: true)
            }
        } else {
            let stockViewController = StockDataView()
            stockViewController.company = self.filteredCompanies[indexPath.row]
            self.navigationController?.pushViewController(stockViewController, animated: true)
        }
        
        do{ tableView.deselectRow(at: indexPath, animated: true) }
 
    }
    
    //TODO: implement into CollectionView or tap to enlarge cell
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // Get current state from data source
    
        let title = "Refresh MACD"
        let action = UIContextualAction(style: .normal, title: title,
                                        handler: { (action, view, completionHandler) in
                                            // Update data source when user taps action
                                            self.parseCompanyInformation(company: self.filteredCompanies[indexPath.row], index: indexPath, completion: nil)
                                            completionHandler(true)
                                        })
        action.image = nil
        action.backgroundColor = .blue
        let configuration = UISwipeActionsConfiguration(actions: [action])
        return configuration
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 88
    }
    
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToNSAttributedStringKeyDictionary(_ input: [String: Any]) -> [NSAttributedString.Key: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}
