require 'redmine'
require File.dirname(__FILE__) + '/lib/redmine_email_login/email_login_patch'

Redmine::Plugin.register :redmine_email_login do
  name 'Redmine email login'
  author 'Stefan Husch'
  description 'Redmine plugin for login by email or username'
  version '0.0.4'
  requires_redmine :version_or_higher => '5.0.0'
end
