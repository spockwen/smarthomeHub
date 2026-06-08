// 购物车服务 - 符合 ArkTS 规范
import { Product, CartItem, ProductService } from './ProductService'

export class CartService {
  private static instance: CartService = new CartService()
  private cartItems: CartItem[] = []

  private constructor() {}

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
  addToCart(product: Product): void {
    const existingItem = this.cartItems.find(item => item.product.id === product.id)
    if (existingItem) {
      existingItem.quantity++
    } else {
      this.cartItems.push({ product: product, quantity: 1 })
    }
  }

  // 从购物车移除商品
  removeFromCart(productId: number): void {
    this.cartItems = this.cartItems.filter(item => item.product.id !== productId)
  }

  // 更新商品数量
  updateQuantity(productId: number, quantity: number): void {
    const item = this.cartItems.find(item => item.product.id === productId)
    if (item) {
      if (quantity <= 0) {
        this.removeFromCart(productId)
      } else {
        item.quantity = quantity
      }
    }
  }

  // 清空购物车
  clearCart(): void {
    this.cartItems = []
  }

  // 检查商品是否在购物车中
  isInCart(productId: number): boolean {
    return this.cartItems.some(item => item.product.id === productId)
  }
}