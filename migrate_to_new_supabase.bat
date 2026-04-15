@echo off
REM ========================================
REM Supabase Migration Helper Script
REM From: palkarfoods224@gmail.com
REM To: grayprogrammers008@gmail.com
REM ========================================

echo.
echo ========================================
echo TravelCompanion Supabase Migration
echo ========================================
echo.

REM Check if Supabase CLI is installed
where supabase >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Supabase CLI is not installed!
    echo.
    echo Install using one of these methods:
    echo   1. npm install -g supabase
    echo   2. scoop install supabase
    echo.
    echo After installation, run this script again.
    pause
    exit /b 1
)

echo ✓ Supabase CLI is installed
echo.

REM Step 1: Login
echo ========================================
echo Step 1: Login to Supabase
echo ========================================
echo.
echo This will open a browser window...
supabase login

if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Login failed!
    pause
    exit /b 1
)

echo ✓ Login successful
echo.

REM Step 2: Get project references
echo ========================================
echo Step 2: Project Configuration
echo ========================================
echo.
echo You need the project reference IDs from both projects.
echo.
echo To find project-ref:
echo   1. Go to https://app.supabase.com
echo   2. Open your project
echo   3. URL will be: https://app.supabase.com/project/[PROJECT-REF]
echo   4. Copy the [PROJECT-REF] part
echo.
set /p OLD_PROJECT_REF="Enter OLD project reference ID (palkarfoods224): "
set /p NEW_PROJECT_REF="Enter NEW project reference ID (grayprogrammers008): "
echo.

REM Step 3: Export from old project
echo ========================================
echo Step 3: Export Schema from Old Project
echo ========================================
echo.
echo Linking to old project...
supabase link --project-ref %OLD_PROJECT_REF%

if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to link to old project!
    pause
    exit /b 1
)

echo ✓ Linked to old project
echo.
echo Pulling database schema...
supabase db pull

if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to pull schema!
    pause
    exit /b 1
)

echo ✓ Schema exported successfully
echo.

REM Step 4: Switch to new project
echo ========================================
echo Step 4: Import to New Project
echo ========================================
echo.
echo Unlinking from old project...
supabase unlink

echo Linking to new project...
supabase link --project-ref %NEW_PROJECT_REF%

if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to link to new project!
    pause
    exit /b 1
)

echo ✓ Linked to new project
echo.

REM Step 5: Apply all migrations
echo ========================================
echo Step 5: Applying All Migrations
echo ========================================
echo.
echo This will apply 37 migration files to the new project...
echo.
set /p CONFIRM="Are you sure you want to proceed? (Y/N): "
if /i "%CONFIRM%" NEQ "Y" (
    echo Migration cancelled.
    pause
    exit /b 0
)

echo.
echo Pushing migrations to new project...
supabase db push

if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to push migrations!
    echo.
    echo You may need to apply migrations manually.
    pause
    exit /b 1
)

echo ✓ Migrations applied successfully
echo.

REM Step 6: Next steps
echo ========================================
echo Migration Complete!
echo ========================================
echo.
echo Schema migration is complete.
echo.
echo NEXT STEPS:
echo.
echo 1. Migrate Data:
echo    - Use the Supabase Dashboard to export/import CSV files
echo    - OR use pg_dump/psql for full data export
echo.
echo 2. Migrate Storage:
echo    - Download files from old project Storage
echo    - Upload to new project Storage
echo    - OR use the migration script in SUPABASE_MIGRATION_GUIDE.md
echo.
echo 3. Update App Configuration:
echo    - Update lib/core/config/supabase_config.dart
echo    - Replace old Supabase URL and Anon Key with new ones
echo.
echo 4. Test Everything:
echo    - Run the app and test all features
echo    - Verify data integrity
echo.
echo 5. Get new credentials from new project:
echo    - Go to Settings -^> API
echo    - Copy new Project URL
echo    - Copy new Anon/Public Key
echo    - Update in your app
echo.
echo Full guide: SUPABASE_MIGRATION_GUIDE.md
echo.

pause
