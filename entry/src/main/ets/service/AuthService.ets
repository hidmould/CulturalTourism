import { relationalStore } from '@kit.ArkData'
import { DatabaseHelper } from '../database/DatabaseHelper'
import { PreferencesHelper } from '../preferences/PreferencesHelper'
import { UserModel, LoginType } from '../model/UserModel'

/**
 * 用户认证服务
 * 处理登录、注册、自动登录、退出登录
 */
export class AuthService {
  private static instance: AuthService
  private dbHelper: DatabaseHelper = DatabaseHelper.getInstance()
  private prefsHelper: PreferencesHelper = PreferencesHelper.getInstance()

  static getInstance(): AuthService {
    if (!AuthService.instance) {
      AuthService.instance = new AuthService()
    }
    return AuthService.instance
  }

  /**
   * 手机号+验证码登录
   */
  async loginByPhoneCode(phone: string, code: string): Promise<UserModel | null> {
    // 模拟验证码校验（实际应调用短信验证接口）
    if (code !== '123456' && code !== '000000') {
      throw new Error('验证码错误')
    }
    return this.findOrCreateUser(phone)
  }

  /**
   * 账号密码登录
   */
  async loginByPassword(phone: string, password: string): Promise<UserModel | null> {
    const predicates = new relationalStore.RdbPredicates('user')
    predicates.equalTo('phone', phone)
    const resultSet = await this.dbHelper.query(predicates)

    if (resultSet.rowCount === 0) {
      throw new Error('用户不存在，请先注册')
    }

    resultSet.goToFirstRow()
    const storedPassword = resultSet.getString(resultSet.getColumnIndex('password'))
    resultSet.close()

    if (storedPassword !== password) {
      throw new Error('密码错误')
    }

    return this.findOrCreateUser(phone, password)
  }

  /**
   * 注册新用户
   */
  async register(phone: string, password: string): Promise<UserModel> {
    const predicates = new relationalStore.RdbPredicates('user')
    predicates.equalTo('phone', phone)
    const resultSet = await this.dbHelper.query(predicates)

    if (resultSet.rowCount > 0) {
      resultSet.close()
      throw new Error('该手机号已注册')
    }
    resultSet.close()

    const values: relationalStore.ValuesBucket = {
      'phone': phone,
      'password': password,
      'nickname': `用户${phone.substring(phone.length - 4)}`,
      'travel_preference': '综合',
      'create_time': Date.now()
    }

    const rowId = await this.dbHelper.insert('user', values)

    const user = new UserModel()
    user.id = rowId
    user.phone = phone
    user.password = password
    user.nickname = `用户${phone.substring(phone.length - 4)}`
    user.travelPreference = '综合'
    user.token = `token_${rowId}_${Date.now()}`

    // 保存登录状态
    await this.saveLoginState(user)
    return user
  }

  /**
   * 查找或创建用户
   */
  private async findOrCreateUser(phone: string, password?: string): Promise<UserModel> {
    const predicates = new relationalStore.RdbPredicates('user')
    predicates.equalTo('phone', phone)
    const resultSet = await this.dbHelper.query(predicates)

    let user = new UserModel()

    if (resultSet.rowCount > 0) {
      resultSet.goToFirstRow()
      user.id = resultSet.getLong(resultSet.getColumnIndex('id'))
      user.phone = resultSet.getString(resultSet.getColumnIndex('phone'))
      user.nickname = resultSet.getString(resultSet.getColumnIndex('nickname'))
      user.travelPreference = resultSet.getString(resultSet.getColumnIndex('travel_preference'))
      user.city = resultSet.getString(resultSet.getColumnIndex('city'))
      user.avatar = resultSet.getString(resultSet.getColumnIndex('avatar'))
      user.token = `token_${user.id}_${Date.now()}`
      resultSet.close()
    } else {
      resultSet.close()
      // 新用户自动注册
      const values: relationalStore.ValuesBucket = {
        'phone': phone,
        'password': password || '',
        'nickname': `用户${phone.substring(phone.length - 4)}`,
        'travel_preference': '综合',
        'create_time': Date.now()
      }
      const rowId = await this.dbHelper.insert('user', values)
      user.id = rowId
      user.phone = phone
      user.nickname = `用户${phone.substring(phone.length - 4)}`
      user.travelPreference = '综合'
      user.token = `token_${rowId}_${Date.now()}`
    }

    await this.saveLoginState(user)
    return user
  }

  /**
   * 保存登录状态
   */
  private async saveLoginState(user: UserModel): Promise<void> {
    await this.prefsHelper.setLoggedIn(true)
    await this.prefsHelper.saveUserId(user.id)
    await this.prefsHelper.saveToken(user.token)
    await this.prefsHelper.saveUserPhone(user.phone)
    await this.prefsHelper.saveTravelPreference(user.travelPreference)
  }

  /**
   * 自动登录（检查记住密码）
   */
  async autoLogin(): Promise<UserModel | null> {
    const isLoggedIn = await this.prefsHelper.isLoggedIn()
    if (!isLoggedIn) {
      return null
    }

    const userId = await this.prefsHelper.getUserId()
    if (userId <= 0) {
      return null
    }

    const predicates = new relationalStore.RdbPredicates('user')
    predicates.equalTo('id', userId)
    const resultSet = await this.dbHelper.query(predicates)

    if (resultSet.rowCount === 0) {
      resultSet.close()
      return null
    }

    resultSet.goToFirstRow()
    const user = new UserModel()
    user.id = resultSet.getLong(resultSet.getColumnIndex('id'))
    user.phone = resultSet.getString(resultSet.getColumnIndex('phone'))
    user.nickname = resultSet.getString(resultSet.getColumnIndex('nickname'))
    user.travelPreference = resultSet.getString(resultSet.getColumnIndex('travel_preference'))
    user.city = resultSet.getString(resultSet.getColumnIndex('city'))
    user.avatar = resultSet.getString(resultSet.getColumnIndex('avatar'))
    user.token = await this.prefsHelper.getToken()
    resultSet.close()

    return user
  }

  /**
   * 退出登录
   */
  async logout(): Promise<void> {
    await this.prefsHelper.setLoggedIn(false)
    await this.prefsHelper.clearToken()
    await this.prefsHelper.saveUserId(0)
  }

  /**
   * 更新用户信息
   */
  async updateUserInfo(user: UserModel): Promise<void> {
    const values: relationalStore.ValuesBucket = {
      'nickname': user.nickname,
      'travel_preference': user.travelPreference,
      'city': user.city,
      'avatar': user.avatar
    }
    const predicates = new relationalStore.RdbPredicates('user')
    predicates.equalTo('id', user.id)
    await this.dbHelper.update('user', values, predicates)

    await this.prefsHelper.saveTravelPreference(user.travelPreference)
    await this.prefsHelper.saveCity(user.city)
  }

  /**
   * 获取当前登录用户
   */
  async getCurrentUser(): Promise<UserModel | null> {
    const userId = await this.prefsHelper.getUserId()
    if (userId <= 0) {
      return null
    }

    const predicates = new relationalStore.RdbPredicates('user')
    predicates.equalTo('id', userId)
    const resultSet = await this.dbHelper.query(predicates)

    if (resultSet.rowCount === 0) {
      resultSet.close()
      return null
    }

    resultSet.goToFirstRow()
    const user = new UserModel()
    user.id = resultSet.getLong(resultSet.getColumnIndex('id'))
    user.phone = resultSet.getString(resultSet.getColumnIndex('phone'))
    user.nickname = resultSet.getString(resultSet.getColumnIndex('nickname'))
    user.travelPreference = resultSet.getString(resultSet.getColumnIndex('travel_preference'))
    user.city = resultSet.getString(resultSet.getColumnIndex('city'))
    user.avatar = resultSet.getString(resultSet.getColumnIndex('avatar'))
    resultSet.close()

    return user
  }
}