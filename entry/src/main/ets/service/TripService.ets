/**
 * 行程服务
 */
import { DatabaseHelper } from '../database/DatabaseHelper'
import { TripItem } from '../model/Models'
import { relationalStore } from '@kit.ArkData'
import { TABLE_TRIP } from '../common/Constants'

export class TripService {
  private static instance: TripService

  static getInstance(): TripService {
    if (!TripService.instance) {
      TripService.instance = new TripService()
    }
    return TripService.instance
  }

  /**
   * 创建行程
   */
  async createTrip(title: string, city: string, duration: number, content: string): Promise<number> {
    let store = await DatabaseHelper.getInstance().getStore()

    // 获取当前最大 sortOrder
    let maxOrder = await this.getMaxSortOrder()

    let valueBucket: relationalStore.ValuesBucket = {
      'title': title,
      'day_index': 0,
      'sort_order': maxOrder + 1,
      'content': content,
      'city': city,
      'duration': duration,
      'create_time': Date.now(),
      'update_time': Date.now()
    }
    try {
      return await store.insert(TABLE_TRIP, valueBucket)
    } catch (err) {
      console.error('[TripService] 插入失败，重建表后重试: ' + JSON.stringify(err))
      try {
        await store.executeSql(`DROP TABLE IF EXISTS ${TABLE_TRIP}`)
      } catch (e) {
        // 忽略
      }
      await store.executeSql(`CREATE TABLE IF NOT EXISTS ${TABLE_TRIP} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT DEFAULT '',
        day_index INTEGER DEFAULT 0,
        sort_order INTEGER DEFAULT 0,
        content TEXT DEFAULT '',
        city TEXT DEFAULT '',
        duration INTEGER DEFAULT 0,
        create_time INTEGER DEFAULT 0,
        update_time INTEGER DEFAULT 0
      )`)
      return await store.insert(TABLE_TRIP, valueBucket)
    }
  }

  /**
   * 更新行程
   */
  async updateTrip(id: number, updates: Record<string, number | string | boolean>): Promise<void> {
    let store = await DatabaseHelper.getInstance().getStore()
    let valueBucket: relationalStore.ValuesBucket = {}
    let keys = Object.keys(updates)
    for (let i = 0; i < keys.length; i++) {
      let key = keys[i]
      valueBucket[key] = updates[key]
    }
    valueBucket['update_time'] = Date.now()

    let predicates = new relationalStore.RdbPredicates(TABLE_TRIP)
    predicates.equalTo('id', id)
    await store.update(valueBucket, predicates)
  }

  /**
   * 删除行程
   */
  async deleteTrip(id: number): Promise<void> {
    let store = await DatabaseHelper.getInstance().getStore()
    let predicates = new relationalStore.RdbPredicates(TABLE_TRIP)
    predicates.equalTo('id', id)
    await store.delete(predicates)
  }

  /**
   * 获取所有行程（按 sortOrder 排序）
   */
  async getAllTrips(): Promise<TripItem[]> {
    let store = await DatabaseHelper.getInstance().getStore()
    let predicates = new relationalStore.RdbPredicates(TABLE_TRIP)
    predicates.orderByAsc('sort_order')
    let resultSet = await store.query(predicates)

    let list: TripItem[] = []
    while (resultSet.goToNextRow()) {
      list.push(this.parseTrip(resultSet))
    }
    resultSet.close()
    return list
  }

  /**
   * 获取单个行程
   */
  async getTripById(id: number): Promise<TripItem | null> {
    let store = await DatabaseHelper.getInstance().getStore()
    let predicates = new relationalStore.RdbPredicates(TABLE_TRIP)
    predicates.equalTo('id', id)
    let resultSet = await store.query(predicates)

    let trip: TripItem | null = null
    if (resultSet.goToFirstRow()) {
      trip = this.parseTrip(resultSet)
    }
    resultSet.close()
    return trip
  }

  /**
   * 交换两个行程的排序
   */
  async swapOrder(id1: number, id2: number): Promise<void> {
    let store = await DatabaseHelper.getInstance().getStore()
    let trip1 = await this.getTripById(id1)
    let trip2 = await this.getTripById(id2)

    if (trip1 && trip2) {
      let temp = trip1.sortOrder
      await this.updateTrip(id1, { 'sort_order': trip2.sortOrder })
      await this.updateTrip(id2, { 'sort_order': temp })
    }
  }

  private async getMaxSortOrder(): Promise<number> {
    let store = await DatabaseHelper.getInstance().getStore()
    try {
      let sql = `SELECT MAX(sort_order) as max_order FROM ${TABLE_TRIP}`
      let resultSet = await store.querySql(sql)
      let maxOrder = 0
      if (resultSet.goToFirstRow()) {
        let colIndex = resultSet.getColumnIndex('max_order')
        if (colIndex >= 0) {
          maxOrder = resultSet.getLong(colIndex)
        }
      }
      resultSet.close()
      return maxOrder
    } catch (err) {
      console.error('[TripService] getMaxSortOrder 失败: ' + JSON.stringify(err))
      return 0
    }
  }

  private parseTrip(resultSet: relationalStore.ResultSet): TripItem {
    let trip = new TripItem()
    trip.id = resultSet.getLong(resultSet.getColumnIndex('id'))
    trip.title = resultSet.getString(resultSet.getColumnIndex('title'))
    trip.dayIndex = resultSet.getLong(resultSet.getColumnIndex('day_index'))
    trip.sortOrder = resultSet.getLong(resultSet.getColumnIndex('sort_order'))
    trip.content = resultSet.getString(resultSet.getColumnIndex('content'))
    trip.city = resultSet.getString(resultSet.getColumnIndex('city'))
    trip.duration = resultSet.getLong(resultSet.getColumnIndex('duration'))
    trip.createTime = resultSet.getLong(resultSet.getColumnIndex('create_time'))
    trip.updateTime = resultSet.getLong(resultSet.getColumnIndex('update_time'))
    return trip
  }
}