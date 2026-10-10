# ClickUp API Limitation: Comment Reactions

## Issue Reference
- GitHub Issue: [#100](https://github.com/iamgerwin/dotfiles/issues/100)
- Date Documented: 2025-12-16

## Summary

The ClickUp API v2 does not provide documented endpoints for adding or managing emoji reactions on comments. This is a feature that exists in the ClickUp web and mobile UI but is not exposed through the public API.

## Requested Feature

Add the ability to:
1. Add emoji reactions to comments (e.g., `:white_check_mark:`, `:+1:`, `:eyes:`)
2. Remove emoji reactions from comments
3. List reactions on a comment

## API Investigation

### Endpoints Checked
- `GET /task/{task_id}/comment` - Returns comments but no reaction data in response
- `PUT /comment/{comment_id}` - Supports `resolved` and `assignee` but not `reactions`
- No documented `/comment/{comment_id}/reaction` endpoint exists

### Official Documentation References
- [Update Comment API](https://developer.clickup.com/reference/updatecomment)
- [Get Task Comments API](https://developer.clickup.com/reference/gettaskcomments)
- [ClickUp Comments Overview](https://developer.clickup.com/docs/comments)

### What IS Supported
The following comment management features ARE available via the API:
- `resolve-comment` - Mark a comment as resolved
- `unresolve-comment` - Mark a comment as unresolved
- `assign-comment` - Assign a comment to a user
- `unassign-comment` - Remove assignment from a comment

## Workarounds

### Option 1: Use Text-Based Reactions
Instead of emoji reactions, add a reply comment with the reaction:
```bash
./clickup-api.sh add-comment TASK_ID "Acknowledged"
```

### Option 2: Use Resolve Status
For acknowledgment purposes, use the resolve feature:
```bash
./clickup-api.sh resolve-comment COMMENT_ID
```

### Option 3: Use Comment Assignment
Assign the comment to indicate someone is handling it:
```bash
./clickup-api.sh assign-comment COMMENT_ID USER_ID
```

## Potential Future Solutions

1. **ClickUp Feature Request**: Submit a feature request to ClickUp for API support for comment reactions
   - [ClickUp Feature Requests Portal](https://clickup.canny.io/)

2. **Undocumented Endpoints**: There may be undocumented API endpoints that support reactions (common in evolving APIs)
   - Risk: Undocumented endpoints may change without notice

3. **Webhooks**: Monitor for reaction events via webhooks (if available) for read-only access

## Impact

| Use Case | Workaround Available |
|----------|---------------------|
| Quick acknowledgment | Use `resolve-comment` |
| Assign for follow-up | Use `assign-comment` |
| Express agreement/disagreement | Add text comment reply |
| Track reaction counts | Not available |

## Status

**LIMITATION CONFIRMED** - As of December 2025, the ClickUp API v2 does not support comment reactions.

## Related Commands Implemented

Despite the reaction limitation, the following comment management commands were implemented:

```bash
# Mark comment as resolved
./clickup-api.sh resolve-comment COMMENT_ID

# Mark comment as unresolved
./clickup-api.sh unresolve-comment COMMENT_ID

# Assign comment to user
./clickup-api.sh assign-comment COMMENT_ID USER_ID

# Unassign comment
./clickup-api.sh unassign-comment COMMENT_ID
```

## Changelog

- **2025-12-16**: Initial documentation created
- **2025-12-16**: Implemented resolve, unresolve, assign, and unassign comment commands as partial solution
