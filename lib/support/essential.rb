class Object
	def blank?
		return true if self.nil?
		return true if self == false
		return true if self.respond_to?(:empty?) && self.empty?
		return true if self.is_a?(String) && /\A\s*\z/.match(self)
		false
	end
end
