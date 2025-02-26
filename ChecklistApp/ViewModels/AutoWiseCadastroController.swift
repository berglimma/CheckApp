import Foundation

class AutoWiseCadastroController {
    private let databaseController = AutoWiseCadastroSQLiteController()
    
    func saveUser(name: String, email: String, phone: String, password: String, confirmPassword: String, isAdmin: Bool) -> Bool {
        guard !name.isEmpty, !email.isEmpty, password == confirmPassword else {
            return false
        }
        return databaseController.saveUser(
            name: name,
            email: email,
            phone: phone,
            password: password,
            isAdmin: isAdmin
        )
    }
    
    func cancelRegistration() {
        print("Cadastro cancelado.")
    }
}
