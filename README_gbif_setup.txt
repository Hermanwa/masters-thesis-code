GBIF credential setup (do this once)
=====================================

The script reads your GBIF login from R's .Renviron file so your password
never appears in the script or on screen.

STEP 1 - Open .Renviron in R/RStudio:
    usethis::edit_r_environ()        # if you have the 'usethis' package
  OR open this file in a text editor:
    C:\Users\herma\Documents\.Renviron

STEP 2 - Add these three lines (no quotes, no spaces around '='):

    GBIF_USER=your_gbif_username
    GBIF_PWD=your_gbif_password
    GBIF_EMAIL=your_account_email@example.com

STEP 3 - Save the file, then FULLY RESTART R (Session > Restart R).
         .Renviron is only read at startup.

STEP 4 - Verify it loaded (should print your username, not ""):
    Sys.getenv("GBIF_USER")

Then run:  source("gbif_norway_maps.R")

Notes
-----
- Keep .Renviron out of any git repo / cloud share if it holds your password.
- The download runs on GBIF's servers and may take from seconds to a few
  minutes; occ_download_wait() polls until it is ready.
- The resulting DOI (printed at the end and saved to gbif_data/CITATION.txt)
  is what you cite in your formal work.
