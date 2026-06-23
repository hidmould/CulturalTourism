import { relationalStore } from '@kit.ArkData'
import { DatabaseHelper } from '../database/DatabaseHelper'
import { PreferencesHelper } from '../preferences/PreferencesHelper'
import { FavoriteModel } from '../model/FavoriteModel'

/**
 * 收藏服务
 * 管理用户收藏的对话内容
 */
export class FavoriteService {
  private static instance: FavoriteService
  private dbHelper: DatabaseHelper = DatabaseHelper.getInstance()
  private prefsHelper: PreferencesHelper = PreferencesHelper.getInstance()

  static getInstance(): FavoriteService {
    if (!FavoriteService.instance) {
      FavoriteService.instance = new FavoriteService()
    }
    return FavoriteService.instance
  }

  /**
   * 添加收藏
   */
  async addFavorite(
    messageId: number,
    chatId: number,
    content: string,
    favoriteType: string
  ): Promise<number> {
    const userId = await this.prefsHelper.getUserId()
    const values: relationalStore.ValuesBucket = {
      'user_id': userId,
      'message_id': messageId,
      'chat_id': chatId,
      'content': content,
      'favorite_type': favoriteType,
      'create_time': Date.now()
    }
    return await this.dbHelper.insert('favorite', values)
  }

  /**
   * 取消收藏
   */
  async removeFavorite(favoriteId: number): Promise<void> {
    const predicates = new relationalStore.RdbPredicates('favorite')
    predicates.equalTo('id', favoriteId)
    await this.dbHelper.delete(predicates)
  }

  /**
   * 获取收藏列表
   */
  async getFavorites(): Promise<FavoriteModel[]> {
    const userId = await this.prefsHelper.getUserId()
    const predicates = new relationalStore.RdbPredicates('favorite')
    predicates.equalTo('user_id', userId)
    predicates.orderByDesc('create_time')
    const resultSet = await this.dbHelper.query(predicates)

    const favorites: FavoriteModel[] = []
    while (resultSet.goToNextRow()) {
      const fav = new FavoriteModel()
      fav.id = resultSet.getLong(resultSet.getColumnIndex('id'))
      fav.userId = resultSet.getLong(resultSet.getColumnIndex('user_id'))
      fav.messageId = resultSet.getLong(resultSet.getColumnIndex('message_id'))
      fav.chatId = resultSet.getLong(resultSet.getColumnIndex('chat_id'))
      fav.content = resultSet.getString(resultSet.getColumnIndex('content'))
      fav.favoriteType = resultSet.getString(resultSet.getColumnIndex('favorite_type'))
      fav.createTime = resultSet.getLong(resultSet.getColumnIndex('create_time'))
      favorites.push(fav)
    }
    resultSet.close()
    return favorites
  }

  /**
   * 检查消息是否已收藏
   */
  async isFavorite(messageId: number): Promise<boolean> {
    const userId = await this.prefsHelper.getUserId()
    const predicates = new relationalStore.RdbPredicates('favorite')
    predicates.equalTo('user_id', userId)
    predicates.equalTo('message_id', messageId)
    const resultSet = await this.dbHelper.query(predicates)
    const count = resultSet.rowCount
    resultSet.close()
    return count > 0
  }
}