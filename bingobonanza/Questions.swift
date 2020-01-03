//
//  Questions.swift
//  bingobonanza
//
//  Created by Kim Stephen Bovim on 03/01/2020.
//  Copyright © 2020 Kim Stephen Bovim. All rights reserved.
//

import Foundation

class Questions: NSObject, Codable, NSCoding {
    var newQuestions: [Question]
    var seenQuestions: [Question]
    
    init(newQuestions: [Question], seenQuestions: [Question] = []) {
        self.newQuestions = newQuestions
        self.seenQuestions = seenQuestions
    }
    
    func getDue() -> Int {
        var dueCount = 0
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        while (dueCount < seenQuestions.count && seenQuestions[dueCount].timeToShow < tomorrow) {
            dueCount = dueCount + 1
        }
        return dueCount
    }
    
    func getNextQuestion(lastQuestion: Question? = nil) -> Question {
        if let lastQuestion = lastQuestion {
            if (!newQuestions.isEmpty && newQuestions.first!.anagram == lastQuestion.anagram) {
                newQuestions.removeFirst()
            } else {
                seenQuestions.removeFirst()
            }
            seenQuestions.insert(lastQuestion, at: 0)
            seenQuestions = seenQuestions.sorted(by: { $0.timeToShow < $1.timeToShow } )
        }
        DispatchQueue.global(qos: .background).async {
            SessionHandler.shared.saveQuestions()
        }
        
        if (newQuestions.isEmpty || (!seenQuestions.isEmpty && seenQuestions.first!.timeToShow < Date())) {
            return seenQuestions.first!
        }
        return newQuestions.first!
    }
    
    //MARK: Archiving Paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("questions")
    
    //NSCoding
    struct PropertyKey {
        static let newQuestions = "newQuestions"
        static let seenQuestions = "seenQuestions"
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(newQuestions, forKey: PropertyKey.newQuestions)
        aCoder.encode(seenQuestions, forKey: PropertyKey.seenQuestions)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let newQuestions = aDecoder.decodeObject(forKey: PropertyKey.newQuestions) as! [Question]
        let seenQuestions = aDecoder.decodeObject(forKey: PropertyKey.seenQuestions) as! [Question]
        
        self.init(newQuestions: newQuestions, seenQuestions: seenQuestions)
    }
    
    
    
    
}
