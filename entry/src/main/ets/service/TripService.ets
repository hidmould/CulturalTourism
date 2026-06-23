import { relationalStore } from '@kit.ArkData'
import { DatabaseHelper } from '../database/DatabaseHelper'
import { PreferencesHelper } from '../preferences/PreferencesHelper'
import { TripModel, ScheduleItem, ScheduleDetail } from '../model/TripModel'

/**
 * 行程JSON解析结果
 */
interface ScheduleJson {
  schedule?: ScheduleItem[]
}

/**
 * 行程服务
 * 管理用户的行程清单
 */
export class TripService {
  private static instance: TripService
  private dbHelper: DatabaseHelper = DatabaseHelper.getInstance()
  private prefsHelper: PreferencesHelper = PreferencesHelper.getInstance()

  static getInstance(): TripService {
    if (!TripService.instance) {
      TripService.instance = new TripService()
    }
    return TripService.instance
  }

  /**
   * 获取所有行程
   */
  async getTrips(): Promise<TripModel[]> {
    const userId = await this.prefsHelper.getUserId()
    const predicates = new relationalStore.RdbPredicates('trip')
    predicates.equalTo('user_id', userId)
    predicates.orderByDesc('create_time')
    const resultSet = await this.dbHelper.query(predicates)

    const trips: TripModel[] = []
    while (resultSet.goToNextRow()) {
      const trip = new TripModel()
      trip.id = resultSet.getLong(resultSet.getColumnIndex('id'))
      trip.userId = resultSet.getLong(resultSet.getColumnIndex('user_id'))
      trip.title = resultSet.getString(resultSet.getColumnIndex('title'))
      trip.destination = resultSet.getString(resultSet.getColumnIndex('destination'))
      trip.days = resultSet.getLong(resultSet.getColumnIndex('days'))
      trip.startDate = resultSet.getString(resultSet.getColumnIndex('start_date'))
      trip.scheduleJson = resultSet.getString(resultSet.getColumnIndex('schedule_json'))
      trip.isGenerated = resultSet.getLong(resultSet.getColumnIndex('is_generated'))
      trip.createTime = resultSet.getLong(resultSet.getColumnIndex('create_time'))
      trip.updateTime = resultSet.getLong(resultSet.getColumnIndex('update_time'))
      trips.push(trip)
    }
    resultSet.close()
    return trips
  }

  /**
   * 获取单个行程详情
   */
  async getTripById(tripId: number): Promise<TripModel | null> {
    const predicates = new relationalStore.RdbPredicates('trip')
    predicates.equalTo('id', tripId)
    const resultSet = await this.dbHelper.query(predicates)

    if (resultSet.rowCount === 0) {
      resultSet.close()
      return null
    }

    resultSet.goToFirstRow()
    const trip = new TripModel()
    trip.id = resultSet.getLong(resultSet.getColumnIndex('id'))
    trip.userId = resultSet.getLong(resultSet.getColumnIndex('user_id'))
    trip.title = resultSet.getString(resultSet.getColumnIndex('title'))
    trip.destination = resultSet.getString(resultSet.getColumnIndex('destination'))
    trip.days = resultSet.getLong(resultSet.getColumnIndex('days'))
    trip.startDate = resultSet.getString(resultSet.getColumnIndex('start_date'))
    trip.scheduleJson = resultSet.getString(resultSet.getColumnIndex('schedule_json'))
    trip.isGenerated = resultSet.getLong(resultSet.getColumnIndex('is_generated'))
    trip.createTime = resultSet.getLong(resultSet.getColumnIndex('create_time'))
    trip.updateTime = resultSet.getLong(resultSet.getColumnIndex('update_time'))
    resultSet.close()

    return trip
  }

  /**
   * 解析行程JSON为日程数组
   */
  parseSchedule(trip: TripModel): ScheduleItem[] {
    if (!trip.scheduleJson) {
      return []
    }
    try {
      const schedule: ScheduleJson = JSON.parse(trip.scheduleJson) as ScheduleJson
      if (schedule.schedule) {
        return schedule.schedule
      }
      return []
    } catch (_) {
      return []
    }
  }

  /**
   * 保存行程
   */
  async saveTrip(trip: TripModel): Promise<number> {
    const userId = await this.prefsHelper.getUserId()
    const values: relationalStore.ValuesBucket = {
      'user_id': userId,
      'title': trip.title,
      'destination': trip.destination,
      'days': trip.days,
      'start_date': trip.startDate,
      'schedule_json': trip.scheduleJson,
      'is_generated': trip.isGenerated,
      'create_time': trip.createTime || Date.now(),
      'update_time': Date.now()
    }
    return await this.dbHelper.insert('trip', values)
  }

  /**
   * 更新行程
   */
  async updateTrip(trip: TripModel): Promise<void> {
    const values: relationalStore.ValuesBucket = {
      'title': trip.title,
      'destination': trip.destination,
      'days': trip.days,
      'start_date': trip.startDate,
      'schedule_json': trip.scheduleJson,
      'update_time': Date.now()
    }
    const predicates = new relationalStore.RdbPredicates('trip')
    predicates.equalTo('id', trip.id)
    await this.dbHelper.update('trip', values, predicates)
  }

  /**
   * 删除行程
   */
  async deleteTrip(tripId: number): Promise<void> {
    const predicates = new relationalStore.RdbPredicates('trip')
    predicates.equalTo('id', tripId)
    await this.dbHelper.delete(predicates)
  }

  /**
   * 从AI生成的JSON创建行程
   */
  async createTripFromJson(
    title: string,
    destination: string,
    days: number,
    scheduleJson: string
  ): Promise<number> {
    const trip = new TripModel()
    trip.title = title
    trip.destination = destination
    trip.days = days
    trip.scheduleJson = scheduleJson
    trip.isGenerated = 1
    return await this.saveTrip(trip)
  }
}