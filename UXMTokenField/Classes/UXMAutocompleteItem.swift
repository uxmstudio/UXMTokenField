//
//  UXMAutocompleteItem.swift
//  UXMTokenField
//
//  Created by Chris Anderson on 4/16/16.
//  Copyright © 2016 UXM Studio. All rights reserved.
//

import UIKit

public class UXMAutocompleteItem {

    var title:String = ""
    var subtitle:String = ""
    
    convenience init(title: String, subtitle: String) {
        self.init()
        
        self.title = title
        self.subtitle = subtitle
    }
}
