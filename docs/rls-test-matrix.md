
# Lab 5 - Row-Level Security Test Matrix

## Purpose
Verify that the properties table protects user data using Supabase Row-Level Security (RLS).

## Test Cases

| User Role | Test | Expected Result |
|---|---|---|
| Anonymous | Read published properties | Allowed |
| Anonymous | Read draft properties | Denied |
| Anonymous | Create a property | Denied |
| Authenticated owner | Read own draft | Allowed |
| Authenticated owner | Edit own draft | Allowed |
| Authenticated owner | Edit another user's property | Denied |
| Other authenticated user | Read someone else's draft | Denied |
| Other authenticated user | Delete someone else's property | Denied |
| Administrator | Manage properties with valid admin authorization | Allowed |
| Service role | Access database from trusted server code | Allowed |

## Security Issue Identified

The current properties_update_own policy permits owners to update published properties. It also permits owners to change a draft directly to published.

The Lab 5 requirements specify that owners should only edit their own unapproved records.

Recommended improvement:
Restrict owner updates to draft records and enforce the intended approval workflow.

## Verification Status

These are planned test cases. Results must be recorded after executing tests against the development database.

## AI Collaboration

AI tool: ChatGPT

Prompt: Review the properties table and RLS policies for ownership and authorization weaknesses.

Useful finding: The owner UPDATE policy does not restrict edits to unapproved records.

Verification needed: Execute owner, non-owner, anonymous, and administrator access tests.

## Individual Contribution

GitHub user: guillenemily4-debug

Responsibility: Security review, RLS test planning, and documentation.

Next steps: Execute tests, record actual results, and submit changes for peer review.

## RLS Test Results

Environment: Separate Supabase development project,
lab5-rls-test.

Testing method: SQL Editor with simulated database
roles and JWT claims.

| Test | Actual Result | Status |
|---|---|---|
| Anonymous SELECT privilege | Granted | PASS |
| Anonymous INSERT privilege | Not granted | PASS |
| Owner reads own draft | Visible | PASS |
| Owner reads published listing | Visible | PASS |
| Owner reads another user's draft | Hidden | PASS |
| Owner updates own draft | 1 row updated | PASS |
| Owner updates published listing | 0 rows updated | PASS |
| Owner updates another user's draft | 0 rows updated | PASS |
| Owner deletes own draft | 1 row affected | PASS |
| Owner deletes published listing | 0 rows affected | PASS |
| Owner deletes another user's draft | 0 rows affected | PASS |
| Owner inserts draft | Allowed | PASS |
| Owner inserts published listing | RLS error 42501 | PASS |

### Additional Verification Needed
- Anonymous access with published and draft test records.
- Other-user authenticated access tests.
- Administrator access tests.
- Service-role access tests.
- Real application/API authentication tests.

All UPDATE and DELETE test changes were rolled
back to preserve test data.

## Additional RLS Verification Results

Test environment: lab5-rls-test (Supabase)

| Security Test | Actual Result | Status |
|---|---|---|
| Other user reads own draft | Visible | PASS |
| Other user reads owner's private draft | Hidden | PASS |
| Other user reads published listing | Visible | PASS |
| Anonymous user reads published listing | Visible | PASS |
| Anonymous user reads private drafts | Hidden | PASS |
| Simulated administrator reads all properties | 3 rows visible | PASS |
| Simulated service role reads all properties | 3 rows visible | PASS |

## Testing Notes

- Tests were performed in a separate Supabase development project.
- Database roles and JWT claims were simulated using SQL Editor.
- Fictional property records were used.
- No production database was modified.
- Administrator and service-role visibility tests passed.
- Real application authentication and administrator claim protection still require verification.
- Additional write-permission and secret-hygiene checks remain pending.

## Individual Contribution

GitHub username: guillenemily4-debug

Completed database security testing, documented access-control results, and submitted RLS improvements for peer review.
