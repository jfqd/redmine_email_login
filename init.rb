require 'redmine'
require 'email_login_patch'

Redmine::Plugin.register :redmine_email_login do
  name 'Redmine email login'
  author 'Stefan Husch'
  description 'Redmine plugin for login by email or username'
  version '0.0.3'
  requires_redmine :version_or_higher => '4.0.0'
end
