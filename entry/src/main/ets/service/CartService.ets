// 购物车服务 - 符合 ArkTS 规范
import { Product, CartItem, ProductService } from './ProductService'

export class CartService {
  private static instance: CartService = new CartService()
  private cartItems: CartItem[] = []

  private constructor() {
    this.loadFromStorage()
  }

  // 从存储加载购物车数据
  private loadFromStorage(): void {
    try {
      // 使用AppStorage获取购物车数据
      if (AppStorage.has('cart_items')) {
        const stored = AppStorage.get<string>('cart_items')
        if (stored) {
          const parsed = JSON.parse(stored) as CartItem[]
          // 确保数据格式正确
          if (Array.isArray(parsed)) {
            this.cartItems = parsed
          }
        }
      }
    } catch (error) {
      console.error('Failed to load cart from storage:', error)
    }
  }

  // 保存购物车数据到存储
  private saveToStorage(): void {
    try {
      AppStorage.set('cart_items', JSON.stringify(this.cartItems))
    } catch (error) {
      console.error('Failed to save cart to storage:', error)
    }
  }

  static getInstance(): CartService {
    return CartService.instance
  }

  // 获取购物车商品列表
  getItems(): CartItem[] {
    return this.cartItems
  }

  // 获取购物车商品数量
  getCount(): number {
    return this.cartItems.reduce((sum, item) => sum + item.quantity, 0)
  }

  // 获取购物车总价格
  getTotalPrice(): number {
    return this.cartItems.reduce((sum, item) => sum + item.product.price * item.quantity, 0)
  }

  // 添加商品到购物车
  addToCart(product: Product): boolean {
    const existingItem = this.cartItems.find(item => item.product.id === product.id)
    if (existingItem) {
      // 检查库存
      if (existingItem.quantity >= product.stock) {
        return false // 库存不足
      }
      existingItem.quantity++
    } else {
      // 检查库存
      if (product.stock <= 0) {
        return false // 库存不足
      }
      this.cartItems.push({ product: product, quantity: 1 })
    }
    this.saveToStorage()
    return true
  }

  // 从购物车移除商品
  removeFromCart(productId: number): void {
    this.cartItems = this.cartItems.filter(item => item.product.id !== productId)
    this.saveToStorage()
  }

  // 移除商品（别名，与CartPage中调用保持一致）
  removeItem(productId: number): void {
    this.removeFromCart(productId)
  }

  // 更新商品数量
  updateQuantity(productId: number, quantity: number): boolean {
    const item = this.cartItems.find(item => item.product.id === productId)
    if (item) {
      if (quantity <= 0) {
        this.removeFromCart(productId)
        return true
      } else {
        // 检查库存
        if (quantity > item.product.stock) {
          return false // 库存不足
        }
        item.quantity = quantity
        this.saveToStorage()
        return true
      }
    }
    return false
  }

  // 清空购物车
  clearCart(): void {
    this.cartItems = []
    this.saveToStorage()
  }

  // 检查商品是否在购物车中
  isInCart(productId: number): boolean {
    return this.cartItems.some(item => item.product.id === productId)
  }

  // 检查购物车中是否有库存不足的商品
  hasOutOfStockItems(): boolean {
    for (let i = 0; i < this.cartItems.length; i++) {
      const item = this.cartItems[i]
      if (item.quantity > item.product.stock) {
        return true
      }
    }
    return false
  }

  // 获取库存不足的商品列表
  getOutOfStockItems(): CartItem[] {
    const outOfStock: CartItem[] = []
    for (let i = 0; i < this.cartItems.length; i++) {
      const item = this.cartItems[i]
      if (item.quantity > item.product.stock) {
        outOfStock.push(item)
      }
    }
    return outOfStock
  }

  // 检查是否可以结算（所有商品都有足够库存）
  canCheckout(): boolean {
    return !this.hasOutOfStockItems()
  }
}