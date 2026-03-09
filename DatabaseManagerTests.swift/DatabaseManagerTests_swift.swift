import XCTest
@testable import ChecklistApp

final class DatabaseManagerTests: XCTestCase {
    
    override func setUpWithError() throws {
        let inseriu = DatabaseManager.shared.insertUser(
            name: "Teste",
            email: "teste@email.com",
            phone: "999999999",
            password: "123456",
            isAdmin: false
        )
        XCTAssertTrue(inseriu, "Erro ao inserir usuário de teste no banco de dados.")
    }
    
    func testValidarUsuarioCorreto() {
        let result = DatabaseManager.shared.validateUser(email: "teste@email.com", password: "123456")
        XCTAssertTrue(result, "Usuário deveria ser validado corretamente.")
    }

    func testValidarUsuarioSenhaIncorreta() {
        let result = DatabaseManager.shared.validateUser(email: "teste@email.com", password: "senhaErrada")
        XCTAssertFalse(result, "Usuário não deveria ser validado com senha errada.")
    }

    func testValidarUsuarioInexistente() {
        let result = DatabaseManager.shared.validateUser(email: "naoexiste@email.com", password: "123456")
        XCTAssertFalse(result, "Usuário que não existe não deveria ser validado.")
    }
}
