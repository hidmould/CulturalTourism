/**
 * 用户服务 - 登录/注册、个人信息管理
 */
import { preferences } from '@kit.ArkData'
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { DatabaseHelper } from '../database/DatabaseHelper'
import { UserInfo } from '../model/Models'
import { HttpClient } from '../network/HttpClient'
import {
  PREF_NAME,
  PREF_KEY_TOKEN,
  PREF_KEY_PASSWORD,
  PREF_KEY_PHONE,
  PREF_KEY_REMEMBER,
  PREF_KEY_AUTO_LOGIN,
  PREF_KEY_NICKNAME,
  PREF_KEY_AVATAR,
  PREF_KEY_TRAVEL_PREF,
  PREF_KEY_CITY,
  TABLE_USER
} from '../common/Constants'
import { relationalStore } from '@kit.ArkData'

export class UserService {
  private static instance: UserService
  private context: common.UIAbilityContext | null = null

  static getInstance(): UserService {
    if (!UserService.instance) {
      UserService.instance = new UserService()
    }
    return UserService.instance
  }

  init(context: common.UIAbilityContext): void {
    this.context = context
  }

  /**
   * 获取 Preferences 实例
   */
  private async getPrefs(): Promise<preferences.Preferences> {
    if (!this.context) {
      throw new Error('UserService 未初始化')
    }
    return await preferences.getPreferences(this.context, PREF_NAME)
  }

  /**
   * 注册新用户
   */
  async register(phone: string, password: string, nickname?: string): Promise<boolean> {
    let prefs = await this.getPrefs()
    let savedPassword = await prefs.get(PREF_KEY_PASSWORD, '') as string

    // 检查手机号是否已注册
    if (savedPassword !== '') {
      let savedPhone = await prefs.get(PREF_KEY_PHONE, '') as string
      if (savedPhone === phone) {
        throw new Error('该手机号已注册')
      }
    }

    // 保存密码
    await prefs.put(PREF_KEY_PASSWORD, password)
    await prefs.put(PREF_KEY_PHONE, phone)

    // 生成 token
    let token = `token_${phone}_${Date.now()}`
    await prefs.put(PREF_KEY_TOKEN, token)
    await prefs.put(PREF_KEY_AUTO_LOGIN, true)

    // 保存昵称
    if (nickname && nickname.trim().length > 0) {
      await prefs.put(PREF_KEY_NICKNAME, nickname.trim())
    }

    await prefs.flush()

    // 保存用户到数据库
    await this.ensureUserInDb(phone, nickname)
    return true
  }

  /**
   * 手机号+验证码登录（模拟验证码为 123456）
   */
  async loginByPhone(phone: string, code: string): Promise<boolean> {
    // 模拟验证码校验
    if (code !== '123456') {
      throw new Error('验证码错误')
    }
    // 生成模拟 token
    let token = `token_${phone}_${Date.now()}`
    let prefs = await this.getPrefs()
    await prefs.put(PREF_KEY_TOKEN, token)
    await prefs.put(PREF_KEY_PHONE, phone)
    await prefs.put(PREF_KEY_AUTO_LOGIN, true)
    await prefs.flush()

    // 保存用户到数据库
    await this.ensureUserInDb(phone)
    return true
  }

  /**
   * 账号密码登录
   */
  async loginByPassword(phone: string, password: string, remember: boolean): Promise<boolean> {
    let prefs = await this.getPrefs()
    let savedPassword = await prefs.get(PREF_KEY_PASSWORD, '') as string

    // 首次登录或密码匹配
    if (savedPassword === '' || savedPassword === password) {
      let token = `token_${phone}_${Date.now()}`
      await prefs.put(PREF_KEY_TOKEN, token)
      await prefs.put(PREF_KEY_PHONE, phone)
      if (remember) {
        await prefs.put(PREF_KEY_PASSWORD, password)
        await prefs.put(PREF_KEY_REMEMBER, true)
      }
      await prefs.put(PREF_KEY_AUTO_LOGIN, true)
      await prefs.flush()

      await this.ensureUserInDb(phone)
      return true
    }
    throw new Error('密码错误')
  }

  /**
   * 自动登录
   */
  async autoLogin(): Promise<boolean> {
    let prefs = await this.getPrefs()
    let autoLogin = await prefs.get(PREF_KEY_AUTO_LOGIN, false) as boolean
    let token = await prefs.get(PREF_KEY_TOKEN, '') as string
    return autoLogin && token !== ''
  }

  /**
   * 退出登录
   */
  async logout(): Promise<void> {
    let prefs = await this.getPrefs()
    await prefs.put(PREF_KEY_AUTO_LOGIN, false)
    await prefs.put(PREF_KEY_TOKEN, '')
    await prefs.flush()
  }

  /**
   * 获取记住的密码
   */
  async getRememberedPassword(): Promise<string> {
    let prefs = await this.getPrefs()
    return await prefs.get(PREF_KEY_PASSWORD, '') as string
  }

  /**
   * 获取记住密码状态
   */
  async getRememberState(): Promise<boolean> {
    let prefs = await this.getPrefs()
    return await prefs.get(PREF_KEY_REMEMBER, false) as boolean
  }

  /**
   * 获取已登录手机号
   */
  async getPhone(): Promise<string> {
    let prefs = await this.getPrefs()
    return await prefs.get(PREF_KEY_PHONE, '') as string
  }

  /**
   * 获取 Token
   */
  async getToken(): Promise<string> {
    let prefs = await this.getPrefs()
    return await prefs.get(PREF_KEY_TOKEN, '') as string
  }

  /**
   * 获取用户信息
   */
  async getUserInfo(): Promise<UserInfo> {
    let store = await DatabaseHelper.getInstance().getStore()
    let prefs = await this.getPrefs()
    let phone = await prefs.get(PREF_KEY_PHONE, '') as string

    let predicates = new relationalStore.RdbPredicates(TABLE_USER)
    predicates.equalTo('phone', phone)
    let resultSet = await store.query(predicates)

    let user = new UserInfo()
    if (resultSet.goToFirstRow()) {
      user.id = resultSet.getLong(resultSet.getColumnIndex('id'))
      user.phone = resultSet.getString(resultSet.getColumnIndex('phone'))
      user.nickname = resultSet.getString(resultSet.getColumnIndex('nickname'))
      user.avatar = resultSet.getString(resultSet.getColumnIndex('avatar'))
      user.travelPreference = resultSet.getString(resultSet.getColumnIndex('travel_preference'))
      user.residentCity = resultSet.getString(resultSet.getColumnIndex('resident_city'))
      user.createTime = resultSet.getLong(resultSet.getColumnIndex('create_time'))
    }
    resultSet.close()

    // 如果 Preferences 中有更新数据，以 Preferences 为准
    let nickname = await prefs.get(PREF_KEY_NICKNAME, '') as string
    let avatar = await prefs.get(PREF_KEY_AVATAR, '') as string
    let travelPref = await prefs.get(PREF_KEY_TRAVEL_PREF, '') as string
    let city = await prefs.get(PREF_KEY_CITY, '') as string

    if (nickname) user.nickname = nickname
    if (avatar) user.avatar = avatar
    if (travelPref) user.travelPreference = travelPref
    if (city) user.residentCity = city

    return user
  }

  /**
   * 更新用户信息
   */
  async updateUserInfo(field: string, value: string): Promise<void> {
    let prefs = await this.getPrefs()
    let store = await DatabaseHelper.getInstance().getStore()
    let phone = await prefs.get(PREF_KEY_PHONE, '') as string

    // 更新 Preferences
    let prefKey = ''
    switch (field) {
      case 'nickname':
        prefKey = PREF_KEY_NICKNAME
        break
      case 'avatar':
        prefKey = PREF_KEY_AVATAR
        break
      case 'travelPreference':
        prefKey = PREF_KEY_TRAVEL_PREF
        break
      case 'residentCity':
        prefKey = PREF_KEY_CITY
        break
    }
    if (prefKey) {
      await prefs.put(prefKey, value)
      await prefs.flush()
    }

    // 更新数据库
    let dbField = ''
    switch (field) {
      case 'nickname':
        dbField = 'nickname'
        break
      case 'avatar':
        dbField = 'avatar'
        break
      case 'travelPreference':
        dbField = 'travel_preference'
        break
      case 'residentCity':
        dbField = 'resident_city'
        break
    }

    if (dbField) {
      let valueBucket: relationalStore.ValuesBucket = {}
      valueBucket[dbField] = value
      let predicates = new relationalStore.RdbPredicates(TABLE_USER)
      predicates.equalTo('phone', phone)
      await store.update(valueBucket, predicates)
    }
  }

  /**
   * 确保用户在数据库中存在
   */
  private async ensureUserInDb(phone: string, nickname?: string): Promise<void> {
    let store = await DatabaseHelper.getInstance().getStore()
    let predicates = new relationalStore.RdbPredicates(TABLE_USER)
    predicates.equalTo('phone', phone)
    let resultSet = await store.query(predicates)

    if (resultSet.rowCount === 0) {
      let displayName = (nickname && nickname.trim().length > 0)
        ? nickname.trim()
        : `用户${phone.substring(phone.length - 4)}`
      let valueBucket: relationalStore.ValuesBucket = {
        'phone': phone,
        'nickname': displayName,
        'create_time': Date.now()
      }
      await store.insert(TABLE_USER, valueBucket)
    }
    resultSet.close()
  }
}