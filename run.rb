# coding: utf-8
require './connect_fb.rb'
require './modules.rb'
require 'progress_bar'

#TODO Paralelizar

categories = [
#  "Education",
  "Media/News/Publishing",
  "News/Media Website",
  "Society/Culture Website",
  "Magazine",
  "Public Figure",
  "Organization",
  "Government Organization",
  "Political Organization",
  "Non-Profit Organization",
  "Community Organization",
  "Non-Governmental Organization (NGO)",
#  "Education Website",
  "Community",
  "Political Party",
  "Politician",
  "Journalist",
#  "Author",
#  "Teacher",
#  "Writer",
  "Cause"
]

unless Page.exists?
  print "Digite o id de uma página para começar: "
  pg = Facebook.get_page(gets.chomp)
  from = Page.create(fb_id: pg['id'],
                     name: pg['name'],
                     likes_count: pg["engagement"]["count"],
                     category: pg['category'],
                     visited: false)
end

loop do
  from = Page.order(likes_count: :desc).where(category: categories).where(visited: false).limit(1).first
  from.visited = true
  from.save

  puts "#{from.name} - #{from.likes_count} (#{from.category})"
  nodes = Page.where(category: categories).count
  visited = Page.where(visited: true).count
  percent = (100.0*visited/nodes).round 2
  puts "#{nodes} nós (#{visited} visitados #{percent}%) e #{Like.count} arestas (#{(Like.count/visited.to_f).round 2})"
  likes = Facebook.connect(from.fb_id, "likes", {limit: 300})
  size = likes.size == 0 ? 1 : likes.size
  bar = ProgressBar.new size  
  Facebook.total(likes) do |like|
    bar.increment!
    pg = Facebook.get_page(like['id'])

    begin
      paises = pg['insights']['data'][0]["values"][0]["value"]
      next if paises["BR"] < paises.values.max
    rescue
      next
    end

    to = (Page.find_by_fb_id(like['id']) or
          Page.create(fb_id: like['id'],
                      name: pg['name'],
                      likes_count: pg["engagement"]["count"],
                      category: pg['category'],
                      visited: false))
    Like.create(from: from, to: to)
  end
end
