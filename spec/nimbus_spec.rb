# encoding: UTF-8
require File.dirname(__FILE__) + '/spec_helper'


describe 'Nimbus module' do

  it "manages a Nimbus::Application object" do
    app = Nimbus.application
    expect(app).to be_kind_of Nimbus::Application
  end

  it "accepts setting an external Nimbus::Application" do
    app = Nimbus::Application.new
    Nimbus.application = app
    expect(Nimbus.application).to eq app
  end

end