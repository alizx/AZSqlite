import XCTest
@testable import AZSqlite

final class AZSqliteTests: XCTestCase {
    
    var db: SQLiteBase!
    var dbPath: String!
    
    override func setUp() {
        super.setUp()
        
        db = SQLiteBase()
        
        let fileManager = FileManager.default
        dbPath = fileManager.temporaryDirectory.appendingPathComponent("AZSqliteTestDB.sqlite").path
        
        // Remove existing DB file if it exists
        if fileManager.fileExists(atPath: dbPath) {
            try? fileManager.removeItem(atPath: dbPath)
        }
    }
    
    func testDatabaseOperations() {
        
        // Open the database
        guard db.open(dbPath: dbPath) else {
            XCTFail("Failed to open the database.")
            return
        }
        
        _ = db.execute(sql: """
              CREATE TABLE IF NOT EXISTS TestTable(
                  strCol TEXT NOT NULL,
                  intCol INTEGER NOT NULL,
                  doubleCol REAL NOT NULL,
                  boolCol INTEGER NOT NULL CHECK (boolCol IN (0,1)),
                  nullableStrCol TEXT,
                  nullableIntCol INTEGER,
                  nullableDoubleCol REAL,
                  nullableBoolCol INTEGER CHECK (nullableBoolCol IN (0,1))
              );
          """)
        
        let testDataEntry = TestDataEntry(
            strCol: "testString",
            intCol: 123,
            doubleCol: 123.456,
            boolCol: true,
            nullableStrCol: nil,
            nullableIntCol: nil,
            nullableDoubleCol: nil,
            nullableBoolCol: nil
        )
        
        _ = db.execute(
            sql: """
                 INSERT INTO TestTable (strCol, intCol, doubleCol, boolCol, nullableStrCol, nullableIntCol, nullableDoubleCol, nullableBoolCol)
                 VALUES (?,?,?,?,?,?,?,?);
                 """,
            parameters: [
                testDataEntry.strCol,
                testDataEntry.intCol,
                testDataEntry.doubleCol,
                testDataEntry.boolCol ? 1 : 0,
                testDataEntry.nullableStrCol as Any,
                testDataEntry.nullableIntCol as Any,
                testDataEntry.nullableDoubleCol as Any,
                testDataEntry.nullableBoolCol as Any
            ]
        )
        
        
        let row = db.query(sql: "SELECT * FROM TestTable WHERE strCol = ?", parameters: [testDataEntry.strCol]).first!
        var retrievedData = TestDataEntry(
            strCol: row["strCol"] as! String,
            intCol: row["intCol"] as! Int,
            doubleCol: row["doubleCol"] as! Double,
            boolCol: (row["boolCol"] as! Int) == 1,
            nullableStrCol: row["nullableStrCol"] as? String,
            nullableIntCol: row["nullableIntCol"] as? Int,
            nullableDoubleCol: row["nullableDoubleCol"] as? Double,
            nullableBoolCol: (row["nullableBoolCol"] as? Int).map { $0 == 1 }
        )
        
        
        XCTAssertEqual(retrievedData.strCol, testDataEntry.strCol)
        XCTAssertEqual(retrievedData.intCol, testDataEntry.intCol)
        XCTAssertEqual(retrievedData.doubleCol, testDataEntry.doubleCol, accuracy: 0.0001)
        XCTAssertEqual(retrievedData.boolCol, testDataEntry.boolCol)
        XCTAssertEqual(retrievedData.nullableStrCol, testDataEntry.nullableStrCol)
        XCTAssertEqual(retrievedData.nullableIntCol, testDataEntry.nullableIntCol)
        XCTAssertEqual(retrievedData.nullableDoubleCol, testDataEntry.nullableDoubleCol)
        XCTAssertEqual(retrievedData.nullableBoolCol, testDataEntry.nullableBoolCol)
        
        // Preparing the second data entry with values for nullable columns
        let secondTestDataEntry = TestDataEntry(
            strCol: "TestStr2",
            intCol: 2,
            doubleCol: 2.2,
            boolCol: false,
            nullableStrCol: "NullableStr2",
            nullableIntCol: 2,
            nullableDoubleCol: 2.2,
            nullableBoolCol: false
        )
        
        // Inserting the second data entry into the database
        _ = db.execute(
            sql: """
                INSERT INTO TestTable (strCol, intCol, doubleCol, boolCol, nullableStrCol, nullableIntCol, nullableDoubleCol, nullableBoolCol)
                VALUES (?,?,?,?,?,?,?,?);
                """,
            parameters: [
                secondTestDataEntry.strCol,
                secondTestDataEntry.intCol,
                secondTestDataEntry.doubleCol,
                secondTestDataEntry.boolCol ? 1 : 0,
                secondTestDataEntry.nullableStrCol as Any,
                secondTestDataEntry.nullableIntCol as Any,
                secondTestDataEntry.nullableDoubleCol as Any,
                secondTestDataEntry.nullableBoolCol.map { $0 ? 1 : 0 } as Any
            ]
        )
        
        let row2 = db.query(sql: "SELECT * FROM TestTable WHERE strCol = ?", parameters: [secondTestDataEntry.strCol]).first!
        var retrievedSecondEntry = TestDataEntry(
            strCol: row2["strCol"] as! String,
            intCol: row2["intCol"] as! Int,
            doubleCol: row2["doubleCol"] as! Double,
            boolCol: (row2["boolCol"] as! Int) == 1,
            nullableStrCol: row2["nullableStrCol"] as? String,
            nullableIntCol: row2["nullableIntCol"] as? Int,
            nullableDoubleCol: row2["nullableDoubleCol"] as? Double,
            nullableBoolCol: (row2["nullableBoolCol"] as? Int).map { $0 == 1 }
        )
        
        // Verifying that the retrieved data matches the second inserted data entry
        XCTAssertNotNil(retrievedSecondEntry)
        XCTAssertEqual(retrievedSecondEntry.strCol, secondTestDataEntry.strCol)
        XCTAssertEqual(retrievedSecondEntry.intCol, secondTestDataEntry.intCol)
        XCTAssertEqual(retrievedSecondEntry.doubleCol, secondTestDataEntry.doubleCol)
        XCTAssertEqual(retrievedSecondEntry.boolCol, secondTestDataEntry.boolCol)
        XCTAssertEqual(retrievedSecondEntry.nullableStrCol, secondTestDataEntry.nullableStrCol)
        XCTAssertEqual(retrievedSecondEntry.nullableIntCol, secondTestDataEntry.nullableIntCol)
        XCTAssertEqual(retrievedSecondEntry.nullableDoubleCol, secondTestDataEntry.nullableDoubleCol)
        XCTAssertEqual(retrievedSecondEntry.nullableBoolCol, secondTestDataEntry.nullableBoolCol)
        
    }
    
    
    static var allTests = [
        ("testDatabaseOperations", testDatabaseOperations),
    ]
}


struct TestDataEntry {
    let strCol: String
    let intCol: Int
    let doubleCol: Double
    let boolCol: Bool
    let nullableStrCol: String?
    let nullableIntCol: Int?
    let nullableDoubleCol: Double?
    let nullableBoolCol: Bool?
}
