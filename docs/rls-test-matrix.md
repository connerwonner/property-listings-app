
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
