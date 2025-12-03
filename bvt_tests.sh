#!/bin/bash

# GadgetCloud Forms API Test Script
# Based on Bruno collection

set -e

# Configuration
BASE_URL="${BASE_URL:-https://forms.gadgetcloud.io}"
CLIENT="${CLIENT:-gadgetcloud}"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0

# Test function
test_endpoint() {
  local name="$1"
  local expected_status="$2"
  local actual_status="$3"
  local response="$4"

  if [ "$actual_status" -eq "$expected_status" ]; then
    echo -e "${GREEN}✓ PASS${NC}: $name (HTTP $actual_status)"
    PASSED=$((PASSED + 1))
  else
    echo -e "${RED}✗ FAIL${NC}: $name (Expected: $expected_status, Got: $actual_status)"
    echo "  Response: $response"
    FAILED=$((FAILED + 1))
  fi
}

echo "========================================"
echo "GadgetCloud Forms API Tests"
echo "========================================"
echo "Base URL: $BASE_URL"
echo "Client: $CLIENT"
echo "========================================"
echo ""

# ----------------------------------------
# Health Check
# ----------------------------------------
echo -e "${YELLOW}[1/10] Health Check${NC}"
RESPONSE=$(curl -s -w "\n%{http_code}" "$BASE_URL/forms/health")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')
test_endpoint "GET /forms/health" 200 "$HTTP_CODE" "$BODY"
echo ""

# ----------------------------------------
# API Info
# ----------------------------------------
echo -e "${YELLOW}[2/10] API Info${NC}"
RESPONSE=$(curl -s -w "\n%{http_code}" "$BASE_URL/forms/info")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')
test_endpoint "GET /forms/info" 200 "$HTTP_CODE" "$BODY"
echo ""

# ----------------------------------------
# Submit Form - Contact Form
# ----------------------------------------
echo -e "${YELLOW}[3/10] Submit Contact Form${NC}"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/forms" \
  -H "Content-Type: application/json" \
  -d '{
    "client": "'"$CLIENT"'",
    "formType": "contacts",
    "tags": "BVT,tests",
    "formData": {
      "firstName": "John",
      "lastName": "Doe",
      "email": "john.doe@example.com",
      "message": "This is a test message from the test script"
    }
  }')
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')
test_endpoint "POST /forms (contacts)" 201 "$HTTP_CODE" "$BODY"
echo ""

# ----------------------------------------
# Submit Form - Feedback Form
# ----------------------------------------
echo -e "${YELLOW}[4/10] Submit Feedback Form${NC}"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/forms" \
  -H "Content-Type: application/json" \
  -d '{
    "client": "'"$CLIENT"'",
    "formType": "feedback",
    "tags": "BVT,tests",
    "formData": {
      "email": "feedback@example.com",
      "comments": "This is test feedback submitted via test script"
    }
  }')
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')
test_endpoint "POST /forms (feedback)" 201 "$HTTP_CODE" "$BODY"
echo ""

# ----------------------------------------
# Submit Form - Service Request
# ----------------------------------------
echo -e "${YELLOW}[5/10] Submit Service Request${NC}"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/forms" \
  -H "Content-Type: application/json" \
  -d '{
    "client": "'"$CLIENT"'",
    "formType": "serviceRequests",
    "tags": "BVT,tests",
    "formData": {
      "firstName": "Jane",
      "lastName": "Smith",
      "email": "jane.smith@example.com",
      "serviceType": "Repair",
      "mobile": "+919876543210",
      "description": "This is a test service request submitted via test script for testing purposes"
    }
  }')
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')
test_endpoint "POST /forms (serviceRequests)" 201 "$HTTP_CODE" "$BODY"
echo ""

# ----------------------------------------
# Submit Form - Survey Form
# ----------------------------------------
echo -e "${YELLOW}[6/10] Submit Survey Form${NC}"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/forms" \
  -H "Content-Type: application/json" \
  -d '{
    "client": "'"$CLIENT"'",
    "formType": "survey",
    "tags": "BVT,tests",
    "formData": {
      "email": "survey@example.com",
      "responses": {
        "question1": "Very Satisfied",
        "question2": "Yes",
        "question3": "5"
      }
    }
  }')
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')
test_endpoint "POST /forms (survey)" 201 "$HTTP_CODE" "$BODY"
echo ""

# ----------------------------------------
# Validation Test - Invalid Client
# ----------------------------------------
echo -e "${YELLOW}[7/10] Validation: Invalid Client${NC}"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/forms" \
  -H "Content-Type: application/json" \
  -d '{
    "client": "invalidclient",
    "formType": "contacts",
    "tags": "BVT,tests",
    "formData": {
      "firstName": "Test",
      "lastName": "User",
      "email": "test@example.com",
      "message": "This should fail validation"
    }
  }')
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')
test_endpoint "POST /forms (invalid client)" 400 "$HTTP_CODE" "$BODY"
echo ""

# ----------------------------------------
# Validation Test - Missing Required Fields
# ----------------------------------------
echo -e "${YELLOW}[8/10] Validation: Missing Required Fields${NC}"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/forms" \
  -H "Content-Type: application/json" \
  -d '{
    "client": "'"$CLIENT"'",
    "formType": "contacts",
    "tags": "BVT,tests",
    "formData": {
      "firstName": "Test"
    }
  }')
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')
test_endpoint "POST /forms (missing fields)" 400 "$HTTP_CODE" "$BODY"
echo ""

# ----------------------------------------
# Validation Test - Invalid Email
# ----------------------------------------
echo -e "${YELLOW}[9/10] Validation: Invalid Email${NC}"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/forms" \
  -H "Content-Type: application/json" \
  -d '{
    "client": "'"$CLIENT"'",
    "formType": "contacts",
    "tags": "BVT,tests",
    "formData": {
      "firstName": "Test",
      "lastName": "User",
      "email": "invalid-email",
      "message": "This should fail email validation"
    }
  }')
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')
test_endpoint "POST /forms (invalid email)" 400 "$HTTP_CODE" "$BODY"
echo ""

# ----------------------------------------
# Validation Test - Invalid Form Type
# ----------------------------------------
echo -e "${YELLOW}[10/10] Validation: Invalid Form Type${NC}"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/forms" \
  -H "Content-Type: application/json" \
  -d '{
    "client": "'"$CLIENT"'",
    "formType": "invalidtype",
    "tags": "BVT,tests",
    "formData": {
      "email": "test@example.com"
    }
  }')
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')
test_endpoint "POST /forms (invalid form type)" 400 "$HTTP_CODE" "$BODY"
echo ""

# ----------------------------------------
# Summary
# ----------------------------------------
echo "========================================"
echo "Test Summary"
echo "========================================"
echo -e "Passed: ${GREEN}$PASSED${NC}"
echo -e "Failed: ${RED}$FAILED${NC}"
echo "Total:  $((PASSED + FAILED))"
echo "========================================"

if [ "$FAILED" -gt 0 ]; then
  exit 1
fi
