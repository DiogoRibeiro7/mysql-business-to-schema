// MongoDB Migration Script
// Generated: 2026-02-17T23:16:48.774091
// From MySQL to MongoDB

use converted_db;

// Create collection: users
db.createCollection('users');

// Create collection: user_profiles
db.createCollection('user_profiles');

// Create collection: user_settings
db.createCollection('user_settings');

// Create collection: relationships
db.createCollection('relationships');

// Create collection: relationship_requests
db.createCollection('relationship_requests');

// Create collection: posts
db.createCollection('posts');

// Create collection: post_media
db.createCollection('post_media');

// Create collection: comments
db.createCollection('comments');

// Create collection: reactions
db.createCollection('reactions');

// Create collection: shares
db.createCollection('shares');

// Create collection: bookmarks
db.createCollection('bookmarks');

// Create collection: hashtags
db.createCollection('hashtags');

// Create collection: post_hashtags
db.createCollection('post_hashtags');

// Create collection: trending_topics
db.createCollection('trending_topics');

// Create collection: conversations
db.createCollection('conversations');

// Create collection: conversation_participants
db.createCollection('conversation_participants');

// Create collection: messages
db.createCollection('messages');

// Create collection: notifications
db.createCollection('notifications');

// Create collection: reports
db.createCollection('reports');

// Create collection: banned_content
db.createCollection('banned_content');

// Create collection: user_activity_logs
db.createCollection('user_activity_logs');

// Create collection: engagement_metrics
db.createCollection('engagement_metrics');

// Create collection: viral_content_tracking
db.createCollection('viral_content_tracking');

// Create collection: user_lists
db.createCollection('user_lists');

// Create collection: list_members
db.createCollection('list_members');

// Indexes for users

// Indexes for user_profiles
db.user_profiles.createIndex({"user_id": 1}, {"name": "user_profiles_user_id_idx"});
db.user_profiles.createIndex({"bio": "text"}, {"name": "user_profiles_text"});

// Indexes for user_settings
db.user_settings.createIndex({"user_id": 1}, {"name": "user_settings_user_id_idx"});

// Indexes for relationships
db.relationships.createIndex({"from_user_id": 1}, {"name": "relationships_from_user_id_idx"});
db.relationships.createIndex({"to_user_id": 1}, {"name": "relationships_to_user_id_idx"});

// Indexes for relationship_requests
db.relationship_requests.createIndex({"from_user_id": 1}, {"name": "relationship_requests_from_user_id_idx"});
db.relationship_requests.createIndex({"to_user_id": 1}, {"name": "relationship_requests_to_user_id_idx"});
db.relationship_requests.createIndex({"message": "text"}, {"name": "relationship_requests_text"});

// Indexes for posts
db.posts.createIndex({"user_id": 1}, {"name": "posts_user_id_idx"});
db.posts.createIndex({"parent_post_id": 1}, {"name": "posts_parent_post_id_idx"});
db.posts.createIndex({"content": "text"}, {"name": "posts_text"});

// Indexes for post_media
db.post_media.createIndex({"post_id": 1}, {"name": "post_media_post_id_idx"});
db.post_media.createIndex({"alt_text": "text"}, {"name": "post_media_text"});

// Indexes for comments
db.comments.createIndex({"post_id": 1}, {"name": "comments_post_id_idx"});
db.comments.createIndex({"user_id": 1}, {"name": "comments_user_id_idx"});
db.comments.createIndex({"parent_comment_id": 1}, {"name": "comments_parent_comment_id_idx"});
db.comments.createIndex({"content": "text"}, {"name": "comments_text"});

// Indexes for reactions
db.reactions.createIndex({"user_id": 1}, {"name": "reactions_user_id_idx"});

// Indexes for shares
db.shares.createIndex({"post_id": 1}, {"name": "shares_post_id_idx"});
db.shares.createIndex({"user_id": 1}, {"name": "shares_user_id_idx"});
db.shares.createIndex({"share_text": "text"}, {"name": "shares_text"});

// Indexes for bookmarks
db.bookmarks.createIndex({"user_id": 1}, {"name": "bookmarks_user_id_idx"});
db.bookmarks.createIndex({"post_id": 1}, {"name": "bookmarks_post_id_idx"});

// Indexes for hashtags

// Indexes for post_hashtags
db.post_hashtags.createIndex({"post_id": 1}, {"name": "post_hashtags_post_id_idx"});
db.post_hashtags.createIndex({"hashtag_id": 1}, {"name": "post_hashtags_hashtag_id_idx"});

// Indexes for conversations
db.conversations.createIndex({"creator_user_id": 1}, {"name": "conversations_creator_user_id_idx"});
db.conversations.createIndex({"description": "text"}, {"name": "conversations_text"});

// Indexes for conversation_participants
db.conversation_participants.createIndex({"conversation_id": 1}, {"name": "conversation_participants_conversation_id_idx"});
db.conversation_participants.createIndex({"user_id": 1}, {"name": "conversation_participants_user_id_idx"});

// Indexes for messages
db.messages.createIndex({"conversation_id": 1}, {"name": "messages_conversation_id_idx"});
db.messages.createIndex({"sender_user_id": 1}, {"name": "messages_sender_user_id_idx"});
db.messages.createIndex({"content": "text"}, {"name": "messages_text"});

// Indexes for notifications
db.notifications.createIndex({"user_id": 1}, {"name": "notifications_user_id_idx"});
db.notifications.createIndex({"actor_user_id": 1}, {"name": "notifications_actor_user_id_idx"});
db.notifications.createIndex({"body": "text"}, {"name": "notifications_text"});

// Indexes for reports
db.reports.createIndex({"reporter_user_id": 1}, {"name": "reports_reporter_user_id_idx"});
db.reports.createIndex({"description": "text"}, {"name": "reports_text"});

// Indexes for banned_content
db.banned_content.createIndex({"reason": "text"}, {"name": "banned_content_text"});

// Indexes for engagement_metrics

// Indexes for viral_content_tracking
db.viral_content_tracking.createIndex({"post_id": 1}, {"name": "viral_content_tracking_post_id_idx"});

// Indexes for user_lists
db.user_lists.createIndex({"user_id": 1}, {"name": "user_lists_user_id_idx"});
db.user_lists.createIndex({"description": "text"}, {"name": "user_lists_text"});

// Indexes for list_members
db.list_members.createIndex({"list_id": 1}, {"name": "list_members_list_id_idx"});
db.list_members.createIndex({"user_id": 1}, {"name": "list_members_user_id_idx"});

// Validation for users
db.runCommand({
  collMod: 'users',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "username",
      "email",
      "password_hash"
    ],
    "properties": {
      "username": {
        "bsonType": "string"
      },
      "email": {
        "bsonType": "string"
      },
      "email_verified": {
        "bsonType": "boolean"
      },
      "password_hash": {
        "bsonType": "string"
      },
      "phone_number": {
        "bsonType": "string"
      },
      "phone_verified": {
        "bsonType": "boolean"
      },
      "status": {
        "bsonType": "string"
      },
      "account_type": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      },
      "last_active": {
        "bsonType": "date"
      },
      "deleted_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for user_profiles
db.runCommand({
  collMod: 'user_profiles',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "user_id"
    ],
    "properties": {
      "user_id": {
        "bsonType": "number"
      },
      "display_name": {
        "bsonType": "string"
      },
      "bio": {
        "bsonType": "string"
      },
      "profile_picture_url": {
        "bsonType": "string"
      },
      "cover_picture_url": {
        "bsonType": "string"
      },
      "website": {
        "bsonType": "string"
      },
      "location": {
        "bsonType": "string"
      },
      "birth_date": {
        "bsonType": "date"
      },
      "gender": {
        "bsonType": "string"
      },
      "language": {
        "bsonType": "string"
      },
      "timezone": {
        "bsonType": "string"
      },
      "is_private": {
        "bsonType": "boolean"
      },
      "verified_badge": {
        "bsonType": "boolean"
      },
      "follower_count": {
        "bsonType": "number"
      },
      "following_count": {
        "bsonType": "number"
      },
      "post_count": {
        "bsonType": "number"
      },
      "updated_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for user_settings
db.runCommand({
  collMod: 'user_settings',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "user_id"
    ],
    "properties": {
      "user_id": {
        "bsonType": "number"
      },
      "notification_email": {
        "bsonType": "boolean"
      },
      "notification_push": {
        "bsonType": "boolean"
      },
      "notification_sms": {
        "bsonType": "boolean"
      },
      "privacy_profile_visibility": {
        "bsonType": "string"
      },
      "privacy_message_requests": {
        "bsonType": "string"
      },
      "privacy_show_activity_status": {
        "bsonType": "boolean"
      },
      "privacy_show_read_receipts": {
        "bsonType": "boolean"
      },
      "content_filter_sensitive": {
        "bsonType": "boolean"
      },
      "content_filter_violence": {
        "bsonType": "boolean"
      },
      "content_language_preferences": {
        "bsonType": "object"
      },
      "updated_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for relationships
db.runCommand({
  collMod: 'relationships',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "from_user_id",
      "to_user_id"
    ],
    "properties": {
      "from_user_id": {
        "bsonType": "number"
      },
      "to_user_id": {
        "bsonType": "number"
      },
      "relationship_type": {
        "bsonType": "string"
      },
      "status": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      },
      "updated_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for relationship_requests
db.runCommand({
  collMod: 'relationship_requests',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "from_user_id",
      "to_user_id"
    ],
    "properties": {
      "from_user_id": {
        "bsonType": "number"
      },
      "to_user_id": {
        "bsonType": "number"
      },
      "request_type": {
        "bsonType": "string"
      },
      "status": {
        "bsonType": "string"
      },
      "message": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      },
      "responded_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for posts
db.runCommand({
  collMod: 'posts',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "user_id"
    ],
    "properties": {
      "user_id": {
        "bsonType": "number"
      },
      "parent_post_id": {
        "bsonType": "number"
      },
      "content": {
        "bsonType": "string"
      },
      "post_type": {
        "bsonType": "string"
      },
      "visibility": {
        "bsonType": "string"
      },
      "is_edited": {
        "bsonType": "boolean"
      },
      "edit_history": {
        "bsonType": "object"
      },
      "location": {
        "bsonType": "string"
      },
      "latitude": {
        "bsonType": "decimal128"
      },
      "longitude": {
        "bsonType": "decimal128"
      },
      "view_count": {
        "bsonType": "number"
      },
      "share_count": {
        "bsonType": "number"
      },
      "comment_count": {
        "bsonType": "number"
      },
      "like_count": {
        "bsonType": "number"
      },
      "engagement_score": {
        "bsonType": "decimal128"
      },
      "is_promoted": {
        "bsonType": "boolean"
      },
      "is_archived": {
        "bsonType": "boolean"
      },
      "created_at": {
        "bsonType": "string"
      },
      "updated_at": {
        "bsonType": "date"
      },
      "deleted_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for post_media
db.runCommand({
  collMod: 'post_media',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "post_id",
      "media_url"
    ],
    "properties": {
      "post_id": {
        "bsonType": "number"
      },
      "media_type": {
        "bsonType": "string"
      },
      "media_url": {
        "bsonType": "string"
      },
      "thumbnail_url": {
        "bsonType": "string"
      },
      "media_metadata": {
        "bsonType": "object"
      },
      "display_order": {
        "bsonType": "number"
      },
      "alt_text": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for comments
db.runCommand({
  collMod: 'comments',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "post_id",
      "user_id",
      "content"
    ],
    "properties": {
      "post_id": {
        "bsonType": "number"
      },
      "user_id": {
        "bsonType": "number"
      },
      "parent_comment_id": {
        "bsonType": "number"
      },
      "content": {
        "bsonType": "string"
      },
      "like_count": {
        "bsonType": "number"
      },
      "is_edited": {
        "bsonType": "boolean"
      },
      "is_hidden": {
        "bsonType": "boolean"
      },
      "created_at": {
        "bsonType": "string"
      },
      "updated_at": {
        "bsonType": "date"
      },
      "deleted_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for reactions
db.runCommand({
  collMod: 'reactions',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "user_id",
      "target_id"
    ],
    "properties": {
      "user_id": {
        "bsonType": "number"
      },
      "target_type": {
        "bsonType": "string"
      },
      "target_id": {
        "bsonType": "number"
      },
      "reaction_type": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for shares
db.runCommand({
  collMod: 'shares',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "post_id",
      "user_id"
    ],
    "properties": {
      "post_id": {
        "bsonType": "number"
      },
      "user_id": {
        "bsonType": "number"
      },
      "share_type": {
        "bsonType": "string"
      },
      "share_text": {
        "bsonType": "string"
      },
      "platform": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "string"
      }
    }
  }
}
});

// Validation for bookmarks
db.runCommand({
  collMod: 'bookmarks',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "user_id",
      "post_id"
    ],
    "properties": {
      "user_id": {
        "bsonType": "number"
      },
      "post_id": {
        "bsonType": "number"
      },
      "collection_name": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for hashtags
db.runCommand({
  collMod: 'hashtags',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "tag",
      "tag_normalized"
    ],
    "properties": {
      "tag": {
        "bsonType": "string"
      },
      "tag_normalized": {
        "bsonType": "string"
      },
      "post_count": {
        "bsonType": "number"
      },
      "weekly_count": {
        "bsonType": "number"
      },
      "daily_count": {
        "bsonType": "number"
      },
      "created_at": {
        "bsonType": "date"
      },
      "last_used": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for post_hashtags
db.runCommand({
  collMod: 'post_hashtags',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "post_id",
      "hashtag_id"
    ],
    "properties": {
      "post_id": {
        "bsonType": "number"
      },
      "hashtag_id": {
        "bsonType": "number"
      },
      "position": {
        "bsonType": "number"
      },
      "created_at": {
        "bsonType": "string"
      }
    }
  }
}
});

// Validation for trending_topics
db.runCommand({
  collMod: 'trending_topics',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "trend_value"
    ],
    "properties": {
      "trend_type": {
        "bsonType": "string"
      },
      "trend_value": {
        "bsonType": "string"
      },
      "region": {
        "bsonType": "string"
      },
      "score": {
        "bsonType": "string"
      },
      "velocity": {
        "bsonType": "decimal128"
      },
      "post_count": {
        "bsonType": "number"
      },
      "user_count": {
        "bsonType": "number"
      },
      "start_time": {
        "bsonType": "date"
      },
      "peak_time": {
        "bsonType": "date"
      },
      "end_time": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for conversations
db.runCommand({
  collMod: 'conversations',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [],
    "properties": {
      "conversation_type": {
        "bsonType": "string"
      },
      "title": {
        "bsonType": "string"
      },
      "description": {
        "bsonType": "string"
      },
      "creator_user_id": {
        "bsonType": "number"
      },
      "is_archived": {
        "bsonType": "boolean"
      },
      "created_at": {
        "bsonType": "date"
      },
      "last_message_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for conversation_participants
db.runCommand({
  collMod: 'conversation_participants',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "conversation_id",
      "user_id"
    ],
    "properties": {
      "conversation_id": {
        "bsonType": "number"
      },
      "user_id": {
        "bsonType": "number"
      },
      "role": {
        "bsonType": "string"
      },
      "joined_at": {
        "bsonType": "date"
      },
      "last_read_at": {
        "bsonType": "date"
      },
      "is_muted": {
        "bsonType": "boolean"
      },
      "left_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for messages
db.runCommand({
  collMod: 'messages',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "conversation_id",
      "sender_user_id"
    ],
    "properties": {
      "conversation_id": {
        "bsonType": "number"
      },
      "sender_user_id": {
        "bsonType": "number"
      },
      "message_type": {
        "bsonType": "string"
      },
      "content": {
        "bsonType": "string"
      },
      "media_url": {
        "bsonType": "string"
      },
      "is_edited": {
        "bsonType": "boolean"
      },
      "is_deleted": {
        "bsonType": "boolean"
      },
      "created_at": {
        "bsonType": "string"
      },
      "edited_at": {
        "bsonType": "date"
      },
      "deleted_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for notifications
db.runCommand({
  collMod: 'notifications',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "user_id"
    ],
    "properties": {
      "user_id": {
        "bsonType": "number"
      },
      "type": {
        "bsonType": "string"
      },
      "actor_user_id": {
        "bsonType": "number"
      },
      "target_type": {
        "bsonType": "string"
      },
      "target_id": {
        "bsonType": "number"
      },
      "title": {
        "bsonType": "string"
      },
      "body": {
        "bsonType": "string"
      },
      "data": {
        "bsonType": "object"
      },
      "is_read": {
        "bsonType": "boolean"
      },
      "is_pushed": {
        "bsonType": "boolean"
      },
      "created_at": {
        "bsonType": "string"
      },
      "read_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for reports
db.runCommand({
  collMod: 'reports',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "reporter_user_id",
      "reported_id"
    ],
    "properties": {
      "reporter_user_id": {
        "bsonType": "number"
      },
      "reported_type": {
        "bsonType": "string"
      },
      "reported_id": {
        "bsonType": "number"
      },
      "reason": {
        "bsonType": "string"
      },
      "description": {
        "bsonType": "string"
      },
      "status": {
        "bsonType": "string"
      },
      "priority": {
        "bsonType": "string"
      },
      "moderator_id": {
        "bsonType": "number"
      },
      "action_taken": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      },
      "reviewed_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for banned_content
db.runCommand({
  collMod: 'banned_content',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "content_value"
    ],
    "properties": {
      "content_value": {
        "bsonType": "string"
      },
      "severity": {
        "bsonType": "string"
      },
      "reason": {
        "bsonType": "string"
      },
      "added_by": {
        "bsonType": "number"
      },
      "is_active": {
        "bsonType": "boolean"
      },
      "created_at": {
        "bsonType": "date"
      },
      "expires_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for user_activity_logs
db.runCommand({
  collMod: 'user_activity_logs',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "user_id"
    ],
    "properties": {
      "user_id": {
        "bsonType": "number"
      },
      "action_type": {
        "bsonType": "string"
      },
      "target_type": {
        "bsonType": "string"
      },
      "target_id": {
        "bsonType": "number"
      },
      "session_id": {
        "bsonType": "string"
      },
      "ip_address": {
        "bsonType": "string"
      },
      "user_agent": {
        "bsonType": "string"
      },
      "referrer": {
        "bsonType": "string"
      },
      "duration_ms": {
        "bsonType": "number"
      },
      "metadata": {
        "bsonType": "object"
      },
      "created_at": {
        "bsonType": "string"
      }
    }
  }
}
});

// Validation for engagement_metrics
db.runCommand({
  collMod: 'engagement_metrics',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "metric_date",
      "entity_id"
    ],
    "properties": {
      "metric_date": {
        "bsonType": "string"
      },
      "metric_hour": {
        "bsonType": "number"
      },
      "metric_type": {
        "bsonType": "string"
      },
      "entity_id": {
        "bsonType": "number"
      },
      "impressions": {
        "bsonType": "number"
      },
      "engagements": {
        "bsonType": "number"
      },
      "clicks": {
        "bsonType": "number"
      },
      "shares": {
        "bsonType": "number"
      },
      "comments": {
        "bsonType": "number"
      },
      "likes": {
        "bsonType": "number"
      },
      "reach": {
        "bsonType": "number"
      },
      "engagement_rate": {
        "bsonType": "decimal128"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for viral_content_tracking
db.runCommand({
  collMod: 'viral_content_tracking',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "post_id"
    ],
    "properties": {
      "post_id": {
        "bsonType": "number"
      },
      "check_time": {
        "bsonType": "string"
      },
      "view_velocity": {
        "bsonType": "decimal128"
      },
      "share_velocity": {
        "bsonType": "decimal128"
      },
      "engagement_velocity": {
        "bsonType": "decimal128"
      },
      "total_reach": {
        "bsonType": "number"
      },
      "cascade_depth": {
        "bsonType": "number"
      },
      "is_trending": {
        "bsonType": "boolean"
      },
      "trend_score": {
        "bsonType": "string"
      }
    }
  }
}
});

// Validation for user_lists
db.runCommand({
  collMod: 'user_lists',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "user_id",
      "name"
    ],
    "properties": {
      "user_id": {
        "bsonType": "number"
      },
      "name": {
        "bsonType": "string"
      },
      "description": {
        "bsonType": "string"
      },
      "is_public": {
        "bsonType": "boolean"
      },
      "member_count": {
        "bsonType": "number"
      },
      "created_at": {
        "bsonType": "string"
      },
      "updated_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for list_members
db.runCommand({
  collMod: 'list_members',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "list_id",
      "user_id"
    ],
    "properties": {
      "list_id": {
        "bsonType": "number"
      },
      "user_id": {
        "bsonType": "number"
      },
      "added_at": {
        "bsonType": "date"
      }
    }
  }
}
});
