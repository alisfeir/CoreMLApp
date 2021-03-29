//
//  CoreMLExtension.swift
//  CoreMLApp
//
//  Created by Ali MAHFOUDHI on 03/03/2021.
//

import UIKit
import Vision
import CoreML

extension ViewController {
    
    func requete(_ ciImage: CIImage) {
        do {
            let coreMLModel = try VNCoreMLModel(for: Mask().model)
            let requete = VNCoreMLRequest(model: coreMLModel, completionHandler: reponse)
            let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
            try handler.perform([requete])
        } catch {
            print(error.localizedDescription)
        }
        
    }
    
    
    func reponse(_ requete: VNRequest, _ error: Error?) {
        DispatchQueue.main.async {
            if let resultats = requete.results as? [VNClassificationObservation], resultats.count > 0 {
                let resultatsTries = resultats.sorted(by: {$0.confidence > $1.confidence})
                let meilleurResultat = resultatsTries[0]
                let objet = meilleurResultat.identifier
                let pourcentage = Int(meilleurResultat.confidence * 100)
                //                if pourcentage > 50 {
                let pourcentageString = "Confiance: " + String(pourcentage) + "%"
                let attributed = NSMutableAttributedString(string: objet + "\n", attributes: [.font: UIFont.boldSystemFont(ofSize: 20), .foregroundColor: UIColor.red])
                attributed.append(NSAttributedString(string: pourcentageString, attributes: [.font: UIFont.italicSystemFont(ofSize: 17), .foregroundColor: UIColor.blue]))
                self.predictionLabel.attributedText = attributed
            } else {
                self.predictionLabel.text = ""
            }
        }
    }
    
}
