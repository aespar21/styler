add_package_checks(notes_are_errors = getRversion() >= "3.2")

if (Sys.getenv("id_rsa") != "" && ci()$get_branch() == "master" && Sys.getenv("BUILD_PKGDOWN") != "") {
  # pkgdown documentation can be built optionally. Other example criteria:
  # - `inherits(ci(), "TravisCI")`: Only for Travis CI
  # - `ci()$is_tag()`: Only for tags, not for branches
  # - `Sys.getenv("BUILD_PKGDOWN") != ""`: If the env var "BUILD_PKGDOWN" is set
  # - `Sys.getenv("TRAVIS_EVENT_TYPE") == "cron"`: Only for Travis cron jobs
  get_stage("before_deploy") %>%
    add_step(step_setup_ssh())

  get_stage("deploy") %>%
    add_step(step_build_pkgdown()) %>%
    add_code_step(writeLines("styler.r-lib.org", "docs/CNAME")) %>%
    add_step(step_push_deploy("docs", "gh-pages"))
}
