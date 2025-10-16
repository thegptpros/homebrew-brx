import Foundation

struct Todo: Identifiable {
    let id = UUID()
    var text: String
    var isCompleted: Bool = false
}

class TodoStore: ObservableObject {
    @Published var todos: [Todo] = []
    
    func add(text: String) {
        let todo = Todo(text: text)
        todos.append(todo)
    }
    
    func toggle(_ todo: Todo) {
        if let index = todos.firstIndex(where: { $0.id == todo.id }) {
            todos[index].isCompleted.toggle()
        }
    }
    
    func delete(at offsets: IndexSet) {
        todos.remove(atOffsets: offsets)
    }
}

