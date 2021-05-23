Fenix::App.helpers do
  def allow_route?(name)
    project_modules.find {|pmodule| pmodule.name == name }
  end

  def role_is?(name)
    (current_account.role.to_sym rescue :any).equal? name
  end

  def user_browser
    ua = request.env['HTTP_USER_AGENT']
    chrome = ua[/chrome\/(\w)*/i]
    ff = ua[/firefox\/(\w)*/i]
    safari = ua[/version\/(\w)*/i]
    br = :unknown
    br = :chrome if chrome
    br = :ff if ff
    br = :safari if safari

    v = (chrome||ff||safari).split('/').last.to_i rescue 0
    { v: v, br: br }
  end
end
