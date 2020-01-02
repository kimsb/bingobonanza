//
//  InterfaceController.swift
//  bingobonanza WatchKit Extension
//
//  Created by Kim Stephen Bovim on 28/12/2019.
//  Copyright © 2019 Kim Stephen Bovim. All rights reserved.
//

import WatchKit
import Foundation


class InterfaceController: WKInterfaceController {
    @IBOutlet weak var table: WKInterfaceTable!
    var answers = [String]()
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    
    
    @IBAction func tapped(_ sender: Any) {
        
        if (answers.count == 0) {
            answers = ["SENTRAL", "STERNAL", "ENTILES", "DENNEDA"]
            print("Har blitt tapped, prøver å fylle lista!")
        } else {
            answers = []
            print("Har blitt tapped, prøver å tømme lista!")
        }
        table.setNumberOfRows(answers.count, withRowType: "TableRow")
        
        for index in 0..<table.numberOfRows {
          guard let controller = table.rowController(at: index) as? TableRow else { continue }

          controller.answer = answers[index]
        }
    }
}
