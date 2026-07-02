// 景点图片资源映射工具
// 解决 $rawfile() 必须是字面量的限制：通过 switch/case 分支映射
// 每个 case 都使用字符串字面量，确保编译期可校验资源存在

/**
 * 根据图片名返回对应的 rawfile 资源
 * @param name rawfile 目录下的文件名（不含扩展名）
 * @returns Resource 资源对象，可直接传入 Image()
 */
export function getSpotImageResource(name: string): Resource {
  switch (name) {
    case 'xihu': return $rawfile('xihu.png')
    case 'huangshan': return $rawfile('huangshan.png')
    case 'zhangjiajie': return $rawfile('zhangjiajie.png')
    case 'jiuzhaigou': return $rawfile('jiuzhaigou.png')
    case 'guilin': return $rawfile('guilin.png')
    case 'qinghaihu': return $rawfile('qinghaihu.png')
    case 'changbaishan': return $rawfile('changbaishan.png')
    case 'lijiang': return $rawfile('lijiang.png')
    case 'sanya': return $rawfile('sanya.png')
    case 'daocheng': return $rawfile('daocheng.png')
    case 'kanasi': return $rawfile('kanasi.png')

    case 'gugong': return $rawfile('gugong.png')
    case 'changcheng': return $rawfile('changcheng.png')
    case 'bingmayong': return $rawfile('bingmayong.png')
    case 'dunhuang': return $rawfile('dunhuang.png')
    case 'budala': return $rawfile('budala.png')
    case 'yiheyuan': return $rawfile('yiheyuan.png')
    case 'tiantan': return $rawfile('tiantan.png')
    case 'longmen': return $rawfile('longmen.png')

    case 'suzhouyl': return $rawfile('suzhouyl.png')
    case 'pingyao': return $rawfile('pingyao.png')
    case 'dazu': return $rawfile('dazu.png')

    case 'waitan': return $rawfile('waitan.png')
    case 'hongyadong': return $rawfile('hongyadong.png')
    case 'gulangyu': return $rawfile('gulangyu.png')
    case 'chayan': return $rawfile('chayan.png')
    case 'liziba': return $rawfile('liziba.png')
    case 'csifs': return $rawfile('csifs.png')
    case 'datang': return $rawfile('datang.png')
    case 'taiguli': return $rawfile('taiguli.png')

    case 'disney': return $rawfile('disney.png')
    case 'gztower': return $rawfile('gztower.png')
    case 'wuhandq': return $rawfile('wuhandq.png')

    case 'kuanzhai': return $rawfile('kuanzhai.png')
    case 'huimin': return $rawfile('huimin.png')
    case 'fuzimiao': return $rawfile('fuzimiao.png')
    case 'wangfujing': return $rawfile('wangfujing.png')
    case 'hubu': return $rawfile('hubu.png')
    case 'zhongshan': return $rawfile('zhongshan.png')
    case 'jinli': return $rawfile('jinli.png')
    case 'nanluogu': return $rawfile('nanluogu.png')
    case 'chenghuang': return $rawfile('chenghuang.png')
    case 'taiping': return $rawfile('taiping.png')
    case 'jianshe': return $rawfile('jianshe.png')

    // 默认占位：使用故宫图作为兜底
    default: return $rawfile('gugong.png')
  }
}
