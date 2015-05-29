//
//  samples.swift
//  Incidents
//
//  © 2015 Burning Man and its contributors. All rights reserved.
//  See the file COPYRIGHT.md for terms.
//



let address1 = RodGarettAddress(
    concentric      : ConcentricStreet.C,
    radialHour      : 8,
    radialMinute    : 45,
    textDescription : "Red and yellow flags, dome"
)

let location1 = Location(name: "Equilibrium", address: address1)

let date1String = "1971-04-20T16:20:04Z"
let date2String = "1972-06-29T08:04:15Z"
let date3String = "1972-06-30T18:40:51Z"
let date4String = "1972-06-30T18:40:52Z"

let date1 = DateTime.fromRFC3339String(date1String)
let date2 = DateTime.fromRFC3339String(date2String)
let date3 = DateTime.fromRFC3339String(date3String)
let date4 = DateTime.fromRFC3339String(date4String)

let ranger1 = Ranger(
    handle: "Tool",
    name: "Wilfredo Sánchez Vega",
    status: "vintage"
)

let ranger2 = Ranger(
    handle: "Splinter",
    name: "Mark Harder",
    status: "vintage"
)
