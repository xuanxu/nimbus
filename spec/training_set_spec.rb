# encoding: UTF-8
require File.dirname(__FILE__) + '/spec_helper'

describe Nimbus::TrainingSet do

  it "stores individuals list and fenotype data for them" do
    i1 = Nimbus::Individual.new 1, 11.0, [1,0,2,1]
    i2 = Nimbus::Individual.new 2, 22.0, [2,1,2,2]
    i3 = Nimbus::Individual.new 3, 33.0, [0,2,1,0]
    @training_set = Nimbus::TrainingSet.new [i1, i3], {i1.id => 11.0, i3.id => 33.0}

    @training_set.individuals.should   == [i1, i3]
    @training_set.ids_fenotypes.should == {i1.id => 11.0, i3.id => 33.0}
  end

  it "keeps track of ids of all individuals in the training set" do
    i1 = Nimbus::Individual.new 1, 11.0, [1,0,2,1]
    i2 = Nimbus::Individual.new 2, 22.0, [2,1,2,2]
    i3 = Nimbus::Individual.new 3, 33.0, [0,2,1,0]
    @training_set = Nimbus::TrainingSet.new [i1, i3], {i1.id => 11.0, i3.id => 33.0}

    @training_set.all_ids.should == [1,3]
  end

end