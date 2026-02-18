# MongoDB Schema for example_11_social_media

Converted from MySQL on 2026-02-17T23:16:48.776571

## Collections

### users

**Document Structure:**
```json
{
  "username": {
    "type": "String",
    "required": true
  },
  "email": {
    "type": "String",
    "required": true
  },
  "email_verified": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "password_hash": {
    "type": "String",
    "required": true
  },
  "phone_number": {
    "type": "String",
    "required": false
  },
  "phone_verified": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "status": {
    "type": "String",
    "required": false
  },
  "account_type": {
    "type": "String",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "last_active": {
    "type": "Date",
    "required": false
  },
  "deleted_at": {
    "type": "Date",
    "required": false
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### user_profiles

**Document Structure:**
```json
{
  "user_id": {
    "type": "Number",
    "required": true
  },
  "display_name": {
    "type": "String",
    "required": false
  },
  "bio": {
    "type": "String",
    "required": false
  },
  "profile_picture_url": {
    "type": "String",
    "required": false
  },
  "cover_picture_url": {
    "type": "String",
    "required": false
  },
  "website": {
    "type": "String",
    "required": false
  },
  "location": {
    "type": "String",
    "required": false
  },
  "birth_date": {
    "type": "Date",
    "required": false
  },
  "gender": {
    "type": "String",
    "required": false
  },
  "language": {
    "type": "String",
    "required": false,
    "default": "en"
  },
  "timezone": {
    "type": "String",
    "required": false,
    "default": "UTC"
  },
  "is_private": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "verified_badge": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "follower_count": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "following_count": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "post_count": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** users_id

### user_settings

**Document Structure:**
```json
{
  "user_id": {
    "type": "Number",
    "required": true
  },
  "notification_email": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
  },
  "notification_push": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
  },
  "notification_sms": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "privacy_profile_visibility": {
    "type": "String",
    "required": false
  },
  "privacy_message_requests": {
    "type": "String",
    "required": false
  },
  "privacy_show_activity_status": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
  },
  "privacy_show_read_receipts": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
  },
  "content_filter_sensitive": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "content_filter_violence": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
  },
  "content_language_preferences": {
    "type": "Object",
    "required": false
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** users_id

### relationships

**Document Structure:**
```json
{
  "from_user_id": {
    "type": "Number",
    "required": true
  },
  "to_user_id": {
    "type": "Number",
    "required": true
  },
  "relationship_type": {
    "type": "String",
    "required": false
  },
  "status": {
    "type": "String",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** users_id, users_id

### relationship_requests

**Document Structure:**
```json
{
  "from_user_id": {
    "type": "Number",
    "required": true
  },
  "to_user_id": {
    "type": "Number",
    "required": true
  },
  "request_type": {
    "type": "String",
    "required": false
  },
  "status": {
    "type": "String",
    "required": false
  },
  "message": {
    "type": "String",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "responded_at": {
    "type": "Date",
    "required": false
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** users_id, users_id

### posts

**Document Structure:**
```json
{
  "user_id": {
    "type": "Number",
    "required": true
  },
  "parent_post_id": {
    "type": "Number",
    "required": false
  },
  "content": {
    "type": "String",
    "required": false
  },
  "post_type": {
    "type": "String",
    "required": false
  },
  "visibility": {
    "type": "String",
    "required": false
  },
  "is_edited": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "edit_history": {
    "type": "Object",
    "required": false
  },
  "location": {
    "type": "String",
    "required": false
  },
  "latitude": {
    "type": "Decimal128",
    "required": false
  },
  "longitude": {
    "type": "Decimal128",
    "required": false
  },
  "view_count": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "share_count": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "comment_count": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "like_count": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "engagement_score": {
    "type": "Decimal128",
    "required": false
  },
  "is_promoted": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "is_archived": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "deleted_at": {
    "type": "Date",
    "required": false
  }
}
```

**Embedded Documents:** commentss

**References:** users_id, posts_id

### post_media

**Document Structure:**
```json
{
  "post_id": {
    "type": "Number",
    "required": true
  },
  "media_type": {
    "type": "String",
    "required": false
  },
  "media_url": {
    "type": "String",
    "required": true
  },
  "thumbnail_url": {
    "type": "String",
    "required": false
  },
  "media_metadata": {
    "type": "Object",
    "required": false
  },
  "display_order": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "alt_text": {
    "type": "String",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** posts_id

### comments

**Document Structure:**
```json
{
  "post_id": {
    "type": "Number",
    "required": true
  },
  "user_id": {
    "type": "Number",
    "required": true
  },
  "parent_comment_id": {
    "type": "Number",
    "required": false
  },
  "content": {
    "type": "String",
    "required": true
  },
  "like_count": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "is_edited": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "is_hidden": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "deleted_at": {
    "type": "Date",
    "required": false
  }
}
```

**References:** users_id, comments_id

### reactions

**Document Structure:**
```json
{
  "user_id": {
    "type": "Number",
    "required": true
  },
  "target_type": {
    "type": "String",
    "required": false
  },
  "target_id": {
    "type": "Number",
    "required": true
  },
  "reaction_type": {
    "type": "String",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** users_id

### shares

**Document Structure:**
```json
{
  "post_id": {
    "type": "Number",
    "required": true
  },
  "user_id": {
    "type": "Number",
    "required": true
  },
  "share_type": {
    "type": "String",
    "required": false
  },
  "share_text": {
    "type": "String",
    "required": false
  },
  "platform": {
    "type": "String",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** posts_id, users_id

### bookmarks

**Document Structure:**
```json
{
  "user_id": {
    "type": "Number",
    "required": true
  },
  "post_id": {
    "type": "Number",
    "required": true
  },
  "collection_name": {
    "type": "String",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** users_id, posts_id

### hashtags

**Document Structure:**
```json
{
  "tag": {
    "type": "String",
    "required": true
  },
  "tag_normalized": {
    "type": "String",
    "required": true
  },
  "post_count": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "weekly_count": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "daily_count": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "last_used": {
    "type": "Date",
    "required": false,
    "default": "CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### post_hashtags

**Document Structure:**
```json
{
  "post_id": {
    "type": "Number",
    "required": true
  },
  "hashtag_id": {
    "type": "Number",
    "required": true
  },
  "position": {
    "type": "Number",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** posts_id, hashtags_id

### trending_topics

**Document Structure:**
```json
{
  "trend_type": {
    "type": "String",
    "required": false
  },
  "trend_value": {
    "type": "String",
    "required": true
  },
  "region": {
    "type": "String",
    "required": false,
    "default": "global"
  },
  "score": {
    "type": "String",
    "required": false
  },
  "velocity": {
    "type": "Decimal128",
    "required": false
  },
  "post_count": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "user_count": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "start_time": {
    "type": "Date",
    "required": false,
    "default": "CURRENT_TIMESTAMP"
  },
  "peak_time": {
    "type": "Date",
    "required": false
  },
  "end_time": {
    "type": "Date",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### conversations

**Document Structure:**
```json
{
  "conversation_type": {
    "type": "String",
    "required": false
  },
  "title": {
    "type": "String",
    "required": false
  },
  "description": {
    "type": "String",
    "required": false
  },
  "creator_user_id": {
    "type": "Number",
    "required": false
  },
  "is_archived": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "last_message_at": {
    "type": "Date",
    "required": false
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** users_id

### conversation_participants

**Document Structure:**
```json
{
  "conversation_id": {
    "type": "Number",
    "required": true
  },
  "user_id": {
    "type": "Number",
    "required": true
  },
  "role": {
    "type": "String",
    "required": false
  },
  "joined_at": {
    "type": "Date",
    "required": false,
    "default": "CURRENT_TIMESTAMP"
  },
  "last_read_at": {
    "type": "Date",
    "required": false
  },
  "is_muted": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "left_at": {
    "type": "Date",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** conversations_id, users_id

### messages

**Document Structure:**
```json
{
  "conversation_id": {
    "type": "Number",
    "required": true
  },
  "sender_user_id": {
    "type": "Number",
    "required": true
  },
  "message_type": {
    "type": "String",
    "required": false
  },
  "content": {
    "type": "String",
    "required": false
  },
  "media_url": {
    "type": "String",
    "required": false
  },
  "is_edited": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "is_deleted": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "edited_at": {
    "type": "Date",
    "required": false
  },
  "deleted_at": {
    "type": "Date",
    "required": false
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** conversations_id, users_id

### notifications

**Document Structure:**
```json
{
  "user_id": {
    "type": "Number",
    "required": true
  },
  "type": {
    "type": "String",
    "required": false
  },
  "actor_user_id": {
    "type": "Number",
    "required": false
  },
  "target_type": {
    "type": "String",
    "required": false
  },
  "target_id": {
    "type": "Number",
    "required": false
  },
  "title": {
    "type": "String",
    "required": false
  },
  "body": {
    "type": "String",
    "required": false
  },
  "data": {
    "type": "Object",
    "required": false
  },
  "is_read": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "is_pushed": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "read_at": {
    "type": "Date",
    "required": false
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** users_id, users_id

### reports

**Document Structure:**
```json
{
  "reporter_user_id": {
    "type": "Number",
    "required": true
  },
  "reported_type": {
    "type": "String",
    "required": false
  },
  "reported_id": {
    "type": "Number",
    "required": true
  },
  "reason": {
    "type": "String",
    "required": false
  },
  "description": {
    "type": "String",
    "required": false
  },
  "status": {
    "type": "String",
    "required": false
  },
  "priority": {
    "type": "String",
    "required": false
  },
  "moderator_id": {
    "type": "Number",
    "required": false
  },
  "action_taken": {
    "type": "String",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "reviewed_at": {
    "type": "Date",
    "required": false
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** users_id

### banned_content

**Document Structure:**
```json
{
  "content_value": {
    "type": "String",
    "required": true
  },
  "severity": {
    "type": "String",
    "required": false
  },
  "reason": {
    "type": "String",
    "required": false
  },
  "added_by": {
    "type": "Number",
    "required": false
  },
  "is_active": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "expires_at": {
    "type": "Date",
    "required": false
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### user_activity_logs

**Document Structure:**
```json
{
  "user_id": {
    "type": "Number",
    "required": true
  },
  "action_type": {
    "type": "String",
    "required": false
  },
  "target_type": {
    "type": "String",
    "required": false
  },
  "target_id": {
    "type": "Number",
    "required": false
  },
  "session_id": {
    "type": "String",
    "required": false
  },
  "ip_address": {
    "type": "String",
    "required": false
  },
  "user_agent": {
    "type": "String",
    "required": false
  },
  "referrer": {
    "type": "String",
    "required": false
  },
  "duration_ms": {
    "type": "Number",
    "required": false
  },
  "metadata": {
    "type": "Object",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### engagement_metrics

**Document Structure:**
```json
{
  "metric_date": {
    "type": "String",
    "required": false
  },
  "metric_hour": {
    "type": "Number",
    "required": false
  },
  "metric_type": {
    "type": "String",
    "required": false
  },
  "entity_id": {
    "type": "Number",
    "required": true
  },
  "impressions": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "engagements": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "clicks": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "shares": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "comments": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "likes": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "reach": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "engagement_rate": {
    "type": "Decimal128",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### viral_content_tracking

**Document Structure:**
```json
{
  "post_id": {
    "type": "Number",
    "required": true
  },
  "check_time": {
    "type": "String",
    "required": false
  },
  "view_velocity": {
    "type": "Decimal128",
    "required": false
  },
  "share_velocity": {
    "type": "Decimal128",
    "required": false
  },
  "engagement_velocity": {
    "type": "Decimal128",
    "required": false
  },
  "total_reach": {
    "type": "Number",
    "required": false
  },
  "cascade_depth": {
    "type": "Number",
    "required": false
  },
  "is_trending": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "trend_score": {
    "type": "String",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** posts_id

### user_lists

**Document Structure:**
```json
{
  "user_id": {
    "type": "Number",
    "required": true
  },
  "name": {
    "type": "String",
    "required": true
  },
  "description": {
    "type": "String",
    "required": false
  },
  "is_public": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "member_count": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** users_id

### list_members

**Document Structure:**
```json
{
  "list_id": {
    "type": "Number",
    "required": true
  },
  "user_id": {
    "type": "Number",
    "required": true
  },
  "added_at": {
    "type": "Date",
    "required": false,
    "default": "CURRENT_TIMESTAMP"
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** user_lists_id, users_id

