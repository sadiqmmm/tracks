module TracksStepHelper
  def submit_multiple_next_action_form
    xpath = "//form[@id='todo-form-multi-new-action']//button[@id='todo_multi_new_action_submit']"
    handle_js_confirm do
      within("form#todo-form-multi-new-action") do
        click_button("todo_multi_new_action_submit")
      end
      wait_for_ajax
      wait_for_animations_to_end
    end
  end

  def submit_next_action_form
    handle_js_confirm do
      within("#todo-form-new-action") do
        click_button("todo_new_action_submit")
      end
      wait_for_ajax
      wait_for_animations_to_end
    end
  end

  def submit_new_context_form
    within "form#context-form" do
      find("button#context_new_submit").click
    end
    wait_for_ajax
    wait_for_animations_to_end
  end

  def submit_new_project_form
    within "form#project_form" do
      click_button "project_new_project_submit"
    end
    wait_for_ajax
    wait_for_animations_to_end
  end

  def wait_for_form_to_go_away(todo)
    page.should_not have_content("button#submit_todo_#{todo.id}")
  end
  
  def submit_edit_todo_form (todo)
    within "div#edit_todo_#{todo.id}" do
      click_button "submit_todo_#{todo.id}"
    end
    wait_for_form_to_go_away(todo)
  end

  def format_date(date)
    # copy-and-past from ApplicationController::format_date
    return date ? date.in_time_zone(@current_user.prefs.time_zone).strftime("#{@current_user.prefs.date_format}") : ''
  end

  def execute_javascript(js)
    page.execute_script(js)
  end

  def clear_context_name_from_next_action_form
    execute_javascript("$('#todo_context_name').val('');")
  end

  def clear_project_name_from_next_action_form
    execute_javascript("$('#todo_project_name').val('');")
  end
  
  def open_edit_form_for(todo)
    within "div#line_todo_#{todo.id}" do
      find("a#icon_edit_todo_#{todo.id}").click
    end
    wait_for_animations_to_end
  end
  
  def wait_for_animations_to_end
    wait_until do
      page.evaluate_script('$(":animated").length') == 0
    end
  end
  
  def wait_for_ajax
    start_time = Time.now
    page.evaluate_script('jQuery.isReady&&jQuery.active==0').class.should_not eql(String)
    until(page.evaluate_script('jQuery.isReady&&jQuery.active==0') || (start_time + 5.seconds) < Time.now)
      sleep 1
    end
  end

  def handle_js_confirm(accept=true)
    page.execute_script "window.original_confirm_function = window.confirm"
    page.execute_script "window.confirmMsg = null"
    page.execute_script "window.confirm = function(msg) { window.confirmMsg = msg; return #{!!accept}; }"
    yield
  ensure
    page.execute_script "window.confirm = window.original_confirm_function"
  end
  
  def get_confirm_text
    page.evaluate_script "window.confirmMsg"
  end

  def open_submenu_for(todo)
    submenu_arrow = "div#line_todo_#{todo.id} img.todo-submenu"
    page.find(submenu_arrow).should be_visible
    
    page.find(submenu_arrow).click
    
    # wait for the submenu to be visible
    wait_until do
      page.find("div#line_todo_#{todo.id} ul#ultodo_#{todo.id}").visible?
    end
    
    wait_for_animations_to_end
  end

  def context_list_find_index(context_name)
    div_id = "context_#{@current_user.contexts.find_by_name(context_name).id}"
    contexts = page.all("div.context").map { |x| x[:id] }
    return contexts.find_index(div_id)
  end

  def project_list_find_index(project_name)
    # TODO: refactor with context_list_find_index
    div_id = "project_#{@current_user.projects.find_by_name(project_name).id}"
    project = page.all("div.project").map { |x| x[:id] }
    return project.find_index(div_id)
  end
  
  def open_project_edit_form(project)
    click_link "link_edit_project_#{project.id}"
    page.should have_css("button#submit_project_#{project.id}")
  end
  
  def submit_project_edit_form(project)
    page.find("button#submit_project_#{project.id}").click
  end
  
  def edit_project_no_wait(project)
    open_project_edit_form(project)
    yield
    submit_project_edit_form(project)
  end
  
  def edit_project(project)
    open_project_edit_form(project)
    yield
    submit_project_edit_form(project)
    
    wait_for_ajax
    wait_for_animations_to_end
    
    page.should_not have_css("button#submit_project_#{project.id}", :visible => true)
  end
  
  def edit_project_settings(project)
    open_project_edit_form(project)
    yield
    submit_project_edit_form(project)
    page.should_not have_css("button#submit_project_#{project.id}", :visible => true)
  end
  
end

World(TracksStepHelper)