@echo off
echo Building Human Benchmark Web Version...
echo.

echo Features:
echo - Landing page showcasing mobile app
echo - "Test Your Brain" button in header
echo - Persistent sidebar navigation
echo - Web-optimized reaction time game
echo - Full-width leaderboard with filters
echo - Material 3 design system
echo - Responsive layout for all devices
echo.

flutter build web --target lib/web/main.dart --release

echo.
echo Build complete! Web files are in build/web/
echo Open build/web/index.html in your browser to test.
echo.
pause
