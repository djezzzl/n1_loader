# 3rd party service, or database, or anything else that can perform in batches
class Service
  def self.count
    @count ||= 0
  end

  def self.increase!
    @count = (@count || 0) + 1
  end

  def self.receive(*users)
    increase!

    users.flatten.map(&:object_id)
  end

  def self.single(user)
    user.object_id
  end
end