require 'spec_helper'
require 'support/webmock'

describe Travis::Github::Payload::PullRequest do
  include Support::Webmock

  let(:payload) { Travis::Github::Payload.for('pull-request', GITHUB_PAYLOADS['pull-request']) }

  describe 'repository' do
    it 'returns all attributes required for a Repository' do
      payload.repository.should == {
        :name => 'test-project-1',
        :description => 'Test dummy repository for testing Travis CI',
        :url => 'https://github.com/travis-repos/test-project-1',
        :owner_type => 'Organization',
        :owner_name => 'travis-repos',
        :owner_email => nil,
        :private => false
      }
    end
  end

  describe 'owner' do
    it 'returns all attributes required for an Owner' do
      payload.owner.should == {
        :type => 'Organization',
        :login => 'travis-repos'
      }
    end
  end

  describe 'request' do
    it 'returns all attributes required for a Request' do
      payload.request.should == {
        :payload => GITHUB_PAYLOADS['pull-request'],
      }
    end
  end

  describe 'commit' do
    it 'returns all attributes required for a Commit' do
      payload.commit.should == {
        :commit => '77ca44550e92e9292f58150a0f9c11e9a0dac922',
        :message => 'Update README.md',
        :branch => 'master',
        :ref => 'refs/pull/1/merge',
        :committed_at => '2012-02-14T14:00:25Z',
        :committer_name => 'Konstantin Haase',
        :committer_email => 'k.haase@finn.de',
        :author_name => 'Konstantin Haase',
        :author_email => 'k.haase@finn.de',
        :compare_url => 'https://github.com/travis-repos/test-project-1/pull/1'
      }
    end
  end
end