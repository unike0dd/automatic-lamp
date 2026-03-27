# Cafeteria-as-a-Service

Production-oriented starter for a multi-tenant cafeteria commerce platform:

- **Backend**: Node.js API for AI menu assistance + Stripe checkout.
- **Frontend**: Flutter web/mobile app.
- **Infrastructure**: Terraform for Cloud Run deployment.

## Repository structure

```text
.
├── backend/
│   ├── server.js
│   ├── package.json
│   ├── Dockerfile
│   └── .env.example
├── frontend/
│   ├── lib/main.dart
│   ├── pubspec.yaml
│   └── web/_headers
├── infra/
│   └── main.tf
└── .github/workflows/ci.yml
```

## Is this Cloud Run, Firebase, Flutter, Stripe, and Cloudflare ready?

**Short answer: Yes, as a deployable base.**

Readiness by stack:

- ✅ **Cloud Run**: Terraform service (`google_cloud_run_v2_service`) + Dockerfile are included.
- ✅ **Firebase**: Backend uses Firebase Admin SDK and Firestore collections for menu retrieval.
- ✅ **Flutter**: Flutter app scaffold + dependencies are included.
- ✅ **Stripe**: Checkout session flow with tax + invoice creation is implemented.
- ✅ **Cloudflare Pages**: Flutter web output can be deployed; security headers template included in `frontend/web/_headers`.

Still required before production:

- Configure real domains and callback URLs.
- Move secret handling to Secret Manager (or equivalent) instead of plain Terraform variables.
- Add Stripe webhook endpoint for post-payment state synchronization.
- Add authentication/authorization and tenant isolation controls.

## 1) Backend (Cloud Run)

### Local run
This repository is split into three parts:

- `backend/`: Node.js + Express API for AI suggestions and Stripe Checkout.
- `frontend/`: Flutter app with AI budget chat and checkout trigger.
- `infra/`: Terraform for provisioning Cloud Run.

## Backend (Cloud Run)

```bash
cd backend
npm install
cp .env.example .env
npm start
```

Environment variables required:

- `OPENAI_API_KEY`
- `STRIPE_SECRET_KEY`
- `PORT` (optional, defaults to 8080)

### Build container

```bash
docker build -t gcr.io/YOUR_PROJECT/backend-image:latest backend
```

## 2) Frontend (Flutter)

### Local web run

```bash
cd frontend
flutter pub get
flutter run -d chrome --dart-define=BACKEND_BASE_URL=http://localhost:8080
```

### Production web build

```bash
flutter build web --release --dart-define=BACKEND_BASE_URL=https://YOUR_CLOUD_RUN_URL
```

Deploy `frontend/build/web` to Cloudflare Pages.

## 3) Infrastructure (Terraform)
npm start
```

Required env vars:

- `OPENAI_API_KEY`
- `STRIPE_SECRET_KEY`

## Frontend (Flutter)

Pass Cloud Run URL at build time:

```bash
flutter build web --release --dart-define=BACKEND_BASE_URL=https://YOUR_RUN_URL
```

## Infrastructure (Terraform)

```bash
cd infra
terraform init
terraform apply \
  -var="project_id=YOUR_PROJECT" \
  -var="backend_image=gcr.io/YOUR_PROJECT/backend-image:latest" \
  -var="stripe_secret_key=..." \
  -var="openai_api_key=..."
```

## GitHub visibility and legibility

This repository is now structured for easy GitHub browsing:

- Clear folder boundaries (`backend`, `frontend`, `infra`).
- Quick-start sections per stack.
- CI workflow for syntax/format checks.
- Security header template for static hosting.

If this repository is **public**, all files/commits are publicly visible on GitHub. If it is **private**, only authorized users can view it.
