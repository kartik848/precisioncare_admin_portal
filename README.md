# PrecisionCare Diagnostic Centre - Web Admin Portal

Official Web Admin Portal for PrecisionCare Diagnostic Centre, built with Flutter Web.

## Features
- **Booking Requests Management**: Real-time patient appointment bookings, status updates (Pending, Confirmed, Completed, Cancelled).
- **Home Visit Dispatches**: Phlebotomist/technician assignment and live tracking.
- **Medical Staff & Technicians Directory**: Add, edit, manage healthcare staff and field technicians.
- **Test Categories & Departments**: Add, edit, and delete diagnostic categories (Digital X-Ray, Blood Tests, ECG & Cardiology, Ultrasound, PFT, Physiotherapy, Health Packages).
- **Diagnostic Test Catalog**: Full catalog management with search, price filters, category assignment, and strict category isolation.
- **Promotional Banners & Offers**: Top carousel banner configuration and management.
- **Patient User Directory**: Registered patient management.
- **Doctor Prescription Slips**: View uploaded prescriptions and generate printable PDF prescription slips.

## Project Structure
- `lib/screens/admin/admin_dashboard_screen.dart`: Main admin portal dashboard.
- `lib/screens/admin/widgets/`: Add test dialog, add category dialog, staff dialog, banner dialog.
- `lib/providers/admin_provider.dart`: Live admin data state management.
- `build/web/`: Production Flutter Web compilation ready for Vercel deployment.
- `vercel.json`: Vercel routing configuration.

## Vercel Deployment
This repository is configured with `vercel.json` pointing to `build/web` for static web deployment on Vercel:
- **Live URL**: `https://precisioncare-admin-portal.vercel.app`
