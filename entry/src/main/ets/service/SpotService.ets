import { relationalStore } from '@kit.ArkData'
import { DatabaseHelper } from '../database/DatabaseHelper'
import { ScenicSpotModel, SPOT_CATEGORIES } from '../model/ScenicSpotModel'

/**
 * 景点服务
 * 管理景点数据的浏览和初始化
 */
export class SpotService {
  private static instance: SpotService
  private dbHelper: DatabaseHelper = DatabaseHelper.getInstance()

  static getInstance(): SpotService {
    if (!SpotService.instance) {
      SpotService.instance = new SpotService()
    }
    return SpotService.instance
  }

  /**
   * 初始化预置景点数据（仅首次运行）
   */
  async initPresetSpots(): Promise<void> {
    const predicates = new relationalStore.RdbPredicates('scenic_spot')
    const resultSet = await this.dbHelper.query(predicates)
    if (resultSet.rowCount > 0) {
      resultSet.close()
      return
    }
    resultSet.close()

    const presetSpots: Array<relationalStore.ValuesBucket> = [
      { name: '故宫博物院', category: '历史人文', city: '北京', description: '明清两代皇家宫殿，世界文化遗产', image_url: '', rating: 4.9, tags: '世界遗产,皇家宫殿,博物馆', create_time: Date.now() },
      { name: '长城', category: '历史人文', city: '北京', description: '世界七大奇迹之一，中国象征', image_url: '', rating: 4.8, tags: '世界遗产,古代建筑,徒步', create_time: Date.now() },
      { name: '西湖', category: '自然风光', city: '杭州', description: '淡妆浓抹总相宜的人间天堂', image_url: '', rating: 4.8, tags: '湖泊,免费,骑行', create_time: Date.now() },
      { name: '九寨沟', category: '自然风光', city: '阿坝', description: '童话世界，人间仙境', image_url: '', rating: 4.9, tags: '自然风光,彩林,瀑布', create_time: Date.now() },
      { name: '兵马俑', category: '历史人文', city: '西安', description: '世界第八大奇迹', image_url: '', rating: 4.8, tags: '世界遗产,考古,博物馆', create_time: Date.now() },
      { name: '外滩', category: '网红打卡', city: '上海', description: '万国建筑博览群，都市夜景', image_url: '', rating: 4.7, tags: '夜景,黄浦江,建筑', create_time: Date.now() },
      { name: '洪崖洞', category: '网红打卡', city: '重庆', description: '现实版千与千寻', image_url: '', rating: 4.7, tags: '夜景,吊脚楼,美食', create_time: Date.now() },
      { name: '张家界', category: '自然风光', city: '张家界', description: '阿凡达取景地，石英砂岩峰林', image_url: '', rating: 4.8, tags: '自然风光,山峰,玻璃栈道', create_time: Date.now() },
      { name: '布达拉宫', category: '历史人文', city: '拉萨', description: '世界上海拔最高的宫殿', image_url: '', rating: 4.9, tags: '世界遗产,藏文化,宗教', create_time: Date.now() },
      { name: '三亚湾', category: '自然风光', city: '三亚', description: '椰风海韵，热带天堂', image_url: '', rating: 4.6, tags: '海滩,热带,度假', create_time: Date.now() },
      { name: '大唐不夜城', category: '网红打卡', city: '西安', description: '盛唐文化主题街区', image_url: '', rating: 4.7, tags: '夜景,美食,演艺', create_time: Date.now() },
      { name: '成都大熊猫基地', category: '自然风光', city: '成都', description: '近距离接触国宝大熊猫', image_url: '', rating: 4.8, tags: '大熊猫,亲子,自然', create_time: Date.now() }
    ]

    for (const spot of presetSpots) {
      await this.dbHelper.insert('scenic_spot', spot)
    }
  }

  /**
   * 获取所有景点分类
   */
  getCategories(): string[] {
    return SPOT_CATEGORIES
  }

  /**
   * 按分类获取景点列表
   */
  async getSpotsByCategory(category: string): Promise<ScenicSpotModel[]> {
    const predicates = new relationalStore.RdbPredicates('scenic_spot')
    if (category) {
      predicates.equalTo('category', category)
    }
    predicates.orderByDesc('rating')
    const resultSet = await this.dbHelper.query(predicates)

    return this.parseSpotResults(resultSet)
  }

  /**
   * 搜索景点
   */
  async searchSpots(keyword: string): Promise<ScenicSpotModel[]> {
    const predicates = new relationalStore.RdbPredicates('scenic_spot')
    predicates.like('name', `%${keyword}%`)
    predicates.orderByDesc('rating')
    const resultSet = await this.dbHelper.query(predicates)

    return this.parseSpotResults(resultSet)
  }

  /**
   * 获取所有景点
   */
  async getAllSpots(): Promise<ScenicSpotModel[]> {
    return this.getSpotsByCategory('')
  }

  /**
   * 解析景点查询结果
   */
  private parseSpotResults(resultSet: relationalStore.ResultSet): ScenicSpotModel[] {
    const spots: ScenicSpotModel[] = []
    while (resultSet.goToNextRow()) {
      const spot = new ScenicSpotModel()
      spot.id = resultSet.getLong(resultSet.getColumnIndex('id'))
      spot.name = resultSet.getString(resultSet.getColumnIndex('name'))
      spot.category = resultSet.getString(resultSet.getColumnIndex('category'))
      spot.city = resultSet.getString(resultSet.getColumnIndex('city'))
      spot.description = resultSet.getString(resultSet.getColumnIndex('description'))
      spot.imageUrl = resultSet.getString(resultSet.getColumnIndex('image_url'))
      spot.rating = resultSet.getDouble(resultSet.getColumnIndex('rating'))
      spot.tags = resultSet.getString(resultSet.getColumnIndex('tags'))
      spot.isFavorite = resultSet.getLong(resultSet.getColumnIndex('is_favorite'))
      spots.push(spot)
    }
    resultSet.close()
    return spots
  }
}