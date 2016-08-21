# coding: utf-8
require './connect_fb.rb'
require './modules.rb'
require 'progress_bar'

RAND_CONST = 30
CATEGORIES = [
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
  "Community",
  "Political Party",
  "Politician",
  "Journalist",
  "Cause"
  #  "Education",
  #  "Author",
  #  "Teacher",
  #  "Writer",
  #  "Education Website",
]

if ARGV.size >= 1 && ARGV[0] == "-u"
  Facebook.new_user
  exit
end

# primeira página é arbitrária e precisa ser dada pelo usuário
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
  # pega a pg com mais likes dentre as que ainda não foram visitadas
  from = Page.order(likes_count: :desc).where(category: categories).where(visited: false).limit(1).first
  from.visited = true
  from.save

  # imprime algumas estatisticas de progresso
  puts "#{from.name} - #{from.likes_count} (#{from.category})"
  nodes = Page.where(category: categories).count
  visited = Page.where(visited: true).count
  percent = (100.0*visited/nodes).round 2
  puts "#{nodes} nós (#{visited} visitados #{percent}%) e #{Like.count} arestas (#{(Like.count/visited.to_f).round 2})"

  # pega todos os likes de paginas brasileiras
  likes = Facebook.connect(from.fb_id, "likes", {limit: 300})
  next if likes.size == 0
  bar = ProgressBar.new size  
  Facebook.total(likes) do |like|
    bar.increment!
    id = like['id']
    pg = Facebook.get_page(id)

    begin
      # pula se não for brasileira
      next unless Facebook.brazilian?(id)
      to = (Page.find_by_fb_id(id) or
            Page.create(fb_id: id,
                        name: pg['name'],
                        likes_count: pg["engagement"]["count"],
                        category: pg['category'],
                        visited: false))
      Like.create(from: from, to: to)
    rescue Koala::Facebook::APIError => e
      puts e.message
      puts e.error_type
      # se der um erro de limite de requisições, reconecta
      next
    rescue Exception => e
      puts e.message
      next
    end
  end

  # sorteia um usuário novo de tempos em tempos
  if Random.rand(RAND_CONST) == 0
    puts "Reconectando..."
    Facebook.reconnect
    puts "Conectado como #{Facebook.user['email']}"
  end

end
