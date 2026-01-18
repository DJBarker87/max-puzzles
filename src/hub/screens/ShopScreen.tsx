import Header from '../components/Header'

/**
 * Shop screen placeholder - V3 feature
 * Will allow users to spend coins on avatar items
 */
export default function ShopScreen() {
  return (
    <div className="min-h-screen flex flex-col bg-background-dark">
      <Header title="Shop" showBack />

      <main className="flex-1 flex items-center justify-center">
        <div className="text-center p-4">
          <div className="text-6xl mb-4">🛒</div>
          <h1 className="text-2xl font-bold mb-2">Shop</h1>
          <p className="text-text-secondary">Coming in V3!</p>
          <p className="text-text-secondary text-sm mt-2">
            Spend your coins on cool avatar items
          </p>
        </div>
      </main>
    </div>
  )
}
