# Regrowth Model from Ye et al (Submitted, 2018)

## Disclaimer

This repository will be updated and a permanent release will be created when manuscript is accepted.

## Purpose

Given a list of dendritic segments, run a random regrowth model to test the null hypothesis, "The fraction of regrowing spines is happening by chance".

This is the random model used in manuscript figure 7.

## Requirements

- Download the contents of this repository and run it on a local machine. 
- This code needs to be run in [Igor Pro 7 (Wavemetrics)][igor-pro] on either Microsoft Windows or macOS. A fully functioning demo version of Igor Pro can be [downloaded here][igor-pro-demo].

## Running the model

 1. Open 'bRegrowth.ipf' into Igor Pro 7.
 
 2. In Igor Pro, type 'regrowthModel_Init()' at the command prompt like this
 
 	regrowthModel_Init()
 	
 You will be prompted to open a file, open either 'ovxRegrowth.txt' for Ovx data or 'controlRegrowth.txt' for control data.

 Once loaded, a window titled 'Regrowth Model' will open. Each row in the table is an individual dendritic segment.

 3. Run all the models (rows) by clicking the 'Run All' button.

## Miscellaneous

- Keyboard 'e' in the Regrowth Model window will open a text table so values can be copied/pasted into another program.
- See function 'runRegrowthModel()' for the code that actually runs the model


[igor-pro]: https://www.wavemetrics.com/
[igor-pro-demo]: https://www.wavemetrics.com/products/igorpro
