//
//  ConcentricStreetFieldDelegate.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//

import Cocoa



class ConcentricStreetFieldDelegate: CompletingControlDelegate {
    
    override var completionValues: [String] {
        return [
            ConcentricStreet.Esplanade.description,
            ConcentricStreet.A.description,
            ConcentricStreet.B.description,
            ConcentricStreet.C.description,
            ConcentricStreet.D.description,
            ConcentricStreet.E.description,
            ConcentricStreet.F.description,
            ConcentricStreet.G.description,
            ConcentricStreet.H.description,
            ConcentricStreet.I.description,
            ConcentricStreet.J.description,
            ConcentricStreet.K.description,
            ConcentricStreet.L.description
            //ConcentricStreet.M.description
            //ConcentricStreet.N.description
        ]
    }
    
}