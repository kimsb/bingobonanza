//
//  Question.swift
//  bingobonanza
//
//  Created by Kim Stephen Bovim on 02/01/2020.
//  Copyright © 2020 Kim Stephen Bovim. All rights reserved.
//

import Foundation

class Question: NSObject, Codable, NSCoding {
    var anagram: String
    var answers: [String]
    var timeToShow: Date
    var daysToAdd: Int
    var wrongGuessCount: Int
    var firstShown: Date
    
    init(anagram: String, answers: [String],
         timeToShow: Date = Date.distantFuture, daysToAdd: Int = 3, wrongGuessCount: Int = 0, firstShown: Date = Date.distantPast) {
        self.anagram = anagram
        self.answers = answers
        self.timeToShow = timeToShow
        self.daysToAdd = daysToAdd
        self.wrongGuessCount = wrongGuessCount
        self.firstShown = firstShown
    }
    
    func setTimeToShow(answeredCorrect: Bool) -> Int {
        if (answeredCorrect) {
            let daysAdded = daysToAdd
            
            let dayToShow = Calendar.current.date(byAdding: .day, value: daysToAdd, to: Date())!
            let cal = Calendar(identifier: .gregorian)
            timeToShow = cal.startOfDay (for: dayToShow)
            
            switch wrongGuessCount {
            case 0: daysToAdd = daysToAdd * 4
            case 1: daysToAdd = daysToAdd * 3
            case 2: daysToAdd = (daysToAdd * 25) / 10
            default: daysToAdd = daysToAdd * 2
            }
            
            print("days to add: \(daysToAdd)")
            
            return daysAdded
            
        } else {
            //straffer ikke feil svar første gang et anagram blir vist
            if (timeToShow != Date.distantFuture) {
                wrongGuessCount = wrongGuessCount + 1
            }
            timeToShow = Calendar.current.date(byAdding: .minute, value: 5, to: Date())!
            daysToAdd = 1
            return 0
        }
    }
    
    //NSCoding
    struct PropertyKey {
        static let anagram = "anagram"
        static let answers = "answers"
        static let timeToShow = "timeToShow"
        static let daysToAdd = "daysToAdd"
        static let wrongGuessCount = "wrongGuessCount"
        static let firstShown = "firstShown"
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(anagram, forKey: PropertyKey.anagram)
        aCoder.encode(answers, forKey: PropertyKey.answers)
        aCoder.encode(timeToShow, forKey: PropertyKey.timeToShow)
        aCoder.encode(daysToAdd, forKey: PropertyKey.daysToAdd)
        aCoder.encode(wrongGuessCount, forKey: PropertyKey.wrongGuessCount)
        aCoder.encode(firstShown, forKey: PropertyKey.firstShown)
    }

    required convenience init?(coder aDecoder: NSCoder) {
        let anagram = aDecoder.decodeObject(forKey: PropertyKey.anagram) as! String
        let answers = aDecoder.decodeObject(forKey: PropertyKey.answers) as! [String]
        let timeToShow = aDecoder.decodeObject(forKey: PropertyKey.timeToShow) as! Date
        let daysToAdd = aDecoder.decodeInteger(forKey: PropertyKey.daysToAdd)
        let wrongGuessCount = aDecoder.decodeInteger(forKey: PropertyKey.wrongGuessCount)
        let firstShown = aDecoder.decodeObject(forKey: PropertyKey.firstShown) as? Date
                
        self.init(anagram: anagram, answers: answers, timeToShow: timeToShow, daysToAdd: daysToAdd, wrongGuessCount: wrongGuessCount, firstShown: firstShown != nil ? firstShown! : Date.distantPast)
    }
}
