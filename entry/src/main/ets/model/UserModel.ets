/**
 * 用户数据模型
 */
export class UserModel {
  id: number = 0
  phone: string = ''
  nickname: string = ''
  avatar: string = ''
  travelPreference: string = ''    // 亲子/独行/美食/综合
  city: string = ''                // 常住城市
  token: string = ''
  password: string = ''            // 本地加密存储的密码
  rememberPassword: boolean = false
  createTime: number = Date.now()
}

/**
 * 旅行偏好选项
 */
export const TRAVEL_PREFERENCES: string[] = ['亲子', '独行', '美食', '综合']

/**
 * 登录类型
 */
export enum LoginType {
  PHONE_CODE = 1,   // 手机号+验证码
  PASSWORD = 2,     // 账号密码
}