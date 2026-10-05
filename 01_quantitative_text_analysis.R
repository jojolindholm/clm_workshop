# clm-workshop
# johan lindholm, umeå university
# 15 september 2026
#
# ************************************
# **** quantitative text analysis ****
# ************************************
# a hands-on introduction to r and legal qta
# you will learn about: basic coding concepts; foundations of r; 
# loading, modifying, and saving data; tf-idf; doc2vec; and cosine similarity


# prepare ----------------------------------------------------------------------

set.seed(42)   # keeps results reproducible

# load packages

library(tidyverse)   # collection of data science packages 
library(tidytext)    # for qta in tidyverse 
library(Matrix)      # for sparse matrix for the large word-by-case table
library(SnowballC)   # for collapsing words into common root
library(doc2vec)     # for text vectors that considers word order

# load text data

text <- read_csv("text.csv")    # judgment text
cases <- read_csv("cases.csv")   # judgment metadata

# select anchor_case (to which we will compare other judgments)

anchor_case <- "B 1064-19"   # define anchor_case as NJA 2019 s. 684 (mopedbilen)


# step 1 — build the corpus ----------------------------------------------------

# intro to functions and objects: check 

help(head)   # functions are called by name followed by arguments in parentheses
head(text)   # head() glances at the table and its variables
dim(text)    # dim() presents how table is shaped

# intro to tidy: create `corpus` with one document per case

corpus <-                                 # variable before `<-` becomes a new object, doesn't touch `text` 
  text |>                                 # variable before `|>` is passed (piped) to the next function
  arrange(case_num, para_num) |>          # keep paragraphs in reading order
  group_by(case_num) |>                   # group data by case number
  summarise(                              # functions can be placed inside
    text = paste(text, collapse = " ")    # paste() combines strings
  )

head(corpus)  # results in one row per case with full opinion as `text`

# different codes can achieve the some product

corpus <- arrange(text, case_num, para_num)
corpus <- group_by(corpus, case_num)
corpus <- summarise(corpus, text = paste(text, collapse = " "))
head(corpus)

# create `corpus_facts` with only facts

corpus_facts <- text |>
  filter(section_class == "intro") |>   # filter to only keep paragraphs in section "intro"
  arrange(case_num, para_num) |>    
  group_by(case_num) |>               
  summarise(text = paste(text, collapse = " "))


# step 2 — compare judgments using tf-idf --------------------------------------
# tf-idf gives every word in every judgment a weight, which is high when the 
# word is frequent in the judgment but rare in the corpus, and near zero for 
# words that occur everywhere.
# each judgment becomes a vector of its distinctive words, and two judgments 
# can be compared by how much their vectors overlap.

## create tf-idf table `corpus_tfidf` ------------------------------------------

corpus_tfidf <- corpus |>                                              
  unnest_tokens(word, text) |>                                        # split text into one row per word
  mutate(word = SnowballC::wordStem(word, language = "swedish")) |>   # reduce words to stems, e.g. domar -> dom
  count(case_num, word, sort = TRUE) |>                               # count words per case
  bind_tf_idf(word, case_num, n)                                      # add tf-idf weight

dim(corpus_tfidf)

# which words distinguishes anchor case? 

filter(corpus_tfidf, case_num == anchor_case)   # tf-idf representation of anchor_case

corpus_tfidf |>
  filter(case_num == anchor_case) |>   # filter data to only anchor_case
  slice_max(tf_idf, n = 10) |>         # select ten highest-weighted words
  select(word, n, tf_idf)              # select interesting variables

## compare cases to anchor case by cosine similarity ---------------------------

# calculate cosine similarity 

m <- cast_sparse(corpus_tfidf, case_num, word, tf_idf)    # turn table into matrix, one row per judgment, one column per word, values are tf-idf weight 
target <- as.numeric(m[anchor_case, ])                    # take row for anchor_case
cosine <- as.numeric(m %*% target) /                      # matrix multiply each other judgment's weights by anchor case's
  (sqrt(Matrix::rowSums(m^2)) * sqrt(sum(target^2)))      # turn product into cosine similarity
names(cosine) <- rownames(m)                              # add case names

##  top-10 by tf-idf cosine similiarity ---------------------------------------- 

top_10_tfidf <- tibble(case_num = names(cosine), similarity = as.numeric(cosine)) |>
  left_join(cases |> select(case_num, publ_num, court_header), by = "case_num") |>
  filter(case_num != anchor_case) |>     # drop the case itself (similarity 1)
  arrange(desc(similarity)) |>
  slice_head(n = 10) |>
  mutate(similarity = round(similarity, 3))

top_10_tfidf   # inspect top-10 list

save(top_10_tfidf, file = "top_10_tfidf.csv")   # save top-list to csv file


# step 3 — compare judgments using doc2vec -------------------------------------
# tf-idf treats a judgment as a bag of words: only exact word overlap counts.
# doc2vec instead "learns" a dense vector for each judgment, so words used in
# similar ways end up close together and two judgments can be similar even when
# they share few exact words.
# we train on `corpus_facts`

## pre-process: doc2vec needs clean, lowercase text and a document id without spaces ----

facts_clean <- corpus_facts |>
  mutate(                                             # modify table content 
    doc_id = str_replace_all(case_num, " ", "_"),     # "B 1064-19" -> "B_1064-19"
    text = tolower(text),                             # lowercase
    text = str_replace_all(text, "[^a-zåäö ]", " "),  # keep letters only
    text = str_squish(text)                           # collapse repeated spaces
  ) |>
  mutate(text = map_chr(text, ~ paste(head(str_split(.x, " ")[[1]], 1000), collapse = " ")))  # max 1000 words for doc2vec

## train doc2vec model: learns one vector per case by predicting its words ------

facts_doc2vec <- paragraph2vec(
  x = as.data.frame(facts_clean[, c("doc_id", "text")]),
  type = "PV-DBOW", dim = 50, iter = 10, min_count = 2, threads = 1
)

# extract one 50-dimensional vector per case

facts_vectors <- as.matrix(facts_doc2vec, which = "docs")
dim(facts_vectors)

## compare every case to anchor case by cosine similarity ----------------------

anchor_id <- str_replace_all(anchor_case, " ", "_")
facts_cosine <- as.numeric(facts_vectors %*% facts_vectors[anchor_id, ])
names(facts_cosine) <- rownames(facts_vectors)

## top-10 by doc2vec/facts cosine similarity -----------------------------------

top_10_doc2vec <- tibble(doc_id = names(facts_cosine), similarity = as.numeric(facts_cosine)) |>
  left_join(facts_clean |> select(doc_id, case_num), by = "doc_id") |>
  left_join(cases |> select(case_num, publ_num, court_header), by = "case_num") |>
  filter(doc_id != anchor_id) |>
  arrange(desc(similarity)) |>
  slice_head(n = 10) |>
  mutate(similarity = round(similarity, 3)) |>
  select(case_num, publ_num, similarity, court_header)

top_10_doc2vec   # inspect top-10 list
save(top_10_doc2vec, file = "top_10_doc2vec.csv")   # save top-list to csv file
