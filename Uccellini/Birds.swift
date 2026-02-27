

import Foundation
// MARK: - Sound Model
struct Sound: Identifiable {
    let id = UUID()
    let name: String
    let fileName: String
    let imageName: String
    
    init(name: String, fileName: String, imageName: String) {
        self.name = name
        self.fileName = fileName
        self.imageName = imageName
    }
}

// MARK: - Sounds Manager
class SoundsManager {
    static let shared = SoundsManager()
    
    let sounds: [Sound] = [
        Sound(name: "Cinciallegra", fileName: "Cinciallegra", imageName: "Cinciallegra"),
        Sound(name: "Cinciarella", fileName: "Cinciarella", imageName: "Cinciarella"),
        Sound(name: "Codibugnolo", fileName: "Codibugnolo", imageName: "Codibugnolo"),
        Sound(name: "Fringuello", fileName: "Fringuello", imageName: "Fringuello"),
        Sound(name: "Gazza", fileName: "Gazza", imageName: "Gazza"),
        Sound(name: "Martin Pescatore", fileName: "MartinPescatore", imageName: "MartinPescatore"),
        Sound(name: "Passero", fileName: "Passero", imageName: "Passero"),
        Sound(name: "Pettirosso", fileName: "Pettirosso", imageName: "Pettirosso"),
        Sound(name: "Picchio Muratore", fileName: "PicchioMuratore", imageName: "PicchioMuratore"),
        Sound(name: "Picchio Rosso Maggiore", fileName: "PicchioRossoMaggiore", imageName: "PicchioRossoMaggiore"),
        Sound(name: "Storno europeo", fileName: "Storno", imageName: "Storno"),
        ]
    
    private init() {}
}

