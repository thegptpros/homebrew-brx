import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: TodoStore
    @State private var newTodoText = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    TextField("Add a new task...", text: $newTodoText)
                        .textFieldStyle(.roundedBorder)
                    
                    Button(action: addTodo) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                    .disabled(newTodoText.isEmpty)
                }
                .padding()
                
                List {
                    ForEach(store.todos) { todo in
                        HStack {
                            Button(action: { store.toggle(todo) }) {
                                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(todo.isCompleted ? .green : .gray)
                            }
                            .buttonStyle(.plain)
                            
                            Text(todo.text)
                                .strikethrough(todo.isCompleted)
                                .foregroundColor(todo.isCompleted ? .gray : .primary)
                            
                            Spacer()
                        }
                    }
                    .onDelete(perform: deleteTodos)
                }
                
                Link("Built with brx.dev", destination: URL(string: "https://brx.dev")!)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            }
            .navigationTitle("Todo List")
        }
    }
    
    private func addTodo() {
        guard !newTodoText.isEmpty else { return }
        store.add(text: newTodoText)
        newTodoText = ""
    }
    
    private func deleteTodos(at offsets: IndexSet) {
        store.delete(at: offsets)
    }
}

