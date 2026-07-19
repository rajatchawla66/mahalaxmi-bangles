# PROJECT STRUCTURE — Mahalaxmi Bangles Order Manager

## Root Directory

```
C:\Users\rajat\Labour-receipt\
│
├── main.py                 # Entry point, navigation, render, state
├── db.py                   # Supabase REST API layer (httpx)
├── utils.py                # Image processing, helpers, connectivity banner
├── cache.py                # Offline caching (JSON files)
├── session_helper.py       # Session save/load/clear
├── slip_pdf_generator.py   # Karigar slip PDF generation (fpdf2)
├── auth.py                 # Legacy auth (moved to views/auth.py)
│
├── views/                  # All screen implementations
│   ├── __init__.py
│   ├── auth.py             # Login / role selection
│   ├── home.py             # Admin + Labour dashboard
│   ├── orders.py           # Order forms, detail, karigar slip
│   ├── pricing.py          # Add Item, Catalogue, Costing
│   ├── settings.py         # Settings, Tag Master, categories
│   ├── customer.py         # Customer PIN login, catalogue, cart, search
│   ├── customers.py        # Admin Manage Customers
│   ├── labour.py           # Labour production checklist
│   └── archive.py          # Completed/cancelled order archive
│
├── sql/                    # Database migrations
│   ├── create_customers_table.sql
│   ├── migration_add_production_status.sql
│   ├── migration_add_tag_categories_jsonb.sql
│   ├── migration_add_tags.sql
│   └── migration_remove_card_path.sql
│
├── assets/                 # Static assets
│   └── fonts/
│       └── HindiFont.ttf   # Hindi font for PDF slips
│   ├── icon.png            # App icon
│   └── watermark.png       # Watermark for images
│
├── archive/                # Archived documentation
│   ├── PROJECT_CONTEXT.md
│   ├── PROJECT_HANDOVER.md
│   └── contextD.md
│
├── .github/workflows/
│   └── build_apk.yml       # GitHub Actions CI config
│
├── android/
│   └── debug.keystore      # Release signing keystore
│
├── project configs
│   ├── pyproject.toml      # Flet build config + dependencies
│   ├── requirements.txt    # Python dependencies
│   ├── .gitignore          # Git exclusions
│   └── version.txt         # App version
│
├── documentation
│   ├── PROJECT_MEMORY.md   # Main project memory (~1700 lines)
│   ├── ARCHITECTURE.md     # Architecture documentation
│   ├── ARCHITECTURE_OVERVIEW.md  # Compact architecture (backup)
│   ├── FEATURE_STATUS.md   # Feature tracking
│   ├── KNOWN_ISSUES.md     # Known bugs/issues
│   ├── Audit Report 11June.md  # Card audit report
│   └── IMPORTANT_WORKFLOWS.md  # Business workflows (backup)
│
├── backup docs (generated for migration)
│   ├── BACKUP_MANIFEST.md
│   └── MIGRATION_NOTES_FOR_FLUTTER.md
│
├── excludes from backup
│   ├── venv/               # Python virtual env
│   ├── build/              # APK build artifacts
│   ├── product_images/     # Uploaded product images
│   ├── generated_cards/    # Price card images
│   ├── item_images/        # Item images
│   ├── storage/            # Storage cache
│   ├── cache/              # Offline cache (JSON + images)
│   ├── .git/               # Git repository
│   ├── __pycache__/        # Python cache
│   ├── .kiro/              # Kiro AI tool artifacts
│   ├── .streamlit/         # Streamlit config
│   └── release-signing-backup/  # Keystore backup
```

## Key File Line Counts

| File | Lines | Role |
|------|-------|------|
| main.py | ~1000 | Orchestrator |
| db.py | ~850 | Data access |
| views/customer.py | ~1400 | Customer flows |
| views/orders.py | ~1100 | Order flows |
| views/settings.py | ~920 | Admin settings |
| views/pricing.py | ~800 | Catalogue/costing |
| views/home.py | ~350 | Dashboard |
| views/labour.py | ~250 | Labour flows |
| views/customers.py | ~200 | Customer mgmt |
| views/archive.py | ~30 | Archive |
| views/auth.py | ~50 | Login |
| cache.py | ~200 | Offline cache |
| utils.py | ~150 | Helpers |
| session_helper.py | ~50 | Sessions |
| slip_pdf_generator.py | ~300 | PDF gen |
| PROJECT_MEMORY.md | ~1700 | Master doc |
