//
//  ViewController.swift
//  bingobonanza
//
//  Created by Kim Stephen Bovim on 28/12/2019.
//  Copyright © 2019 Kim Stephen Bovim. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource {
    
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var listSegment: UISegmentedControl!
    @IBOutlet var tapRecognizer: UITapGestureRecognizer!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var anagramLabel: UILabel!
    @IBOutlet weak var daysAddedLabel: UILabel!
    var question: Question?
    var showingAnswers = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        tableView.dataSource = self

        showNextQuestion()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (!showingAnswers || question == nil) {
            return 0
        }
        return question!.answers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TableRowCell", for: indexPath) as? TableRowCell  else {
            fatalError("The dequeued cell is not an instance of TableRowCell.")
        }
        cell.answerLabel.text = question!.answers[indexPath.row]
        return cell
    }
    
    @objc func showNextQuestion(answered: Bool = false) {
        showingAnswers = false
                        
        question = SessionHandler.shared.getNextQuestion(lastAnswered: answered ? question : nil)
        
        let newTodayText = SessionHandler.shared.getNewTodayText()
        let due = SessionHandler.shared.getDue()
        infoLabel.text = "\(due > 0 ? "Due: \(due) " : "") (\(SessionHandler.shared.getPercentage())% : \(SessionHandler.shared.getSeenCount())) \(newTodayText)"
                
        anagramLabel.text = question?.anagram
        tableView.reloadData()
    }
    
    @IBAction func tapped(_ sender: Any) {
        
        if (showingAnswers) {
            let location = tapRecognizer.location(in: self.view)
            let answeredCorrect = location.x > 100
            
            let daysAdded = question!.setTimeToShow(answeredCorrect: answeredCorrect)
            
            if (answeredCorrect) {
                daysAddedAnimation(answeredCorrect: true, text: "\(daysAdded)")
            } else {
                daysAddedAnimation(answeredCorrect: false, text: "x \(question!.wrongGuessCount)")
            }
                        
            showNextQuestion(answered: true)
        } else {
            if (question != nil && question!.timeToShow == Date.distantFuture) {
                question?.firstShown = Date()
            }
            showingAnswers = true
            tableView.reloadData()
        }
        
    }
    
    func daysAddedAnimation(answeredCorrect: Bool, text: String) {
        daysAddedLabel.text = answeredCorrect ? "+\(text)" : "\(text)"
        daysAddedLabel.textColor = answeredCorrect ? UIColor.green : UIColor.red

        daysAddedLabel.fadeOutAnimation(completion: {
        (finished: Bool) -> Void in
            self.daysAddedLabel.text = ""
            self.daysAddedLabel.alpha = 1
            self.daysAddedLabel.transform = CGAffineTransform(scaleX: 1, y: 1)
        })
    }
    
    @IBAction func listSegmentChanged(_ sender: Any) {
        SessionHandler.shared.setCurrentKey(keyIndex: listSegment.selectedSegmentIndex)
        showNextQuestion()
    }
 
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector:#selector(showNextQuestion), name:UIApplication.didBecomeActiveNotification, object:UIApplication.shared
        )
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
    
}

