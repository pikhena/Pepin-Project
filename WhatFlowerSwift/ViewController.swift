//
//  ViewController.swift
//  What Flower
//
//  Created by Priscilla Ikhena on 07/06/2019.
//  Copyright © 2019 Priscilla Ikhena. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var label: UILabel!
    
    @IBOutlet weak var imageBar: UIImageView!
    
    let wikipediaURL = "https://en.wikipedia.org/w/api.php"
    let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = false
        // Do any additional setup after loading the view.
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let userTakenImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            
            print("I have picked up the image")
            
            guard let ciImage = CIImage(image: userTakenImage) else {fatalError("could not convert UIImage into CIImage")}
            
            detectImage(image: ciImage)
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
        print("I have been dismissed")
    }
    
    func detectImage(image: CIImage) {
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("Loading CoreML Model Failed")
        } //creating a vision container

        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let results = request.results as? [VNClassificationObservation] else {
                fatalError("model processing failed, could not classify image")
            }
            guard let classification = results.first else{fatalError("Error with classifying image")}
            
             self.navigationItem.title = classification.identifier.capitalized
             self.requestInfo(flowerName: classification.identifier)
                
        }
        let handler = VNImageRequestHandler(ciImage: image)
        do {
            try handler.perform([request])
        }
        
        catch {
            print(error)
        }
    }
    
    func requestInfo(flowerName: String){
        
        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro": "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids":"",
            "redirects": "1",
            "pithumbsize" : "500"
        ]
        
        Alamofire.request(wikipediaURL, method: .get, parameters: parameters).responseJSON { (response) in
            if response.result.isSuccess {
               print("Got the wikipedia info")
                print(response)
                
                let flowerJSON : JSON = JSON(response.result.value!)
                let pageid = flowerJSON["query"]["pageids"][0].stringValue
                let flowerDescription = flowerJSON["query"]["pages"][pageid]["extract"].string
                let flowerImageURL = flowerJSON["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
                self.label.text = flowerDescription
                self.imageBar.sd_setImage(with: URL(string: flowerImageURL))
                
            }
        }
    }
    
    
    @IBAction func cameraButtonPressed(_ sender: UIBarButtonItem) {
        print("camera has been tapped")
        present(imagePicker, animated: true, completion: nil)
    }
   
    
    


}

