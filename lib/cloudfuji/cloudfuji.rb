module Umi
  module Cloudfuji
    class << self
      def enable_cloudfuji!
        disable_devise_for_cloudfuji_controllers!
      end

      # Temporary hack because all routes require authentication in
      # Fulcrum
      def disable_devise_for_cloudfuji_controllers!
        puts "Disabling devise auth protection on cloudfuji controllers"

        ::Cloudfuji::DataController.instance_eval { before_filter :authenticate_user!, :except => [:index]  }
        ::Cloudfuji::EnvsController.instance_eval { before_filter :authenticate_user!, :except => [:update] }
        ::Cloudfuji::MailController.instance_eval { before_filter :authenticate_user!, :except => [:index]  }

        puts "Devise checks disabled for Cloudfuji controllers"
      end
    end
  end
end
