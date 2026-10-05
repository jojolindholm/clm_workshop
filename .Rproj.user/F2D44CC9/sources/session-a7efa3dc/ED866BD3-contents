# clm-workshop
# johan lindholm, umeå universitet
# 5 october 2026
#
# ******************************
# **** llm-based comparison ****
# ******************************
# a hands-on introduction to r and using llms through scripts
# you will learn about: functions; loops; llm api calls; prompting.


# prepare ----------------------------------------------------------------------

set.seed(42)   # keeps results reproducible

library(tidyverse)   # collection of data science packages
library(jsonlite)    # read and write json files
library(glue)        # for formating strings

# load files

text       <- read_csv("text.csv")            # case text per paragraph
cases      <- read_csv("cases.csv")           # case metadata
opinions   <- read_csv("opinions.csv")        # opinion metadata
llm_prompt <- read_json("prompt_eval.json")   # task instructions for llm  

# load the five saved top-10 lists

load("top_10_neighbors.csv")   # network ego-neighbours (binary)
load("top_10_community.csv")   # network community members (continuous)
load("top_10_tfidf.csv")       # tf-idf cosine similarity (continuous)
load("top_10_doc2vec.csv")     # doc2vec cosine similarity (continuous)

# define variables

anchor_case  <- "B 1064-19"                                     # the case we compare all others to
anchor_label <- cases$publ_num[cases$case_num == anchor_case]   # NJA reference for anchor

api_url   <- "https://openrouter.ai/api/v1/chat/completions"                               # url to llm inference endpoint
api_key   <- "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"   # authentication key (bad practice!)
api_model <- "openai/gpt-oss-20b"                                                          # llm model name 


# step 1 — compare the five top-10 lists ---------------------------------------
# combine top-10 lists into one long table

compare <- tibble(                               # create new table
  case_num = unique(c(top_10_neighbors,          # add all unique case_nums from top-10s
                      top_10_community$case_num,
                      top_10_tfidf$case_num,
                      top_10_doc2vec$case_num))   
  ) |>
  filter(case_num != anchor_case) |>             # remove anchor case from results
  mutate(                                        # add values from top-10 lists
    neighbors = as.integer(case_num %in% top_10_neighbors),
    community = top_10_community$norm_pagerank[match(case_num, top_10_community$case_num)],
    tfidf     = top_10_tfidf$similarity[match(case_num, top_10_tfidf$case_num)],
    doc2vec   = top_10_doc2vec$similarity[match(case_num, top_10_doc2vec$case_num)]
  ) |>
  left_join(cases |> select(case_num, publ_num), by = "case_num") |>   # add NJA identifiers
  pivot_longer(cols = -c(case_num, publ_num),                          # pivot wide data to long (one row per case and approach)
               names_to = "approach",                                  # top-10 method column name -> value for `approach`  
               values_to = "value") |>                                 # top-10 method value -> value for `value`
  replace_na(list(value = 0))                                          # similarity 0 if not in list (na)

head(compare)   # glance data

# plot comparison (green = similar, red = not similar)

compare |>
  ggplot(aes(x = approach, 
             y = publ_num, 
             fill = value)) +
  geom_tile(colour = "white", linewidth = 1) +
  scale_fill_gradient(low = "#C0392B", 
                      high = "#27AE60", 
                      limits = c(0, 1)) +
  labs(x = NULL, y = NULL, fill = "similarity")


# step 2 — llm comparison ------------------------------------------------------
# an llm can answer the same question as the five approaches, with the judgment
# texts themselves as context. this step demonstrates the basic elements of
# using llms: script, authentication, prompt, context, and output

## define functions for repeated work ------------------------------------------

get_judgment_text <- function(case) {            # returns selected judgment text for `case`
  case_text <- filter(text, case_num == case)    # filter text for case

  first_instance_majority <- opinions |>         # paragraph range of the first-instance majority opinion
    filter(case_num == case,                     # filter for case_num 
           institution_class == "first",         # filter for first instance court 
           opinion_class == "majority")          # filter for majority opinion
  final_instance_majority <- opinions |>         # paragraph range of the final-instance majority opinion
    filter(case_num == case,                     # filter for case_num 
           institution_class == "final",         # filter for final instance court 
           opinion_class == "majority")          # filter for majority opinion

  if (nrow(first_instance_majority) == 0 |       # if text is missing (error handling)
      nrow(final_instance_majority) == 0) return("")

  facts_text <- case_text |>                     # background (facts) from the first instance
    filter(para_num >= min(first_instance_majority$start_paragraph_id),   # several opinions can match:
           para_num <= max(first_instance_majority$stop_paragraph_id),        # use the whole span
           section_class == "intro") |>
    pull(text)

  sc_majority_text <- case_text |>               # the majority decision from the Supreme Court
    filter(para_num >= min(final_instance_majority$start_paragraph_id),
           para_num <= max(final_instance_majority$stop_paragraph_id)) |>
    pull(text)

  text <- paste(c(facts_text, sc_majority_text), collapse = " ")  # combine background and sv majority into one text 
                
  return(text)                                   # function returns the combined text
}


fill_prompt <- function(candidate_num) {                 # function for building the prompt
  candidate_text <- get_judgment_text(candidate_num)     # get the candidate text using our function
  glue(llm_prompt$user,                                  # combine different strings to what llm requires 
       anchor_case = anchor_label,
       anchor_text = anchor_text,
       candidate_case = candidate_num,
       candidate_text = candidate_text,
       .open = "{{", .close = "}}")
}

# demo of what is passed to the llm

anchor_text <- get_judgment_text(anchor_case)   # use get_judgment_text() to generate text for anchor case
cat(llm_prompt$system)                          # glance system prompt
fill_prompt(compare$case_num[1])                # use fill_prompt() to generate user prompt


## loop for llm evaluation of every candidate ----------------------------------

llm_results <- tibble()                       # empty table for storing results
candidates <- unique(compare$case_num)        # list of all unique case_nums in compare 

for (i in 1:length(candidates)) {             # loop over the candidates
  cat(" ",i, "-", candidates[i], "\n")        # display progress
  prompt_text <- fill_prompt(candidates[i])   # build prompt
  resp <- httr::POST(api_url,                 # send the prompt to the api
                     httr::add_headers(Authorization = paste("Bearer", api_key)),   # authentication
                     body = list(
                       model = api_model,     # model name
                       temperature = 0,       # amount of variation
                       messages = list(
                         list(role = "system", content = llm_prompt$system),
                         list(role = "user", content = prompt_text)
                       )
                     ),
                     encode = "json")

  ans <- httr::content(resp, as = "text", encoding = "UTF-8")
  msg <- fromJSON(ans, simplifyVector = FALSE)$choices[[1]]$message$content
  verdict <- tryCatch(fromJSON(msg, simplifyVector = FALSE), error = function(e) NULL)

  similar <- isTRUE(verdict$similar)              # did the llm find them similar?
  reason  <- verdict$reason                       # its explanation
  if (is.null(reason)) {                          # answer was not json: use the raw text
    similar <- grepl("true", tolower(msg))
    reason  <- substr(msg, 1, 200)
  }

  llm_results <- bind_rows(llm_results, tibble(   # add llm evaluation of this candidate to the results
    case_num = candidates[i],    
    similar = similar,
    reason = reason
  ))
}

head(llm_results)                        # glance data
write_csv(llm_results, "llm_eval.csv")   # save data
