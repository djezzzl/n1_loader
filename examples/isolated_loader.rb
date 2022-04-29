require 'n1_loader'

class IsolatedLoader < N1Loader::Loader
  def perform(elements)
    elements.each { |element| fulfill(element, [element]) }
  end
end

objects = [1, 2, 3, 4]
loader = IsolatedLoader.new(objects)
objects.each do |object|
  loader.for(object) # => it has no N+1 and it doesn't require to be injected in the class
end