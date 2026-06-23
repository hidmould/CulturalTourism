import { relationalStore } from '@kit.ArkData'
import { Context } from '@kit.AbilityKit'

const DATABASE_NAME = 'CulturalTourism.db'
const STORE_CONFIG: relationalStore.StoreConfig = {
  name: DATABASE_NAME,
  securityLevel: relationalStore.SecurityLevel.S1
}

/**
 * 关系型数据库帮助类
 * 管理所有业务表的创建和升级
 */
export class DatabaseHelper {
  private static instance: DatabaseHelper
  private rdbStore: relationalStore.RdbStore | null = null

  static getInstance(): DatabaseHelper {
    if (!DatabaseHelper.instance) {
      DatabaseHelper.instance = new DatabaseHelper()
    }
    return DatabaseHelper.instance
  }

  async init(context: Context): Promise<void> {
    if (this.rdbStore) {
      return
    }
    this.rdbStore = await relationalStore.getRdbStore(context, STORE_CONFIG)
    await this.createTables()
  }

  private async createTables(): Promise<void> {
    const sqls: string[] = [
      // 用户表
      `CREATE TABLE IF NOT EXISTS user (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        phone TEXT NOT NULL,
        nickname TEXT,
        avatar TEXT,
        travel_preference TEXT DEFAULT '综合',
        city TEXT,
        token TEXT,
        password TEXT,
        remember_password INTEGER DEFAULT 0,
        create_time INTEGER
      )`,

      // 对话表
      `CREATE TABLE IF NOT EXISTS chat (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        summary TEXT,
        model_type TEXT DEFAULT 'general',
        last_message_time INTEGER,
        create_time INTEGER,
        is_deleted INTEGER DEFAULT 0
      )`,

      // 消息表
      `CREATE TABLE IF NOT EXISTS message (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chat_id INTEGER NOT NULL,
        role TEXT NOT NULL,
        content TEXT,
        message_type TEXT DEFAULT 'text',
        structured_data TEXT,
        is_favorite INTEGER DEFAULT 0,
        create_time INTEGER,
        FOREIGN KEY (chat_id) REFERENCES chat(id)
      )`,

      // 景点表
      `CREATE TABLE IF NOT EXISTS scenic_spot (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT,
        city TEXT,
        description TEXT,
        image_url TEXT,
        rating REAL DEFAULT 0,
        tags TEXT,
        is_favorite INTEGER DEFAULT 0,
        create_time INTEGER
      )`,

      // 收藏表
      `CREATE TABLE IF NOT EXISTS favorite (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        message_id INTEGER,
        chat_id INTEGER,
        content TEXT,
        favorite_type TEXT,
        create_time INTEGER
      )`,

      // 行程表
      `CREATE TABLE IF NOT EXISTS trip (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        title TEXT,
        destination TEXT,
        days INTEGER DEFAULT 0,
        start_date TEXT,
        schedule_json TEXT,
        is_generated INTEGER DEFAULT 0,
        create_time INTEGER,
        update_time INTEGER
      )`
    ]

    for (const sql of sqls) {
      await this.rdbStore!.executeSql(sql)
    }
  }

  getStore(): relationalStore.RdbStore | null {
    return this.rdbStore
  }

  /**
   * 通用插入
   */
  async insert(table: string, values: relationalStore.ValuesBucket): Promise<number> {
    return await this.rdbStore!.insert(table, values)
  }

  /**
   * 通用更新
   */
  async update(table: string, values: relationalStore.ValuesBucket,
    predicates: relationalStore.RdbPredicates): Promise<number> {
    return await this.rdbStore!.update(values, predicates)
  }

  /**
   * 通用删除
   */
  async delete(predicates: relationalStore.RdbPredicates): Promise<number> {
    return await this.rdbStore!.delete(predicates)
  }

  /**
   * 通用查询
   */
  async query(predicates: relationalStore.RdbPredicates,
    columns?: string[]): Promise<relationalStore.ResultSet> {
    return await this.rdbStore!.query(predicates, columns)
  }

  /**
   * 执行原始SQL
   */
  async executeSql(sql: string, bindArgs?: Array<relationalStore.ValueType>): Promise<void> {
    await this.rdbStore!.executeSql(sql, bindArgs)
  }
}