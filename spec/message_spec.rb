require 'spec_helper'
describe Cthulhu::Message do
  subject { Cthulhu::Message }
  let(:message) { {subject: 'test', action: 'action', payload: {id: '1', text: 'abc'}} }
  before do
    Cthulhu::Application.name = 'app_name'
    Cthulhu::Application.queue_name = Cthulhu::Application.name + '.87c174a2-e216-44a4-a35b-672a4c78756d'
  end
  it 'broadcast' do
    allow(Bunny).to receive(:new).and_return(Bunny::Session)
    allow(Bunny::Session).to receive(:start)
    allow(Bunny::Session).to receive(:create_channel).and_return(BunnyMock::Channel.new)
    expect_any_instance_of(BunnyMock::Exchange).to receive(:publish)
    subject.broadcast message
  end

  it 'validate' do
    expect(subject.validate(message)).to be == true
    message[:subject] = nil
    expect{subject.validate(message)}.to raise_error('Message must have a subject')
    message[:subject] = "subject"
    message[:action] = nil
    expect{subject.validate(message)}.to raise_error('Message must have an action')
    message[:action] = "action"
    message[:payload] = nil
    expect{subject.validate(message)}.to raise_error('Message must have a payload')
    message[:payload] = {}
    expect{subject.validate(message)}.to raise_error('Message must have a payload')
  end
end
