require 'riaction/iactionable/objects/i_actionable_object.rb'

module IActionable
  module Objects
    class Identifier < IActionableObject
      attr_accessor :id
      attr_accessor :id_hash
      attr_accessor :id_type
    end
  end
end