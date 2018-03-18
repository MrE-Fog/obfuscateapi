//
//  main.swift
//  obfuscateapi
//
//  Created by Pablo Roca Rozas on 18/3/18.
//  Copyright © 2018 PR2Studio. All rights reserved.
//

import Foundation

func usage() {
    print("Usage: obfuscateapi -key <XXX> -iv <XXX> -infile <file> \n");
}

// MARK: - Argument management

if CommandLine.arguments.count < 3 {
    usage()
    exit(1)
}

var arrArguments = CommandLine.arguments
arrArguments.removeFirst()

var argsDict: [String:String] = [:]

// create Dictionary from arguments
for (index, element) in arrArguments.enumerated() {
    if remainder(Double(index), 2) == 1 {
        var key = arrArguments[index-1]
        key.remove(at: element.startIndex)
        argsDict[key] = element
    }
}

var infile = "apiplain.plist"
guard let infileFromArgs = argsDict["infile"] else {
    print("Missing infile or default '\(infile)' does not exist");
    usage()
    exit(1)
}
infile = infileFromArgs

guard let aesKey = argsDict["key"] else {
    usage()
    exit(1)
}

var hexiv = "00000000000000000000000000000000"
if let ivFromArgs = argsDict["iv"] {
    hexiv = ivFromArgs
}

// MARK: - Create outfile

var outfile = "APIConstants.swift"
if let outfileFromArgs = argsDict["outfile"] {
    outfile = outfileFromArgs
}

guard var inputDict = NSDictionary(contentsOfFile: infile) else {
    exit(1)
}

FileManager.default.createFile(atPath: outfile, contents: nil, attributes: nil)

do {
    let fileHandler = try FileHandle(forWritingTo: URL(string: outfile)!)
    fileHandler.seekToEndOfFile()
    let header = String(format: "//\n// %@\n//\n\n", outfile)
    fileHandler.write(header.data(using: .utf8)!)

    fileHandler.seekToEndOfFile()
    fileHandler.write("import Foundation\n\n".data(using: .utf8)!)

    fileHandler.seekToEndOfFile()
    fileHandler.write("/// End Points\n".data(using: .utf8)!)

    fileHandler.seekToEndOfFile()
    fileHandler.write("struct APIConstants {\n\n".data(using: .utf8)!)

    for endPointComment in inputDict {
        fileHandler.seekToEndOfFile()
        let stringEndPointComment = String(format: "    /// %@\n", endPointComment.key as! CVarArg)
        fileHandler.write(stringEndPointComment.data(using: .utf8)!)

        guard let childDict = endPointComment.value as? [String: String] else {
            exit(1)
        }

        // encrypt
        let stringToEncrypt = String(format: "%@", childDict["value"]!)
        let encryptedStringBase64 = stringToEncrypt.aesEncryptWithKey(aesKey, iv: hexiv)
        // encrypt

        //let jar = encryptedStringBase64.aesDecryptWithKey(aesKey, iv: hexiv)

        fileHandler.seekToEndOfFile()
        let endPoint = String(format: "    static let %@ = \"%@\"\n\n", childDict["key"]!, encryptedStringBase64)
        fileHandler.write(endPoint.data(using: .utf8)!)
    }

    fileHandler.seekToEndOfFile()
    fileHandler.write("}\n".data(using: .utf8)!)
    fileHandler.closeFile()
} catch {
    print("Error writing to file \(error)")
    exit(2)
}
