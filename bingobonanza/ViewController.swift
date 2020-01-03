//
//  ViewController.swift
//  bingobonanza
//
//  Created by Kim Stephen Bovim on 28/12/2019.
//  Copyright © 2019 Kim Stephen Bovim. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource {
    
    @IBOutlet weak var listSegment: UISegmentedControl!
    @IBOutlet var tapRecognizer: UITapGestureRecognizer!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var anagramLabel: UILabel!
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
    
    private let listKeys = ["7", "8", "C", "W"]
    func showNextQuestion() {
        showingAnswers = false
        
        print("henter første question")
        
        question = SessionHandler.shared.getNextQuestion(listKey: listKeys[listSegment.selectedSegmentIndex], lastAnswered: question)
        anagramLabel.text = question?.anagram
        tableView.reloadData()
        
        print("showing next question: \(question!.anagram)")
    }
    
    @IBAction func tapped(_ sender: Any) {
        
        if (showingAnswers) {
            let location = tapRecognizer.location(in: self.view)
            
            if (location.x < 100) {
                print("Wrong answer")
                question!.setTimeToShow(answeredCorrect: false)
            } else {
                print("Correct!")
                question!.setTimeToShow(answeredCorrect: true)
            }
            showNextQuestion()
        } else {
            showingAnswers = true
            tableView.reloadData()
        }
        
    }
    
    @IBAction func listSegmentChanged(_ sender: Any) {
        showNextQuestion()
    }
    
}

