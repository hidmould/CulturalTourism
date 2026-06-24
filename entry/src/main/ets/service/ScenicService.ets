/**
 * 景点服务
 */
import { DatabaseHelper } from '../database/DatabaseHelper'
import { ScenicSpot } from '../model/Models'
import { relationalStore } from '@kit.ArkData'
import { TABLE_SCENIC_SPOT, ScenicCategory } from '../common/Constants'

export class ScenicService {
  private static instance: ScenicService

  static getInstance(): ScenicService {
    if (!ScenicService.instance) {
      ScenicService.instance = new ScenicService()
    }
    return ScenicService.instance
  }

  /**
   * 获取所有景点
   */
  async getAllSpots(): Promise<ScenicSpot[]> {
    let store = await DatabaseHelper.getInstance().getStore()
    let predicates = new relationalStore.RdbPredicates(TABLE_SCENIC_SPOT)
    predicates.orderByDesc('rating')
    let resultSet = await store.query(predicates)

    console.info(`[ScenicService] 查询结果 rowCount: ${resultSet.rowCount}`)

    let list: ScenicSpot[] = []
    while (resultSet.goToNextRow()) {
      list.push(this.parseSpot(resultSet))
    }
    resultSet.close()
    console.info(`[ScenicService] 解析景点数量: ${list.length}`)
    return list
  }

  /**
   * 按分类获取景点
   */
  async getSpotsByCategory(category: string): Promise<ScenicSpot[]> {
    let store = await DatabaseHelper.getInstance().getStore()
    let predicates = new relationalStore.RdbPredicates(TABLE_SCENIC_SPOT)
    predicates.equalTo('category', category)
    predicates.orderByDesc('rating')
    let resultSet = await store.query(predicates)

    let list: ScenicSpot[] = []
    while (resultSet.goToNextRow()) {
      list.push(this.parseSpot(resultSet))
    }
    resultSet.close()
    return list
  }

  /**
   * 按城市获取景点
   */
  async getSpotsByCity(city: string): Promise<ScenicSpot[]> {
    let store = await DatabaseHelper.getInstance().getStore()
    let predicates = new relationalStore.RdbPredicates(TABLE_SCENIC_SPOT)
    predicates.equalTo('city', city)
    predicates.orderByDesc('rating')
    let resultSet = await store.query(predicates)

    let list: ScenicSpot[] = []
    while (resultSet.goToNextRow()) {
      list.push(this.parseSpot(resultSet))
    }
    resultSet.close()
    return list
  }

  /**
   * 获取分类列表
   */
  getCategories(): string[] {
    return [
      ScenicCategory.NATURE,
      ScenicCategory.HISTORY,
      ScenicCategory.POPULAR,
      ScenicCategory.FOOD
    ]
  }

  private parseSpot(resultSet: relationalStore.ResultSet): ScenicSpot {
    let spot = new ScenicSpot()
    spot.id = resultSet.getLong(resultSet.getColumnIndex('id'))
    spot.name = resultSet.getString(resultSet.getColumnIndex('name'))
    spot.category = resultSet.getString(resultSet.getColumnIndex('category'))
    spot.city = resultSet.getString(resultSet.getColumnIndex('city'))
    spot.description = resultSet.getString(resultSet.getColumnIndex('description'))
    spot.imageUrl = resultSet.getString(resultSet.getColumnIndex('image_url'))
    spot.address = resultSet.getString(resultSet.getColumnIndex('address'))
    spot.rating = resultSet.getDouble(resultSet.getColumnIndex('rating'))
    spot.createTime = resultSet.getLong(resultSet.getColumnIndex('create_time'))
    return spot
  }
}