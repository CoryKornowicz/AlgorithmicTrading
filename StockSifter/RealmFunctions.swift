//
//  RealmFunctions.swift
//  StockSifter
//
//  Created by Cory Kornowicz on 7/30/18.
//  Copyright © 2018 Cory Kornowicz. All rights reserved.
//

import Foundation
import RealmSwift

extension ViewController {
    
    func pushObjectToRealm(object: Object) {
        DispatchQueue.main.async {
            let realm = try! Realm()
            try! realm.write {
                realm.add(object, update: true)
            }
            realm.refresh()
        }
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
    
    func pushObjectsToRealm(objects: [Object]) {
        DispatchQueue.main.async {
            let realm = try! Realm()
            try! realm.write {
                realm.add(objects, update: true)
            }
            realm.refresh()
        }
    }
    
    func removeObjectsFromRealm(objects: [Object]) {
        DispatchQueue.main.async {
            let realm = try! Realm()
            try! realm.write {
                realm.delete(objects)
            }
            realm.refresh()
        }
    }
    
    func retrieveObjectsFromRealm() -> Results<Company> {
        let realm = try! Realm()
        return realm.objects(Company.self)
    }
    
}
