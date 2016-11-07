require 'spec_helper'
require 'nitlink/param_extractor'

RSpec.describe Nitlink::ParamExtractor do
  let(:param) { described_class.new }

  describe '#extract' do
    it 'parses a simple parameter (name & token value)' do
      expect(param.extract 'rel=next').to eq [%w(rel next)]
    end

    it 'removes extraneous OWS' do
      expect(param.extract ' rel  = next ').to eq [%w(rel next)]
    end

    it "doesn't remove 'whitespace' that's not strict OWS (e.g. a space of horizontal tab)" do
      expect(param.extract "\t\v\frel=next\n\r ").to eq [["\v\frel", "next\n\r"]]
    end

    it 'case-normalises (downcases) parameter names' do
      expect(param.extract 'Rel=next').to eq [%w(rel next)]
    end

    it "doesn't case-normalise parameter values" do
      expect(param.extract 'rel=Bar').to eq [%w(rel Bar)]
    end

    it 'parses boolean attributes (whereby the parameter value will be nil)' do
      expect(param.extract 'crossorigin').to eq [['crossorigin', nil]]
    end

    it 'parses parameters across line-breaks' do
      expect(param.extract "rel\n=next").to eq [["rel\n", "next"]]
    end

    it 'ignores subsequent = characters' do
      expect(param.extract 'sum="1+1=2"').to eq [["sum", "1+1=2"]]
    end

    it 'removes quotes from quoted values' do
      expect(param.extract 'rel = "next"').to eq [%w(rel next)]
    end

    it 'handle an empty quoted value' do
      expect(param.extract 'anchor=""').to eq [['anchor', '']]
    end

    it 'removes backslashes used as escape characters in quoted values' do
      expect(param.extract 'title = "Emmanuel \"Manny\" Pacquiao"').to eq [['title', 'Emmanuel "Manny" Pacquiao']]
    end

    it 'maintains case & leading/trailing space within quoted values' do
      expect(param.extract 'title=" white space  "').to eq [['title', ' white space  ']]
    end

    it 'parses multiple parameters' do
      expect(param.extract 'rel=next; rev = prev ').to eq [%w(rel next), %w(rev prev)]
    end

    it 'parses multiple parameters representing a mixture of token values, quoted values & boolean params' do
      expect(param.extract 'rel=next; crossorigin ; title="Hello World!"').to eq [['rel', 'next'], ['crossorigin', nil], ['title', 'Hello World!']]
    end

    it 'ignores empty parameters, or trailing semicolons' do
      expect(param.extract 'rel=next; ; crossorigin;').to eq [['rel', 'next'], ['crossorigin', nil]]
    end
  end
end