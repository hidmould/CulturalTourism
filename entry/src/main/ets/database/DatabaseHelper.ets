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
  private initPromise: Promise<relationalStore.RdbStore> | null = null

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
    // 防止并发初始化
    if (this.initPromise) {
      return this.initPromise
    }
    if (!this.context) {
      throw new Error('DatabaseHelper 未初始化，请先调用 init()')
    }

    console.info('[DatabaseHelper] 开始创建 RDB 数据库...')

    this.initPromise = this.doInitStore()
    try {
      let store = await this.initPromise
      return store
    } finally {
      this.initPromise = null
    }
  }

  private async doInitStore(): Promise<relationalStore.RdbStore> {
    const config: relationalStore.StoreConfig = {
      name: DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1
    }

    try {
      let store = await relationalStore.getRdbStore(this.context!, config)
      this.store = store
      console.info('[DatabaseHelper] RDB 数据库创建成功')
      await this.createTables()
      console.info('[DatabaseHelper] 数据库表创建完成')
      // 景点数据初始化失败不影响核心功能
      try {
        await this.initScenicSpots()
      } catch (err) {
        let error = err as BusinessError
        console.error(`[DatabaseHelper] 景点数据初始化失败: ${error.message}`)
      }
      return this.store
    } catch (err) {
      this.store = null
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

    await this.store.executeSql(createUserTable)
    await this.store.executeSql(createConversationTable)
    await this.store.executeSql(createMessageTable)
    await this.store.executeSql(createFavoriteTable)
    await this.store.executeSql(createTripTable)
    await this.createScenicSpotTable()
  }

  /**
   * 创建景点表
   */
  private async createScenicSpotTable(): Promise<void> {
    if (!this.store) return
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
    await this.store.executeSql(createScenicTable)
  }

  /**
   * 强制重置景点数据（公开方法，供页面手动触发）
   */
  async resetScenicSpots(): Promise<void> {
    // 确保数据库已初始化
    await this.getStore()
    console.info('[DatabaseHelper] 强制重置景点数据')
    await this.doInitScenicSpots(true)
  }

  /**
   * 初始化预置景点数据
   * 通过检查总数判断是否需要重新初始化，避免部分数据丢失导致页面空白
   */
  private async initScenicSpots(): Promise<void> {
    if (!this.store) return
    await this.doInitScenicSpots(false)
  }

  private async doInitScenicSpots(force: boolean): Promise<void> {
    if (!this.store) return

    // 预置景点数据（每个分类多个景点）
    const spots: Array<[string, string, string, string, string, string, number]> = [
      // 自然风光
      ['西湖', '自然风光', '杭州', '中国十大风景名胜之一，以湖光山色著称，苏堤春晓、断桥残雪闻名天下', '', '杭州市西湖区龙井路1号', 4.8],
      ['黄山', '自然风光', '黄山', '世界文化与自然双重遗产，以奇松、怪石、云海、温泉四绝闻名', '', '安徽省黄山市黄山区', 4.9],
      ['张家界', '自然风光', '张家界', '世界自然遗产，独特的石英砂岩峰林地貌，阿凡达取景地', '', '湖南省张家界市武陵源区', 4.8],
      ['九寨沟', '自然风光', '阿坝', '世界自然遗产，以翠海、叠瀑、彩林、雪峰、藏情五绝著称', '', '四川省阿坝州九寨沟县', 4.9],
      ['桂林漓江', '自然风光', '桂林', '桂林山水甲天下，漓江风光秀丽，喀斯特地貌典型代表', '', '广西壮族自治区桂林市', 4.8],
      ['青海湖', '自然风光', '西宁', '中国最大内陆湖，七月油菜花盛开时美不胜收', '', '青海省海南藏族自治州', 4.7],
      ['长白山', '自然风光', '白山', '东北第一高山，天池壮丽，冬季滑雪胜地', '', '吉林省白山市抚松县', 4.7],
      ['丽江古城', '自然风光', '丽江', '世界文化遗产，纳西族文化发源地，玉龙雪山脚下', '', '云南省丽江市古城区', 4.8],
      ['三亚亚龙湾', '自然风光', '三亚', '中国最美海滩之一，碧海蓝天白沙，热带滨海度假天堂', '', '海南省三亚市亚龙湾国家旅游度假区', 4.8],
      ['稻城亚丁', '自然风光', '甘孜', '蓝色星球最后一片净土，雪山草甸湖泊，摄影天堂', '', '四川省甘孜州稻城县香格里拉镇', 4.9],
      ['喀纳斯湖', '自然风光', '阿勒泰', '中国最美湖泊之一，湖光山色如画，秋季色彩斑斓', '', '新疆维吾尔自治区阿勒泰地区布尔津县', 4.8],

      // 历史人文
      ['故宫', '历史人文', '北京', '明清两代皇家宫殿，世界五大宫之首，世界文化遗产', '', '北京市东城区景山前街4号', 4.9],
      ['长城', '历史人文', '北京', '世界文化遗产，中国古代伟大军事防御工程，人类建筑奇迹', '', '北京市延庆区八达岭', 4.8],
      ['兵马俑', '历史人文', '西安', '世界第八大奇迹，秦始皇陵陪葬坑，展现大秦帝国军威', '', '西安市临潼区秦陵北路', 4.9],
      ['敦煌莫高窟', '历史人文', '敦煌', '世界文化遗产，千年佛教艺术宝库，壁画雕塑举世闻名', '', '甘肃省敦煌市鸣沙山东麓', 4.9],
      ['布达拉宫', '历史人文', '拉萨', '世界文化遗产，藏传佛教圣地，雪域高原的明珠', '', '西藏自治区拉萨市城关区', 4.8],
      ['颐和园', '历史人文', '北京', '中国现存最大皇家园林，世界文化遗产，昆明湖万寿山', '', '北京市海淀区新建宫门路19号', 4.7],
      ['天坛', '历史人文', '北京', '明清皇帝祭天场所，世界文化遗产，中国古代建筑杰作', '', '北京市东城区天坛路', 4.7],
      ['龙门石窟', '历史人文', '洛阳', '世界文化遗产，中国石刻艺术巅峰之作，佛教艺术宝库', '', '河南省洛阳市洛龙区', 4.8],
      ['苏州园林', '历史人文', '苏州', '世界文化遗产，中国古典园林代表，咫尺之内再造乾坤', '', '江苏省苏州市姑苏区', 4.8],
      ['平遥古城', '历史人文', '晋中', '世界文化遗产，中国保存最完整的明清古城，晋商文化发源地', '', '山西省晋中市平遥县', 4.7],
      ['大足石刻', '历史人文', '重庆', '世界文化遗产，中国晚期石窟艺术代表，雕刻精美绝伦', '', '重庆市大足区宝顶镇', 4.7],

      // 网红打卡
      ['外滩', '网红打卡', '上海', '上海标志性景点，黄浦江畔万国建筑博览群，夜景绝美', '', '上海市黄浦区中山东一路', 4.7],
      ['洪崖洞', '网红打卡', '重庆', '重庆网红地标，依山而建的吊脚楼建筑群，千与千寻现实版', '', '重庆市渝中区嘉陵江滨江路', 4.6],
      ['鼓浪屿', '网红打卡', '厦门', '海上花园，世界文化遗产，文艺小资必去之地', '', '厦门市思明区鼓浪屿', 4.7],
      ['茶颜悦色', '网红打卡', '长沙', '长沙网红奶茶品牌，文和友旁必打卡，排队名店', '', '湖南省长沙市天心区', 4.5],
      ['重庆李子坝', '网红打卡', '重庆', '轻轨穿楼奇观，重庆魔幻地形代表，网红拍摄圣地', '', '重庆市渝中区李子坝正街', 4.6],
      ['长沙IFS', '网红打卡', '长沙', '长沙最高楼，KAWS雕塑打卡地，城市地标建筑', '', '湖南省长沙市芙蓉区解放西路', 4.5],
      ['西安大唐不夜城', '网红打卡', '西安', '盛唐文化主题步行街，不倒翁小姐姐表演，夜游胜地', '', '陕西省西安市雁塔区慈恩路', 4.7],
      ['成都太古里', '网红打卡', '成都', '成都时尚地标，大慈寺旁商业街区，潮流聚集地', '', '四川省成都市锦江区中纱帽街', 4.6],
      ['上海迪士尼', '网红打卡', '上海', '中国大陆首座迪士尼乐园，梦幻城堡烟花秀，亲子必去', '', '上海市浦东新区川沙镇', 4.8],
      ['广州塔', '网红打卡', '广州', '广州地标建筑，中国第一高塔，珠江夜景尽收眼底', '', '广州市海珠区阅江西路222号', 4.6],
      ['武汉长江大桥', '网红打卡', '武汉', '万里长江第一桥，武汉标志性建筑，夜景灯光秀', '', '湖北省武汉市武昌区临江大道', 4.5],

      // 美食街区
      ['宽窄巷子', '美食街区', '成都', '成都历史文化街区，汇集四川美食与茶馆文化，体验慢生活', '', '成都市青羊区长顺上街', 4.7],
      ['回民街', '美食街区', '西安', '西安著名美食街，汇聚西北特色小吃，羊肉泡馍肉夹馍', '', '西安市莲湖区北院门', 4.6],
      ['夫子庙', '美食街区', '南京', '南京历史文化地标，秦淮河畔美食聚集地，鸭血粉丝汤', '', '南京市秦淮区贡院街', 4.5],
      ['王府井', '美食街区', '北京', '北京著名商业街，汇聚各地美食，老字号聚集地', '', '北京市东城区王府井大街', 4.5],
      ['户部巷', '美食街区', '武汉', '武汉著名美食街，热干面豆皮三鲜豆皮，早餐文化代表', '', '湖北省武汉市武昌区户部巷', 4.6],
      ['中山路', '美食街区', '厦门', '厦门老字号美食街，沙茶面海蛎煎，闽南风味聚集地', '', '福建省厦门市思明区中山路', 4.5],
      ['锦里', '美食街区', '成都', '成都三国文化主题街区，川味小吃聚集，夜景迷人', '', '四川省成都市武侯区武侯祠大街', 4.6],
      ['南锣鼓巷', '美食街区', '北京', '北京最古老街区之一，文艺小店与老北京美食并存', '', '北京市东城区南锣鼓巷', 4.5],
      ['城隍庙', '美食街区', '上海', '上海老城厢核心，南翔小笼包生煎包，沪上美食天堂', '', '上海市黄浦区方浜中路249号', 4.6],
      ['太平街', '美食街区', '长沙', '长沙千年老街，臭豆腐糖油粑粑，湘味小吃聚集地', '', '湖南省长沙市天心区太平街', 4.5],
      ['建设路', '美食街区', '成都', '成都本地人最爱美食街，串串香冒菜，地道成都味', '', '四川省成都市成华区建设路', 4.7]
    ]

    if (!force) {
      // 检查是否已有完整数据（通过遍历计数，rowCount 在部分设备上不可靠）
      let countPredicates = new relationalStore.RdbPredicates(TABLE_SCENIC_SPOT)
      let countResultSet = await this.store.query(countPredicates)
      let existingCount = 0
      if (countResultSet.goToFirstRow()) {
        existingCount++
        while (countResultSet.goToNextRow()) {
          existingCount++
        }
      }
      countResultSet.close()

      console.info(`[DatabaseHelper] 当前景点数量: ${existingCount}`)

      if (existingCount >= spots.length) {
        console.info(`[DatabaseHelper] 景点数据完整（${existingCount}条），跳过初始化`)
        return
      }

      console.info(`[DatabaseHelper] 景点数据不完整（当前${existingCount}条，需要${spots.length}条），开始重新初始化...`)
    } else {
      console.info('[DatabaseHelper] 强制重置模式，清空并重新插入景点数据')
    }

    // 清空旧数据，重新插入
    try {
      await this.store.executeSql(`DELETE FROM ${TABLE_SCENIC_SPOT}`)
    } catch (err) {
      let error = err as BusinessError
      console.error(`[DatabaseHelper] 清空景点表失败: ${error.message}，尝试重建表`)
      // 如果清空失败，删除表并重新创建
      await this.store.executeSql(`DROP TABLE IF EXISTS ${TABLE_SCENIC_SPOT}`)
      await this.createScenicSpotTable()
    }

    let successCount = 0
    for (let spot of spots) {
      try {
        let valueBucket: relationalStore.ValuesBucket = {
          'name': spot[0],
          'category': spot[1],
          'city': spot[2],
          'description': spot[3],
          'image_url': this.getSpotImageName(spot[0] as string),
          'address': spot[5],
          'rating': spot[6],
          'create_time': Date.now()
        }
        await this.store.insert(TABLE_SCENIC_SPOT, valueBucket)
        successCount++
      } catch (err) {
        let error = err as BusinessError
        console.error(`[DatabaseHelper] 插入景点"${spot[0]}"失败: ${error.message}`)
      }
    }
    console.info(`[DatabaseHelper] 景点数据初始化完成，成功插入 ${successCount}/${spots.length} 条`)
  }

  private getSpotImageName(name: string): string {
    const nameMap: Record<string, string> = {
      '西湖': 'xihu', '黄山': 'huangshan', '张家界': 'zhangjiajie', '九寨沟': 'jiuzhaigou',
      '桂林漓江': 'guilin', '青海湖': 'qinghaihu', '长白山': 'changbaishan', '丽江古城': 'lijiang',
      '三亚亚龙湾': 'sanya', '稻城亚丁': 'daocheng', '喀纳斯湖': 'kanasi',
      '故宫': 'gugong', '长城': 'changcheng', '兵马俑': 'bingmayong', '敦煌莫高窟': 'dunhuang',
      '布达拉宫': 'budala', '颐和园': 'yiheyuan', '天坛': 'tiantan', '龙门石窟': 'longmen',
      '苏州园林': 'suzhouyl', '平遥古城': 'pingyao', '大足石刻': 'dazu',
      '外滩': 'waitan', '洪崖洞': 'hongyadong', '鼓浪屿': 'gulangyu', '茶颜悦色': 'chayan',
      '重庆李子坝': 'liziba', '长沙IFS': 'csifs', '西安大唐不夜城': 'datang', '成都太古里': 'taiguli',
      '上海迪士尼': 'disney', '广州塔': 'gztower', '武汉长江大桥': 'wuhandq',
      '宽窄巷子': 'kuanzhai', '回民街': 'huimin', '夫子庙': 'fuzimiao', '王府井': 'wangfujing',
      '户部巷': 'hubu', '中山路': 'zhongshan', '锦里': 'jinli', '南锣鼓巷': 'nanluogu',
      '城隍庙': 'chenghuang', '太平街': 'taiping', '建设路': 'jianshe'
    }
    return nameMap[name] || 'scenic_nature'
  }

  private getCategoryImageName(category: string): string {
    switch (category) {
      case '自然风光': return 'scenic_nature'
      case '历史人文': return 'scenic_history'
      case '网红打卡': return 'scenic_popular'
      case '美食街区': return 'scenic_food'
      default: return 'scenic_nature'
    }
  }
}