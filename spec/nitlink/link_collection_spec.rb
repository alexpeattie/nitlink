require 'spec_helper'
require 'nitlink/link_collection'

RSpec.describe Nitlink::LinkCollection do
  let(:link_collection) { described_class.new }
  let(:link) { double(:link, relation_type: 'next', title: 'link 1') }
  let(:second_link) { double(:link, relation_type: 'next', title: 'link 2') }
  let(:link_with_extension_rel) { double(:link, relation_type: 'http://example.com/some-rel-type') }

  before {
    link_collection.push(link)
  }

  describe '#by_rel' do
    it 'returns objects where the relation type matches' do
      expect(link_collection.by_rel('next')).to eq link
    end

    it 'returns nil where no match is found' do
      expect(link_collection.by_rel('next')).to eq link
    end

    it 'works when the relation type is a Symbol' do
      expect(link_collection.by_rel(:next)).to eq link
    end

    it 'returns the first instance where multiple links share a relation type' do
      link_collection.push(second_link)

      expect(link_collection.by_rel('next')).to eq link
    end

    it 'raises an error when the relation type is blank' do
      expect { link_collection.by_rel(nil) }.to raise_error ArgumentError
      expect { link_collection.by_rel('') }.to raise_error ArgumentError
    end

    it 'compares relation types case-insensitively' do
      link_collection = described_class.new([link_with_extension_rel])
      expect(link_collection.by_rel('http://Example.com/some-rel-type')).to eq link_with_extension_rel
    end
  end

  describe '#to_h' do
    it 'creates a hash indexed by relation type, keeping only the first example of each relation type' do
      expect(link_collection.to_h).to eq({ 'next' => link })
    end

    it 'turns an empty link collection into an empty hash' do
      expect(described_class.new.to_h).to eq({})
    end

    it 'supports indifferent access by default' do
      indifferent_accessible = link_collection.to_h
      expect(indifferent_accessible['next']).to eq link
      expect(indifferent_accessible[:next]).to eq link
    end

    it 'can optionally return a plain hash (no indifferent access)' do
      not_indifferent_accessible = link_collection.to_h(with_indifferent_access: false)
      expect(not_indifferent_accessible['next']).to eq link
      expect(not_indifferent_accessible[:next]).to be_nil
    end

    it 'is aliased as to_hash' do
      expect(link_collection.to_hash).to eq({ 'next' => link })
    end
  end
end