# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

default_tasks = [
  "スクワット3回",
  "その場で5秒間、軽く足踏み",
  "両手を組んで上に伸びる（10秒）",
  "立ったまま、かかとを上げ下げ5回",
  "壁に手をついて腕立て3回",
  "肩を後ろにゆっくり5回回す",
  "座ったまま、膝を左右交互に3回ずつ上げる",
  "つま先を上げ下げ5回",
  "椅子に座って、足首をゆっくり回す（左右3回ずつ）"
]

default_tasks.each do |name|
  Task.find_or_create_by!(user_id: nil, name: name)
end
