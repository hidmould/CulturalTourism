/**
 * 收藏数据模型
 */
export class FavoriteModel {
  id: number = 0
  userId: number = 0
  messageId: number = 0           // 关联的消息ID
  chatId: number = 0
  content: string = ''            // 收藏内容摘要
  favoriteType: string = ''       // 'spot' | 'route' | 'food' | 'other'
  createTime: number = Date.now()
}