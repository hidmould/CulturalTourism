import { preferences } from '@kit.ArkData'
import { Context } from '@kit.AbilityKit'

const PREFERENCES_NAME = 'CulturalTourismPrefs'

/**
 * 用户首选项帮助类
 * 存储 token、密码、偏好设置等轻量级数据
 */
export class PreferencesHelper {
  private static instance: PreferencesHelper
  private prefs: preferences.Preferences | null = null

  static getInstance(): PreferencesHelper {
    if (!PreferencesHelper.instance) {
      PreferencesHelper.instance = new PreferencesHelper()
    }
    return PreferencesHelper.instance
  }

  async init(context: Context): Promise<void> {
    if (this.prefs) {
      return
    }
    this.prefs = await preferences.getPreferences(context, PREFERENCES_NAME)
  }

  // ========== Token 管理 ==========
  async saveToken(token: string): Promise<void> {
    await this.prefs!.put('token', token)
    await this.prefs!.flush()
  }

  async getToken(): Promise<string> {
    return await this.prefs!.get('token', '') as string
  }

  async clearToken(): Promise<void> {
    await this.prefs!.delete('token')
    await this.prefs!.flush()
  }

  // ========== 用户信息 ==========
  async saveUserId(userId: number): Promise<void> {
    await this.prefs!.put('userId', userId)
    await this.prefs!.flush()
  }

  async getUserId(): Promise<number> {
    return await this.prefs!.get('userId', 0) as number
  }

  async saveUserPhone(phone: string): Promise<void> {
    await this.prefs!.put('userPhone', phone)
    await this.prefs!.flush()
  }

  async getUserPhone(): Promise<string> {
    return await this.prefs!.get('userPhone', '') as string
  }

  // ========== 记住密码 ==========
  async saveRememberPassword(remember: boolean): Promise<void> {
    await this.prefs!.put('rememberPassword', remember)
    await this.prefs!.flush()
  }

  async getRememberPassword(): Promise<boolean> {
    return await this.prefs!.get('rememberPassword', false) as boolean
  }

  async savePassword(password: string): Promise<void> {
    await this.prefs!.put('savedPassword', password)
    await this.prefs!.flush()
  }

  async getPassword(): Promise<string> {
    return await this.prefs!.get('savedPassword', '') as string
  }

  // ========== 登录状态 ==========
  async setLoggedIn(loggedIn: boolean): Promise<void> {
    await this.prefs!.put('isLoggedIn', loggedIn)
    await this.prefs!.flush()
  }

  async isLoggedIn(): Promise<boolean> {
    return await this.prefs!.get('isLoggedIn', false) as boolean
  }

  // ========== 用户偏好 ==========
  async saveTravelPreference(preference: string): Promise<void> {
    await this.prefs!.put('travelPreference', preference)
    await this.prefs!.flush()
  }

  async getTravelPreference(): Promise<string> {
    return await this.prefs!.get('travelPreference', '综合') as string
  }

  async saveCity(city: string): Promise<void> {
    await this.prefs!.put('city', city)
    await this.prefs!.flush()
  }

  async getCity(): Promise<string> {
    return await this.prefs!.get('city', '') as string
  }

  // ========== 模型配置 ==========
  async saveModelType(modelType: string): Promise<void> {
    await this.prefs!.put('modelType', modelType)
    await this.prefs!.flush()
  }

  async getModelType(): Promise<string> {
    return await this.prefs!.get('modelType', 'general') as string
  }

  // ========== 缓存管理 ==========
  async clearAll(): Promise<void> {
    await this.prefs!.clear()
    await this.prefs!.flush()
  }
}