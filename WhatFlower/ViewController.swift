//
//  ViewController.swift
//  WhatFlower
//
//  Created by Matthew Cheung on 18/3/2023.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var labelView: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    let imagePicker = UIImagePickerController()
   
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
        
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let userPickedImage = info[.editedImage] as? UIImage {
            guard let ciimage = CIImage(image: userPickedImage) else{
                fatalError("Cannot convert image")
            }
            detect(ciimage)
            imagePicker.dismiss(animated: true, completion: nil)
        }
    }
    
    func detect(_ image: CIImage){
        guard let model = try? VNCoreMLModel(for: MLModel(contentsOf: FlowerClassifier.urlOfModelInThisBundle)) else {
            fatalError("Loading CoreML Model Failed")
        }
        let request  = VNCoreMLRequest(model: model) { request, error in
            guard let results = request.results as? [VNClassificationObservation] else {
                fatalError("Model failed process image")
            }
            if let firstResult = results.first{
                self.navigationItem.title = firstResult.identifier.capitalized
                self.wikepediaAPI(firstResult.identifier)
            }
        }
        let handler = VNImageRequestHandler(ciImage: image)
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
    }
    func wikepediaAPI(_ flowerName: String){
        
        let wikipediaURl = "https://en.wikipedia.org/w/api.php"
        
        let parameters : [String:String] = [
          "format" : "json",
          "action" : "query",
          "prop" : "extracts|pageimages",
          "exintro" : "",
          "explaintext" : "",
          "titles" : flowerName,
          "indexpageids" : "",
          "redirects" : "1",
          "pithumbsize" : "500"
          ]
        
        let decoder = JSONDecoder()
        
        AF.request(wikipediaURl, method: .get ,parameters: parameters).responseDecodable(of: JSON.self, decoder: decoder) { response in
            switch response.result {
            case .success:
                print(response)
                if let data = response.data{
                    if let jsonData = try? JSON(data: data){
                        let pageid = jsonData["query"]["pageids"][0].stringValue
                        let flowerImageURL = jsonData["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
                        self.imageView.sd_setImage(with: URL(string: flowerImageURL))
                        self.labelView.text = jsonData["query"]["pages"][pageid]["extract"].stringValue
                    }
                }
            case .failure:
                print("Failed to response")
            }
        }
    }
    @IBAction func cameraPressed(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil)
    }
}

