#for methods involving header, breadcrumbs and nav's
module HeaderHelper
  def set_header_defaults
    @meta_tags ||= {}
    default_description = 'Queriac allows you to manage your quicksearches, shortcuts, and bookmarklets by taking them out of your browser profile and onto the web.'
    @meta_tags[:description] ||= default_description
    @meta_tags[:keywords] ||= 'firefox smart keywords, quicksearches, shortcuts, bookmarklets, commands, user commands, options, queries, web commands'
    @title ||= set_breadcrumb_title
    
    #combine title + default description unless there's a new description or everything's default(ie home page)
    @meta_tags[:description] = "#{@title.downcase} - #{@meta_tags[:description]}" unless @meta_tags[:description] != default_description || @title == default_title
    #make paginated pages unique
    @title += " - Page #{params[:page]}" if params[:page].to_i > 1
    @meta_tags[:description] += " - Page #{params[:page]}" if params[:page].to_i > 1
    @meta_tags[:keywords] += " - Page #{params[:page]}" if params[:page].to_i > 1
  end
  
  def set_header(hash)
    @title = hash[:title] if hash[:title]
    @meta_tags ||= {}
    [:description, :keywords, :robots].each do |key|
      @meta_tags[key] = hash[key] if hash[key]
    end
    set_header_defaults
  end
  
  def default_title
    "Queriac. All our quicksearches are belong to us."
  end
  
  def set_rss_header_defaults
    @title ||= default_title
  end
  
  def set_breadcrumb_title
    if breadcrumbs.empty?
      title = default_title
    else
      title_array = breadcrumbs.dup
      title_array.shift
      title = title_array.map {|e| e.is_a?(Array) ? e[0].tr(" ", '_').titleize : e.tr(' ', '_').titleize }.join(" ")
    end
    title
  end
  
  def render_nav
    if breadcrumbs.empty?
      link_to('queriac', home_path)
    else
      breadcrumbs.map {|e| e.is_a?(Array) ? link_to(*e) : e }.join(" &raquo; ")
    end
  end
  
  def breadcrumbs
    @breadcrumbs ||= get_crumbs
  end
  
  #can use boolean @breadcrumbs_allowed to include/exclude actions from breadcrumbs
  def get_crumbs
    crumbs = [['queriac', home_path]]
    return [] unless @breadcrumbs_allowed
    #set_command filter
    if @command
      crumbs << ["commands", commands_path]
      crumbs << [@command.to_param.to_s, command_path(@command)]
      if params[:controller] == 'queries'
        crumbs << 'queries'
      elsif params[:controller] == 'user_commands'
        crumbs << 'user commands'
      end
    #most are set_user_command filter
    elsif @user_command
      crumbs << [@user_command.user.login, user_home_path(@user_command.user)]
      crumbs << [@user_command.keyword, public_user_command_path(@user_command)]      
      if params[:controller] == 'queries'
        crumbs << 'queries'
      end
    elsif @user
      crumbs << [@user.login, user_home_path(@user)]
      if params[:controller] == 'queries'
        crumbs << 'queries'
        add_tags_to_crumbs(crumbs)
      elsif params[:controller] == 'user_commands'
        crumbs << 'user commands'
        add_tags_to_crumbs(crumbs)
      end
    #index-ish user_controller actions
    elsif @user_commands && params[:controller] == 'user_commands'
      crumbs << ['user commands', user_commands_path]
      add_tags_to_crumbs(crumbs)
    elsif @commands && params[:controller] == 'commands'
      crumbs << ['commands', commands_path]
      add_tags_to_crumbs(crumbs)
    elsif @users && params[:controller] = 'users'
      crumbs << ['users', users_path]
    elsif @queries && params[:controller] == 'queries'
      crumbs << ['queries', queries_path]
      add_tags_to_crumbs(crumbs)
    elsif params[:controller] == 'tags'
      crumbs << ['tags', tags_path]
    elsif params[:controller] == 'static'
      crumbs << params[:static_page]
    end
    crumbs
  rescue
    logger.info "BREADCRUMB FAILED: "
    logger.info $!
    logger.info "breadcrumb_parent: #{@breadcrumb_parent}"
    logger.info "crumbs: #{crumbs.inspect}"
    ['queriac', home_path]
  end
  
  def add_tags_to_crumbs(crumbs)
    if ! @tags.blank?
      crumbs << "tag"
      crumbs << @tags.join("+")
    end
  end
  
  def render_mininav
    items = []
    items << "Logged in as " + link(current_user.login, user_home_path(current_user), :class => "bold") if logged_in?
    # items << link(current_user.login, user_home_path(current_user), :class => "bold") if logged_in?
    items << link("Account Settings", settings_path) if logged_in?
    items << link("Setup Instructions", static_page_path('setup')) if logged_in?
    items << link("Help", static_page_path('help'))
    # TODO: Fix "session_url failed to generate from" error..
    # items << link_to("Logout", session_path(session), :confirm => "Are you sure you want to log out?", :method => :delete) if logged_in?
    items << link("Sign up", new_user_path) unless logged_in?
    items << link("Log in", new_session_path) unless logged_in?
    output = ""
    items.each_with_index do |item, index|
      klass = (index == items.size-1) ? 'class="last"' : ''
      output << "<li #{klass}>#{item}</li>"
    end
    content_tag(:ul, output)
  end
  
  def footer_nav
    items = []
    items << link_to_unless_current("Home", home_path)
    items << link_to_unless_current("Commands", commands_path)
    items << link_to_unless_current("User Commands", user_commands_path)
    items << link_to_unless_current("Tags", tags_path)
    items << link_to_unless_current("Queries", queries_path)
    content_tag(:ul, convert_to_list_items(items), :id => "footer_nav")
  end
end