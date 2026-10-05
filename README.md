# Introduction to Computational Legal Methods
**Johan Lindholm, Umeå University**

Welcome to this introdcution to Computional Legal Methods (CLMs)!
You will learn about core CLMs by conducting hands-on computational analysis on real legal data.

To make this possible, you will be also learn the basics of the programming language `R`.
To get the most out of the workshop, I highly recommnd that you install `R` and follow along in the code.
If you do so, after the workshop you will be ready to conduct computational analysis on your own data by changing only a few lines of code.
`R` is a popular, jack-of-all-trades language that can be used for conducting all sorts of empirical research. 
Once you have `R` installed and have learned the basics, you can build on your skills and use it to conduct any kind of empirical research end-to-end, from processing text to producing publication-ready figures and tables.

## Case: Measuring Similarity Between Supreme Court Decisions

To help you understand CLMs, we will apply it to a concrete case: measuring how similar Swedish Supreme Court (Högsta domtolsen) decisions are to each other.
That is to say, we will seek to measure how similar all other judgments are to a particular judgment, which we'll refer to as our `anchor case`.
Case similarity comparison is a realistic and common legal task with clear practical uses that you will learn to do at scale: we will compare more than 2,500 judgments to the anchor case using data from the *sehc* project.

## Getting Ready: Step-by-Step

If you are reading this, it means that you successfully downloaded and unpacked the workshop zip-file. 
We will be working with these files so remember where the folder is.  

1. **Install R.** `R` contains the basic files that allows your computer to run R code. 
Download and install the version that matches your operating system from [**CRAN**](https://mirror.accum.se/mirror/CRAN/).

2. **Install RStudio.** `RStudio` is an application that makes it easier to explore data, write, test and run R code. 
Download and install the version that matches your operating system from [**RStudio**](https://docs.posit.co/ide/user/#direct-downloads-open-source).

3. **Install R packages.** *packages* contain functions that are not in the base-version of `R` and that we need to conduct the analysis. 
Launch `RStudio`, for example by opening the file `clm_intro.Rproj` in the folder. 
Then run the code below in Console (the left pane) to install all the neccessary packages (it will take a few minutes):

```
install.packages(c("tidyverse", "tidytext", "Matrix", "SnowballC", "doc2vec", "igraph", "jsonlite", "glue"))
```

4. **Launch the RProj-file.** In your file manager, find and double-click `clm_intro.Rproj`. This should open the project in RStudio. One way to know that it works is that you'll see the folder content in the Files tab in the bottom-right corner of RStudio

*That's it, you are ready!*

## What's in This Folder? 

The folder that you downloaded contains everything you need for the workshop, including data and R scripts for analyzing the data.

| File | Type | Contents |
|---|---|---|
| `01_quantitative_text_analysit.R` | script | part 1, introduces quantitative text analysis |
| `02_networks.R` | script | part 2, introduces network analysis |
| `03_llms.R` | script | part 3, compares results and introduce how to use llms |
| `cases.csv` | data | table with one row per judgment containing case-level metadata |
| `citation_edges.csv` | data | table with one row per citation from one judgment to another |
| `clm_intro.Rproj` | R-project | used to manage and organize project-related resources in RStudio |
| `opinions.csv` | data | table with one row per opinion containing opinion-level matedata |
| `promp_eval.json` | instructions | strcutured json file for the llm prompt | 
| `README.md` | doc | this document as markdown |
| `README.pdf` | doc | this document as pdf |
| `text.csv` | data | table with one row per paragraph containing judgment text | 

## Having Trouble?

If you run into problems with setting up your machine, you can [book a meeting](https://calendly.com/jojo-lindholm/30min) with me.

## Suggested Further Reading

- Chau, B., & Livermore, M. (2024). Computational Legal Studies Comes of Age. European Journal of Empirical Legal Studies, 1(1), 89–104. [**https://doi.org/10.62355/ejels.19684**](https://doi.org/10.62355/ejels.19684)

- Alschner, W. (2020). Sense and Similarity: Automating Legal Text Comparison. In: Computational Legal Studies: The Promise and Challenge of Data-driven Research (Edward Elgar, Whalen, R. ed). [**https://papers.ssrn.com/sol3/papers.cfm?abstract_id=3338718**](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=3338718)

- Schauer, F., & Spellman, B. (2023). Precedent and Similarity. In: Philosophical Foundations of Precedent (Oxford, Endicott, T. et al. eds.). [**https://doi.org/10.1093/oso/9780192857248.003.0019**](https://doi.org/10.1093/oso/9780192857248.003.0019)
