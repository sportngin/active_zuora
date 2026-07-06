module ActiveZuora
  # Compatibility backport for Savon 1.x. When ActiveZuora can require Ruby 3+
  # and migrate to Savon >= 2.17.2, prefer the upstream fix and remove this patch.
  module SavonModelCve202653510Patch
    def actions(*actions)
      actions.each do |action|
        method_name = action.to_s.snakecase.to_sym

        class_action_module.define_method(method_name) do |body = nil, &block|
          client.request :wsdl, action, :body => body, &block
        end

        instance_action_module.define_method(method_name) do |body = nil, &block|
          self.class.public_send(method_name, body, &block)
        end
      end
    end
  end
end

Savon::Model.prepend(ActiveZuora::SavonModelCve202653510Patch)
