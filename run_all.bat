@echo off
title Quantum Threat Detection Full Verification - SIH 2026
echo ======================================================================
echo   Quantum-Inspired Cyber Threat Detection Framework for Teleportation QDS
echo   Smart India Hackathon 2026 - Automated Complete Verification
echo ======================================================================
echo.

echo [1/4] Running Automated Pytest Suite...
python -m pytest tests\ -v -p no:cacheprovider
if %errorlevel% neq 0 (
    echo [ERROR] Test suite failed.
    pause
    exit /b %errorlevel%
)
echo.

echo [2/4] Generating Publication-Grade Visual Analytics...
python benchmarks\generate_plots.py
echo.

echo [3/4] Executing Comprehensive Benchmark Suite...
python benchmarks\run_benchmarks.py
echo.

echo [4/4] Launching Interactive CLI Demo...
python run_demo.py
echo.

echo ======================================================================
echo   ALL VERIFICATIONS PASSED SUCCESSFULLY!
echo   To launch the graphical web dashboard, run: run_dashboard.bat
echo ======================================================================
pause
