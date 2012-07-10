# encoding: UTF-8
require File.dirname(__FILE__) + '/spec_helper'

describe Nimbus::LossFunctions do

  it "method for average" do
    ids = [1,3,5,7]
    values = {1 => 10, 2 => 5, 3 => 21, 4 => 8, 5 => 31, 7 => 11, 85 => 22}

    Nimbus::LossFunctions.average(ids, values).should == 18.25 # (10 + 21 + 31 + 11 = 73)/4
  end

  it "method for mean squared error" do
    ids = [3,7,85]
    values = {1 => 10, 2 => 5, 3 => 21, 4 => 8, 5 => 31, 7 => 11, 85 => 22}

    Nimbus::LossFunctions.mean_squared_error(ids, values).should == 74.0 # (avg(21 + 11 + 22) = 18: sum (x-11)^2
  end

  it "method for quadratic_loss" do
    ids = [1,4]
    values = {1 => 10, 2 => 5, 3 => 21, 4 => 8, 5 => 31, 7 => 11, 85 => 22}

    Nimbus::LossFunctions.quadratic_loss(ids, values).round(5).should == 1
  end

  it "quadratic loss is mean squared error averaged" do
    ids = [1,2,3,4,5,7,85]
    values = {1 => 10, 2 => 5, 3 => 21, 4 => 8, 5 => 31, 7 => 11, 85 => 22}
    Nimbus::LossFunctions.quadratic_loss(ids, values).round(5).should == (Nimbus::LossFunctions.mean_squared_error(ids, values)/7 ).round(5)
  end

  it "method for squared difference" do
    Nimbus::LossFunctions.squared_difference(50, 40).should == 100.0
    Nimbus::LossFunctions.squared_difference(22, 10).should == 144.0
  end

end