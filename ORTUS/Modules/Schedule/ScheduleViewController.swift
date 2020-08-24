//
//  ScheduleViewController.swift
//  ORTUS
//
//  Created by Firdavs Khaydarov on 25/03/19.
//  Copyright (c) 2019 Firdavs. All rights reserved.
//

import UIKit
import Carbon
import SafariServices
import Models
import Promises

class ScheduleViewController: Module, ModuleViewModel {
    var viewModel: ScheduleViewModel
    
    weak var scheduleView: ScheduleView! { return view as? ScheduleView }
    weak var tableView: UITableView! { return scheduleView.tableView }
    
    var refreshControl: UIRefreshControl!
    
    let toolbarSegmentedControl = UISegmentedControl(items: [])
    
    var selectedScheduleGrouping: Int = 0
    
    lazy var toolbar: UIToolbar = {
        let bar = UIToolbar()
        bar.delegate = self

        let barItem = UIBarButtonItem(customView: self.toolbarSegmentedControl)

        bar.setItems([barItem], animated: false)

        return bar
    }()
    
    lazy var adapter = ScheduleTableViewAdapter(dataSource: self, delegate: self)
    
    lazy var renderer = Renderer(
        adapter: self.adapter,
        updater: UITableViewUpdater()
    )
    
    let dateFormatter: DateFormatter = {
        let dateFormatter = LatviaDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        return dateFormatter
    }()
    
    init(viewModel: ScheduleViewModel) {
        self.viewModel = viewModel
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = ScheduleView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        prepareNavigationItem()
        prepareToolbar()
        prepareRefreshControl()
        prepareData()
        
        loadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.hideBorderLine()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.showBorderLine()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == UserDefaults.Key.showEvents.name {
            loadData()
        }
    }
    
    func loadData(forceUpdate: Bool = false) {
        if forceUpdate {
            viewModel.loadSchedule().always {
                self.render()
            }
            
            return
        }
        
        viewModel.loadCachedSchedule().then { _ -> Promise<Bool> in
            self.render()
            
            return self.viewModel.loadSchedule()
        }.then { _ in
            self.render()
        }
    }
    
    func render() {
        self.refreshControl.endRefreshing()
        
        var data: [Section] = []
        let today = Date()
        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) else {
            return
        }

        for (key, schedule) in viewModel.schedule {
            if selectedScheduleGrouping != 2 {
                guard key == dateFormatter.string(from: selectedScheduleGrouping == 0 ? today : tomorrow) else {
                    continue
                }
            }

            data.append(
                Section(
                    id: key,
                    header: selectedScheduleGrouping == 2 ? ViewNode(ScheduleDateHeader(title: key)) : nil,
                    cells: schedule.compactMap {
                        if let event = $0.item(as: Event.self) {
                            return CellNode(EventComponent(id: event.title, event: event))
                        }

                        if let lecture = $0.item(as: Lecture.self) {
                            return CellNode(LectureComponent(id: lecture.id, lecture: lecture))
                        }

                        return nil
                    }
                )
            )

            if selectedScheduleGrouping != 2 {
                break
            }
        }
        
        if data.isEmpty {
            data.append(
                Section(id: "empty", header: ViewNode(
                    StateComponent(
                        image: Asset.Images.calendarFlatline.image,
                        primaryText: "No upcoming lessons",
                        secondaryText: "Check the schedule for a week or pull to refresh.",
                        height: view.safeAreaLayoutGuide.layoutFrame.height - 44 - 25
                    )
                ))
            )
        }

        renderer.render {
            Group(of: data) { section in
                section
            }
        }
    }
    
    @objc func selectScheduleGrouping() {
        selectedScheduleGrouping = toolbarSegmentedControl.selectedSegmentIndex
        
        render()
    }
    
    @objc func refresh() {
        loadData(forceUpdate: true)
    }
    
    func open(event: Event) {
        EventLogger.log(.openedEvent)
        
        OAuth.refreshToken().then { accessTokenEncrypted in
            guard let url = event.link.generatePinAuthURL(withToken: accessTokenEncrypted) else {
                return
            }
            
            let controller = SFSafariViewController(url: url)
            controller.delegate = self
            
            self.present(controller, animated: true, completion: nil)
        }
    }
}

extension ScheduleViewController {
    func prepareNavigationItem() {
        navigationItem.largeTitleDisplayMode = .never
        
//        let leftButton = UIButton()
//        leftButton.setImage(UIImage(named: "chevronLeft"), for: .normal)
//        leftButton.imageView?.contentMode = .scaleAspectFit
//        leftButton.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
//        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: leftButton)
//        
//        let rightButton = UIButton()
//        rightButton.setImage(UIImage(named: "chevronRight"), for: .normal)
//        rightButton.imageView?.contentMode = .scaleAspectFit
//        rightButton.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
//        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: rightButton)
    }
    
    func prepareToolbar() {
        view.addSubview(toolbar)
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.left.right.equalToSuperview()
        }
        
        toolbarSegmentedControl.addTarget(self, action: #selector(selectScheduleGrouping), for: .valueChanged)
        
        for (index, grouping) in ScheduleGrouping.allCases.enumerated() {
            toolbarSegmentedControl.insertSegment(
                withTitle: grouping.rawValue.capitalized,
                at: index,
                animated: false)
        }
        toolbarSegmentedControl.selectedSegmentIndex = selectedScheduleGrouping
    }
    
    func prepareRefreshControl() {
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    func prepareData() {
        renderer.target = tableView
        
        viewModel.sharedUserDefaults?.addObserver(
            self,
            forKeyPath: UserDefaults.Key.showEvents.name,
            options: .new,
            context: nil
        )
        
        title = L10n.Schedule.title
    }
}

extension ScheduleViewController: ScheduleTableViewAdapterDataSource, ScheduleTableViewAdapterDelegate {
    func item(for indexPath: IndexPath) -> ScheduleItem? {
        let cell = renderer.data[indexPath.section].cells[indexPath.row]
        
        if let event = cell.component(as: EventComponent.self)?.event {
            return ScheduleItem(event, time: event.time)
        }
        
        if let lecture = cell.component(as: LectureComponent.self)?.lecture {
            return ScheduleItem(lecture, time: lecture.timeFrom)
        }
        
        return nil
    }
    
    func openLink(_ url: URL) {
        viewModel.router.openBrowser(url.absoluteString)
    }
}

extension ScheduleViewController: UIToolbarDelegate {
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .top
    }
}

extension ScheduleViewController: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}

