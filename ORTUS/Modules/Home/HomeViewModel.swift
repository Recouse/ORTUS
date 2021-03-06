//
//  HomeViewModel.swift
//  ORTUS
//
//  Created by Firdavs Khaydarov on 04/02/20.
//  Copyright (c) 2020 Firdavs. All rights reserved.
//

import Promises

class HomeViewModel: ViewModel {
    let router: HomeRouter.Routes
    
    var semesters: Semesters = []
        
    init(router: HomeRouter.Routes) {
        self.router = router
    }
    
    @discardableResult
    func loadCourses() -> Promise<Bool> {
        return Promise { fulfill, reject in
            APIClient.performRequest(
                CoursesResponse.self,
                route: CoursesApi.courses
            ).then { response in
                self.semesters = response.result
                
                Cache.shared.save(response, forKey: .courses)
                
                fulfill(true)
            }.catch { reject($0) }
        }
    }
    
    func loadCachedCourses() -> Promise<Bool> {
        return Promise { fulfill, reject in
            do {
                let response = try Cache.shared.fetch(
                    CoursesResponse.self,
                    forKey: .courses
                )
                
                self.semesters = response.result
                
                fulfill(true)
            } catch StorageError.notFound {
                fulfill(true)
            } catch {
                reject(error)
            }
        }
    }
}
