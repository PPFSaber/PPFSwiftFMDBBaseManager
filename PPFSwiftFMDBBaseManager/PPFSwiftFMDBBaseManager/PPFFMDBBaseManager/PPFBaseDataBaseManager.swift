//
//  PPFBaseDataBaseManager.swift
//  DTSimulate
//
//  Created by colinpian on 2020/8/4.
//  Copyright © 2020 PPF. All rights reserved.
//

import UIKit

//基于FMDB 用swift再封装的 基础数据库
private var baseDBManager : PPFBaseDataBaseManager? = nil
private let SQL_TEXT = "TEXT"
private let SQL_INTEGER = "INTEGER"
private let SQL_REAL = "REAL"
private let SQL_BLOB = "BLOB"
private let SQL_JSON = "JSONTEXT"

@objcMembers public class PPFBaseDataBaseManager: NSObject {

    // MARK: - property & public
    var db : FMDatabase
    var dbQueue : FMDatabaseQueue

    // MARK: - property & private

    private var dbPath : String



    // MARK: - life cycle
    @objc class func sharedBaseDBManager() -> PPFBaseDataBaseManager? {
        return sharedBaseDBManager(dbName: nil, dbPath: nil)
    }
    
    @objc class func sharedBaseDBManager(dbName : String? , dbPath : String?) -> PPFBaseDataBaseManager? {
     
         if baseDBManager == nil {
             baseDBManager = PPFBaseDataBaseManager.init(dbName, dbPath)
         }
         
         if baseDBManager?.db.open() == false
         {
             print("database can not open !")
             return nil
         }
         
         return baseDBManager
    }
    

    init(_ dbName : String?, _ dbPath : String?)
    {
        let name = dbName ?? "PPFDB.sqlite"
        let path  = dbPath ?? NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last!
                
        self.dbPath =  path + "/" + name

        self.dbQueue = FMDatabaseQueue.init(path: self.dbPath)!

        self.db = self.dbQueue.value(forKeyPath: "_db") as! FMDatabase
        self.db.open()
        super.init()
    }


    deinit {

    }

    // MARK: - event response


    // MARK: -  public method
    //    数据库操作
    //    在FMDB中，除查询以外的所有操作，都称为“更新” 使用executeUpdate:方法执行更新

    // 本地封装 update sql
    public func ppf_executeUpdate(_ sql : String) -> Bool
    {
        return ppf_executeUpdate(sql, withArgumentsIn: nil)
    }
        
    public func ppf_executeUpdate(_ sql : String, withArgumentsIn: [Any]?) -> Bool
    {
        //         SQL_JSON 在 sql 中其实是以 SQL_TEXT 存储的
        let sql2 = sql.replacingOccurrences(of: SQL_JSON, with: SQL_TEXT)
        return db.executeUpdate(sql2, withArgumentsIn: withArgumentsIn ?? [Any]())
    }

    @objc func ppf_executeQuery(_ sql : String) -> FMResultSet? {
        return ppf_executeQuery(sql, withArgumentsIn: nil)
    }
    
    public func ppf_executeQuery(_ sql : String, withArgumentsIn: [Any]?) -> FMResultSet?
    {
        //         SQL_JSON 在 sql 中其实是以 SQL_TEXT 存储的
        let sql2 = sql.replacingOccurrences(of: SQL_JSON, with: SQL_TEXT)
        return db.executeQuery(sql2, withArgumentsIn: withArgumentsIn ?? [Any]())
    }


    func ppf_close() -> Bool {
        return db.close()
    }

    func ppf_open() -> Bool {
        return db.open()
    }

    // MARK: - table

    // MARK: -- table create创建表

    /// 创建表
    /// - Parameters:
    ///   - tableName: 表名
    ///   - modelClass: 模型类
    /// - Returns: 是否成功
    func ppf_creatTable(tableName : String, modelClass : AnyClass) -> Bool
    {
        return ppf_creatTable(tableName : tableName, modelClass : modelClass, excludeNameArray : nil)
    }


    /// 创建表
    /// - Parameters:
    ///   - tableName: 表名
    ///   - modelClass: 模型类
    ///   - excludeNameArray: 不用添加的字段
    /// - Returns: 是否成功
    func ppf_creatTable(tableName : String, modelClass : AnyClass, excludeNameArray : [String]?) -> Bool
    {
        let dic = getModelClassKeyAndKeyTypDic(modelClass: modelClass)
        return ppf_creatTable(tableName : tableName, keyAndKeyTypeDic : dic, excludeNameArray : excludeNameArray)
    }

    /// 创建表
    /// - Parameters:
    ///   - tableName: 表名
    ///   - keyAndKeyTypeDic: key 和 key 的类型 如  ["age" : "INTEGER", "name" : "TEXT"]
    ///   - excludeNameArray: 例外 的字段（不用添加的字段）
    /// - Returns: 是否成功
    func ppf_creatTable(tableName : String, keyAndKeyTypeDic : [String:String] , excludeNameArray : [String]?) -> Bool
    {
        var fieldStr = "CREATE TABLE IF NOT EXISTS \(tableName) (pkid  INTEGER PRIMARY KEY,"

        var keyCount = 0

        for (key,keyType) in keyAndKeyTypeDic {
            
            keyCount += 1
            
            if (excludeNameArray != nil && (excludeNameArray!.contains(key))) || key == "pkid"
            {
                continue
            }
            
            if keyCount == keyAndKeyTypeDic.count
            {
                fieldStr.append(" \(key) \(keyType))")
            }
            else
            {
                fieldStr.append(" \(key) \(keyType),")
            }
        }

        return ppf_executeUpdate(fieldStr)
    }

    // MARK: --  table  删除表 drop

    /// // `删除表
    /// - Parameter tableName: 表名
    /// - Returns: 是否成功
    func ppf_deleteTable(tableName : String) -> Bool {
        return ppf_executeUpdate("DROP TABLE \(tableName)")
    }



    // `是否存在表
    func ppf_isExistTable(tableName : String) -> Bool {
        let s = ppf_executeQuery("SELECT count(*) as 'count' FROM sqlite_master WHERE type ='table' and name = \(tableName)")

        guard let set = s else { return false }

        while set.next() {
            let count = set.int(forColumn: "count")
            return count != 0
        }

        return false
    }

    // `表中共有多少条数据
    func ppf_tableItemCount(tableName : String) -> Int {
        let s = ppf_executeQuery("SELECT count(*) as 'count' FROM \(tableName)")
        guard let set = s else { return 0 }

        while set.next() {
            let count = set.int(forColumn: "count")
            return Int(count)
        }

        return 0
    }

    // `返回表中的字段名
    func ppf_columnNameArray(tableName : String) -> [String] {
        return getColumnArr(tableName : tableName, fmdb: db)
    }



    // MARK: -  insert

    // 插入 对象

    //返回保存失败的 序号
    func ppf_insert(tableName : String, modles : [NSObject]) -> [Int] {

        var errorIndex = 0
        var resultMArr = [Int]()
        for m  in modles {
            let flag = ppf_insert(tableName : tableName, model : m)
            if flag == false
            {
                resultMArr.append(errorIndex)
            }
            errorIndex += 1
        }

        return resultMArr
    }

    func ppf_insert(tableName : String,  modleDics : [[String : Any]]) -> [Int] {
        var errorIndex = 0
        var resultMArr = [Int]()
        for dic  in modleDics {
            let flag = ppf_insert(tableName : tableName,modelDic : dic)
            if flag == false
            {
                resultMArr.append(errorIndex)
            }
            errorIndex += 1
        }

        return resultMArr
    }


    func ppf_insert(tableName : String, model : NSObject ) -> Bool
    {
        return ppf_insert(tableName : tableName,modelDic : getModelKeyAndValueDic(model))
    }


    // 插入 对象的key-value字典模型
    func ppf_insert(tableName : String,modelDic : [String:Any]?) -> Bool
    {
        let columnArr = getColumnArr(tableName : tableName, fmdb: db)
        var finalStr = "INSERT INTO \(tableName) ("
        var tempStr = String()
        var argumentsArr = [Any]()
        if modelDic != nil
        {
            for (key,value) in modelDic!
            {
                if !columnArr.contains(key) || key == "pkid"
                {
                    continue
                }
                finalStr.append("\(key),")
                tempStr.append("?,")
                
                // array  dic 和 obj 转  json 字符串
                argumentsArr.append(arryAndDicValueToStringValue(value))
            }
        }
        finalStr.removeLast()
        if tempStr.count > 0 {
            tempStr.removeLast()
        }
        finalStr.append(") values (\(tempStr))")
        let flag = ppf_executeUpdate(finalStr, withArgumentsIn: argumentsArr)
        return flag
    }

    // MARK: -     update
    /**
    更改: 根据条件更改表中数据

    @param tableName 表的名称
    @param model 要更改的数据模型
    @param format 条件语句, 如:@"where name = '小李'"
    @return 是否更改成功
    */
    func ppf_updateTable(tableName : String,_ model : NSObject,_ sqlStr : String) -> Bool {
        let dic = getModelKeyAndValueDic(model)
        return ppf_updateTable(tableName : tableName,modelDic : dic, sqlStr)
    }

    /**
    更改: 根据条件更改表中数据

    @param tableName 表的名称
    @param modelDic 要更改的数据,可以是dictionary(格式:@{@"name":@"张三"})
    @param format 条件语句, 如:@"where name = '小李'"
    @return 是否更改成功
    */
    func ppf_updateTable(tableName : String,modelDic : [String : Any]?,_ sqlStr : String?) -> Bool {
        let columnArr = getColumnArr(tableName : tableName, fmdb: db)
        var finalStr = "update \(tableName) set "
        var argumentsArr = [Any]()

        if modelDic != nil
        {
            for (key,value) in modelDic!
            {
                if !columnArr.contains(key) || key == "pkid"
                {
                    continue
                }
                
                finalStr.append("\(key) = ?,")

                argumentsArr.append(arryAndDicValueToStringValue(value))
            }
        }
        finalStr.removeLast()
        if sqlStr != nil {
            finalStr.append(" " + sqlStr!)
        }
        return ppf_executeUpdate(finalStr, withArgumentsIn: argumentsArr)
    }

    // MARK: -     delete
    // 清空表
    func ppf_deleteAllDataFromTable(tableName : String) -> Bool {
        return ppf_executeUpdate("DELETE FROM \(tableName)")
    }


    // MARK: - lookup
    /**
    查找: 根据条件查找表中数据

    @param tableName 表的名称
    @param parameters 每条查找结果放入model(可以是[Person class] or @"Person" or Person实例)或dictionary中
    @param format 条件语句, 如:@"where name = '小李'",
    @return 将结果存入array,数组中的元素的类型为parameters的类型
    */
    func ppf_lookup(tableName : String, modelClass : AnyClass, whereStr : String ) -> [Any] {
        let dic = getModelClassKeyAndKeyTypDic(modelClass: modelClass)//(modelClass, clomnArr)
        return ppf_lookup(tableName : tableName, modelKeyAndKeyTypeDic : dic, modelClass: modelClass, whereStr: whereStr)
    }

    func ppf_lookup(tableName : String, modelKeyAndKeyTypeDic: [String : String], modelClass : AnyClass?, whereStr : String? ) -> [Any] {
        let clomnArr = getColumnArr(tableName : tableName, fmdb: db);
        var endDic = [String:String]()
        for key in clomnArr
        {
            endDic[key] = modelKeyAndKeyTypeDic[key]
        }

        var resultMArr = [Any]()
        let finalStr = "select * from \(tableName) " + (whereStr ?? "");

        let set = ppf_executeQuery(finalStr)
        if set != nil
        {
            while set!.next() {
                var resultDic = [String : Any]()
     
                for (key,value) in endDic
                {
                    if value == SQL_TEXT
                    {
                        if let v = set?.string(forColumn: key) {
                            resultDic[key] = v
                        }
                    }
                    else if value == SQL_INTEGER
                    {
                        if let v = set?.longLongInt(forColumn: key) {
                            resultDic[key] = v
                        }
                    }
                    else if value == SQL_REAL
                    {
                        if let v = set?.double(forColumn: key) {
                            resultDic[key] = v
                        }
                    }
                    else if value == SQL_BLOB
                    {
                        if let v = set?.data(forColumn: key) {
                            resultDic[key] = v
                        }
                    }
                    else if value == SQL_JSON
                    {
                        if let v = set?.string(forColumn: key) {
                            resultDic[key] = NSString.init(string: v).ppf_dictionaryOrArray()
                        }
                    }
                }
                
                print(set?.resultDictionary ?? "")
                
                
                if modelClass != nil
                {
                    let m = modelClass!.yy_model(withJSON: resultDic)
                    resultMArr.append(m!)
                }
                else
                {
                    resultMArr.append(resultDic)
                }
            }
        }
        
        return resultMArr
    }

    func lastInsertPrimaryKeyId(tableName : String) -> Int64 {
        let s = ppf_executeQuery("SELECT * FROM \(tableName) where pkid = (SELECT max(pkid) FROM \(tableName))")
        guard let set = s else { return 0 }
        
        while set.next() {
            return set.longLongInt(forColumn: "pkid")
        }
        return 0
    }

    func ppf_alterTable(tableName : String,modelClass : AnyClass) -> Bool {
        return ppf_alterTable(tableName : tableName, modelClass : modelClass, nil)
    }
    /**
    增加新字段, 在建表后还想新增字段,可以在原建表model或新model中新增对应属性,然后传入即可新增该字段,该操作已在事务中执行

    @param tableName 表的名称
    @param parameters 如果传Model:数据库新增字段为建表时model所没有的属性,如果传dictionary格式为@{@"newname":@"TEXT"}
    @param nameArr 不允许生成字段的属性名的数组
    @return 是否成功
    */
    func ppf_alterTable(tableName : String,modelClass : AnyClass ,_ excludeNameArray : [String]?) -> Bool {
        let keyAndKeyTypeDic = getModelClassKeyAndKeyTypDic(modelClass: modelClass)
        return ppf_alterTable(tableName : tableName, keyAndKeyTypeDic : keyAndKeyTypeDic, excludeNameArray)
    }

    /**
    增加新字段, 在建表后还想新增字段,可以在原建表model或新model中新增对应属性,然后传入即可新增该字段,该操作已在事务中执行

    @param tableName 表的名称
    @param parameters 如果传Model:数据库新增字段为建表时model所没有的属性,如果传dictionary格式为@{@"newname":@"TEXT"}
    @param nameArr 不允许生成字段的属性名的数组
    @return 是否成功
    */
    func ppf_alterTable(tableName : String,keyAndKeyTypeDic : [String:String] ,_ excludeNameArray : [String]?) -> Bool {
        var flag = false
        ppf_inTransaction { (rollback) in
            
            for (key,keyType) in keyAndKeyTypeDic
            {
                if excludeNameArray != nil && excludeNameArray!.contains(key) {
                    continue
                }
                flag = ppf_executeUpdate("ALTER TABLE \(tableName) ADD COLUMN \(key) \(keyType)")
                if (!flag) {
                    rollback.pointee = ObjCBool.init(true);
                    return;
                }
            }
        }
        
        return flag
    }
        
    /**
    将操作语句放入block中即可保证线程安全, 如:

    Person *p = [[Person alloc] init];
    p.name = @"小李";
    [jqdb jq_inDatabase:^{
    [jqdb jq_insertTable:@"users" dicOrModel:p];
    }];
    */
    func ppf_inDatabase(_ block : (()->Void)) {
        dbQueue.inDatabase { (ddb) in
            block()
        }
    }


    /*
    事务: 将操作语句放入block中可执行回滚操作(*rollback = YES;)

    Person *p = [[Person alloc] init];
    p.name = @"小李";

    for (int i=0,i < 1000,i++) {
    [jq jq_inTransaction:^(BOOL *rollback) {
    BOOL flag = [jq jq_insertTable:@"users" dicOrModel:p];
    if (!flag) {
    *rollback = YES; //只要有一次不成功,则进行回滚操作
    return;
    }
    }];
    }*/
    func ppf_inTransaction(_ block : (( _ rollback : UnsafeMutablePointer<ObjCBool> ) -> Void)) {
        dbQueue.inTransaction { (ddb, rollback) in
            block(rollback)
        }
    }


    //
    // MARK: -  override method

    // MARK: -  private method

    // runtime property
    //// 获取model的key和keyType
    private func getModelClassKeyAndKeyTypDic(modelClass : AnyClass) -> [String:String] {
        var outCount : UInt32 = 0
        //        UnsafeMutablePointer<objc_property_t>?
        let pList = class_copyPropertyList(modelClass, &outCount)!

        let count : Int = Int(outCount)
        var keyAndKeyTypeDic = [String:String]()

        for i in 0...(count - 1)
        {
            let aPro : objc_property_t = pList[i]
            let key : String? = String(utf8String: property_getName(aPro))

            let patt = property_getAttributes(aPro)
            if patt != nil
            {
                let keyTypeStr : String? = String(utf8String: patt!)
                let keyType = propertyTypeConvert(keyTypeStr)
                if key != nil && keyType != nil
                {
                    keyAndKeyTypeDic[key!] = keyType
                }
            }
        }



        free(pList)

        return keyAndKeyTypeDic
    }


    private func propertyTypeConvert(_ typeStr : String?) -> String?
    {
        guard let typeStr = typeStr else { return nil }

        var resultStr : String?
        if ( typeStr.hasPrefix("T@\"NSString\""))
        {
            resultStr = SQL_TEXT;
        } else if (typeStr.hasPrefix("T@\"NSData\"")) {
            resultStr = SQL_BLOB;
        } else if (typeStr.hasPrefix("Ti")||typeStr.hasPrefix("TI")||typeStr.hasPrefix("Ts")||typeStr.hasPrefix("TS")||typeStr.hasPrefix("T@\"NSNumber\"")||typeStr.hasPrefix("TB")||typeStr.hasPrefix("Tq")||typeStr.hasPrefix("TQ")) {
            resultStr = SQL_INTEGER;
        } else if (typeStr.hasPrefix("Tf") || typeStr.hasPrefix("Td")){
            resultStr = SQL_REAL;
        }
        else
        {
            resultStr = SQL_JSON
        }

        // TODO:
        print("typeStr  " + typeStr + " -- " + (resultStr ?? ""))
        return resultStr;
    }

        // 得到表里的字段名称
    private func getColumnArr(tableName : String, fmdb:FMDatabase) -> [String]
    {
        var mArray = [String]()
        let set = db.getTableSchema(tableName)
        if set != nil
        {
            while set!.next() {
                let str = set!.string(forColumn: "name")
                str != nil ? mArray.append(str!) : nil
            }
        }

        return mArray
    }

    // 获取model的key和value
    private func getModelKeyAndValueDic(_ model : NSObject) -> [String:Any]?
    {
        var dic = model.modelToDictionary() as? [String : Any]
        
        var outCount : UInt32 = 0
        //        UnsafeMutablePointer<objc_property_t>?
        let pList = class_copyPropertyList(model.classForCoder, &outCount)!

        let count : Int = Int(outCount)
    

        for i in 0...(count - 1)
        {
            let aPro : objc_property_t = pList[i]
            let key : String? = String(utf8String: property_getName(aPro))

            if key != nil
            {
                let data = model.value(forKey: key!) as? Data
                if data != nil {
                    dic?[key!] = data!
                }
            }
            
        }

        free(pList)
        return dic
    }
    
    
    //  转
    private func arryAndDicValueToStringValue(_ value : Any) -> Any {
                        // array  dic 和 obj 转  json 字符串
        if ((value as? Array<Any>) != nil)
        {
            let arr = value as! Array<Any>
            return NSArray.init(array: arr).yy_modelToJSONString() ?? ""
        }
        else if ((value as? Dictionary<AnyHashable,Any>) != nil)
        {
            let arr = value as! Dictionary<AnyHashable,Any>
            return NSDictionary.init(dictionary: arr).yy_modelToJSONString() ?? ""
        }
        else
        {
            return value
        }
    }
    // MARK: -   delegat

    // MARK: -   other
}
