# PrecisionCare Diagnostic Centre - Web Admin Portal

Official Web Admin Portal for PrecisionCare Diagnostic Centre, built with Flutter Web.
This repository contains **only the admin panel**; the patient mobile app lives in its own project.
Both talk to the same Firebase project (`precision-care-2ab84`), so every change made here is live in the patient app.

## Features
- **Booking Requests Management**: Real-time patient appointment bookings, status updates (Pending, Confirmed, Completed, Cancelled).
- **Home Visit Dispatches**: Phlebotomist/technician assignment and live tracking.
- **Medical Staff & Technicians Directory**: Add, edit, manage healthcare staff and field technicians.
- **Test Categories & Departments**: Add, edit, and delete diagnostic categories, each with a **tile photo** and a "Show on patient home" switch that drives the home "Shop by category" grid.
- **Diagnostic Test Catalog**: Full catalog management with smart search (multi-word, `xray` = `X-Ray`, synonyms like `sugar` → HbA1c), price filters, strict category isolation and an optional **test photo** shown on every patient card.
- **Health Packages**: Packages with photo, included tests, offer price, card tag ("Smart Report"), report time, advertised test count and a "Feature at top of home" switch.
- **Lab Sections** (patient home → "Lab tests & packages"): Section (e.g. *For Women*, with photo, gender and age range) → Sub-category (e.g. *Adult Women*, photo, age range) → packages & tests. Gender/age drive the patient's **"Recommended for you"** rail. One-tap starter sections pre-filled from the catalog.
- **Home Sections** (curated rails/tiles on the patient home): *Checkups & Vaccination for Fever*, *Packages for lifestyle concerns*, *Athlete health empowerment* (pill tabs), *Specialised tests* and *Children's range* (photo tiles with "Starting at ₹"). Layout, order, visibility and the items inside are all editable.
- **Specialists & Lab Doctors**: Photo, name, specialty, badge, order and the category opened on tap for the home "Consult specialists" rail (import the built-in doctors with one tap).
- **Promotional Banners & Offers**: Top carousel or mid-page placement, 2:1 image upload, and a tap action (website link, package, test, lab section or category).
- **Patient User Directory**: Registered patient management and broadcast reminders.
- **Doctor Prescription Slips**: View uploaded prescriptions and generate printable PDF prescription slips.

## Project Structure
- `lib/main.dart`: Admin entry point (Firebase init + admin auth gate).
- `lib/screens/admin/admin_dashboard_screen.dart`: Main admin portal dashboard (sidebar + tabs).
- `lib/screens/admin/widgets/`: Dialogs and tabs — tests, categories, staff, banners, packages, lab sections, home sections, image upload.
- `lib/providers/admin_provider.dart`: Live admin data state (Firestore streams).
- `lib/services/`, `lib/models/`: Firestore services and data models shared with the patient app.
- `build/web/`: Production Flutter Web compilation served by Vercel.
- `vercel.json`: Vercel routing configuration.

## Firestore collections
`bookings`, `users`, `staff`, `catalog`, `categories`, `banners`, `packages`, `lab_audiences` (lab sections), `home_collections` (home sections), `specialists`, `reports`, `notifications`, `prescriptions`.

## Build & deploy
```bash
flutter pub get
flutter build web --release   # output: build/web
```
Commit `build/web` — Vercel serves it as configured in `vercel.json`:
- **Live URL**: `https://precisioncare-admin-portal.vercel.app`
