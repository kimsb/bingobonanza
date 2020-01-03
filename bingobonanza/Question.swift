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
    var isMature: Bool
    
    init(anagram: String, answers: [String],
         timeToShow: Date = Date.distantFuture, daysToAdd: Int = 3, isMature: Bool = false) {
        self.anagram = anagram
        self.answers = answers
        self.timeToShow = timeToShow
        self.daysToAdd = isMature ? daysToAdd*2 : daysToAdd
        self.isMature = isMature
    }
    
    func setTimeToShow(answeredCorrect: Bool) {
        if (answeredCorrect) {
            timeToShow = Calendar.current.date(byAdding: .day, value: daysToAdd, to: Date())!
            daysToAdd = isMature ? (daysToAdd * 2) : (daysToAdd * 3)
        } else {
            timeToShow = Calendar.current.date(byAdding: .minute, value: 5, to: Date())!
            daysToAdd = 1
        }
    }
    
    //NSCoding
    struct PropertyKey {
        static let anagram = "anagram"
        static let answers = "answers"
        static let timeToShow = "timeToShow"
        static let daysToAdd = "daysToAdd"
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(anagram, forKey: PropertyKey.anagram)
        aCoder.encode(answers, forKey: PropertyKey.answers)
        aCoder.encode(timeToShow, forKey: PropertyKey.timeToShow)
        aCoder.encode(daysToAdd, forKey: PropertyKey.daysToAdd)
    }

    required convenience init?(coder aDecoder: NSCoder) {
        let anagram = aDecoder.decodeObject(forKey: PropertyKey.anagram) as! String
        let answers = aDecoder.decodeObject(forKey: PropertyKey.answers) as! [String]
        let timeToShow = aDecoder.decodeObject(forKey: PropertyKey.timeToShow) as! Date
        let daysToAdd = aDecoder.decodeInteger(forKey: PropertyKey.daysToAdd)
        
        self.init(anagram: anagram, answers: answers, timeToShow: timeToShow, daysToAdd: daysToAdd)
    }
}
