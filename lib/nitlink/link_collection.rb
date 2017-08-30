require_relative './hash_with_indifferent_access'

module Nitlink
  class LinkCollection < Array
    def by_rel(relation_type)
      raise ArgumentError.new('relation_type cannot be blank') if (!relation_type || relation_type.empty?)
      find { |link| link.relation_type == relation_type.downcase.to_s }
    end

    def to_h
      hash = Nitlink::HashWithIndifferentAccess.new
      each { |link| hash[link.relation_type] ||= link }
      hash
    end
  end
end