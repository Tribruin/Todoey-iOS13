//
//  ViewController.swift
//  Todoey
//
//  Created by Philipp Muellauer on 02/12/2019.
//  Copyright © 2019 App Brewery. All rights reserved.
//

import UIKit
import RealmSwift
import ChameleonFramework

class TodoListViewController: SwipeTableViewController {

    var todoItems : Results<Item>?
    let realm = try! Realm()
    
    var selectedCategory : Category? {
        didSet {
//            loadItems()
        }
    }
    
    @IBOutlet weak var itemNavBar: UINavigationItem!
    @IBOutlet weak var searchBar: UISearchBar!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        loadItems()
        tableView.separatorStyle = .none
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
           if let colorHex = selectedCategory?.backgroundColor {
               title = selectedCategory?.name
               guard let navBar = navigationController?.navigationBar else {fatalError("Navigation Controller does not exist.")}
               if let navBarColor = UIColor(hexString: colorHex) {
                navBar.backgroundColor = navBarColor.darken(byPercentage: 0.50)!
                   navBar.tintColor = ContrastColorOf(navBarColor, returnFlat: true)
                   navBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor : ContrastColorOf(navBarColor, returnFlat: true)]
                   searchBar.barTintColor = navBarColor
                   searchBar.searchTextField.backgroundColor = FlatWhite()
               }
               title = selectedCategory!.name

           }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return todoItems?.count ?? 1
        
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

       let cell = super.tableView(tableView, cellForRowAt: indexPath)
    
        if let item = todoItems?[indexPath.row] {
            
            cell.textLabel?.text = item.title
            if let color = UIColor(hexString: selectedCategory!.backgroundColor)?.darken(byPercentage: (CGFloat(indexPath.row) / CGFloat(todoItems!.count)))
            {
                let beginColor = color.lighten(byPercentage: 0.20)!
                let endColor = color.darken(byPercentage: 0.20)!
                let colors = [beginColor, endColor]
                let cellRect = tableView.rectForRow(at: indexPath)
                cell.backgroundColor = GradientColor(.leftToRight, frame: cellRect, colors: colors)
                cell.textLabel?.textColor = ContrastColorOf(color, returnFlat: true)
            }
            
            //Ternary operator ==>
            // value = condition ? valueIfTrue : valueIfFalse
            
            cell.accessoryType  = item.done ? .checkmark : .none
        } else {
            cell.textLabel?.text = "No Items Added"
        }
        
        return cell
    }
    
    
//MARK: - TableView Delegate Method
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let item = todoItems?[indexPath.row] {
            do {
                try realm.write {
                    item.done = !item.done
                }
            } catch {
                print("Error saving done status \(error)")
            }
        }
        tableView.reloadData()
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    //MARK: - Add New Items

    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {

        var textField = UITextField()

        let alert = UIAlertController(title: "Add New Todoey item", message: "", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "Add Item", style: .default) { (action) in
            //What will happen once the user clicks the add item button on our UIAlert
            
            if let currentCategory = self.selectedCategory {
                do {
                    try self.realm.write {
                        let newItem = Item()
                        newItem.title = textField.text!
                        newItem.dateCreated = Date()
                        currentCategory.items.append(newItem)
                    }
                    } catch {
                        print("Error saving categories: \(error)")
                    }
                }
            
            self.tableView.reloadData()
            }

        
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "Create new item"
            textField = alertTextField
        }

        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    
    //MARK: - Delete Data From Swipe
     override func updateModel(at indexPath: IndexPath) {
         if let itemForDeletion = self.todoItems?[indexPath.row] {
             do {
                 try self.realm.write {
                     self.realm.delete(itemForDeletion)
                 }
             } catch {
                 print("error")
             }
         }
     }

    //MARK: - Model Manupulation Methods
    

    func loadItems() {

        todoItems = selectedCategory?.items.sorted(byKeyPath: "title", ascending: true)
        self.tableView.reloadData()
    }
}

//MARK: - Search Bar Methods

extension TodoListViewController : UISearchBarDelegate {

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {

        executeSearch(searchFor: searchBar.text!)

        // Dismiss the keyboard and search bar focus when user clicks "Search"
        DispatchQueue.main.async {
            searchBar.resignFirstResponder()
        }
        
        tableView.reloadData()
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text?.count == 0 {
            loadItems()

            DispatchQueue.main.async {
                searchBar.resignFirstResponder()
            }
        } else {
            // execute a search based on current searchBar text. This makes for LIVE searching.

            executeSearch(searchFor: searchBar.text!)
        }
    }

    func executeSearch(searchFor searchText : String) {
        // execute a Search of titles based on searchText
        
        // Reset the items list to full items
        loadItems()
        
        // Now filter based on the searchText
        todoItems = todoItems?.filter("title CONTAINS[cd] %@", searchText).sorted(byKeyPath: "dateCreated", ascending: true)
        tableView.reloadData()
    }

}


