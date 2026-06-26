// 商品数据服务 - 符合 ArkTS 规范
export interface Product {
  id: number
  name: string
  price: number
  originalPrice: number
  image: string
  category: string
  rating: number
  sales: number
  description: string
  stock: number
}

export interface CartItem {
  product: Product
  quantity: number
}

export class ProductService {
  private static instance: ProductService = new ProductService()

  private constructor() {}

  static getInstance(): ProductService {
    return ProductService.instance
  }

  // 商品分类
  readonly categories: string[] = ['智能设备', '传感器', '控制器', '安防设备', '健康监测']

  // 商品列表数据
  readonly products: Product[] = [
    { id: 1, name: '智能摄像头 Pro', price: 299, originalPrice: 399, image: 'camera', category: '智能设备', rating: 4.8, sales: 1256, description: '高清夜视，AI人形检测', stock: 50 },
    { id: 2, name: '智能门锁 S1', price: 899, originalPrice: 1199, image: 'lock', category: '安防设备', rating: 4.9, sales: 892, description: '指纹密码，多种开锁方式', stock: 25 },
    { id: 3, name: '温湿度传感器', price: 59, originalPrice: 79, image: 'sensor', category: '传感器', rating: 4.6, sales: 2341, description: '精准监测，联动空调', stock: 100 },
    { id: 4, name: '智能插座', price: 49, originalPrice: 69, image: 'outlet', category: '控制器', rating: 4.7, sales: 3567, description: '远程控制，定时开关', stock: 200 },
    { id: 5, name: '智能窗帘电机', price: 299, originalPrice: 399, image: 'curtain', category: '控制器', rating: 4.5, sales: 678, description: '静音设计，手机控制', stock: 30 },
    { id: 6, name: '人体感应开关', price: 39, originalPrice: 59, image: 'pir', category: '传感器', rating: 4.4, sales: 1890, description: '人来灯亮，智能联动', stock: 150 },
    { id: 7, name: '智能空气检测仪', price: 199, originalPrice: 299, image: 'air', category: '健康监测', rating: 4.8, sales: 543, description: 'PM2.5甲醛检测', stock: 40 },
    { id: 8, name: '智能灯泡', price: 29, originalPrice: 49, image: 'bulb', category: '智能设备', rating: 4.3, sales: 4567, description: '色温调节，语音控制', stock: 300 },
    { id: 9, name: '门窗传感器', price: 35, originalPrice: 49, image: 'door', category: '安防设备', rating: 4.5, sales: 1234, description: '实时监测，远程报警', stock: 120 },
    { id: 10, name: '智能音箱 Mini', price: 199, originalPrice: 299, image: 'speaker', category: '智能设备', rating: 4.7, sales: 2156, description: '语音控制，音乐播放', stock: 60 }
  ]

  // 根据分类获取商品
  getProductsByCategory(category: string): Product[] {
    return this.products.filter(p => p.category === category)
  }

  // 获取热门商品
  getHotProducts(): Product[] {
    return this.products.sort((a, b) => b.sales - a.sales).slice(0, 6)
  }

  // 获取商品详情
  getProductById(id: number): Product | undefined {
    return this.products.find(p => p.id === id)
  }

  // 搜索商品
  searchProducts(keyword: string): Product[] {
    return this.products.filter(p =>
      p.name.includes(keyword) || p.description.includes(keyword)
    )
  }
}