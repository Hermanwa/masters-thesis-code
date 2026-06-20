# =============================================================================
# 00_check_gbif_auth.R  --  Verify GBIF credentials before attempting a download
# =============================================================================
# Hits the GBIF authenticated user endpoint (200 = OK, 401 = bad creds).
# Does NOT print your password.
# =============================================================================

u <- Sys.getenv("GBIF_USER"); p <- Sys.getenv("GBIF_PWD"); e <- Sys.getenv("GBIF_EMAIL")

cat("GBIF_USER :", if (nzchar(u)) u else "<EMPTY>", "\n")
cat("GBIF_EMAIL:", if (nzchar(e)) e else "<EMPTY>", "\n")
cat("GBIF_PWD  :", if (nzchar(p)) paste0("set (", nchar(p), " chars)") else "<EMPTY>", "\n\n")

if (grepl("@", u))
  cat(">> PROBLEM: GBIF_USER looks like an email. It must be your GBIF *username*\n",
      "   (see https://www.gbif.org/user/profile). Set GBIF_USER to that, keep\n",
      "   your email only in GBIF_EMAIL.\n\n", sep = "")

suppressPackageStartupMessages(library(httr))
r <- GET("https://api.gbif.org/v1/user/login", authenticate(u, p))
cat("Auth test status:", status_code(r), "\n")
if (status_code(r) == 200) {
  cat(">> Credentials OK. Re-run 01_download_ano.R.\n")
} else if (status_code(r) == 401) {
  cat(">> 401: username/password rejected. Check username (not email) and password\n",
      "   at https://www.gbif.org/user/profile (and that the account is activated).\n")
} else {
  cat(">> Unexpected status; check network/proxy.\n")
}
