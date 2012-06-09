require './lib/cloudfuji/cloudfuji'

module Cloudfuji
  class Ido
    class << self
      def retrieve_ido_id
        UUID.new.generate
      end
    end
  end
end
