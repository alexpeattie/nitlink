require_relative './hash_with_indifferent_access'

module Nitlink
  class LinkCollection < Array
    def by_rel(relation_type)
      raise ArgumentError.new('relation_type cannot be blank') if (!relation_type || relation_type.empty?)
      find { |link| link.relation_type == relation_type.downcase.to_s }
    end

    def to_h(options = { with_indifferent_access: true })
      options = Nitlink::HashWithIndifferentAccess.new(options)
      indifferent = options.key?(:with_indifferent_access) ? options[:with_indifferent_access] : true

      hash = indifferent ? Nitlink::HashWithIndifferentAccess.new : {}
      each { |link| hash[link.relation_type.to_s] ||= link }
      hash
    end

    alias_method :to_hash, :to_h
  end
end