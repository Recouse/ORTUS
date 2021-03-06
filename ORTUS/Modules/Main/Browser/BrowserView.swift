//
//  BrowserView.swift
//  ORTUS
//
//  Created by Firdavs Khaydarov on 24/12/19.
//  Copyright (c) 2019 Firdavs. All rights reserved.
//

import UIKit
import WebKit

class BrowserView: UIView {
    let loadingOverview: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.isHidden = true
        
        return view
    }()
    
    let activityIndicator = UIActivityIndicatorView(style: .large)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .systemBackground
        
        addSubview(loadingOverview)
        loadingOverview.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        loadingOverview.addSubview(activityIndicator)
        activityIndicator.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        activityIndicator.startAnimating()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
