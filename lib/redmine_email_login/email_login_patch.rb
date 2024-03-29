module RedmineEmailLogin
  module EmailLoginPatch
    
    def self.included(base)
      base.extend ClassMethods
      base.class_eval do
        class << self
          alias_method :try_to_login_without_email!, :try_to_login!
          alias_method :try_to_login!, :try_to_login_with_email!
        end
      end
    end
    
    module ClassMethods
      def try_to_login_with_email!(login, password, active_only=true)
        login = login.to_s.strip
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
          return nil unless user.check_password?(password)
          return nil if !user.active? && active_only
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
        user.update_last_login_on! if user && !user.new_record? && user.active?
        user
      rescue => text
        raise text
      end
      
    end # module ClassMethods
  end # module EmailLoginPatch
end # module RedmineEmailLogin

# Add module to User class
User.send(:include, ::RedmineEmailLogin::EmailLoginPatch)