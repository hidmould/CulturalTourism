import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { window } from '@kit.ArkUI'
import { DatabaseHelper } from '../database/DatabaseHelper'
import { PreferencesHelper } from '../preferences/PreferencesHelper'
import { SpotService } from '../service/SpotService'

const DOMAIN = 0x0000

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET)
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err))
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate')
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate')

    // 先初始化服务，再加载页面
    this.initServices().then(() => {
      windowStage.loadContent('pages/Index', (err) => {
        if (err.code) {
          hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err))
          return
        }
        hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.')
      })
    }).catch((err: Error) => {
      hilog.error(DOMAIN, 'testTag', 'Failed to init services: %{public}s', err.message)
    })
  }

  private async initServices(): Promise<void> {
    await DatabaseHelper.getInstance().init(this.context)
    await PreferencesHelper.getInstance().init(this.context)
    // 初始化预置景点数据
    await SpotService.getInstance().initPresetSpots()
    hilog.info(DOMAIN, 'testTag', 'Services initialized successfully')
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy')
  }

  onForeground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground')
  }

  onBackground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground')
  }
}