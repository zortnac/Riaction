require 'riaction/iactionable/objects/i_actionable_object.rb'

module IActionable
  module Objects
    class PointType < IActionableObject
      attr_accessor :key
      attr_accessor :name
    end
  end
end