defprotocol Etude.Cache do
  def get(cache, key)
  def put(cache, key, value)
  def put_new_lazy_and_return(cache, key, fun)
  def clear(cache)
end
