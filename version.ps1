###
# SmVer version generator based on current commit.
#
# Requires to enable these Git features: unshallow fetch, fetch tags. Output difer from the Git environment:
#
#   - If the tag is added on the current commit, output follows <version core>, or <version core> "+" <build>.
#   - If the tag is added on an ancestor, this build is treaten as a pre-release, output follows <version core> "-" <pre-release>, or <version core> "-" <pre-release> "+" <build>. The pre-release is greater than the previous commit. Choice between patch, minor or major version increment is stored in the ".version" file.
#
# Parameters:
#
#   -m    Displays build metadata (<version core> "+" <build>, or <version core> "-" <pre-release> "+" <build>)
#   -c    Cache the date contained in the metadata. Data is stored in the ".version.cache" file. Alloys re-executing the command multiple times with a reproductible response, like in CI/CD environment.
#
# Usage:
#
#   - Without metadata: "./cicd/version.ps1"
#   - With metadata: "./cicd/version.ps1 -b"
#
# See: https://semver.org/#backusnaur-form-grammar-for-valid-semver-versions
###

param(
  [string]
  [Parameter(Mandatory = $true, HelpMessage = "Repository path")]
  [Alias("g")]
  $repo_path,

  [switch]
  [Parameter(Mandatory = $false, HelpMessage = "Displays build metadata (<version core> '+' <build>, or <version core> '-' <pre-release> '+' <build>)")]
  [Alias("m")]
  $metadata,

  [switch]
  [Parameter(Mandatory = $false, HelpMessage = "Cache the date contained in the metadata. Data is stored in the '.version.cache' file. Alloys re-executing the command multiple times with a reproductible response, like in CI/CD environment.")]
  [Alias("c")]
  $cache
)

if ($null -eq $(git tag --merged HEAD 'v[0-9]*.[0-9]*.[0-9]*')) {
  Write-Output "Error: no tag found, use 'git tag v0.0.0'"
  exit 1
}

$version_file = "${repo_path}/.version.config"
if (Test-Path $version_file) {
  $version_config = Get-Content $version_file
} else {
  $version_config = "patch"
  $version_config | Out-File $version_file
}

$cache_file = "${repo_path}/.version.cache"
$latest_tag_raw = $(git describe --all --abbrev=0 --match "v[0-9]*.[0-9]*.[0-9]*" --candidates=10000)
$latest_tag_matches = Select-String "^tags/v([0-9]+).([0-9]+).([0-9]+)" -inputobject $latest_tag_raw
$latest_tag_x = [int] $latest_tag_matches.Matches.Groups[1].Value
$latest_tag_y = [int] $latest_tag_matches.Matches.Groups[2].Value
$latest_tag_z = [int] $latest_tag_matches.Matches.Groups[3].Value
$count_from_tag = [int] $(git rev-list HEAD ^$latest_tag_raw --count --ancestry-path --no-merges)

if ($count_from_tag -eq 0) {
  # <version core>
  $base_smver = "$latest_tag_x.$latest_tag_y.$latest_tag_z"

} else {
  # Remove all the zeros at the leading zeros, as this is not compliant with SmVer
  $commit_id = git rev-parse --short HEAD | ForEach-Object { $_ -replace '^0*', '' }
  $prerelease_smver = "$count_from_tag.$commit_id"

  switch ($version_config) {
    "major" {
      $latest_tag_x++
      $latest_tag_y = 0
      $latest_tag_z = 0
      break
    }
    "minor" {
      $latest_tag_y++
      $latest_tag_z = 0
      break
    }
    "patch" {
      $latest_tag_z++
      break
    }
    default {
      throw "Unknown version config: $version_config"
    }
  }

  # <version core> "-" <pre-release>
  $base_smver = "$latest_tag_x.$latest_tag_y.$latest_tag_z-$prerelease_smver"
}

if ( $metadata -eq $true ) {
  if ( $cache -eq $true -and (Test-Path $cache_file) ) {
    $build_date = Get-Content $cache_file

  } else {
    $build_date = (Get-Date).ToUniversalTime().ToString("yyyyMMddHHmmss")
    Set-Content $cache_file $build_date
  }

  $metadata_smver = $build_date
  Write-Output "$base_smver+$metadata_smver"

} else {
  Write-Output "$base_smver"
}
