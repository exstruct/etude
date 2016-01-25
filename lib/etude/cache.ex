defprotocol Etude.Cache do
  def get(cache, key)
  def put(cache, key, value)
  def memoize(cache, key, fun)
  def delete(cache, key)
  def clear(cache)
end
