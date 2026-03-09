import SwiftData

final class AutoWiseCadastroController {
    
    func saveUser(
        context: ModelContext,
        name: String,
        email: String,
        phone: String,
        password: String,
        confirmPassword: String,
        role: UserRole
    ) -> Result<Bool, CadastroError> {
        
        guard !name.isEmpty,
              !email.isEmpty,
              !phone.isEmpty,
              !password.isEmpty else {
            return .failure(.camposObrigatorios)
        }
        
        guard password == confirmPassword else {
            return .failure(.senhasNaoConferem)
        }
        
        let user = User(
            name: name,
            email: email,
            phone: phone,
            password: password,
            role: role
        )
        
        context.insert(user)
        
        do {
            try context.save()
            return .success(true)
        } catch {
            return .failure(.erroSalvar)
        }
    }
}
