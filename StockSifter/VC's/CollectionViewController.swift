//
//  CollectionViewController.swift
//  StockSifter
//
//  Created by Cory Kornowicz on 3/19/19.
//  Copyright © 2019 Cory Kornowicz. All rights reserved.
//

import UIKit
import RealmSwift
import ProcedureKit

private let reuseIdentifier = "Cell"

class CollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UISearchResultsUpdating {
    
    //MARK: Variables
    
    private let itemsPerRow: CGFloat = 1
    private var sectionInsets = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
    
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
    
    var lastUpdated: Date?
    
    lazy var procedureQueue = ProcedureQueue()
    
    var groupQueue : ProcedureQueue = {
        let temp = ProcedureQueue()
        temp.maxConcurrentOperationCount = 1
        return temp
    }()
    
    var collectionView: UICollectionView!
    var flowLayout: FlowLayout!
    
    var fireDate = Date()
    var timer : Timer!
    
    var arrOfDataPro = [DataFetchTaskProcedure]()
    var arrOfGroupedData = [GroupProcedure]()
    
    var search : UISearchController = {
        let temp = UISearchController(searchResultsController: nil)
        return temp
    }()
    
    var refreshItem : UIBarButtonItem?
    var queueItem: UIBarButtonItem?
    
    //MARK: viewDidLoad
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        setupView()
        
        self.timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(60.0), repeats: false, block: { (_) in
            self.groupQueue.isSuspended = false
        })
        
        self.updateBool = UserDefaults.standard.bool(forKey: "AutoUpdate")
        let markets = UserDefaults.standard.array(forKey: "Markets")
        
        if markets != nil {
            self.markets = getMarketDictFromArr(arr: markets as! [String])
        }
        
        //MARK: Update Companies
        
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
    
    //MARK: viewWillAppear
    
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
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        var frame = collectionView.frame
        frame.size.height = self.view.frame.size.height
        frame.size.width = self.view.frame.size.width
        frame.origin.x = 0
        frame.origin.y = 0
        collectionView.frame = frame
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        if UIDevice.current.orientation.isLandscape {
            collectionView.contentInset = UIEdgeInsets(top: 10, left: 5, bottom: 10, right: 10)
        } else {
            collectionView.contentInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        }
    }
    
    //MARK: setupView
    
    func setupView() {
        
        flowLayout = FlowLayout()
        collectionView = UICollectionView.init(frame: CGRect.zero, collectionViewLayout: flowLayout)
        collectionView.showsVerticalScrollIndicator = true
        collectionView.showsHorizontalScrollIndicator = false
    
        // Register cell classes
        collectionView.contentInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        
        //        self.collectionView!.register(UINib(nibName: "CollectionViewCell", bundle: nil), forCellWithReuseIdentifier: reuseIdentifier)
        self.collectionView.register(CompanyCollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.backgroundColor = .gray
        
        self.view.backgroundColor = self.collectionView.backgroundColor
        //self.view.insetsLayoutMarginsFromSafeArea = true
        
        self.navigationController?.navigationBar.barStyle = UIBarStyle.default
        self.definesPresentationContext = true
        self.extendedLayoutIncludesOpaqueBars = true
        
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
        
        self.navigationItem.hidesSearchBarWhenScrolling = true
        
        //TODO: Set search controller to collectionView header view
        
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = convertToNSAttributedStringKeyDictionary([NSAttributedString.Key.foregroundColor.rawValue: UIColor.black])
        
        refreshItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(performUpdate))
        queueItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(queueCompanies))
        
        refreshItem?.tintColor = .black
        queueItem?.tintColor = .black
        
        navigationItem.rightBarButtonItems = [refreshItem!, queueItem!]
        
        self.view.addSubview(collectionView)
        
//        let guide = view.safeAreaLayoutGuide
//
//        NSLayoutConstraint.activate([
//
//            collectionView.topAnchor.constraint(equalTo: guide.topAnchor),
//            collectionView.bottomAnchor.constraint(equalTo: guide.bottomAnchor),
//            collectionView.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
//            collectionView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
//            collectionView.centerXAnchor.constraint(equalTo: guide.centerXAnchor),
//            collectionView.centerYAnchor.constraint(equalTo: guide.centerYAnchor),
//
//        ])
        
    }
    
    
    //MARK: performUpdate
    
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
    
    //MARK: initializeTable
    
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
            self.collectionView.reloadData()
        }
    }
    
    //MARK: queueCompanies
    
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
    
    //MARK: parseCompanyInformationReturnProcedure
    
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
                
                self.collectionView.reloadItems(at: [procedure.task.2!])
                
//                self.tableVC.reloadRows(at: [procedure.task.2!], with: .fade)
                self.initilaize(reloadTableView: false)
            }
        }
        
        return dataTask
    }
    
    //MARK: parseCompanyInformation
    
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
                
                self.collectionView.reloadItems(at: [procedure.task.2!])
                
//                self.tableVC.reloadRows(at: [procedure.task.2!], with: .fade)
                self.initilaize(reloadTableView: false)
                if (completion != nil){
                    completion!()
                }
            }
        }
        
        procedureQueue.addOperation(dataTask)
    }
    
    //MARK: filterCompanies
    
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
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource
    
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.filteredCompanies.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! CompanyCollectionViewCell
        
        if filteredCompanies.count > 0 {
            
            cell.companyNameLabel.text = filteredCompanies[indexPath.row].name
            cell.companySymbolLabel.text = filteredCompanies[indexPath.row].symbol
        
            //TODO: fix duplication of MACD value's
//            if self.filteredCompanies[indexPath.row].macd != nil {
//                cell.publicCompanyGetter = filteredCompanies[indexPath.row]
//            }else {
//                cell.company = nil
//            }
            
        }
        
        cell.layer.cornerRadius = 20
        
        return cell
    }

    // MARK: UICollectionViewDelegate

    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
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
        
        do {
            self.collectionView.deselectItem(at: indexPath, animated: true)
        }
        
    }
    
    
    
    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    /*
    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }
    */
    func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
        print(indexPath.row)
    }
    
    
    //MARK: getDataToDict
    
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

//MARK: searchResults

extension CollectionViewController{
    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text, !searchText.isEmpty {
            filteredCompanies = companies.filter { company in
                return (company.name.lowercased().contains(searchText.lowercased()) || company.symbol.lowercased().contains(searchText.lowercased()))
            }
            
        } else {
            filteredCompanies = companies
        }
        
//        self.tableVC.reloadData()
        self.collectionView.reloadData()
    }
    
    
    
}

//MARK: flowLayoutDelegate

extension CollectionViewController: UICollectionViewDelegateFlowLayout{

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        let paddingSpace = sectionInsets.left * (itemsPerRow)
        let availableWidth = view.frame.width - paddingSpace - (view.safeAreaInsets.left+15)
        let widthPerItem = availableWidth / itemsPerRow
        
        return CGSize(width: widthPerItem, height: 60)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.bottom
    }
    
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToNSAttributedStringKeyDictionary(_ input: [String: Any]) -> [NSAttributedString.Key: Any] {
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}
