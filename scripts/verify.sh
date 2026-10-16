#!/usr/bin/env bash
# Verification gate run by the deploy pipeline.
set -euo pipefail

pass() { echo "  PASS  $1"; }

echo "==> Verifying shortlink deployment"

curl -sf http://localhost:4566/_localstack/health > /dev/null
pass "LocalStack is responding"

bucket="$(terraform -chdir=terraform output -raw bucket_name)"
[ -n "$bucket" ]
pass "Terraform state has a bucket ($bucket)"

kubectl get deployment shortlink -n shortlink > /dev/null
pass "Deployment exists"

pods="$(kubectl get pods -n shortlink --no-headers | wc -l | tr -d ' ')"
[ "$pods" -ge 1 ]
pass "Pods scheduled ($pods)"

kubectl get service shortlink -n shortlink -o jsonpath='{.spec.clusterIP}' | grep -q .
pass "Service has a ClusterIP"

echo ""
echo "ALL CHECKS PASSED"
