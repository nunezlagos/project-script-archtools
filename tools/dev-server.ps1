Param(
  [string]$Port = "8000"
)

Add-Type -AssemblyName System.Net.HttpListener
Add-Type -AssemblyName System.Web

$prefix = "http://localhost:$Port/"
$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add($prefix)
$listener.Start()
Write-Host "Server listening at $prefix"

$root = Get-Location
$mime = @{
  '.html' = 'text/html'
  '.htm'  = 'text/html'
  '.css'  = 'text/css'
  '.js'   = 'application/javascript'
  '.png'  = 'image/png'
  '.jpg'  = 'image/jpeg'
  '.jpeg' = 'image/jpeg'
  '.svg'  = 'image/svg+xml'
  '.webp' = 'image/webp'
}

while ($listener.IsListening) {
  $ctx = $listener.GetContext()
  try {
    $localPath = [System.Web.HttpUtility]::UrlDecode($ctx.Request.Url.LocalPath.TrimStart('/'))
    if ([string]::IsNullOrWhiteSpace($localPath)) { $localPath = 'index.html' }
    $fsPath = Join-Path -Path $root -ChildPath $localPath
    if (Test-Path $fsPath -PathType Leaf) {
      $ext = [System.IO.Path]::GetExtension($fsPath).ToLower()
      $ct = $mime[$ext]
      if (-not $ct) { $ct = 'application/octet-stream' }
      $bytes = [System.IO.File]::ReadAllBytes($fsPath)
      $ctx.Response.ContentType = $ct
      $ctx.Response.ContentLength64 = $bytes.Length
      $ctx.Response.OutputStream.Write($bytes,0,$bytes.Length)
    } else {
      $ctx.Response.StatusCode = 404
      $buf = [Text.Encoding]::UTF8.GetBytes('Not Found')
      $ctx.Response.OutputStream.Write($buf,0,$buf.Length)
    }
  } finally {
    $ctx.Response.Close()
  }
}