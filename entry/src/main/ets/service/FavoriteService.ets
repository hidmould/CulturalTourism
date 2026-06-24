/**
 * 收藏服务
 */
import { DatabaseHelper } from '../database/DatabaseHelper'
import { Favorite } from '../model/Models'
import { relationalStore } from '@kit.ArkData'
import { TABLE_FAVORITE } from '../common/Constants'

export class FavoriteService {
  private static instance: FavoriteService

  static getInstance(): FavoriteService {
    if (!FavoriteService.instance) {
      FavoriteService.instance = new FavoriteService()
    }
    return FavoriteService.instance
  }

  /**
   * 添加收藏
   */
  async addFavorite(messageId: number, conversationId: number, content: string, type: string): Promise<number> {
    let store = await DatabaseHelper.getInstance().getStore()
    let valueBucket: relationalStore.ValuesBucket = {
      'message_id': messageId,
      'conversation_id': conversationId,
      'content': content,
      'type': type,
      'create_time': Date.now()
    }
    return await store.insert(TABLE_FAVORITE, valueBucket)
  }

  /**
   * 删除收藏
   */
  async deleteFavorite(id: number): Promise<void> {
    let store = await DatabaseHelper.getInstance().getStore()
    let predicates = new relationalStore.RdbPredicates(TABLE_FAVORITE)
    predicates.equalTo('id', id)
    await store.delete(predicates)
  }

  /**
   * 获取所有收藏
   */
  async getAllFavorites(): Promise<Favorite[]> {
    let store = await DatabaseHelper.getInstance().getStore()
    let predicates = new relationalStore.RdbPredicates(TABLE_FAVORITE)
    predicates.orderByDesc('create_time')
    let resultSet = await store.query(predicates)

    let list: Favorite[] = []
    while (resultSet.goToNextRow()) {
      list.push(this.parseFavorite(resultSet))
    }
    resultSet.close()
    return list
  }

  /**
   * 按类型获取收藏
   */
  async getFavoritesByType(type: string): Promise<Favorite[]> {
    let store = await DatabaseHelper.getInstance().getStore()
    let predicates = new relationalStore.RdbPredicates(TABLE_FAVORITE)
    predicates.equalTo('type', type)
    predicates.orderByDesc('create_time')
    let resultSet = await store.query(predicates)

    let list: Favorite[] = []
    while (resultSet.goToNextRow()) {
      list.push(this.parseFavorite(resultSet))
    }
    resultSet.close()
    return list
  }

  private parseFavorite(resultSet: relationalStore.ResultSet): Favorite {
    let fav = new Favorite()
    fav.id = resultSet.getLong(resultSet.getColumnIndex('id'))
    fav.messageId = resultSet.getLong(resultSet.getColumnIndex('message_id'))
    fav.conversationId = resultSet.getLong(resultSet.getColumnIndex('conversation_id'))
    fav.content = resultSet.getString(resultSet.getColumnIndex('content'))
    fav.type = resultSet.getString(resultSet.getColumnIndex('type'))
    fav.createTime = resultSet.getLong(resultSet.getColumnIndex('create_time'))
    return fav
  }
}