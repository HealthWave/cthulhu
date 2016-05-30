require 'spec_helper'
describe Cthulhu::Handler do
  let(:p) do
    {
      headers: {"subject" => "pass", "action" => "ack_test", "from" => "app"},
      timestamp: Time.now,
      message_id: '374892374823748923748'
    }
  end
  let(:properties) { Bunny::MessageProperties.new(p) }
  let(:message) { {id: "1", text: "2"} }
  subject { Cthulhu::Handler.new(properties, message) }

  it 'ack!' do
    expect(subject.ack!).to be == "ack!"
  end
  it 'requeue!' do
    expect(subject.requeue!).to be == "requeue!"
  end
  it 'ignore!' do
    expect(subject.ignore!).to be == "ignore!"
  end

  it 'logger and self.logger=' do
    Cthulhu::Handler.logger = Logger.new('/tmp/test.log')
    expect(subject.logger).to be_a Logger
  end

  it 'initialize' do
    expect(subject.message).to be == {id: "1", text: "2"}
    expect(subject.properties).to be == properties
    expect(subject.headers).to be == properties.headers
  end
end
