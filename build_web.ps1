Write-Host "Building Human Benchmark Web Version..." -ForegroundColor Green
Write-Host ""

Write-Host "Features:" -ForegroundColor Yellow
Write-Host "- Landing page showcasing mobile app" -ForegroundColor White
Write-Host "- 'Test Your Brain' button in header" -ForegroundColor White
Write-Host "- Persistent sidebar navigation" -ForegroundColor White
Write-Host "- Web-optimized reaction time game" -ForegroundColor White
Write-Host "- Full-width leaderboard with filters" -ForegroundColor White
Write-Host "- Material 3 design system" -ForegroundColor White
Write-Host "- Responsive layout for all devices" -ForegroundColor White
Write-Host ""

flutter build web --target lib/web/main.dart --release

Write-Host ""
Write-Host "Build complete! Web files are in build/web/" -ForegroundColor Green
Write-Host "Open build/web/index.html in your browser to test." -ForegroundColor Cyan
Write-Host ""
Read-Host "Press Enter to continue"
