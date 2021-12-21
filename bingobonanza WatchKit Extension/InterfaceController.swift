//
//  InterfaceController.swift
//  bingobonanza WatchKit Extension
//
//  Created by Kim Stephen Bovim on 28/12/2019.
//  Copyright © 2019 Kim Stephen Bovim. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity

class InterfaceController: WKInterfaceController {
    
    @IBOutlet weak var tableTapRecognizer: WKTapGestureRecognizer!
    @IBOutlet weak var infoLabel: WKInterfaceLabel!
    @IBOutlet weak var anagramLabel: WKInterfaceLabel!
    @IBOutlet weak var table: WKInterfaceTable!
    
    private var session = WCSession.default
    var anagram: String?
    var answers = [String]()
    var showingAnswers = false
    var listKeys = ["7", "8", "C", "W"]
    var currentList = 0
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        anagramLabel.setText("")
        getNextQuestion()
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        session.delegate = self
        session.activate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func getNextQuestion(answeredLastQuestionCorrect: Bool? = nil, lastAnagram: String? = nil) {
        var requestDictionary: [String:Any] = ["nextQuestion" : listKeys[currentList]]
        if (answeredLastQuestionCorrect != nil && lastAnagram != nil) {
            requestDictionary["lastAnagram"] = lastAnagram!
            requestDictionary["correct"] = answeredLastQuestionCorrect!
        }
        
        if session.isReachable {
            
            session.sendMessage(requestDictionary, replyHandler: {(response) in
                
                self.anagram = (response["anagram"]! as! String)
                
                let hasDue = response["due"]! as! Int > 0
                let due = hasDue ? " - Due: \(response["due"]! as! Int)" : ""
                self.infoLabel.setText("\(self.listKeys[self.currentList])\(due)")

                self.anagramLabel.setText("\(self.anagram!)")
                
                self.answers = response["answers"] as! [String]
                
            }, errorHandler: {(error) in
                self.anagramLabel.setText("ERROR")
                print("Error sending message: %@", error)
            })
        } else {
            self.anagramLabel.setText("connecting...")
            print("iPhone is not reachable!!")
        }
    }
    
    func show(answeredLastQuestionCorrect: Bool? = nil, lastAnagram: String? = nil) {
                
        //show next question
        if (showingAnswers) {
            anagramLabel.setText("")
            getNextQuestion(answeredLastQuestionCorrect: answeredLastQuestionCorrect,
                            lastAnagram: lastAnagram)

            table.setNumberOfRows(6, withRowType: "TableRow")
            for index in 0..<6 {
                guard let controller = table.rowController(at: index) as? TableRow else { continue }
                controller.answer = ""
            }
            table.scrollToRow(at: 0)
            
        //show answers
        } else {
            let numberOfRows = max(6, answers.count)
            
            table.setNumberOfRows(numberOfRows, withRowType: "TableRow")
            
            for index in 0..<numberOfRows {
                guard let controller = table.rowController(at: index) as? TableRow else { continue }
                controller.answer = (index >= answers.count) ? "" : answers[index]
            }
        }
        showingAnswers = !showingAnswers
    }
    
    @IBAction func infoTapped(_ sender: Any) {
        
        currentList = currentList < 3 ? (currentList + 1) : 0
        infoLabel.setText(listKeys[currentList])
        showingAnswers = true
        show()
    }
    
    @IBAction func anagramTapped(_ sender: Any) {
                
        show(answeredLastQuestionCorrect: true, lastAnagram: anagram)
    }
    
    @IBAction func tableTapped(_ sender: Any) {
                
        show(answeredLastQuestionCorrect: tableTapRecognizer.locationInObject().x > 50,
        lastAnagram: anagram)
    }
}

extension InterfaceController: WCSessionDelegate {
    // Required stub for delegating session
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("activationDidCompleteWith activationState:\(activationState) error:\(String(describing: error))")
    }
}
