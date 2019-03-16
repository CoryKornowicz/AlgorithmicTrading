//
//  SettingsController.swift
//  StockSifter
//
//  Created by Cory Kornowicz on 1/15/19.
//  Copyright © 2019 Cory Kornowicz. All rights reserved.
//

import UIKit
import RealmSwift

class SettingsController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let marketList = ["NYSE", "NASDAQ", "AMEX"]
    
    var markets = [String]()
    
    /*
     *Automatically Update Toggle
     Markets to Pull Data From Table
     *Clear Companies Saved Button
     */
    
    //Update Toggle
    
    var updateBool : Bool! = {
        let temp = UserDefaults.standard.bool(forKey: "AutoUpdate") 
        return temp
    }()
    
    var updateToggle : UISwitch = {
        let temp = UISwitch(frame: .zero)
        temp.translatesAutoresizingMaskIntoConstraints = false
        return temp
    }()
    
    var updateLabel : UILabel = {
        let temp = UILabel(frame: .zero)
        temp.translatesAutoresizingMaskIntoConstraints = false
        temp.text = "Automatically Update"
        return temp
    }()
    
    //Clear Saved Companies
    
    var clearLabel : UILabel = {
        let temp = UILabel(frame: .zero)
        temp.text = "CLEAR ALL COMPANY DATA"
        temp.translatesAutoresizingMaskIntoConstraints = false
        return temp
    }()
    
    var clearButton : UIButton = {
       let temp = UIButton(frame: .zero)
        temp.setTitle("WIPE THE DATA", for: .normal)
        temp.setTitleColor(.white, for: .normal)
        temp.backgroundColor = .black
        temp.translatesAutoresizingMaskIntoConstraints = false
        return temp
    }()
    
    //Markets to Pull Data From
    
    var marketLabel : UILabel = {
        let temp = UILabel(frame: .zero)
        temp.text = "Markets to Analyze"
        temp.translatesAutoresizingMaskIntoConstraints = false
        return temp
    }()

    var marketTable : UITableView = {
        let temp = UITableView(frame: .zero)
        temp.translatesAutoresizingMaskIntoConstraints = false
        temp.tableFooterView = UIView(frame: .zero)
        return temp
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(SettingsController.loadNSUSerDefaults), name: UserDefaults.didChangeNotification, object: nil)
        loadNSUSerDefaults()
        setupTable()
        setupView()
    }
    
    @objc func loadNSUSerDefaults(){
        //toggle switch
        let updateBool = UserDefaults.standard.bool(forKey: "AutoUpdate")
        updateToggle.setOn(updateBool, animated: true)
        //load markets
        
        let mark = UserDefaults.standard.array(forKey: "Markets")
    
        if mark != nil {
            markets = mark as! [String]
        }else {
            markets = [String]()
        }
    }
    
    func setupTable(){
        marketTable.delegate = self
        marketTable.dataSource = self
        
        marketTable.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        marketTable.reloadData()
    }
   
    func setupView(){
        self.view.backgroundColor = .white
        self.navigationController?.navigationBar.barStyle = UIBarStyle.default
        self.definesPresentationContext = true
        
        self.navigationController?.navigationBar.topItem?.title = "Settings"
        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.black]
        self.navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.black]
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationController?.navigationBar.barTintColor = UIColor.white
        self.navigationController?.navigationBar.isTranslucent = false
        
        //updateToggle
        updateToggle.setOn(updateBool!, animated: true)
        updateToggle.addTarget(self, action: #selector(updateToggled(toggle:)), for: UIControl.Event.valueChanged)
        
        //clear button
        clearButton.addTarget(self, action: #selector(clearAllData), for: .touchUpInside)
    
        let safeLayouts = self.view.safeAreaLayoutGuide
        
        let updateStackView : UIStackView = {
            let temp = UIStackView(arrangedSubviews: [updateLabel, updateToggle])
            temp.translatesAutoresizingMaskIntoConstraints = false
            return temp
        }()
        
        let clearStackView : UIStackView = {
            let temp = UIStackView(arrangedSubviews: [clearLabel, clearButton])
            temp.translatesAutoresizingMaskIntoConstraints = false
            return temp
        }()
        
        let tableStackView : UIStackView = {
            let temp = UIStackView(arrangedSubviews: [marketLabel, marketTable])
            temp.axis = .vertical
            temp.translatesAutoresizingMaskIntoConstraints = false
            return temp
        }()
        
        self.view.addSubview(updateStackView)
        self.view.addSubview(clearStackView)
        self.view.addSubview(tableStackView)
        
        NSLayoutConstraint.activate([
            updateStackView.widthAnchor.constraint(equalTo: safeLayouts.widthAnchor, multiplier: 0.95),
            updateStackView.centerXAnchor.constraint(equalTo: safeLayouts.centerXAnchor),
            updateStackView.heightAnchor.constraint(equalToConstant: 30),
            updateStackView.topAnchor.constraint(equalToSystemSpacingBelow: safeLayouts.topAnchor, multiplier: 0.95),
            
            clearButton.widthAnchor.constraint(equalToConstant: 150),
            marketLabel.heightAnchor.constraint(equalToConstant: 30),
            
            clearStackView.widthAnchor.constraint(equalTo: safeLayouts.widthAnchor, multiplier: 0.95),
            clearStackView.centerXAnchor.constraint(equalTo: safeLayouts.centerXAnchor),
            clearStackView.heightAnchor.constraint(equalToConstant: 30),
            clearStackView.topAnchor.constraint(equalToSystemSpacingBelow: updateStackView.bottomAnchor, multiplier: 0.95),
            
            tableStackView.widthAnchor.constraint(equalTo: safeLayouts.widthAnchor, multiplier: 0.95),
            tableStackView.centerXAnchor.constraint(equalTo: safeLayouts.centerXAnchor),
            tableStackView.heightAnchor.constraint(equalToConstant: 250),
            tableStackView.topAnchor.constraint(equalToSystemSpacingBelow: clearStackView.bottomAnchor, multiplier: 0.95)
            
        ])
        
        
    }
    
    @objc func updateToggled(toggle: UISwitch){
        UserDefaults.standard.set(toggle.isOn, forKey: "AutoUpdate")
    }
    
    @objc func clearAllData(){
        let alertController = UIAlertController(title: "Alert!!", message: "Do you want to continue?", preferredStyle: .alert)
        
        let action1 = UIAlertAction(title: "WIPE ALL DATA", style: .default) { (action:UIAlertAction) in
            print("Wipe all data")
            self.purgeRealm()
            UserDefaults.standard.set(true, forKey: "Wiped Data")
        }
        
        let action2 = UIAlertAction(title: "Cancel", style: .cancel) { (action:UIAlertAction) in
            print("Exiting");
        }
        
        alertController.addAction(action1)
        alertController.addAction(action2)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func purgeRealm() {
        DispatchQueue.main.async {
            let realm = try! Realm()
            try! realm.write {
                realm.deleteAll()
            }
            realm.refresh()
        }
    }
    
    //MARK: Table View Stubs
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return marketList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as UITableViewCell
        
        cell.textLabel?.text = marketList[indexPath.row]
        
        let marketCheck = marketList[indexPath.row]
        
        if markets.contains(marketCheck) {
            cell.accessoryType = .checkmark
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let cell = tableView.cellForRow(at: indexPath) {
            if cell.accessoryType == .none {
                cell.accessoryType = .checkmark
                markets.append((cell.textLabel?.text)!)
            }else {
                cell.accessoryType = .none
                markets.remove((cell.textLabel?.text)!)
            }
            UserDefaults.standard.set(markets, forKey: "Markets")
        }
    
        tableView.deselectRow(at: indexPath, animated: true)
    }

    
}
