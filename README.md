# Nimbus
Random Forest algorithm for genomic selection.

[![Build Status](https://github.com/xuanxu/nimbus/actions/workflows/tests.yml/badge.svg)](https://github.com/xuanxu/nimbus/actions/workflows/tests.yml)
[![Gem Version](https://badge.fury.io/rb/nimbus.png)](http://badge.fury.io/rb/nimbus)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://github.com/xuanxu/nimbus/blob/master/MIT-LICENSE.txt)
[![DOI](http://joss.theoj.org/papers/10.21105/joss.00351/status.svg)](https://doi.org/10.21105/joss.00351)

## Random Forest

The [random forest algorithm](http://en.wikipedia.org/wiki/Random_forest) is a classifier consisting in many random decision trees. It is based on choosing random subsets of variables for each tree and using the most frequent, or the averaged tree output as the overall classification. In machine learning terms, it is an ensemble classifier, so it uses multiple models to obtain better predictive performance than could be obtained from any of the constituent models.

The forest outputs the class that is the mean or the mode (in regression problems) or the majority class (in classification problems) of the node's output by individual trees.

## Genomic selection context

Nimbus is a Ruby gem implementing Random Forest in a genomic selection context, meaning every input file is expected to contain genotype and/or fenotype data from a sample of individuals.

Other than the ids of the individuals, Nimbus handle the data as genotype values for [single-nucleotide polymorphisms](http://en.wikipedia.org/wiki/SNPs) (SNPs), so the variables in the classifier must have values of 0, 1 or 2, corresponding with SNPs classes of AA, AB and BB.

Nimbus can be used to:

* Create a random forest using a training sample of individuals with fenotype data.
* Use an existent random forest to get predictions for a testing sample.

## Learning algorithm

**Training**: Each tree in the forest is constructed using the following algorithm:

1. Let the number of training cases be N, and the number of variables (SNPs) in the classifier be M.
1. We are told the number mtry of input variables to be used to determine the decision at a node of the tree; m should be much less than M
1. Choose a training set for this tree by choosing n times with replacement from all N available training cases (i.e. take a bootstrap sample). Use the rest of the cases (Out Of Bag sample) to estimate the error of the tree, by predicting their classes.
1. For each node of the tree, randomly choose m SNPs on which to base the decision at that node. Calculate the best split based on these m SNPs in the training set.
1. Each tree is fully grown and not pruned (as may be done in constructing a normal tree classifier).
1. When in a node there is not any SNP split that minimizes the general loss function of the node, or the number of individuals in the node is less than the minimum node size then label the node with the average fenotype value of the individuals in the node.

**Testing**: For prediction a sample is pushed down the tree. It is assigned the label of the training sample in the terminal node it ends up in. This procedure is iterated over all trees in the ensemble, and the average vote of all trees is reported as random forest prediction.

## Regression and Classification

Nimbus can be used both with regression and classification problems.

**Regression**: is the default mode.

* The split of nodes uses quadratic loss as loss function.
* Labeling of nodes is made averaging the fenotype values of the individuals in the node.

**Classification**: user-activated declaring `classes` in the configuration file.

* The split of nodes uses the Gini index as loss function.
* Labeling of nodes is made finding the majority fenotype class of the individuals in the node.

## Variable importances

By default Nimbus will estimate SNP importances everytime a training file is run to create a forest.

You can disable this behaviour (and speed up the training process) by setting the parameter `var_importances: No` in the configuration file.

## Installation

You need to have [Ruby](https://www.ruby-lang.org) (2.6 or higher) with Rubygems installed in your computer. Then install Nimbus with:

````shell
> gem install nimbus
````

There are not extra dependencies needed.

## Getting Started

Once you have nimbus installed in your system, you can run the gem using the `nimbus` executable:

````shell
> nimbus
````

It will look for these files in the directory where Nimbus is running:

* `training.data`: If found it will be used to build a random forest.
* `testing.data` : If found it will be pushed down the forest to obtain predictions for every individual in the file.
* `random_forest.yml`: If found it will be the forest used for the testing instead of building one.
* `config.yml`: A file detailing random forest parameters and datasets. If not found default values will be used.

That way in order to train a forest a training file is needed. And to do the testing you need two files: the testing file and one of the other two: the training OR the random_forest file, because Nimbus needs a forest from which obtain the predictions.

## Configuration (config.yml)

The names for the input data files and the forest parameters can be specified in the `config.yml` file that should be located in the directory where you are running `nimbus`.

The `config.yml` has the following structure and parameters:

    #Input files
    input:
      training: training_regression.data
      testing: testing_regression.data
      forest: my_forest.yml
      classes: [0, 1]

    #Forest parameters
    forest:
      forest_size: 10 #how many trees
      SNP_sample_size_mtry: 60 #mtry
      SNP_total_count: 200
      node_min_size: 5

### Under the input chapter:

 * `training`: specify the path to the training data file (optional, if specified `nimbus` will create a random forest).
 * `testing`: specify the path to the testing data file (optional, if specified `nimbus` will traverse this data through a random forest).
 * `forest`: specify the path to a file containing a random forest structure (optional, if there is also testing file, this will be the forest used for the testing).
 * `classes`: **optional (needed only for classification problems)**. Specify the list of classes in the input files as a comma separated list between squared brackets, e.g.:`[A, B]`.

### Under the forest chapter:

 * `forest_size`: number of trees for the forest.
 * `SNP_sample_size_mtry`: size of the random sample of SNPs to be used in every tree node.
 * `SNP_total_count`: total count of SNPs in the training and/or testing files
 * `node_min_size`: minimum amount of individuals in a tree node to make a split.
 * `var_importances`: **optional**. If set to `No` Nimbus will not calculate SNP importances.

### Default values

If there is no config.yml file present, Nimbus will use these default values:

````yaml
forest_size:          300
tree_SNP_sample_size: 60
tree_SNP_total_count: 200
tree_node_min_size:   5
training_file: 'training.data'
testing_file:  'testing.data'
forest_file:   'forest.yml
````

## Input files

The three input files you can use with Nimbus should have proper format:

**The training file** has any number of rows, each representing data for an individual, with this columns:

1. A column with the fenotype for the individual
1. A column with the ID of the individual
1. M columns (where M = SNP_total_count in `config.yml`) with values 0, 1 or 2, representing the genotype of the individual.

**The testing file** has any number of rows, each representing data for an individual, similar to the training file but without the fenotype column:

1. A column with the ID of the individual
1. M columns (where M = SNP_total_count in `config.yml`) with values 0, 1 or 2, representing the genotype of the individual.

**The forest file** contains the structure of a forest in YAML format. It is the output file of a nimbus training run.

## Output files

Nimbus will generate the following output files:

After training:

 * `random_forest.yml`: A file defining the structure of the computed Random Forest. It can be used as input forest file.
 * `generalization_errors.txt`: A file with the generalization error for every tree in the forest.
 * `training_file_predictions.txt`: A file with predictions for every individual from the training file.
 * `snp_importances.txt`: A file with the computed importance for every SNP. _(unless `var_importances` set to `No` in config file)_

After testing:

 * `testing_file_predictions.txt`: A file detailing the predicted results for the testing dataset.

## Example usage

### Sample files

Sample files are located in the `/spec/fixtures` directory, both for regression and classification problems. They can be used as a starting point to tweak your own configurations.

Depending on the kind of problem you want to test different files are needed:

### Regression

**Test with a Random Forest created from a training data set**

Download/copy the `config.yml`, `training.data` and `testing.data` files from the [regression folder](./tree/master/spec/fixtures/regression).

Then run nimbus:

````shell
> nimbus
````

It should output a `random_forest.yml` file with the nodes and structure of the resulting random forest, the `generalization_errors` and `snp_importances` files, and the predictions for both training and testing datasets (`training_file_predictions.txt` and `testing_file_predictions.txt` files).

**Test with a Random Forest previously created**

Download/copy the `config.yml`, `testing.data` and `random_forest.yml` files from the [regression folder](./tree/master/spec/fixtures/regression).

Edit the `config.yml` file to comment/remove the training entry.

Then use nimbus to run the testing:

````shell
> nimbus
````

It should output a `testing_file_predictions.txt` file with the resulting predictions for the testing dataset using the given random forest.

### Classification

**Test with a Random Forest created from a training data set**

Download/copy the `config.yml`, `training.data` and `testing.data` files from the [classification folder](./tree/master/spec/fixtures/classification).

Then run nimbus:

````shell
> nimbus
````

It should output a `random_forest.yml` file with the nodes and structure of the resulting random forest, the `generalization_errors` file, and the predictions for both training and testing datasets (`training_file_predictions.txt` and `testing_file_predictions.txt` files).

**Test with a Random Forest previously created**

Download/copy the `config.yml`, `testing.data` and `random_forest.yml` files from the [classification folder](./tree/master/spec/fixtures/classification).

Edit the `config.yml` file to comment/remove the training entry.

Then use nimbus to run the testing:

````shell
> nimbus
````

It should output a `testing_file_predictions.txt` file with the resulting predictions for the testing dataset using the given random forest.


## Test suite

Nimbus includes a test suite located in the `spec` directory. The current state of the build is [publicly tracked by Travis CI](https://travis-ci.org/xuanxu/nimbus). You can run the specs locally if you clone the code to your local machine and run the default rake task:

````shell
> git clone git://github.com/xuanxu/nimbus.git
> cd nimbus
> bundle install
> rake
````

## Resources

* [Source code](http://github.com/xuanxu/nimbus) – Fork the code
* [Issues](http://github.com/xuanxu/nimbus/issues) – Bugs and feature requests
* [Online rdocs](http://rubydoc.info/gems/nimbus/frames)
* [Nimbus at rubygems.org](https://rubygems.org/gems/nimbus)
* [Random Forest at Wikipedia](http://en.wikipedia.org/wiki/Random_forest)
* [RF Leo Breiman page](http://www.stat.berkeley.edu/~breiman/RandomForests/)


## Contributing

Contributions are welcome. We encourage you to contribute to the Nimbus codebase.

Please read the [CONTRIBUTING](CONTRIBUTING.md) file.


## Credits and DOI

If you use Nimbus, please cite our [JOSS paper: http://dx.doi.org/10.21105/joss.00351](http://dx.doi.org/10.21105/joss.00351)

You can find the citation info in [Bibtex format here](CITATION.bib).

**Cite as:**  
*Bazán et al, (2017), Nimbus: a Ruby gem to implement Random Forest algorithms in a genomic selection context, Journal of Open Source Software, 2(16), 351, doi:10.21105/joss.0035*

Nimbus was developed by [Juanjo Bazán](http://twitter.com/xuanxu) in collaboration with Oscar González-Recio.


## LICENSE

Copyright © Juanjo Bazán, released under the [MIT license](MIT-LICENSE.txt)
