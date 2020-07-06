class OrderPart < ActiveRecord::Base
  enum state: [ :anew, :current, :finished ]

  belongs_to :order
  belongs_to :section
  
  # validates_presence_of     :boxes, :message => 'сколько коробок собрано', :if => :part_complete
  # 
  # def part_complete
  #   status == :finished
  # end

  def no_boxes?
    boxes == 0
  end
  
end
