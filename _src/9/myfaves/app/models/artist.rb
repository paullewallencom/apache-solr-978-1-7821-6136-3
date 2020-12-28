class Artist < ActiveRecord::Base
  searchable do
    text :name, :default_boost => 2
    string :group_type
#    time :release_date
  end
end
