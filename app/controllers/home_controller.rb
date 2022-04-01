require 'smarter_csv'
require 'classifier-reborn'
require 'net/http'
class HomeController < ApplicationController
  def index
    @errors = ""
    @categories = ""
    @news = session[:news] || ""
    if session[:come_from_import] === 1
      @errors = session[:error]
      @categories = session[:categories]
      @class_text = session[:class_text]
    else
      session[:error] = ""
      session[:class_text] = ""
      session[:categories] = ""
      session[:class_text] = ""
    end
    session[:come_from_import] = 0
  end


  def download
    send_file 'app/assets/docs/arquivo.csv', type: 'text/csv', status: 202
  end

  def import
    array = []
    begin
      file = SmarterCSV.process(params[:file],{:chunk_size => 2})
      file.each do |row|
        array.push(row[0][:category])
      end
      arry_uniq = array.compact.uniq
      if arry_uniq.empty?
        generate_error("Seu arquivo não tem as colunas feitas corretamente, por favor reveja")
      else
        clear_msg
        training_model(file, arry_uniq)
        session[:categories] = arry_uniq
        session[:news] = get_news
      end
      session[:come_from_import] = 1
      redirect_to root_path
    rescue
      generate_error("Ouve erro em carregar o seu csv, por favor, tente novamente")
      session[:come_from_import] = 1
      redirect_to root_path
    end
  end

  def classify
    input = params[:text]
    classification = ""
    if !input.empty?
      classification = @@classifier.classify input
      session[:class_text] = "Seu Texto foi classificado como " + classification
    else
      generate_error("Você precisa colocar um texto para ser classificado")
    end
    session[:come_from_import] = 1
    redirect_to root_path
  end

  private
  def generate_error(msg)
    session[:error]= msg
  end

  def clear_msg
    session[:error]=""
  end

  def get_news
    begin
      uri = URI("https://inshortsapi.vercel.app/news?category=all")
      response=Net::HTTP.get(uri)
      data = JSON.parse response
      return data['data'][5]["content"]
    rescue
      return "Infelizmente estamos sem noticias"
    end
  end

  def training_model(file, categories)
    begin
      @@classifier = ClassifierReborn::Bayes.new categories
      file.each do |row|
        @@classifier.train row[0][:category], row[0][:text]
      end
    rescue
      generate_error("Houve um erro no treinamento do modelo")
    end
  end
end
