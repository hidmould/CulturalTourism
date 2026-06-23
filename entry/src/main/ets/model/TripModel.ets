/**
 * 行程数据模型
 */
export class TripModel {
  id: number = 0
  userId: number = 0
  title: string = ''              // 行程标题
  destination: string = ''        // 目的地城市
  days: number = 0                // 行程天数
  startDate: string = ''          // 开始日期
  scheduleJson: string = ''       // 结构化行程JSON（按天整理）
  isGenerated: number = 0         // 是否由AI生成
  createTime: number = Date.now()
  updateTime: number = Date.now()
}

/**
 * 行程日程项
 */
export class ScheduleItem {
  day: number = 0
  items: ScheduleDetail[] = []
}

/**
 * 日程详情
 */
export class ScheduleDetail {
  time: string = ''               // 时间点，如 "09:00"
  activity: string = ''           // 活动描述
  location: string = ''           // 地点
  note: string = ''               // 备注
  order: number = 0               // 排序
}