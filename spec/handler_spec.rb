require 'spec_helper'

class TestHandlerMock < Cthulhu::Handler
  before_action :private1
  after_action :private2

  before_action :private3, only: :test2

  filter_action :filter, only: :test3

  def test1
  end
  def test2
  end
  def test3
  end

  private
    def private1
    end
    def private2
    end
    def private3
    end
    def filter
      return message["filter"] == "true"
    end
end

describe Cthulhu::Handler do
  let(:properties) { bunny_message_properties("ack_test") }
  let(:message) { {id: "1", text: "2"} }

  context "base functionality" do
    subject { Cthulhu::Handler.new(properties, message) }

    it '#ack!' do
      expect(subject.ack!).to be == "ack!"
    end
    it '#requeue!' do
      expect(subject.requeue!).to be == "requeue!"
    end
    it '#ignore!' do
      expect(subject.ignore!).to be == "ignore!"
    end

    it 'logger and self.logger=' do
      Cthulhu::Handler.logger = Logger.new('/tmp/test.log')
      expect(subject.logger).to be_a Logger
    end

    it '#initialize' do
      expect(subject.message).to be == {id: "1", text: "2"}
      expect(subject.properties).to be == properties
      expect(subject.headers).to be == properties.headers
    end

    it '#handle_action' do

    end
  end

  context "callbacks" do

    it 'test1 will have one before(private1) action and one after action(private2)' do
      thm = TestHandlerMock.new(bunny_message_properties("test1"), message)

      expect(thm).to receive(:private1)
      expect(thm).to receive(:private2)

      thm.handle_action("test1")
    end

    context "only option" do
      it 'test2 will only receive private3' do
        thm = TestHandlerMock.new(bunny_message_properties("test1"), message)

        expect(thm).not_to receive(:private3)
        thm.handle_action("test1")
      end

      it 'test1 will not receive private3' do
        thm = TestHandlerMock.new(bunny_message_properties("test2"), message)
        expect(thm).to receive(:private3)

        thm.handle_action("test2")
      end
    end

    context "filter" do
      it 'test3 will be receive when the filter returns true' do
        thm = TestHandlerMock.new(bunny_message_properties("test3"), {"filter" => "true"})

        expect(thm).not_to receive(:ack!)
        expect(thm).to receive(:test3)

        thm.handle_action("test3")
      end

      it 'test3 will not receive when the filter returns false' do
        thm = TestHandlerMock.new(bunny_message_properties("test3"), {"filter" => "false"})

        expect(thm).to receive(:ack!)
        expect(thm).not_to receive(:test3)

        thm.handle_action("test3")
      end
    end

  end


  def bunny_message_properties action, filter="true"
    properties = {
      headers: {"subject" => "pass", "action" => action, "from" => "app"},
      timestamp: Time.now,
      message_id: '374892374823748923748'
    }

    Bunny::MessageProperties.new(properties)
  end

end
