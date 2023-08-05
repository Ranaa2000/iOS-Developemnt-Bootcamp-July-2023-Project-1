//
//  ContentView.swift
//  TodoListApp
//
//  Created by Rana MHD on 17/01/1445 AH.
//

import SwiftUI
import Foundation
import os

enum Priority: Codable {
    case LOW
    case MEDIUM
    case HIGH
}

enum Status: Codable {
    case Backlog
    case Todo
    case InProgress
    case Done
}

struct Item: Identifiable, Codable {
    var id = UUID()
    var title: String
    var description: String
    var priority: Priority
    var status: Status
    
    init(id: UUID = UUID(), title: String = "", description: String = "", priority: Priority = .LOW, status: Status = .Backlog) {
        self.id = id
        self.title = title
        self.description = description
        self.priority = priority
        self.status = status
    }
}

@MainActor class ItemStore : ObservableObject{
    @Published var items :[Item] = []
    
    func addItem(item: Item){
        items.append(item)
    }
    
    func editItem(item: Item){
        var idx = -1
        for (n, c) in items.enumerated() {
            if c.id == item.id {
                idx = n
            }
        }
        
        if idx >= 0 {
            items[idx] = item
        }
    }
    
    func deleteItem(item: Item){
        var idx = -1
        for (n, c) in items.enumerated() {
            if c.id == item.id {
                idx = n
            }
        }
        
        if idx >= 0 {
            items.remove(at: idx)
        }
    }
    
    func getItem(id: UUID) -> Item{
        var idx = -1
        for (n, c) in items.enumerated() {
            if c.id == id {
                idx = n
            }
        }
        
        if idx >= 0 {
            return items[idx]
        } else {
            return Item()
        }
    }
    
    private static func fileURL() throws -> URL {
        try FileManager.default.url(for: .documentDirectory,
                                    in: .userDomainMask,
                                    appropriateFor: nil,
                                    create: false)
        .appendingPathComponent("item.data")
    }
    
    
    func load() async throws {
        let task = Task<[Item], Error> {
            let fileURL = try Self.fileURL()
            guard let data = try? Data(contentsOf: fileURL) else {
                return []
            }
            let item = try JSONDecoder().decode([Item].self, from: data)
            return item
        }
        let items = try await task.value
        self.items = items
    }
    
    
    func save() async throws {
        let task = Task {
            let data = try JSONEncoder().encode(items.self)
            let outfile = try Self.fileURL()
            try data.write(to: outfile)
        }
        _ = try await task.value
    }
}

struct ItemView: View {
    @ObservedObject var itemStore: ItemStore
    @State var id: UUID
    @State var item: Item = Item()
    
    var body: some View {
        VStack{
            Form {
                Text("\(item.description)")
                Section("Priority") {
                    switch item.priority {
                    case .LOW:
                        Text("🔵 Low")
                            .bold()
                            .foregroundColor(.blue)
                    case .MEDIUM:
                        Text("🟡 Medium")
                            .bold()
                            .foregroundColor(.yellow)
                    case .HIGH:
                        Text("🔴 High")
                            .bold()
                            .foregroundColor(.red)
                    }
                }
                Section("Status") {
                    switch item.status {
                    case .Backlog:
                        Text("Backlog")
                            .bold()
                    case .Todo:
                        Text("Todo")
                            .bold()
                    case .InProgress:
                        Text("In Progress")
                            .bold()
                    case .Done:
                        Text("Done")
                            .bold()
                    }
                }
            }
            
            NavigationLink(
                destination:{
                    EditView(itemStore: itemStore, item: item)
                },
                label: {
                    Text("Edit Item")
                        .bold()
                        .frame(width: 290 , height: 60)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            )
        }
        .navigationTitle(item.title)
        .onAppear {
            item = itemStore.getItem(id: id)
        }
    }
}

struct NewView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var itemStore: ItemStore
    @State var title: String = ""
    @State var description: String = ""
    @State var priority: Priority = .LOW
    @State var status: Status = .Backlog
    @State var showAlert : Bool = false
    @State var alertMessage: String = ""
    
    var body: some View {
        VStack {
            Form {
                TextField("Title", text: $title)
                
                TextField("Description", text: $description, axis: .vertical)
                    .lineLimit(5, reservesSpace: true)
                
                Picker(selection: $priority, label: Text("Priority")) {
                    Text("High").tag(Priority.HIGH)
                    Text("Medium").tag(Priority.MEDIUM)
                    Text("Low").tag(Priority.LOW)
                }
                .pickerStyle(.navigationLink)
                
                Picker(selection: $status, label: Text("Status")) {
                    Text("Backlog").tag(Status.Backlog)
                    Text("Todo").tag(Status.Todo)
                    Text("In Progress").tag(Status.InProgress)
                    Text("Done").tag(Status.Done)
                }
                .pickerStyle(.navigationLink)
            }
            
            Button {
                if title.isEmpty {
                    showAlert = true
                    alertMessage = "Title should not be empty!"
                    return
                }
                if description.isEmpty {
                    showAlert = true
                    alertMessage = "Description should not be empty!"
                    return
                }
                itemStore.addItem(item: Item(title: title, description: description, priority: priority, status: status))
                self.presentationMode.wrappedValue.dismiss()
            } label: {
                Text("Add")
                    .bold()
                    .frame(width: 290 , height: 60)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
        }
        .alert(isPresented: $showAlert) {
            Alert (title: Text(alertMessage))
        }
        .navigationTitle("New Item")
    }
}

struct EditView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var itemStore: ItemStore
    @State var item: Item
    @State var showAlert : Bool = false
    @State var alertMessage: String = ""
    
    var body: some View {
        VStack {
            Form {
                TextField("Title", text: $item.title)
                
                TextField("Description", text: $item.description, axis: .vertical)
                    .lineLimit(5, reservesSpace: true)
                
                Picker(selection: $item.priority, label: Text("Priority")) {
                    Text("High").tag(Priority.HIGH)
                    Text("Medium").tag(Priority.MEDIUM)
                    Text("Low").tag(Priority.LOW)
                }
                .pickerStyle(.navigationLink)
                
                Picker(selection: $item.status, label: Text("Status")) {
                    Text("Backlog").tag(Status.Backlog)
                    Text("Todo").tag(Status.Todo)
                    Text("In Progress").tag(Status.InProgress)
                    Text("Done").tag(Status.Done)
                }
                .pickerStyle(.navigationLink)
            }
            
            Button {
                if item.title.isEmpty {
                    showAlert = true
                    alertMessage = "Title should not be empty!"
                    return
                }
                if item.description.isEmpty {
                    showAlert = true
                    alertMessage = "Description should not be empty!"
                    return
                }
                itemStore.editItem(item: item)
                self.presentationMode.wrappedValue.dismiss()
            } label: {
                Text("Edit")
                    .bold()
                    .frame(width: 290 , height: 60)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .alert(isPresented: $showAlert) {
            Alert (title: Text(alertMessage))
        }
        .navigationTitle("Edit Item")
    }
}

struct ContentView: View {
    let statuses : Array<String> = [
        "All" ,
        "Backlog",
        "Todo",
        "In Progress",
        "Done"
    ]
    
    @ObservedObject var itemStore = ItemStore()
    @State var filterItems : Array<Item> = []
    @State var searchBox : String = ""
    @State var currentStatus : String = "All"
    let logger = Logger()
    
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("isDarkMode") private var isDarkMode = false
        
    var body: some View {
        NavigationStack {
            ZStack {
                VStack{
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .padding(.horizontal, 10)
                        TextField("Search", text: $searchBox)
                            .frame(height: 40)
                    } // HStack (Search Box)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 4)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(12)
                    
                    // categories
                    HStack {
                        ForEach(statuses , id: \.self){
                            status in
                            Button(
                                action: {
                                    currentStatus = status
                                    updateView()
                                },
                                label: {
                                    if currentStatus == status {
                                        Text(status)
                                            .bold()
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 8)
                                            .background(Color.blue.opacity(0.3))
                                            .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                                            .cornerRadius(12)
                                    } else {
                                        Text(status)
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 8)
                                            .background(Color.gray.opacity(0.3))
                                            .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                                            .cornerRadius(12)
                                    }
                                    
                                }
                            )
                        }
                    } // HStack
                    .frame(maxWidth:.infinity, alignment: .leading)
                    
                    Form{
                        Section("\(currentStatus) (\(filterItems.count))") {
                            List {
                                ForEach(filterItems) { item in
                                    NavigationLink{
                                        ItemView(
                                            itemStore: itemStore,
                                            id: item.id
                                        )
                                    } label: {
                                        HStack {
                                            switch item.priority {
                                            case .LOW:
                                                Text("🔵")
                                                    .bold()
                                                    .foregroundColor(.blue)
                                            case .MEDIUM:
                                                Text("🟡")
                                                    .bold()
                                                    .foregroundColor(.yellow)
                                            case .HIGH:
                                                Text("🔴")
                                                    .bold()
                                                    .foregroundColor(.red)
                                            }
                                            Text(item.title)
                                        }
                                    }
                                }
                                .onDelete{ indexSet in
                                    // to delete, swipe left
                                    if let idx = indexSet.first {
                                        itemStore.deleteItem(item: filterItems[idx])
                                        filterItems = itemStore.items
                                    }
                                }
                            }
                            .onAppear {
                                updateView()
                                //filterItems = itemStore.items
                            }
                        }
                    }
                    
                    NavigationLink(
                        destination:{
                            NewView(itemStore: itemStore)
                        },
                        label: {
                            Text("New Item")
                        }
                    )
                    .bold()
                    .frame(width: 290 , height: 60)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding()
                    
                    Toggle("Dark Mode", isOn: $isDarkMode)
                        .padding()
                }
                .navigationTitle("To Do List")
            }.onAppear {
                logger.log("main view appear")
                updateView()
            }
        }
        .padding(4)
        .onAppear {
            Task {
                do {
                    try await itemStore.load()
                    logger.info("Loaded (\(itemStore.items.count)) items")
                    filterItems = itemStore.items
                } catch {
                    fatalError(error.localizedDescription)
                }
            }
        }
        .onChange(of: searchBox){
            newValue in searchItems(newValue)
        }
        .onChange(of: scenePhase) { phase in
            if phase == .inactive { saveAction() }
        }
    }
    
    func updateView(){
        logger.log("Updating view")
        switch self.currentStatus {
            case statuses[1] :
                filterItems = itemStore.items.filter({
                    item in item.status == .Backlog
                })
                
            case statuses[2] :
                filterItems = itemStore.items.filter({
                    item in item.status == .Todo
                })
                
            case statuses[3] :
                filterItems = itemStore.items.filter({
                    item in item.status == .InProgress
                })
                
            case statuses[4] :
                filterItems = itemStore.items.filter({
                    item in item.status == .Done
                })
                
            default:
                filterItems = itemStore.items
            }
    }
    
    func searchItems(_ value :String){
        if value.isEmpty {
            filterItems = itemStore.items
        } else {
            let loweredCasedValue = value.lowercased()
            filterItems = itemStore.items.filter({ item in
                return item.title.lowercased().contains(loweredCasedValue)
            })
        }
    }
    
    func saveAction() {
        //if(itemStore.items.count > 0) {
            Task {
                do {
                    try await itemStore.save()
                    logger.info("Saved (\(itemStore.items.count)) items")
                } catch {
                    fatalError(error.localizedDescription)
                }
            }
        //}
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(.light)
    }
}
