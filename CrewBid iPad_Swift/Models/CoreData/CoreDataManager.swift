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
            container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            container.viewContext.automaticallyMergesChangesFromParent = true
        })
        return container
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        return persistentContainer.viewContext
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        let resource = "CrewBid_iPad_Swift"
        guard let modelURL = Bundle.main.url(forResource: resource, withExtension:"momd") else {
            fatalError("Error loading model from bundle")
        }
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    

    func applicationDocumentDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
    }
    
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.undoManager = nil
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
        
    }
    
    func saveData(){
        let context = persistentContainer.viewContext
        if context.hasChanges{
            do{
                try context.save()
            }catch{
                AlertService.showAlertForTopVC(title: "Save Error", message: "There was a problem saving your data. Please try again later.")
                print("Error saving data")
            }
        }
    }
    
    func deleteAllData(for entityName: String) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try persistentContainer.viewContext.execute(deleteRequest)
            try persistentContainer.viewContext.save()
        } catch {
            print("Failed to delete data for entity \(entityName): \(error)")
        }
    }
    
}
