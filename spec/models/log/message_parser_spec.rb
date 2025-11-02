require_relative '../../../lib/fini'
require_relative '../../../lib/fini/models/log'
require_relative '../../../lib/fini/models/log/message_parser'

RSpec.describe Log::MessageParser do
  describe '.parse' do
    context 'with duration at end' do
      it 'parses @30m and removes from text' do
        result = described_class.parse('working on task @30m')
        expect(result[:text]).to eq('working on task')
        expect(result[:duration]).to eq(30)
      end

      it 'parses @2h and removes from text' do
        result = described_class.parse('meeting @2h')
        expect(result[:text]).to eq('meeting')
        expect(result[:duration]).to eq(120)
      end

      it 'parses @1.5h and removes from text' do
        result = described_class.parse('planning session @1.5h')
        expect(result[:text]).to eq('planning session')
        expect(result[:duration]).to eq(90)
      end

      it 'parses @1h30 and removes from text' do
        result = described_class.parse('working on feature @1h30')
        expect(result[:text]).to eq('working on feature')
        expect(result[:duration]).to eq(90)
      end

      it 'parses @2h15 and removes from text' do
        result = described_class.parse('workshop @2h15')
        expect(result[:text]).to eq('workshop')
        expect(result[:duration]).to eq(135)
      end
    end

    context 'with duration not at end' do
      it 'parses @2h at beginning' do
        result = described_class.parse('@2h working on project')
        expect(result[:text]).to eq('working on project')
        expect(result[:duration]).to eq(120)
      end

      it 'parses @2h in middle' do
        result = described_class.parse('worked for @2h on project')
        expect(result[:text]).to eq('worked for on project')
        expect(result[:duration]).to eq(120)
      end
    end

    context 'with action at end' do
      it 'parses +coding and removes from text' do
        result = described_class.parse('implementing feature +coding')
        expect(result[:text]).to eq('implementing feature')
        expect(result[:action]).to eq('coding')
      end
    end

    context 'with action not at end' do
      it 'parses +review at beginning and keeps in text without +' do
        result = described_class.parse('+review pull request')
        expect(result[:text]).to eq('pull request')
        expect(result[:action]).to eq('review')
      end
    end

    context 'with context' do
      it 'parses @backend at end' do
        result = described_class.parse('working on feature @backend')
        expect(result[:text]).to eq('working on feature')
        expect(result[:context]).to eq('backend')
      end

      it 'parses context with hyphens and underscores' do
        result = described_class.parse('task @my-awesome_context')
        expect(result[:text]).to eq('task')
        expect(result[:context]).to eq('my-awesome_context')
      end

      it 'parses @context at beginning' do
        result = described_class.parse('@api refactoring endpoints')
        expect(result[:text]).to eq('refactoring endpoints')
        expect(result[:context]).to eq('api')
      end

      it 'parses @context in middle' do
        result = described_class.parse('spent @backend time on coding')
        expect(result[:text]).to eq('spent time on coding')
        expect(result[:context]).to eq('backend')
      end
    end

    context 'with all metadata at end' do
      it 'parses all metadata' do
        result = described_class.parse('on auth system +coding @backend @2h')
        expect(result[:text]).to eq('on auth system')
        expect(result[:action]).to eq('coding')
        expect(result[:context]).to eq('backend')
        expect(result[:duration]).to eq(120)
      end

      it 'parses multiple orderings' do
        result = described_class.parse('code changes +review @frontend @1h30')
        expect(result[:text]).to eq('code changes')
        expect(result[:action]).to eq('review')
        expect(result[:context]).to eq('frontend')
        expect(result[:duration]).to eq(90)
      end

      it 'parses with action at end' do
        result = described_class.parse('daily standup @team @15m +meeting')
        expect(result[:text]).to eq('daily standup')
        expect(result[:action]).to eq('meeting')
        expect(result[:context]).to eq('team')
        expect(result[:duration]).to eq(15)
      end

      it 'parses with duration and action both truly at end' do
        result = described_class.parse('daily standup @team +meeting @15m')
        expect(result[:text]).to eq('daily standup')
        expect(result[:action]).to eq('meeting')
        expect(result[:context]).to eq('team')
        expect(result[:duration]).to eq(15)
      end
    end

    context 'with metadata scattered throughout' do
      it 'extracts values' do
        result = described_class.parse('worked @2h +coding the @backend system')
        expect(result[:text]).to eq('worked the system')
        expect(result[:action]).to eq('coding')
        expect(result[:context]).to eq('backend')
        expect(result[:duration]).to eq(120)
      end
    end

    context 'with mixed positions' do
      it 'extracts metadata' do
        result = described_class.parse('+coding @backend task @2h')
        expect(result[:text]).to eq('task')
        expect(result[:action]).to eq('coding')
        expect(result[:context]).to eq('backend')
        expect(result[:duration]).to eq(120)
      end
    end

    context 'with partial metadata' do
      it 'handles missing action' do
        result = described_class.parse('working on feature @backend @2h')
        expect(result[:text]).to eq('working on feature')
        expect(result[:context]).to eq('backend')
        expect(result[:duration]).to eq(120)
      end

      it 'handles missing context' do
        result = described_class.parse('on something +coding @1h')
        expect(result[:text]).to eq('on something')
        expect(result[:action]).to eq('coding')
        expect(result[:duration]).to eq(60)
      end

      it 'handles missing duration' do
        result = described_class.parse('issue +debugging @backend')
        expect(result[:text]).to eq('issue')
        expect(result[:action]).to eq('debugging')
        expect(result[:context]).to eq('backend')
        expect(result[:duration]).to be_nil
      end
    end

    context 'without any metadata' do
      it 'returns nil for all metadata' do
        result = described_class.parse('just working')
        expect(result[:text]).to eq('just working')
        expect(result[:duration]).to be_nil
      end
    end
  end
end
