require 'spec_helper'
require 'ostruct'

class TestHandler < Cthulhu::Handler
  def method

  end
  def ack_test
    ack!
  end
  def requeue_test
    requeue!
  end
  def ignore_test
    ignore!
  end
end

describe Cthulhu::Application do
  subject { Cthulhu::Application }
  let(:p) do
    {
      headers: {"subject" => "pass", "action" => "ack_test", "from" => "app"},
      timestamp: Time.now,
      message_id: '374892374823748923748'
    }
  end
  let(:properties) { Bunny::MessageProperties.new(p) }
  let(:message) { {id: "1", text: "2"} }
  let(:delivery_info) { OpenStruct.new(delivery_tag: 'tag') }

  before(:each) do
    Cthulhu.routes do
      route subject: 'pass', to: 'TestHandler'
      route subject: 'fail', to: 'SomeHandler'
    end
  end

  it "#name= and #name" do
    subject.name = "app_name"
    expect(subject.name).to be == "app_name"
  end
  it "#queue_name= and #queue_name" do
    subject.queue_name = "queue_name"
    expect(subject.queue_name).to be == "queue_name"
  end
  it "#logger= and #logger" do
    expect{subject.logger = "logger"}.to raise_error("Invalid logger")
    subject.logger = Logger.new('/tmp/test.log')
    expect(subject.logger).to be_a Logger
  end
  it "#valid?" do

    expect(subject.valid?(properties, message)).to be == true

    p_test = properties
    p_test.headers["subject"] = nil
    expect(subject.valid?(properties, message)).to be == false

    p_test = properties
    p_test.headers["action"] = nil
    expect(subject.valid?(properties, message)).to be == false

    p_test = properties
    p_test.headers["from"] = ""
    expect(subject.valid?(properties, message)).to be == false

    p = {
      headers: {"subject" => "1", "action" => "2", "from" => "app"},
      timestamp: "Time.now",
      message_id: '374892374823748923748'
    }
    properties = Bunny::MessageProperties.new(p)
    p_test = properties
    expect(subject.valid?(properties, message)).to be == false

    p = {
      headers: {"subject" => "1", "action" => "2", "from" => "app"},
      timestamp: "Time.now"
    }
    properties = Bunny::MessageProperties.new(p)
    p_test = properties
    expect(subject.valid?(properties, message)).to be == false
  end

  it '#handler_exists?' do

    expect(subject.handler_exists?(properties, message)).to be == "TestHandler"

    p = {
      headers: {"subject" => "fail", "action" => "ack_test", "from" => "app"},
      timestamp: Time.now,
      message_id: '374892374823748923748'
    }
    properties = Bunny::MessageProperties.new(p)
    expect(subject.handler_exists?(properties, message)).to be == false

  end

  it '#call_handler_for' do
    # expect that calling the method, the class will be instantiated
    # and the method called
    expect_any_instance_of(TestHandler).to receive(:handle_action).with("ack_test")
    subject.call_handler_for(properties, message)
  end

  it '#start' do
    # test the start method
    subject.name = 'app_name'
    subject.queue_name = subject.name + '.87c174a2-e216-44a4-a35b-672a4c78756d'
    subject.logger = Logger.new("/tmp/test.log")
    allow(Bunny).to receive(:new).and_return(Bunny::Session)
    allow(Bunny::Session).to receive(:start)
    allow(Bunny::Session).to receive(:create_channel).and_return(BunnyMock::Channel.new)
    expect_any_instance_of(BunnyMock::Queue).to receive(:subscribe)
    subject.start
  end

  it '#parse' do
    # properties.headers["action"] was set as "ack_test" at the top of this file
    # The method #parse expects message as JSON.
    expect( subject.parse(delivery_info, properties, message.to_json) ).to be == "ack!"
    properties.headers["action"] = "ignore_test"
    expect( subject.parse(delivery_info, properties, message.to_json) ).to be == "ignore!"
    properties.headers["action"] = "requeue_test"
    expect( subject.parse(delivery_info, properties, message.to_json) ).to be == "requeue!"
  end
end
