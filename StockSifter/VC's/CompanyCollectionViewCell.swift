//
//  CompanyCollectionViewCell.swift
//  StockSifter
//
//  Created by Cory Kornowicz on 3/21/19.
//  Copyright © 2019 Cory Kornowicz. All rights reserved.
//

import UIKit
import SwiftChart

class CompanyCollectionViewCell: UICollectionViewCell {
    
    var company : Company?
    
    var publicCompanyGetter:Company {
        set {
            if company == nil {
                company = newValue;
            }
        }
        get {
            return company!;
        }
    }
    
    var chart: Chart = {
        let temp = Chart(frame: CGRect.zero)
        temp.translatesAutoresizingMaskIntoConstraints = false
        temp.backgroundColor = .white
        temp.layer.cornerRadius = 15
        temp.yLabels = []
        //temp.yLabels = [-1.0, -0.75, -0.5, -0.25, 0, 0.25, 0.5, 0.75, 1.0]
        //temp.yLabelsFormatter = { String(Double($1))}
        temp.xLabels = []
        temp.bottomInset = 0
        temp.topInset = 0
        temp.hideHighlightLineOnTouchEnd = true
        return temp
    }()
    
    var companyNameLabel: UILabel = {
        let temp = UILabel(frame: .zero)
        temp.translatesAutoresizingMaskIntoConstraints = false
        temp.font = UIFont.systemFont(ofSize: 15)
        temp.text = "Name"
        return temp
    }()
    
    var companySymbolLabel: UILabel = {
        let temp = UILabel(frame: .zero)
        temp.translatesAutoresizingMaskIntoConstraints = false
        temp.font = UIFont.systemFont(ofSize: 12)
        temp.text = "Symbol"
        return temp
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .white
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.contentView.addSubview(companyNameLabel)
        self.contentView.addSubview(companySymbolLabel)
        setupContraints()
    }
    
    var fetchInt = 12;
    
    func setupContraints() {
        
        let safeArea = self.contentView.safeAreaLayoutGuide
        
        if (company != nil && company?.macd != nil){
        
            let dataHIST = Array((company?.macd?.values)!).map { (macdValue) -> Double in
                macdValue.MACD_Hist.value!
            }
            
            let b = Array(dataHIST.suffix(fetchInt))
            
            let seriesHIST = ChartSeries(b)
            
            seriesHIST.area = true
            seriesHIST.colors = (
                above: ChartColors.greenColor(),
                below: ChartColors.redColor(),
                zeroLevel: 0
            )
            
            chart.add(seriesHIST)
        }
        
        self.contentView.addSubview(chart)
        
        if company == nil {
            chart.isHidden = true
        }else {
            chart.isHidden = false
        }
        
        NSLayoutConstraint.activate([
            //width, height, top, leading
            chart.widthAnchor.constraint(equalTo: safeArea.widthAnchor, multiplier: 0.45),
//            chart.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 5),
            chart.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -10),
            chart.heightAnchor.constraint(equalTo: safeArea.heightAnchor, multiplier: 0.89),
            chart.centerYAnchor.constraint(equalTo: safeArea.centerYAnchor, constant: 0),
            companyNameLabel.widthAnchor.constraint(equalTo: safeArea.widthAnchor, multiplier: 0.45),
            companyNameLabel.heightAnchor.constraint(equalToConstant: 20),
            companyNameLabel.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 10),
            companyNameLabel.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 10),
            companySymbolLabel.widthAnchor.constraint(equalTo: safeArea.widthAnchor, multiplier: 0.45),
            companySymbolLabel.heightAnchor.constraint(equalToConstant: 15),
            companySymbolLabel.topAnchor.constraint(equalTo: companyNameLabel.bottomAnchor, constant: 5),
            companySymbolLabel.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 10)
        ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
