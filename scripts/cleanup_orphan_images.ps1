param(
  [Parameter(Mandatory = $true, HelpMessage = 'Supabase service_role key from Project Settings > API')]
  [string]$ServiceRoleKey
)

$ProjectRef = "lgiepatlslklpxmeqkww"
$BaseUrl = "https://$ProjectRef.supabase.co"
$Bucket = "product-images"

$headers = @{
  "apikey" = $ServiceRoleKey
  "Authorization" = "Bearer $ServiceRoleKey"
  "Content-Type" = "application/json"
}

Write-Host "=== Fetching all files from bucket ===" -ForegroundColor Cyan
$rootFiles = @(Invoke-RestMethod -Uri "$BaseUrl/storage/v1/object/list/$Bucket" `
  -Method Post -Headers $headers -Body (@{ prefix = ""; limit = 1000; sortBy = @{ column = "name"; order = "asc" } } | ConvertTo-Json))
$itemsFiles = @(Invoke-RestMethod -Uri "$BaseUrl/storage/v1/object/list/$Bucket" `
  -Method Post -Headers $headers -Body (@{ prefix = "items/"; limit = 1000; sortBy = @{ column = "name"; order = "asc" } } | ConvertTo-Json))
$catFiles = @(Invoke-RestMethod -Uri "$BaseUrl/storage/v1/object/list/$Bucket" `
  -Method Post -Headers $headers -Body (@{ prefix = "category_covers/"; limit = 1000; sortBy = @{ column = "name"; order = "asc" } } | ConvertTo-Json))

Write-Host "Root-level files: $($rootFiles.Count)"
Write-Host "items/ files: $($itemsFiles.Count)"
Write-Host "category_covers/ files: $($catFiles.Count)"

Write-Host "`n=== Fetching referenced URLs from DB ===" -ForegroundColor Cyan

# Get all image_urls from rate_list (non-empty)
$rateListResp = Invoke-RestMethod -Uri "$BaseUrl/rest/v1/rate_list?select=image_url&image_url=neq." `
  -Method Get -Headers $headers
$referencedItemUrls = @($rateListResp | ForEach-Object { $_.image_url })

# Get all cover_image_urls from categories (non-null)
$catResp = Invoke-RestMethod -Uri "$BaseUrl/rest/v1/categories?select=cover_image_url&cover_image_url=not.is.null" `
  -Method Get -Headers $headers
$referencedCatUrls = @($catResp | ForEach-Object { $_.cover_image_url })

$allReferencedUrls = $referencedItemUrls + $referencedCatUrls
Write-Host "Referenced URLs found: $($allReferencedUrls.Count)"

# Helper: extract storage path from public URL
function Get-StoragePath($url) {
  $prefix = "$BaseUrl/storage/v1/object/public/$Bucket/"
  if ($url -like "$prefix*") {
    return $url.Substring($prefix.Length)
  }
  return $null
}

$referencedPaths = @($allReferencedUrls | ForEach-Object { Get-StoragePath $_ } | Where-Object { $_ -ne $null })
Write-Host "Referenced storage paths: $($referencedPaths.Count)"
Write-Host "`nReferenced paths:"
$referencedPaths | ForEach-Object { Write-Host "  $_" }

# Determine orphans
function Get-Orphans($files, $prefix) {
  $orphans = @()
  foreach ($f in $files) {
    if ($f.name -eq $null -or $f.metadata -eq $null) { continue }  # skip folder entries
    $storagePath = if ($prefix) { "$prefix/$($f.name)" } else { $f.name }
    if ($storagePath -notin $referencedPaths) {
      $orphans += $storagePath
    }
  }
  return $orphans
}

$rootOrphans = Get-Orphans $rootFiles $null
$itemsOrphans = Get-Orphans $itemsFiles "items"
$catOrphans = Get-Orphans $catFiles "category_covers"

$allOrphans = $rootOrphans + $itemsOrphans + $catOrphans

Write-Host "`n============================================" -ForegroundColor Yellow
Write-Host "ORPHAN FILES TO DELETE ($($allOrphans.Count) total)" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Yellow

if ($allOrphans.Count -eq 0) {
  Write-Host "No orphan files found. Nothing to clean up." -ForegroundColor Green
  exit 0
}

Write-Host "`n--- Root level orphans ($($rootOrphans.Count)) ---"
$rootOrphans | ForEach-Object { Write-Host "  $_" }

Write-Host "`n--- items/ orphans ($($itemsOrphans.Count)) ---"
$itemsOrphans | ForEach-Object { Write-Host "  $_" }

Write-Host "`n--- category_covers/ orphans ($($catOrphans.Count)) ---"
$catOrphans | ForEach-Object { Write-Host "  $_" }

$totalSize = 0
$allFiles = $rootFiles + $itemsFiles + $catFiles
$orphanNames = @($allOrphans | ForEach-Object {
  # Extract just the filename for matching
  if ($_ -like "items/*") { return $_.Substring(6) }
  elseif ($_ -like "category_covers/*") { return $_.Substring(16) }
  else { return $_ }
})
foreach ($f in $allFiles) {
  if ($f.name -and $f.metadata -and $f.name -in $orphanNames) {
    $totalSize += $f.metadata.size
  }
}
Write-Host "`nTotal size: $([math]::Round($totalSize / 1MB, 2)) MB" -ForegroundColor Yellow

# Confirm and delete
$confirm = Read-Host "`nDelete these $($allOrphans.Count) files? (y/N)"
if ($confirm -ne 'y' -and $confirm -ne 'Y') {
  Write-Host "Aborted." -ForegroundColor Red
  exit 0
}

Write-Host "`n=== Deleting orphan files ===" -ForegroundColor Cyan

# Delete in batches of 100 (Supabase limit)
$batchSize = 100
for ($i = 0; $i -lt $allOrphans.Count; $i += $batchSize) {
  $batch = $allOrphans[$i..([Math]::Min($i + $batchSize - 1, $allOrphans.Count - 1))]
  $body = @{ prefixes = @($batch) } | ConvertTo-Json -Compress
  
  try {
    $result = Invoke-RestMethod -Uri "$BaseUrl/storage/v1/object/$Bucket" `
      -Method Delete -Headers $headers -Body $body
    Write-Host "  Deleted batch: $($batch.Count) files" -ForegroundColor Green
  } catch {
    Write-Host "  Error deleting batch: $_" -ForegroundColor Red
    $_.Exception.Response | ForEach-Object { Write-Host $_.StatusCode }
  }
}

Write-Host "`n=== Done ===" -ForegroundColor Cyan
