# Cafeteria-as-a-Service

This repository is split into three parts:

- `backend/`: Node.js + Express API for AI suggestions and Stripe Checkout.
- `frontend/`: Flutter app with AI budget chat and checkout trigger.
- `infra/`: Terraform for provisioning Cloud Run.

## Will this be visible on GitHub?

Yes. Everything committed to this repository branch is visible on GitHub to anyone who has access to the repo.

- In a **public** repository: all committed files are publicly visible.
- In a **private** repository: only collaborators/authorized users can see commits and files.
- **Secrets are never safe in Git.** Do not commit API keys or tokens; store them in GitHub Actions secrets, GCP Secret Manager, or Terraform Cloud/workspace variables.

## Backend (Cloud Run)

```bash
cd backend
npm install
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
