require 'spec_helper'
describe Cthulhu do
  subject {Cthulhu}

  let(:first_global_route) {{ to: 'TestHandler', action: 'test_action' }}
  let(:second_global_route) { {to: 'TestHandler2', action: 'test_action2'} }

  it "#routes and #route" do
    subject.delete_routes
    subject.route subject: 'subject1', to: 'MessageHandler1'
    subject.route subject: 'subject2', to: 'MessageHandler2'
    expect(subject.routes).to be == {
      'subject1' => 'MessageHandler1',
      'subject2' => 'MessageHandler2'
    }
    subject.routes do
      route subject: 'a', to: 'b'
      route subject: 'c', to: 'd'
    end
    expect(subject.routes).to be == {
      'subject1' => 'MessageHandler1',
      'subject2' => 'MessageHandler2',
      'a' => 'b',
      'c' => 'd'
    }
  end

  it "#catch_all" do
    subject.delete_routes
    subject.catch_all( first_global_route )
    subject.catch_all( second_global_route )

    expect(subject.global_route).to be == second_global_route
  end

  it "#channel" do
    allow(Bunny).to receive(:new).and_return(Bunny::Session)
    allow(Bunny::Session).to receive(:start)
    allow(Bunny::Session).to receive(:create_channel).and_return(BunnyMock::Channel.new)
    expect(subject.channel).to be_a (BunnyMock::Channel)
  end

  it 'delete routes' do
    subject.delete_routes
    expect(subject.routes).to be_nil
  end

end
