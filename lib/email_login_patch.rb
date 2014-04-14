module RedmineEmailLogin
  module EmailLoginPatch
    
    def self.included(base)
      base.extend ClassMethods
      base.class_eval do
        class << self
          alias_method_chain :try_to_login, :email
        end
      end
    end
    
    module ClassMethods
      def try_to_login_with_email(login, password)
        login = login.to_s
        password = password.to_s

        # Make sure no one can sign in with an empty login or password
        return nil if login.empty? || password.empty?
        # let the user login by email or username: http://www.redmine.org/issues/3956
        user = if login.match(/\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/)
          find_by_mail(login)
        else
          find_by_login(login)
        end
        # validate user
        if user
          # user is already in local database
          return nil unless user.active?
          return nil unless user.check_password?(password)
        else
          # user is not yet registered, try to authenticate with available sources
          attrs = AuthSource.authenticate(login, password)
          if attrs
            user = new(attrs)
            user.login = login
            user.language = Setting.default_language
            if user.save
              user.reload
              logger.info("User '#{user.login}' created from external auth source: #{user.auth_source.type} - #{user.auth_source.name}") if logger && user.auth_source
            end
          end
        end
        user.update_column(:last_login_on, Time.now) if user && !user.new_record?
        user
      rescue => text
        raise text
      end
      
    end # module ClassMethods
  end # module EmailLoginPatch
end # module RedmineEmailLogin

# Add module to User class
User.send(:include, RedmineEmailLogin::EmailLoginPatch)