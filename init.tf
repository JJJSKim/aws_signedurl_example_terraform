locals {
  resource_prefix = join("-", compact([
    var.csp
  ]))
  resource_suffix = join("-", [
    var.env,
    var.region
  ])
}