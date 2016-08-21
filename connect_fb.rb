# coding: utf-8
require 'koala'
require 'mechanize'
require 'highline/import'
require 'yaml'

class FB
  attr_reader :user, :users
  
  def initialize
    load_config # le as configuracoes do app
    # conecta com a Graph API
    puts "Conectando..."
    @oauth = Koala::Facebook::OAuth.new(@config['app_id'], @config['app_secret'], @config['url'])
    load_users # le o arquivo dos usuarios
    @user = @users.last
    puts "Conectado como #{@user['email']}"
    @graph = Koala::Facebook::API.new(@user['token'])
  end

  # reconecta com um usuario aleatorio
  def reconnect
    @user = @users.sample
    @graph = Koala::Facebook::API.new(@user['token'])
  end
  
  # o fb pagina alguns resultados
  # este metodo aplica o bloco &block em todas as paginas
  def total(klass, &block)
    loop do
      break if(!klass)
      klass.each(&block)
      klass = next_page klass
    end
  end

  def connect(id, type, args = {})
    begin
      if type == "self"
        return @graph.get_object(id, args)
      else
        return @graph.get_connections(id, type, args)
      end
    rescue Exception => e
      puts e.message
      puts e.backtrace
    end
  end

  def total_likes(id)
    pg = connect(id, "self", fields: "likes.summary(true)")
    begin
      return pg['likes']['summary']['total_count']
    rescue Exception => e
      puts e.message
    end
  end

  def get_page(id)
    connect(id, "self", fields: ["engagement", "name", "category"])
  end

  def brazilian?(id)
    array = connect(id, "insights/page_fans_country")
    paises = array[0]["values"][0]["value"]
    return paises["BR"] == paises.values.max
  end

  # cria um usuario e guarda no arquivo .users
  def new_user
    users = File.zero?('.users') ? [] : YAML.load_file('.users')
    user = {}
    user['email'] = ask "Digite seu email"
    pswd = ask("Digite sua senha do Facebook") { |q| q.echo = '*' }

    begin
      code = get_access_code(@oauth.url_for_oauth_code, user['email'], pswd)
    rescue Koala::Facebook::APIError => e
      puts "Houve um erro ao resgatar o token de autorização. Copie e cole o seguinte URL"
      puts "em um browser, autorize o app e tente novamente"
      puts @oauth.url_for_oauth_code
      exit
    end
    user['token'] = @oauth.get_access_token(code)
    users << user
    File.open('.users','w') do |f|
      f.write users.to_yaml
    end
  end
  
  private
  # pega ou cria um arquivo de configuracao
  def load_config
    unless File.exist? '.config'
      File.open('.config','w') do |f|
        config = {}
        config['url'] = ask "Digite o URL do app"
        # "http://gpopai.usp.br/"
        config['app_id'] = ask "Digite seu app id"
        config['app_secret'] = ask "Digite seu app secret"
        f.write config.to_yaml
      end
    end
    @config = YAML.load_file(".config")
  end

  def get_access_code(page, email, pswd)
    @agent = Mechanize.new
    @agent.redirect_ok = :all
    @agent.follow_meta_refresh = :anywhere

    page = @agent.get page
    form = page.form_with(method: "POST")
    form.email = email
    form.pass = pswd
    @agent.submit form
    uri = URI(@agent.page.uri)
    CGI.parse(uri.query)['code'].first
  end

  # le o arquivo de usuarios e guarda em um atributo
  # se o arquivo estiver vazio cria um usuario
  def load_users
    new_user if File.zero?('.users')
    @users = YAML.load_file('.users')
  end

  # Proxima pagina de resultados paginados
  def next_page(klass)
    begin
      return klass.next_page if klass
    rescue
      sleep 3
      return next_page klass
    end
  end
end

Facebook = FB.new
