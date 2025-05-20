//
//  CoreDataManager.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 08/05/25.
//

import Foundation
import CoreData


class CoreDataManager{
    
    static let shared = CoreDataManager()

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "CrewBid_iPad_Swift")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    lazy var managedObjectModel: NSManagedObjectModel = {
        let resource = "CrewBid_iPad_Swift"
        guard let modelURL = Bundle.main.url(forResource: resource, withExtension:"momd") else {
            fatalError("Error loading model from bundle")
        }
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    lazy var persistantStoreCoordinator: NSPersistentStoreCoordinator = {
        let storeURL = self.applicationDocumentDirectory().appendingPathComponent( "CrewBid_iPad_Swift.sqlite")
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        return persistentContainer.persistentStoreCoordinator
    }()
    

    func applicationDocumentDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
    }
    
    
    func saveData(){
        let context = persistentContainer.viewContext
        if context.hasChanges{
            do{
                try context.save()
            }catch{
                print("Error saving data")
            }
        }
    }
    
}
