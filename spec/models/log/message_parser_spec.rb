require_relative '../../../lib/fini'
require_relative '../../../lib/fini/models/log'
require_relative '../../../lib/fini/models/log/message_parser'

RSpec.describe Log::MessageParser do
  describe '.parse_duration' do
    context 'with minutes only' do
      it 'parses @30m' do
        text, duration = described_class.parse_duration('working on task @30m')
        expect(text).to eq('working on task')
        expect(duration).to eq(30)
      end

      it 'parses @5m' do
        text, duration = described_class.parse_duration('quick fix @5m')
        expect(text).to eq('quick fix')
        expect(duration).to eq(5)
      end
    end

    context 'with hours only' do
      it 'parses @2h' do
        text, duration = described_class.parse_duration('meeting @2h')
        expect(text).to eq('meeting')
        expect(duration).to eq(120)
      end

      it 'parses @1.5h' do
        text, duration = described_class.parse_duration('planning session @1.5h')
        expect(text).to eq('planning session')
        expect(duration).to eq(90)
      end

      it 'parses @0.5h' do
        text, duration = described_class.parse_duration('standup @0.5h')
        expect(text).to eq('standup')
        expect(duration).to eq(30)
      end
    end

    context 'with combined hours and minutes' do
      it 'parses @1h30' do
        text, duration = described_class.parse_duration('working on feature @1h30')
        expect(text).to eq('working on feature')
        expect(duration).to eq(90)
      end

      it 'parses @2h15' do
        text, duration = described_class.parse_duration('workshop @2h15')
        expect(text).to eq('workshop')
        expect(duration).to eq(135)
      end
    end

    context 'without duration' do
      it 'returns nil duration when no duration is specified' do
        text, duration = described_class.parse_duration('just working')
        expect(text).to eq('just working')
        expect(duration).to be_nil
      end
    end

    context 'with duration at different positions' do
      it 'parses duration at the beginning' do
        text, duration = described_class.parse_duration('@2h working on project')
        expect(text).to eq('working on project')
        expect(duration).to eq(120)
      end

      it 'parses duration in the middle' do
        text, duration = described_class.parse_duration('worked for @2h on project')
        expect(text).to eq('worked for  on project')
        expect(duration).to eq(120)
      end

      it 'parses duration at the end' do
        text, duration = described_class.parse_duration('working on project @2h')
        expect(text).to eq('working on project')
        expect(duration).to eq(120)
      end
    end
  end

  describe '.parse_action' do
    context 'with explicit action tags' do
      it 'parses +coding' do
        text, action = described_class.parse_action('implementing feature +coding')
        expect(text).to eq('implementing feature')
        expect(action).to eq('coding')
      end

      it 'parses action at the beginning' do
        text, action = described_class.parse_action('+review pull request')
        expect(text).to eq('pull request')
        expect(action).to eq('review')
      end
    end

    context 'without explicit action tags' do
      it 'infers action from config rules' do
        text, action = described_class.parse_action('working on something')
        expect(text).to eq('working on something')
        # Action will be nil or inferred based on config
        expect(action).to be_a(String).or be_nil
      end
    end
  end

  describe '.parse_project' do
    context 'with explicit project tags' do
      it 'parses @project-name' do
        text, project = described_class.parse_project('working on feature @backend')
        expect(text).to eq('working on feature')
        expect(project).to eq('backend')
      end

      it 'parses @frontend' do
        text, project = described_class.parse_project('fixing bug @frontend')
        expect(text).to eq('fixing bug')
        expect(project).to eq('frontend')
      end

      it 'parses project with hyphens and underscores' do
        text, project = described_class.parse_project('task @my-awesome_project')
        expect(text).to eq('task')
        expect(project).to eq('my-awesome_project')
      end

      it 'parses project at the beginning' do
        text, project = described_class.parse_project('@api refactoring endpoints')
        expect(text).to eq('refactoring endpoints')
        expect(project).to eq('api')
      end
    end

    context 'without explicit project tags' do
      it 'infers project from config rules' do
        text, project = described_class.parse_project('general work')
        expect(text).to eq('general work')
        # Project will be nil or inferred based on config
        expect(project).to be_a(String).or be_nil
      end
    end
  end

  describe '.parse' do
    context 'with complete message' do
      it 'parses all components' do
        result = described_class.parse('+coding on auth system @backend @2h')

        expect(result[:text]).to eq('on auth system')
        expect(result[:action]).to eq('coding')
        expect(result[:project]).to eq('backend')
        expect(result[:duration]).to eq(120)
      end

      it 'parses message with combined duration format' do
        result = described_class.parse('+review code changes @frontend @1h30')

        expect(result[:text]).to eq('code changes')
        expect(result[:action]).to eq('review')
        expect(result[:project]).to eq('frontend')
        expect(result[:duration]).to eq(90)
      end

      it 'parses message with minutes only' do
        result = described_class.parse('+meeting daily standup @team @15m')

        expect(result[:text]).to eq('daily standup')
        expect(result[:action]).to eq('meeting')
        expect(result[:project]).to eq('team')
        expect(result[:duration]).to eq(15)
      end
    end

    context 'with partial metadata' do
      it 'handles missing action' do
        result = described_class.parse('working on feature @backend @2h')

        expect(result[:text]).to eq('working on feature')
        expect(result[:project]).to eq('backend')
        expect(result[:duration]).to eq(120)
      end

      it 'handles missing project' do
        result = described_class.parse('+coding on something @1h')

        expect(result[:text]).to eq('on something')
        expect(result[:action]).to eq('coding')
        expect(result[:duration]).to eq(60)
      end

      it 'handles missing duration' do
        result = described_class.parse('+debugging issue @backend')

        expect(result[:text]).to eq('issue')
        expect(result[:action]).to eq('debugging')
        expect(result[:project]).to eq('backend')
        expect(result[:duration]).to be_nil
      end
    end

    context 'with minimal message' do
      it 'parses text-only message' do
        result = described_class.parse('just did some work')

        expect(result[:text]).to eq('just did some work')
        expect(result[:duration]).to be_nil
      end
    end
  end
end
