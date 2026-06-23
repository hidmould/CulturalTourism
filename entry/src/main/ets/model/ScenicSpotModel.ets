/**
 * 景点数据模型
 */
export class ScenicSpotModel {
  id: number = 0
  name: string = ''
  category: string = ''           // 自然风光/历史人文/网红打卡
  city: string = ''
  description: string = ''
  imageUrl: string = ''
  rating: number = 0
  tags: string = ''               // 逗号分隔的标签
  isFavorite: number = 0
  createTime: number = Date.now()
}

/**
 * 景点分类
 */
export const SPOT_CATEGORIES: string[] = ['自然风光', '历史人文', '网红打卡']