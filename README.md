# Azure Project 1 — Static Site Hosting (Storage Account + Front Door)

Mirrors AWS Project 1 (S3 + CloudFront). Static site hosted on an Azure Storage
Account, served globally via Azure Front Door Standard, deployed with Bicep.

**Live URL:** https://ademp1-afd-endpoint-hjcrgwd6bkaxahh5.z03.azurefd.net

## Note: Azure CDN (classic) is deprecated
As of Aug 2025, Azure CDN (classic) no longer allows new profile creation.
This project uses Azure Front Door Standard instead — the current Microsoft-
recommended replacement, with origin groups/routes instead of classic endpoints.

## Deploy
```bash
az group create --name project1-static-site-rg --location eastus
az deployment group create --resource-group project1-static-site-rg --template-file main.bicep --parameters storageAccountPrefix=yourprefix
az storage blob service-properties update --account-name <name> --static-website --index-document index.html --404-document index.html
az storage blob upload-batch --account-name <name> -d '$web' -s ./site
```

## Debugging notes
- Storage account names must be <=24 chars — `take()` used to guarantee this
- Front Door routes require `linkToDefaultDomain: 'Enabled'` explicitly
- First-deploy propagation took ~5-8 minutes before returning 200 (longer than CloudFront)
