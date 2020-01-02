//
//  TableRow.swift
//  bingobonanza WatchKit Extension
//
//  Created by Kim Stephen Bovim on 30/12/2019.
//  Copyright © 2019 Kim Stephen Bovim. All rights reserved.
//

import WatchKit

class TableRow: NSObject {

    @IBOutlet weak var tableRowLabel: WKInterfaceLabel!
    
    var answer: String? {
      didSet {
        guard let answer = answer else { return }
        tableRowLabel.setText(answer)
      }
    }
}
