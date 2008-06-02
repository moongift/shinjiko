class AccountController < ApplicationController
  # Be sure to include AuthenticationSystem in Application Controller instead
  layout 'default'
  # say something nice, you goof!  something sweet.
  def index
    redirect_to(:action => 'signup') unless logged_in? || User.count > 0
  end
  
  def api_login
    return render(:status => 401, :text => _('Invalid request')) unless request.post?
    self.current_user = User.authenticate(params[:Email], params[:Passwd])
    if logged_in?
      Api.create :session => session.session_id, :user => self.current_user, :expired_at => Time.now + 60 * 60
      return render(:text => "Auth=#{session.session_id}")
    end
    return render(:status => 403, :text => _('Message=Authorization failed'))
  end
  
  def cookie_login
    location = params[:continue]
    api = Api.find(:first, :conditions => ['session = ? and expired_at >= ?', params[:auth], Time.now])
    unless api or api.user
      return render(:status => 302, :text => _('Message=Authorization failed'))
    end
    self.current_user = api.user
    a = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a + ['-', '+', '~', '=', "!", "#"]
    s = Array.new(120){a[rand(a.size)]}.join
    api.cookie = s
    cookies[:ACSID] = {:value => s, :expires => Time.now + 1.day}
    api.save
    return redirect_to(params[:continue])
  end
  
  def login
    return unless request.post?
    self.current_user = User.authenticate(params[:login], params[:password])
    if logged_in?
      if params[:remember_me] == "1"
        self.current_user.remember_me
        cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
      end
      redirect_back_or_default(:controller => :issue, :action => :index)
      flash[:notice] = "Logged in successfully"
    end
  end

  def signup
    @user = User.new(params[:user])
    return unless request.post?
    @user.save!
    self.current_user = @user
    redirect_back_or_default(:controller => :issue, :action => :index)
    flash[:notice] = "Thanks for signing up!"
  rescue ActiveRecord::RecordInvalid
    render :action => 'signup'
  end
  
  def logout
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session
    flash[:notice] = "You have been logged out."
    redirect_back_or_default(:controller => :issue, :action => :index)
  end
end