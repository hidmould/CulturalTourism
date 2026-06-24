/**
 * 关系型数据库（RDB）管理
 */
import { relationalStore } from '@kit.ArkData'
import { BusinessError } from '@kit.BasicServicesKit'
import { common } from '@kit.AbilityKit'
import {
  DB_NAME,
  DB_VERSION,
  TABLE_USER,
  TABLE_CONVERSATION,
  TABLE_MESSAGE,
  TABLE_FAVORITE,
  TABLE_TRIP,
  TABLE_SCENIC_SPOT
} from '../common/Constants'

export class DatabaseHelper {
  private static instance: DatabaseHelper
  private store: relationalStore.RdbStore | null = null
  private context: common.UIAbilityContext | null = null

  static getInstance(): DatabaseHelper {
    if (!DatabaseHelper.instance) {
      DatabaseHelper.instance = new DatabaseHelper()
    }
    return DatabaseHelper.instance
  }

  init(context: common.UIAbilityContext): void {
    this.context = context
  }

  async getStore(): Promise<relationalStore.RdbStore> {
    if (this.store) {
      return this.store
    }
    if (!this.context) {
      throw new Error('DatabaseHelper 未初始化，请先调用 init()')
    }

    const config: relationalStore.StoreConfig = {
      name: DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1
    }

    try {
      this.store = await relationalStore.getRdbStore(this.context, config)
      await this.createTables()
      await this.initScenicSpots()
      return this.store
    } catch (err) {
      let error = err as BusinessError
      throw new Error(`数据库初始化失败: ${error.message}`)
    }
  }

  private async createTables(): Promise<void> {
    if (!this.store) return

    // 用户表
    const createUserTable = `
      CREATE TABLE IF NOT EXISTS ${TABLE_USER} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        phone TEXT NOT NULL,
        nickname TEXT DEFAULT '',
        avatar TEXT DEFAULT '',
        travel_preference TEXT DEFAULT '',
        resident_city TEXT DEFAULT '',
        create_time INTEGER DEFAULT 0
      )`

    // 对话表
    const createConversationTable = `
      CREATE TABLE IF NOT EXISTS ${TABLE_CONVERSATION} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT DEFAULT '',
        summary TEXT DEFAULT '',
        model_type TEXT DEFAULT '',
        last_message_time INTEGER DEFAULT 0,
        create_time INTEGER DEFAULT 0,
        message_count INTEGER DEFAULT 0
      )`

    // 消息表
    const createMessageTable = `
      CREATE TABLE IF NOT EXISTS ${TABLE_MESSAGE} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        conversation_id INTEGER NOT NULL,
        role TEXT NOT NULL,
        content TEXT DEFAULT '',
        create_time INTEGER DEFAULT 0
      )`

    // 收藏表
    const createFavoriteTable = `
      CREATE TABLE IF NOT EXISTS ${TABLE_FAVORITE} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        message_id INTEGER DEFAULT 0,
        conversation_id INTEGER DEFAULT 0,
        content TEXT DEFAULT '',
        type TEXT DEFAULT '',
        create_time INTEGER DEFAULT 0
      )`

    // 行程表
    const createTripTable = `
      CREATE TABLE IF NOT EXISTS ${TABLE_TRIP} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT DEFAULT '',
        day_index INTEGER DEFAULT 0,
        sort_order INTEGER DEFAULT 0,
        content TEXT DEFAULT '',
        city TEXT DEFAULT '',
        duration INTEGER DEFAULT 0,
        create_time INTEGER DEFAULT 0,
        update_time INTEGER DEFAULT 0
      )`

    // 景点表
    const createScenicTable = `
      CREATE TABLE IF NOT EXISTS ${TABLE_SCENIC_SPOT} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT DEFAULT '',
        city TEXT DEFAULT '',
        description TEXT DEFAULT '',
        image_url TEXT DEFAULT '',
        address TEXT DEFAULT '',
        rating REAL DEFAULT 0,
        create_time INTEGER DEFAULT 0
      )`

    await this.store.executeSql(createUserTable)
    await this.store.executeSql(createConversationTable)
    await this.store.executeSql(createMessageTable)
    await this.store.executeSql(createFavoriteTable)
    await this.store.executeSql(createTripTable)
    await this.store.executeSql(createScenicTable)
  }

  /**
   * 初始化预置景点数据
   */
  private async initScenicSpots(): Promise<void> {
    if (!this.store) return

    // 检查是否已有数据
    let predicates = new relationalStore.RdbPredicates(TABLE_SCENIC_SPOT)
    let resultSet = await this.store.query(predicates)
    if (resultSet.rowCount > 0) {
      resultSet.close()
      return
    }
    resultSet.close()

    // 预置景点数据
    const spots = [
      ['故宫', '历史人文', '北京', '明清两代的皇家宫殿，世界文化遗产', '', '北京市东城区景山前街4号', 4.9],
      ['长城', '历史人文', '北京', '世界文化遗产，中国古代军事防御工程', '', '北京市延庆区', 4.8],
      ['西湖', '自然风光', '杭州', '中国十大风景名胜之一，以湖光山色著称', '', '杭州市西湖区', 4.8],
      ['黄山', '自然风光', '黄山', '世界文化与自然双重遗产，以奇松怪石云海闻名', '', '安徽省黄山市', 4.9],
      ['外滩', '网红打卡', '上海', '上海标志性景点，黄浦江畔的万国建筑博览群', '', '上海市黄浦区', 4.7],
      ['洪崖洞', '网红打卡', '重庆', '重庆网红地标，依山而建的吊脚楼建筑群', '', '重庆市渝中区', 4.6],
      ['宽窄巷子', '美食街区', '成都', '成都历史文化街区，汇集四川美食与茶馆文化', '', '成都市青羊区', 4.7],
      ['回民街', '美食街区', '西安', '西安著名美食街，汇聚西北特色小吃', '', '西安市莲湖区', 4.6],
      ['张家界', '自然风光', '张家界', '世界自然遗产，独特的石英砂岩峰林地貌', '', '湖南省张家界市', 4.8],
      ['兵马俑', '历史人文', '西安', '世界第八大奇迹，秦始皇陵的陪葬坑', '', '西安市临潼区', 4.9],
      ['鼓浪屿', '网红打卡', '厦门', '海上花园，世界文化遗产', '', '厦门市思明区', 4.7],
      ['夫子庙', '美食街区', '南京', '南京历史文化地标，秦淮河畔美食聚集地', '', '南京市秦淮区', 4.5]
    ]

    for (let spot of spots) {
      let valueBucket: relationalStore.ValuesBucket = {
        'name': spot[0],
        'category': spot[1],
        'city': spot[2],
        'description': spot[3],
        'image_url': spot[4],
        'address': spot[5],
        'rating': spot[6],
        'create_time': Date.now()
      }
      await this.store.insert(TABLE_SCENIC_SPOT, valueBucket)
    }
  }
}