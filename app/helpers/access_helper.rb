Fenix::App.helpers do
  LEVEL0_NAMES = %i[order draw list timeline sys].freeze
  LEVEL0_ROLES = %i[
    admin user editor manager director
    stickerman supplier sectioner limsectioner stager].freeze

  LEVEL1_ACCESS = {
    order: {
      create: 1,
      confirm: 2,
      fact: 4,
      modify: 8
    },
    list: {
      draft: 1,
      current: 2,
      finished: 4,
      archive: 8,
      stickers: 16
    },
    timeline: {
      all: 1,
      stickers: 2,
      trips: 4
    },
    draw: {
      create: 1,
      all: 2
    },
    sys: {
      editors: 1,
      stats: 2,
      stock: 4,
      archetypes: 8,
      sync: 16,
      prefs: 32
    }
  }.freeze

  LEVEL2_ACCESS = {
    1 => 2**1,
    2 => 2**2,
    3 => 2**3,
    4 => 2**4,
    5 => 2**5,
    6 => 2**6
  }.freeze

  LEVEL3_ACCESS = {
    sections: {
      draft: LEVEL2_ACCESS,
      list: LEVEL2_ACCESS,
      complete: LEVEL2_ACCESS,
      sum: LEVEL2_ACCESS,
      stock: LEVEL2_ACCESS
    }
  }.freeze

  LEVEL4_ACCESS = {
    stock: {
      any: 1,
      all: 2,
      archetypes: 4
    },
    list: {
      draft: 1
    },
    draw: {
      any: 1
    }
  }.freeze

  # TESTA = { order: 2, list: 0, timeline: 1, sys: 23 }
  # TESTAS = { draft: 4, list: 6, sum: 0, stock: 62 }
  AH_ROLE_NONE = { sections: 1, btn: {} }.freeze
  AH_ROLE_STICKER = { list: 18, timeline: 7, sys: 4, draw: 3,
    sections: { list: (1..6).sum{|d|2**d}, complete: (1..6).sum{|d|2**d} },
    btn: { stock: 3, draw: 1 }
  }.freeze
  AH_ROLE_MNG = { order: 9, list: 31, timeline: 7, sys: 15, sections: (1..6).sum{|d|2**d}, btn: { stock: 7 } }.freeze
  AH_ROLE_LSC = { order: 0, list: 0, timeline: 0, sys: 0, btn: { stock: 3 } }.freeze
  AH_ROLE_FSC = { order: 1, list: 0, timeline: 1, sys: 9, btn: { stock: 7, list: 1 } }.freeze
  AH_ROLE_STG = { sections: 0, btn: {} }.freeze

  def can_view?(dir, sub = nil, user: current_account.id)
    @kc_access_user ||= CabiePio.get([:m, :access, :user], user).data || AH_ROLE_NONE
    kcr = @kc_access_user[dir] || 0
    la = LEVEL1_ACCESS[dir]
    la = la.fetch(sub, nil) unless sub.nil?
    (la & kcr) > 0
  end

  def can_view_section?(dir, sub, section, user: current_account.id)
    @kc_access_user ||= CabiePio.get([:m, :access, :user], user).data || AH_ROLE_NONE
    kcr = @kc_access_user[dir].fetch(sub, 0) rescue @kc_access_user[dir]
    (LEVEL3_ACCESS[dir].fetch(sub, nil).fetch(section, 0) & kcr) > 0
  end

  def can_view_any_section?(dir, sub, user: current_account.id)
    @kc_access_user ||= CabiePio.get([:m, :access, :user], user).data || AH_ROLE_NONE
    kcr = @kc_access_user[dir].fetch(sub, 0) rescue @kc_access_user[dir]
    (LEVEL3_ACCESS[dir].fetch(sub, nil).values.sum & kcr) > 0
  end

  def can_view_stickers?
    can_view_section?(:sections, :sum, 1)
  end

  def can_view_all?(dir, sub, user: current_account.id)
    @kc_access_user ||= CabiePio.get([:m, :access, :user], user).data || AH_ROLE_NONE
    kcr = @kc_access_user[dir].fetch(sub, 0) rescue @kc_access_user[dir]
    LEVEL3_ACCESS[dir].fetch(sub, nil).values.sum == kcr
  end

  def can_btn_view?(dir, sub = nil, user: current_account.id)
    @kc_access_user ||= CabiePio.get([:m, :access, :user], user).data || AH_ROLE_NONE
    kcr = @kc_access_user.fetch(:btn, {})[dir] || 0
    (LEVEL4_ACCESS[dir].fetch(sub, nil) & kcr) > 0
  end

  def print_ac_view(**args)
    mtx = []
    LEVEL1_ACCESS.each do |k,v|
      v.each do |r, bw|
        mtx << [[k,r], can_view?(k,r, **args)]
      end
    end
    @kc_access_user = nil
    mtx
  end

  def print_ac_sections_view(**args)
    mtx = {}
    LEVEL3_ACCESS.each do |k,v|
      v.each do |r, bw|
        mtx[[k,r]] = []
        s = Section.all
        s.each do |ars|
          mtx[[k,r]] << [[k,r], [ars.name, ars.id], can_view_section?(k,r, ars.id, **args)]
        end
      end
    end
    @kc_access_user = nil
    mtx
  end

  def ac_bit_section
    (1..6).sum{|d|2**d}
  end

  def ac_admin_template
    tpl = { sections: ac_bit_section }
    LEVEL1_ACCESS.each do |k,v|
      tpl[k] = v.sum do |r, bw|
        bw
      end
    end
    tpl
  end

  def combine_rights(role, sections = nil)
    achash = {
      sectioner: AH_ROLE_FSC, limsectioner: AH_ROLE_LSC, admin: ac_admin_template,
      stickerman: AH_ROLE_STICKER, manager: AH_ROLE_MNG, stager: AH_ROLE_STG
    }
    wonderbox_set(:ac, achash)
    template = wonderbox(:ac, role) || {}

    if [:sectioner, :limsectioner].include? role
      bws = (sections || []).sum{|a|2**a}
      section_part = { list: bws, stock: bws, complete: bws }
      section_part = section_part.merge(draft: bws, sum: bws) if role == :sectioner
      template[:sections] = section_part
    end
    template
  end

  def kc_save_box_ac(user, ac)
    CabiePio.set [:m, :access, :user], user, ac
    @kc_access_user = nil
  end

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
