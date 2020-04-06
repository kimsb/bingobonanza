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
    
    func showNextQuestion(answered: Bool = false) {
        showingAnswers = false
                        
        question = SessionHandler.shared.getNextQuestion(lastAnswered: answered ? question : nil)
        let due = SessionHandler.shared.getDue()
        infoLabel.text = "\(due > 0 ? "Due: \(due) " : "") (\(String(format: "%.2f", SessionHandler.shared.getPercentage()))%)"
                
        anagramLabel.text = question?.anagram
        tableView.reloadData()
    }
    
    @IBAction func tapped(_ sender: Any) {
        
        if (showingAnswers) {
            let location = tapRecognizer.location(in: self.view)
            
            daysAddedAnimation(text: "\(question!.setTimeToShow(answeredCorrect: location.x > 100))")
            
            showNextQuestion(answered: true)
        } else {
            showingAnswers = true
            tableView.reloadData()
        }
        
    }
    
    func daysAddedAnimation(text: String) {
        let answeredCorrect = text != "0"
        daysAddedLabel.text = answeredCorrect ? "+\(text)" : "X"
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
    
}

