//
//  StockDataView.swift
//  StockSifter
//
//  Created by Cory Kornowicz on 8/17/18.
//  Copyright © 2018 Cory Kornowicz. All rights reserved.
//

//TODO: Think about moving to Charts not SwiftCharts

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
        temp.yLabelsFormatter = { String(Double($1))}
        temp.bottomInset = 40
        temp.topInset = 40
        temp.hideHighlightLineOnTouchEnd = true
        return temp
    }()
    
    var seriesMacdLabel: UILabel = {
        let temp = UILabel.init(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 50, height: 20)))
        temp.translatesAutoresizingMaskIntoConstraints = false
        temp.font = .systemFont(ofSize: 11)
        return temp
    }()
    
    var seriesHistLabel: UILabel = {
        let temp = UILabel.init(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 50, height: 20)))
        temp.translatesAutoresizingMaskIntoConstraints = false
        temp.font = .systemFont(ofSize: 11)

        return temp
    }()
    
    var seriesSignalLabel: UILabel = {
        let temp = UILabel.init(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 50, height: 20)))
        temp.translatesAutoresizingMaskIntoConstraints = false
        temp.font = .systemFont(ofSize: 11)
        return temp
    }()
    
    var labelStackView: UIStackView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        setupView()
    }

    var fetchInt: Int = 12
    
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
            
            //TODO: add in correct color representation
            
            let seriesMACD = ChartSeries(a)
            let seriesHIST = ChartSeries(b)
            let seriesSIGNAL = ChartSeries(c)
            
            seriesMACD.area = false
            seriesMACD.colors = (
                above: ChartColors.greenColor(),
                below: ChartColors.redColor(),
                zeroLevel: 0
            )
            
            seriesHIST.area = true
            seriesHIST.colors = (
                above: ChartColors.greenColor(),
                below: ChartColors.redColor(),
                zeroLevel: 0
            )
            
            seriesSIGNAL.area = false
            seriesSIGNAL.colors = (
                above: ChartColors.greenColor(),
                below: ChartColors.redColor(),
                zeroLevel: 0
            )
            
            chart.add([seriesMACD, seriesHIST, seriesSIGNAL])
        }
        
        self.labelStackView = UIStackView(arrangedSubviews: [seriesMacdLabel, seriesHistLabel, seriesSignalLabel])
        self.labelStackView?.translatesAutoresizingMaskIntoConstraints = false
        self.labelStackView?.distribution = .equalSpacing
        labelStackView?.isHidden = true
        
        self.view.addSubview(chart)
        self.view.addSubview(labelStackView!)
        
        chart.delegate = self
        
        NSLayoutConstraint.activate([
            chart.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
            chart.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 40),
            chart.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 15),
            chart.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -15),
            chart.heightAnchor.constraint(equalToConstant: 300),
            (labelStackView?.widthAnchor.constraint(equalTo: safeArea.widthAnchor, constant: -20))!,
            (labelStackView?.heightAnchor.constraint(equalToConstant: 20))!,
            (labelStackView?.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor, constant: 0))!,
            (labelStackView?.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 10))!
        ])
        
    }

}

extension StockDataView: ChartDelegate {
    func didTouchChart(_ chart: Chart, indexes: [Int?], x: Double, left: CGFloat) {
        //chart.add([seriesMACD, seriesHIST, seriesSIGNAL])
        for (seriesIndex, dataIndex) in indexes.enumerated() {
        
            switch seriesIndex {
            case 0:
                if dataIndex != nil {
                    let value = chart.valueForSeries(seriesIndex, atIndex: dataIndex)
                    //print("MACD value: \(String(describing: value))")
                    seriesMacdLabel.text = "MACD value: \(value!)"
                }
                break;
            case 1:
                if dataIndex != nil {
                    let value = chart.valueForSeries(seriesIndex, atIndex: dataIndex)
                    //print("Hist value: \(String(describing: value))")
                    seriesHistLabel.text = "Hist value: \(value!)"
                }
                break;
            case 2:
                if dataIndex != nil {
                    let value = chart.valueForSeries(seriesIndex, atIndex: dataIndex)
                    //print("Signal value: \(String(describing: value))")
                    seriesSignalLabel.text = "Signal value: \(value!)"
                }
                break
            default:
                break;
            }
            
        }
        
        self.labelStackView?.isHidden = false

        
    }
    
    func didFinishTouchingChart(_ chart: Chart) {
        return
    }
    
    func didEndTouchingChart(_ chart: Chart) {
        self.labelStackView?.isHidden = true
        return
    }

}
