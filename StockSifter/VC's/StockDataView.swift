//
//  StockDataView.swift
//  StockSifter
//
//  Created by Cory Kornowicz on 8/17/18.
//  Copyright © 2018 Cory Kornowicz. All rights reserved.
//

import Foundation
import UIKit
import SwiftChart

class StockDataView: UIViewController {
    
    var company : Company?
    
    var chart: Chart = {
        let temp = Chart(frame: CGRect.zero)
        temp.translatesAutoresizingMaskIntoConstraints = false
        temp.backgroundColor = .white
        temp.yLabels = [-1.0, -0.75, -0.5, -0.25, 0, 0.25, 0.5, 0.75, 1.0]
        temp.bottomInset = 40
        temp.topInset = 40
        temp.hideHighlightLineOnTouchEnd = true
        return temp
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.view.backgroundColor = UIColor.white
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    var fetchInt: Int = 40
    
    func setupView() {
        
        let safeArea = self.view.safeAreaLayoutGuide
        
        if (company != nil){
            let dataMACD = Array((company?.macd?.values)!).map { (macdValue) -> Double in
                macdValue.MACD.value!
            }
            
            let dataHIST = Array((company?.macd?.values)!).map { (macdValue) -> Double in
                macdValue.MACD_Hist.value!
            }
            
            let dataSIGNAL = Array((company?.macd?.values)!).map { (macdValue) -> Double in
                macdValue.MACD_Signal.value!
            }
            
            let a = Array(dataMACD.suffix(fetchInt))
            let b = Array(dataHIST.suffix(fetchInt))
            let c = Array(dataSIGNAL.suffix(fetchInt))
            
            let seriesMACD = ChartSeries(a)
            let seriesHIST = ChartSeries(b)
            let seriesSIGNAL = ChartSeries(c)
            
            seriesMACD.area = false
            seriesMACD.colors = (
                above: ChartColors.greenColor(),
                below: ChartColors.yellowColor(),
                zeroLevel: 0
            )
            
            seriesHIST.area = true
            seriesHIST.colors = (
                above: ChartColors.redColor(),
                below: ChartColors.blueColor(),
                zeroLevel: 0
            )
            
            seriesSIGNAL.area = false
            seriesSIGNAL.colors = (
                above: ChartColors.cyanColor() ,
                below: ChartColors.maroonColor(),
                zeroLevel: 0
            )
            
            chart.add([seriesMACD, seriesHIST, seriesSIGNAL])
        }
        
        self.view.addSubview(chart)
        
        NSLayoutConstraint.activate([
            chart.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
            chart.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 15),
            chart.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 15),
            chart.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -15),
            //chart.heightAnchor.constraint(equalToConstant: 225)
            chart.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor)
        ])
        
    }

}

extension StockDataView: ChartDelegate {
    func didTouchChart(_ chart: Chart, indexes: [Int?], x: Double, left: CGFloat) {
        return
    }
    
    func didFinishTouchingChart(_ chart: Chart) {
        return
    }
    
    func didEndTouchingChart(_ chart: Chart) {
        return
    }

}
