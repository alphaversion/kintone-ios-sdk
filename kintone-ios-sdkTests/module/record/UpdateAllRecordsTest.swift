//
//  UpdateAllRecordsTest.swift
//  kintone-ios-sdkTests
//
//  Created by Ho Kim Cuc on 8/28/19.
//  Copyright © 2019 Cybozu. All rights reserved.
//

import XCTest
@testable import kintone_ios_sdk
@testable import Promises

class UpdateAllRecordsTest: XCTestCase {
    private let USERNAME = TestsConstants.ADMIN_USERNAME
    private let PASSWORD = TestsConstants.ADMIN_PASSWORD
    private let APP_ID = 1
    private let LANG = LanguageSetting.EN
    private var record: Record? = nil
    private var connection: Connection? = nil
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        var auth = Auth.init()
        auth = auth.setPasswordAuth(self.USERNAME, self.PASSWORD)
        self.connection = Connection(TestsConstants.DOMAIN, auth)
        self.record = Record(self.connection!)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testUpdateAllRecordsSuccess()
    {
        let numberRecordToUpdate = 2500
        var recordsToUpdate: [[String:FieldValue]] = []
        var recordsToAdd: [[String:FieldValue]] = []
        var i = 0
        while (i < numberRecordToUpdate) {
            var record1 = createAddData()
            var record2 = createAddData()
            record1 = addData(record1, "SINGLE_LINE_TEXT", FieldType.SINGLE_LINE_TEXT, "add record")
            recordsToAdd.append(record1)
          record2 = addData(record2, "SINGLE_LINE_TEXT", FieldType.SINGLE_LINE_TEXT, "testUpdateRecords1")
            recordsToUpdate.append(record2)
            i += 1
        }
        
        self.addAllRecords(APP_ID, recordsToAdd).then{ buklsAddRecordRsp -> Promise<BulkRequestResponse> in
            var updateItems: [RecordUpdateItem] = []
            i = 0
            for result in buklsAddRecordRsp.getResults()! {
                let addRecordsResponse = result as! [AddRecordsResponse]
                for item in addRecordsResponse {
                    for id in item.getIDs()! {
                        let item = RecordUpdateItem(id, nil, nil, recordsToUpdate[i])
                        updateItems.append(item)
                    }
                }
                i += 1
            }
            return (self.record?.updateAllRecords(self.APP_ID, updateItems))!
        }.then{ updateRecordRsp in
            for result in updateRecordRsp.getResults()! {
                let updateRecordsResponse = result as! [UpdateRecordsResponse]
                for item in updateRecordsResponse {
                    var expectID: Int = (item.getRecords()![0] as RecordUpdateResponseItem).getID()!
                    for record in item.getRecords()! {
                        XCTAssert(record.getID() ==  expectID)
                        XCTAssert(record.getRevision()! ==  2)
                        expectID += 1
                    }
                }
            }
        }.catch{ error in
            var errorString = ""
            if (type(of: error) == BulksException.self) {
                errorString = (error as! KintoneAPIException).toString()!
            } else {
                errorString = error.localizedDescription
            }
            XCTFail(errorString)
        }
        XCTAssert(waitForPromises(timeout: 10000))
    }
    
    func testUpdateAllRecordsWhenAppIDNotExist() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let appId: Int = -99999
        self.record?.updateAllRecords(appId, []).then{ response in
            XCTFail("No errors occurred")
        }.catch{ error in
            XCTAssert(type(of: error) == BulksException.self)
        }
        XCTAssert(waitForPromises(timeout: 5))
    }
    
    private func addBulkRecord (_ app: Int, _ records: [[String:FieldValue]]) -> Promise<BulkRequestResponse>{
        let bulkRequest = BulkRequest(self.connection!)
        let length = records.count
        var numRequest =  length / RecordConstants.LIMIT_ADD_RECORD
        if ((length % RecordConstants.LIMIT_ADD_RECORD) > 0 || length == 0) {
            numRequest += 1
        }
        for index in 1...numRequest {
            let begin = (index - 1) * RecordConstants.LIMIT_ADD_RECORD
            let end = (length - begin) < RecordConstants.LIMIT_ADD_RECORD ? length : begin + RecordConstants.LIMIT_ADD_RECORD
            let recordsPerRequest = Array(records[begin..<end])
            do {
                try _ = bulkRequest.addRecords(app, recordsPerRequest)
            } catch {
                return Promise<BulkRequestResponse> { _,reject in
                    reject(error)
                }
            }
        }
        return bulkRequest.execute()
    }
    
    /// Add all record to kintone app
    ///
    /// - Parameters:
    ///   - app: the ID of kintone app
    ///   - records: the records data which will add to kintone app
    /// - Returns: AddRecordResponse
    /// - Throws: BulksException
    private func addAllRecords (_ app: Int, _ records: [[String:FieldValue]] ) -> Promise<BulkRequestResponse>{
        return Promise<BulkRequestResponse>(on: .global(), { fulfill, reject in
            let numRecordsPerBulk = RecordConstants.NUM_BULK_REQUEST * RecordConstants.LIMIT_ADD_RECORD
            var numBulkRequest = records.count / numRecordsPerBulk
            let bulkRequestResponse = BulkRequestResponse()
            
            if ((records.count % numRecordsPerBulk) > 0 || records.count == 0)
            {
                numBulkRequest += 1
            }
            
            var offset = 0
            for _ in 1...numBulkRequest {
                let length = records.count
                let end = (length - offset) < numRecordsPerBulk ? length : offset + numRecordsPerBulk
                do {
                    let recordsPerBulk = Array(records[offset..<end])
                    let resultPerBulk = try await(self.addBulkRecord(app, recordsPerBulk))
                    bulkRequestResponse.addResponse(resultPerBulk.getResults() as Any)
                } catch {
                    bulkRequestResponse.addResponse(error)
                    return reject(BulksException(bulkRequestResponse.getResults()))
                }
                offset += numRecordsPerBulk
            }
            fulfill(bulkRequestResponse)
        })
    }
    
    private func createAddData() -> Dictionary<String, FieldValue> {
        var testRecord: Dictionary<String, FieldValue> = [:]
        
        // text type
        testRecord = addData(testRecord, "SINGLE_LINE_TEXT", FieldType.SINGLE_LINE_TEXT, "single line text add data")
        testRecord = addData(testRecord, "UPDATE_KEY", FieldType.SINGLE_LINE_TEXT, "")
        testRecord = addData(testRecord, "MULTI_LINE_TEXT", FieldType.MULTI_LINE_TEXT, "multi line text add data1\nmulti line text add data2")
        testRecord = addData(testRecord, "RICH_TEXT", FieldType.RICH_TEXT, "<div><strong>rich text test add</strong></div>")
        
        let uniqunum = arc4random() % 10
        testRecord = addData(testRecord, "NUMBER", FieldType.NUMBER, uniqunum.description)
        return testRecord
    }
    
    private func addData(_ recordData: Dictionary<String, FieldValue>, _ code: String, _ type: FieldType, _ value: Any) -> Dictionary<String, FieldValue> {
        
        var recData = recordData
        let field = FieldValue()
        field.setType(type)
        field.setValue(value)
        recData[code] = field
        return recData
    }
}

