#!/usr/bin/env bash
# RLS verification for public.properties (no Python needed; works in Git Bash).
# Run:  bash test_rls.sh | tee rls_evidence.txt

URL="https://<project-ref>.supabase.co"      # your Supabase Project URL
ANON="<anon-key>"                           # your Supabase anon (public) key
EMAIL_A="owner@test.com";  PW_A="<password-for-owner>"
EMAIL_B="other@test.com";  PW_B="<password-for-other>"

login() { # $1 email, $2 password -> raw login JSON
  curl -s "$URL/auth/v1/token?grant_type=password" -H "apikey: $ANON" \
    -H "Content-Type: application/json" -d "{\"email\":\"$1\",\"password\":\"$2\"}"
}

LOGIN_A=$(login "$EMAIL_A" "$PW_A")
LOGIN_B=$(login "$EMAIL_B" "$PW_B")
JWT_A=$(echo "$LOGIN_A" | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
JWT_B=$(echo "$LOGIN_B" | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
UID_A=$(echo "$LOGIN_A" | sed -n 's/.*"user":{"id":"\([^"]*\)".*/\1/p')

if [ -z "$JWT_A" ] || [ -z "$JWT_B" ]; then
  echo "LOGIN FAILED. Check emails/passwords and that both users have Auto Confirm on."
  echo "User A response: $LOGIN_A"
  echo "User B response: $LOGIN_B"
  exit 1
fi
echo "Logged in OK as both users. User A id: $UID_A"

S='\nHTTP STATUS: %{http_code}\n'   # prints the status code after each response body

echo; echo "=== SETUP: User A creates one published and one draft listing ==="
SEED=$(curl -s -X POST "$URL/rest/v1/properties" -H "apikey: $ANON" -H "Authorization: Bearer $JWT_A" \
  -H "Content-Type: application/json" -H "Prefer: return=representation" \
  -d '[{"address":"123 Maple St","price":425000,"bedrooms":3,"bathrooms":2,"sqft":1600,"property_type":"house","status":"published"},
       {"address":"45 Draft Ave","price":610000,"bedrooms":4,"bathrooms":3,"sqft":2100,"property_type":"house","status":"draft"}]')
echo "$SEED"
IDS=$(echo "$SEED" | grep -o '"id":"[^"]*"' | sed 's/"id":"\([^"]*\)"/\1/')
ROW_PUB=$(echo "$IDS" | sed -n 1p)
ROW_DRAFT=$(echo "$IDS" | sed -n 2p)
if [ -z "$ROW_PUB" ] || [ -z "$ROW_DRAFT" ]; then
  echo "SETUP FAILED: could not create listings. Did the SQL migration run successfully?"
  exit 1
fi
echo "Published row: $ROW_PUB"
echo "Draft row:     $ROW_DRAFT"

echo; echo "=== ANON: INSERT (expect HTTP 401, code 42501 permission denied) ==="
curl -s -w "$S" -X POST "$URL/rest/v1/properties" -H "apikey: $ANON" -H "Authorization: Bearer $ANON" \
  -H "Content-Type: application/json" \
  -d '{"address":"hacked","price":1,"bedrooms":1,"bathrooms":1,"sqft":1,"property_type":"house"}'

echo; echo "=== ANON: SELECT User A's DRAFT (expect HTTP 200 and []) ==="
curl -s -w "$S" "$URL/rest/v1/properties?id=eq.$ROW_DRAFT" -H "apikey: $ANON" -H "Authorization: Bearer $ANON"

echo; echo "=== ANON: SELECT all rows (expect HTTP 200, only the published row) ==="
curl -s -w "$S" "$URL/rest/v1/properties?select=id,address,status" -H "apikey: $ANON" -H "Authorization: Bearer $ANON"

echo; echo "=== USER B: UPDATE User A's published row (expect HTTP 200 and [] , nothing changed) ==="
curl -s -w "$S" -X PATCH "$URL/rest/v1/properties?id=eq.$ROW_PUB" -H "apikey: $ANON" -H "Authorization: Bearer $JWT_B" \
  -H "Content-Type: application/json" -H "Prefer: return=representation" -d '{"address":"owned by B now"}'

echo; echo "=== USER B: DELETE User A's published row (expect HTTP 200 and [] , row still exists) ==="
curl -s -w "$S" -X DELETE "$URL/rest/v1/properties?id=eq.$ROW_PUB" -H "apikey: $ANON" -H "Authorization: Bearer $JWT_B" \
  -H "Prefer: return=representation"

echo; echo "=== USER B: SELECT User A's DRAFT (expect HTTP 200 and []) ==="
curl -s -w "$S" "$URL/rest/v1/properties?id=eq.$ROW_DRAFT" -H "apikey: $ANON" -H "Authorization: Bearer $JWT_B"

echo; echo "=== USER B: INSERT spoofing owner_id = User A (expect HTTP 403, 42501 violates row-level security policy) ==="
curl -s -w "$S" -X POST "$URL/rest/v1/properties" -H "apikey: $ANON" -H "Authorization: Bearer $JWT_B" \
  -H "Content-Type: application/json" \
  -d "{\"owner_id\":\"$UID_A\",\"address\":\"spoof\",\"price\":1,\"bedrooms\":1,\"bathrooms\":1,\"sqft\":1,\"property_type\":\"house\"}"

echo; echo "=== OWNER A: UPDATE own row (expect HTTP 200 and the updated row) ==="
curl -s -w "$S" -X PATCH "$URL/rest/v1/properties?id=eq.$ROW_PUB" -H "apikey: $ANON" -H "Authorization: Bearer $JWT_A" \
  -H "Content-Type: application/json" -H "Prefer: return=representation" -d '{"price":430000}'

echo; echo "=== OWNER A: UPDATE owner_id (expect HTTP 403, 42501 permission denied, column privilege) ==="
curl -s -w "$S" -X PATCH "$URL/rest/v1/properties?id=eq.$ROW_PUB" -H "apikey: $ANON" -H "Authorization: Bearer $JWT_A" \
  -H "Content-Type: application/json" -d '{"owner_id":"00000000-0000-0000-0000-000000000000"}'

echo; echo "=== DONE ==="
