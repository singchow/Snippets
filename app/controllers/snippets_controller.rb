class SnippetsController < ApplicationController
  # Switches to use snippet_layout.html.erb instead of application.html.erb
  require 'coderay'
  layout 'dashboard_layout'
  before_action :set_snippet, only: [:show, :edit, :update, :destroy]
  before_action :auth_user
  # impressionist :actions => [:show, :index]

  # GET /snippets
  # GET /snippets.json
  def index
    @snippets = Snippet.all.order(snippet_view_count: :desc)
    puts @snippets.first
    puts "Snippet ID here"
  end

  def save_favorite
    # Get user ID
    # @user = User.find_by()
    @user = User.find_by(email: session[:current_user_email])

    @snippet = Snippet.find(params[:id])

    @fav = Favorite.new(user_id: @user.id, snippet_id: @snippet.id)
    if @fav.save
    puts "getting favorite id"
    puts params[:id]
    respond_to do |format|
      format.html { redirect_to @snippet, notice: 'Snippet was successfully Favorite.' }
      format.json { render :show, status: :created, location: @snippet }
    end
    else
      puts @fav.errors.full_messages
      flash[:alert] = @fav.errors.full_messages
      puts flash[:alert]
      format.html { redirect_to @snippet, notice: 'Snippet was successfully Favorite.' }
      format.json { render json: @snippet.errors, status: :unprocessable_entity }
    end
  end

  def favorites
    @personaluserid =  User.find_by(email: session[:current_user_email])
    @favSnippetId = @personaluserid.favorites.flat_map {|x| x.snippet_id}
    @favSnippets = Snippet.all.where(id: @favSnippetId.uniq)

    @welcomemsg = "#{@personaluserid.username}'s personal snippets collection"
  end

  # Shiung's addition
  # Copying from UsersController

  # GET /snippets/1
  # GET /snippets/1.json
  def show
    @snippet.snippet_content = CodeRay.scan(@snippet.snippet_content, :ruby).div(:line_numbers => :table)

    @snippetuser = User.find_by(email: session[:current_user_email])
    @hasFavorite = @snippetuser.favorites.find_by(snippet_id:  @snippet.id)
    puts "Getting user favorite"
    puts @hasFavorite.blank?
  end

  # GET /snippets/new
  def new
    if(session.has_key?("current_user_email"))
    @snippet = Snippet.new
    @snippetuser = User.find_by(email: session[:current_user_email])
    puts @snippetuser.email
  else
    flash[:alert] = "You must be logged in to access this section."
    redirect_to "/login"
  end
  end

  # GET /snippets/1/edit
  def edit
  end

  # POST /snippets
  # POST /snippets.json
  def create
    # Associate User to Snippets

    @snippetuser = User.find_by(email: session[:current_user_email])
    @snippet = @snippetuser.snippets.create(snippet_params)

    respond_to do |format|
      if @snippet.save
        format.html { redirect_to @snippet }
        format.json { render :show, status: :created, location: @snippet }
      else
        format.html { render :new }
        format.json { render json: @snippet.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /snippets/1
  # PATCH/PUT /snippets/1.json
  def update
    respond_to do |format|
      if @snippet.update(snippet_params)
        format.html { redirect_to @snippet, notice: 'Snippet was successfully updated.' }
        format.json { render :show, status: :ok, location: @snippet }
      else
        format.html { render :edit }
        format.json { render json: @snippet.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /snippets/1
  # DELETE /snippets/1.json
  def destroy
    @snippet.destroy
    respond_to do |format|
      format.html { redirect_to snippets_url, notice: 'Snippet was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
  def auth_user
    if(!session.has_key?("current_user_email"))
      flash[:alert] = "You must be logged in to access this section."
        redirect_to "/login" and return
    end
  end
    # Use callbacks to share common setup or constraints between actions.
    def set_snippet
      @snippet = Snippet.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def snippet_params
      params.require(:snippet).permit(:snippet_title, :snippet_description, :snippet_content, :snippet_view_count)
    end
end
