require 'spec_helper'
require 'nitlink/link_collection'

RSpec.describe Nitlink::HashWithIndifferentAccess do
  let(:hash) do
    Nitlink::HashWithIndifferentAccess.new :foo => 'bar', 'baz' => 'bee', :force => true
  end

  it 'has values accessible by either strings or symbols' do
    expect(hash['foo']).to eq('bar')
    expect(hash[:foo]).to eq('bar')

    expect(hash.values_at(:foo, :baz)).to eq(%w(bar bee))
    expect(hash.delete(:foo)).to eq('bar')
  end

  it 'supports fetch' do
    expect(hash.fetch('foo')).to eq('bar')
    expect(hash.fetch('foo', nil)).to eq('bar')
    expect(hash.fetch(:foo)).to eq('bar')
    expect(hash.fetch(:foo, nil)).to eq('bar')

    expect(hash.fetch('baz')).to eq('bee')
    expect(hash.fetch('baz', nil)).to eq('bee')
    expect(hash.fetch(:baz)).to eq('bee')
    expect(hash.fetch(:baz, nil)).to eq('bee')

    expect { hash.fetch(:missing) }.to raise_error(IndexError)
    expect(hash.fetch(:missing, :found)).to eq(:found)
  end

  it 'has key checkable by either strings or symbols' do
    expect(hash.key?('foo')).to be true
    expect(hash.key?(:foo)).to be true
    expect(hash.key?('nothing')).to be false
    expect(hash.key?(:nothing)).to be false
  end

  it 'merges keys independent if they are symbols or strings' do
    hash['force'] = false
    hash[:baz] = 'boom'
    expect(hash[:force]).to eq(false)
    expect(hash['baz']).to eq('boom')
  end

  it 'creates a new hash by merging keys independent if they are symbols or strings' do
    other = hash.merge('force' => false, :baz => 'boom')
    expect(other[:force]).to eq(false)
    expect(other['baz']).to eq('boom')
  end

  it 'converts to a traditional hash' do
    expect(hash.to_hash.class).to eq(Hash)
    expect(hash).to eq('foo' => 'bar', 'baz' => 'bee', 'force' => true)
  end

  it 'handles reverse_merge' do
    other = {:foo => 'qux', 'boo' => 'bae'}
    new_hash = hash.reverse_merge(other)

    expect(hash.object_id).not_to eq(new_hash.object_id)
    expect(new_hash[:foo]).to eq('bar')
    expect(new_hash[:boo]).to eq('bae')
  end

  it 'handles reverse_merge!' do
    other = {:foo => 'qux', 'boo' => 'bae'}
    new_hash = hash.reverse_merge!(other)

    expect(hash.object_id).to eq(new_hash.object_id)
    expect(new_hash[:foo]).to eq('bar')
    expect(new_hash[:boo]).to eq('bae')
  end
end