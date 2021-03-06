//
//  ORTUSTableViewController.swift
//  ORTUS
//
//  Created by Firdavs Khaydarov on 6/17/20.
//  Copyright © 2020 Firdavs. All rights reserved.
//

import UIKit
import Carbon
import Promises

class ORTUSTableViewController: Module, ORTUSTableViewAdapterDelegate {
    weak var baseView: ORTUSTableView! { return view as? ORTUSTableView }
    weak var tableView: UITableView! { return baseView.tableView }
    
    var refreshControl: UIRefreshControl!
    
    lazy var renderer = Renderer(
        adapter: ORTUSTableViewAdapter(delegate: self),
        updater: UITableViewUpdater()
    )
    
    override func loadView() {
        view = ORTUSTableView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        prepareRefreshControl()
        prepareData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let selectedIndexPath = tableView.indexPathForSelectedRow,
            let coordinator = transitionCoordinator else {
            return
        }
        
        coordinator.animate(alongsideTransition: { context in
            self.tableView.deselectRow(at: selectedIndexPath, animated: true)
        }) { context in
            if context.isCancelled {
                self.tableView.selectRow(at: selectedIndexPath, animated: false, scrollPosition: .none)
            } else {
                self.tableView.deselectRow(at: selectedIndexPath, animated: true)
            }
        }
    }
    
    @objc func refresh() {
        
    }
    
    func prepareRefreshControl() {
        refreshControl = UIRefreshControl()
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
    }
    
    func prepareData() {
        renderer.target = tableView
    }
    
    func deselectSelectedRow() {
        guard let selectedIndexPath = tableView.indexPathForSelectedRow else {
            return
        }
        
        tableView.deselectRow(at: selectedIndexPath, animated: true)
    }
    
    // MARK: - ORTUSTableViewAdapterDelegate
    
    @available(iOS 13.0, *)
    func contextMenuConfiguration(forRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return nil
    }
    
    @available(iOS 13.0, *)
    func willPerformPreviewActionForMenu(configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        
    }
    
    func separatorInset(forRowAt indexPath: IndexPath) -> UIEdgeInsets? {
        nil
    }
}
