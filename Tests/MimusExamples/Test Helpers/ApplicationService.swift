//
//  ApplicationService.swift
//  MimusExamples
//
//  Created by Pawel Dudek on 27/11/2017.
//  Copyright © 2017 AirHelp. All rights reserved.
//

import Foundation
import Mimus

protocol ApplicationService {
    
}

protocol ApplicationServiceRegistrator {
    func register(service: ApplicationService)
}

class FakeApplicationServiceRegistrator: ApplicationServiceRegistrator, Mock {

    var storage: [RecordedCall] = []
    
    func register(service: ApplicationService) {
        recordCall(withIdentifier: "register", arguments: [service])
    }
}

class FakeApplicationService: ApplicationService { }
