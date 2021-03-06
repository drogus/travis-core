require 'spec_helper'

describe Travis::Notification::Instrument::Github::Sync::Organizations do
  include Support::ActiveRecord

  let(:user)      { Factory(:user, :login => 'sven', :github_oauth_token => '123456') }
  let(:org)       { { 'id' => 1, 'name' => 'The Org', 'login' => 'the-org'  } }

  let(:publisher) { Travis::Notification::Publisher::Memory.new }
  let(:event)     { publisher.events.first }
  let(:sync)      { Travis::Github::Sync::Organizations.new(user) }

  before :each do
    Travis::Notification.publishers.replace([publisher])
    GH.stubs(:[]).with('user/orgs').returns [org]
    sync.run
  end

  it 'publishes a payload' do
    event.should == {
      :message => "travis.github.sync.organizations.run:call",
      :payload => { :result => [org], :msg => %(Travis::Github::Sync::Organizations#run for #<User id=#{user.id} login="sven">) },
      :uuid => Travis.uuid
    }
  end
end

