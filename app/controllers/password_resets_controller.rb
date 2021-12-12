class PasswordResetsController < ApplicationController
  before_action :get_user,         only: [:edit, :update]
  before_action :valid_user,       only: [:edit, :update]
  before_action :check_expiration, only: [:edit, :update]
  
  def new
  end
  
  def create
    @user = User.find_by(email: params[:password_reset][:email].downcase)
      if @user
        @user.create_reset_digest
        @user.send_password_reset_email
        flash[:info] = "送信されたメールからパスワードの変更を行ってください。"
        redirect_to root_url
      else
        flash.now[:danger] = "メールアドレスが見つかりません"
        render 'new'
      end
  end

  def edit
  end
  
  def update
    if params[:user][:password].empty?  #新しいパスワードが空文字列になっていないか
      @user.errors.add(:password, :blank)
      render 'edit'
    elsif @user.update(user_params) #新しいパスワードが正しければ、更新する
      log_in @user
      flash[:success] = "パスワードが変更されました" #
      redirect_to @user
    else                     #無効なパスワードだった場合
      render 'edit'
    end
  end
  
  def password_reset_expired?
    reset_sent_at < 2. hours.ago
  end
  
  private
    def user_params
      params.require(:user).permit(:password, :password_confirmation)
    end
    
    #beforeフィルタ
    
    def get_user
      @user = User.find_by(email: params[:email])
    end
    
    # 正しいユーザーかどうか確認する
    def valid_user
      unless (@user && @user.activated? &&
              @user.authenticated?(:reset, params[:id]))
        redirect_to root_url
      end
    end
    
    #期限切れかどうかを確認する
    def check_expiration
      if @user.password_reset_expired?
        flash[:danger] = "Password resset has expired."
        redirect_to new_password_reset_url
      end
    end
end
