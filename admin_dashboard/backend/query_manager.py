"""
Query Manager for saving, sharing, and managing SQL queries
"""

import logging
import json
import hashlib
from typing import List, Dict, Any, Optional
from datetime import datetime, timedelta
from pathlib import Path
import uuid

logger = logging.getLogger(__name__)


class QueryManager:
    """Manages saved queries, collections, and sharing"""

    def __init__(self):
        self.storage_path = Path(__file__).parent.parent.parent / "saved_queries"
        self.storage_path.mkdir(exist_ok=True)
        self.queries = {}
        self.collections = {}
        self.shared_queries = {}
        self.query_versions = {}
        self.performance_history = {}
        self._load_saved_queries()

    def _load_saved_queries(self):
        """Load saved queries from storage"""
        try:
            # Load queries
            queries_file = self.storage_path / "queries.json"
            if queries_file.exists():
                with open(queries_file, "r") as f:
                    data = json.load(f)
                    self.queries = data.get("queries", {})
                    self.collections = data.get("collections", {})
                    self.shared_queries = data.get("shared", {})
                    self.query_versions = data.get("versions", {})
                    self.performance_history = data.get("performance", {})

            logger.info(f"Loaded {len(self.queries)} saved queries")
        except Exception as e:
            logger.error(f"Error loading saved queries: {e}")

    def _save_to_storage(self):
        """Persist queries to storage"""
        try:
            queries_file = self.storage_path / "queries.json"
            data = {
                "queries": self.queries,
                "collections": self.collections,
                "shared": self.shared_queries,
                "versions": self.query_versions,
                "performance": self.performance_history,
            }
            with open(queries_file, "w") as f:
                json.dump(data, f, indent=2, default=str)
        except Exception as e:
            logger.error(f"Error saving queries: {e}")

    def save_query(self, user_id: str, query_data: Dict[str, Any]) -> Dict[str, Any]:
        """Save a new query or update existing one"""
        query_id = query_data.get("id") or str(uuid.uuid4())

        # Create query object
        query = {
            "id": query_id,
            "name": query_data.get("name", "Untitled Query"),
            "description": query_data.get("description", ""),
            "sql": query_data.get("sql", ""),
            "database": query_data.get("database", ""),
            "tags": query_data.get("tags", []),
            "collection_id": query_data.get("collection_id"),
            "owner": user_id,
            "created_at": query_data.get("created_at", datetime.now().isoformat()),
            "updated_at": datetime.now().isoformat(),
            "is_public": query_data.get("is_public", False),
            "shared_with": query_data.get("shared_with", []),
            "execution_count": 0,
            "avg_execution_time": 0,
            "last_executed": None,
            "favorite": query_data.get("favorite", False),
            "parameters": query_data.get("parameters", []),  # For parameterized queries
        }

        # Handle versioning if query exists
        if query_id in self.queries:
            self._create_version(query_id, self.queries[query_id])

        self.queries[query_id] = query
        self._save_to_storage()

        return {
            "status": "success",
            "query": query,
            "message": f"Query '{query['name']}' saved successfully",
        }

    def _create_version(self, query_id: str, query_data: Dict[str, Any]):
        """Create a version of a query before updating"""
        if query_id not in self.query_versions:
            self.query_versions[query_id] = []

        version = {
            "version_id": str(uuid.uuid4()),
            "query_id": query_id,
            "sql": query_data.get("sql", ""),
            "name": query_data.get("name", ""),
            "description": query_data.get("description", ""),
            "created_at": query_data.get("updated_at", datetime.now().isoformat()),
            "created_by": query_data.get("owner", ""),
        }

        self.query_versions[query_id].append(version)

        # Keep only last 10 versions
        if len(self.query_versions[query_id]) > 10:
            self.query_versions[query_id] = self.query_versions[query_id][-10:]

    def get_query(self, query_id: str, user_id: str) -> Optional[Dict[str, Any]]:
        """Get a specific query if user has access"""
        query = self.queries.get(query_id)

        if not query:
            return None

        # Check access permissions
        if (
            query["owner"] == user_id
            or query["is_public"]
            or user_id in query.get("shared_with", [])
        ):
            return query

        return None

    def get_user_queries(
        self, user_id: str, include_shared: bool = True
    ) -> List[Dict[str, Any]]:
        """Get all queries accessible to a user"""
        user_queries = []

        for query in self.queries.values():
            if query["owner"] == user_id or (
                include_shared
                and (query["is_public"] or user_id in query.get("shared_with", []))
            ):
                user_queries.append(query)

        # Sort by updated_at descending
        user_queries.sort(key=lambda x: x["updated_at"], reverse=True)

        return user_queries

    def delete_query(self, query_id: str, user_id: str) -> Dict[str, Any]:
        """Delete a query if user is owner"""
        query = self.queries.get(query_id)

        if not query:
            return {"status": "error", "message": "Query not found"}

        if query["owner"] != user_id:
            return {"status": "error", "message": "Permission denied"}

        # Remove from collections
        for collection in self.collections.values():
            if query_id in collection.get("query_ids", []):
                collection["query_ids"].remove(query_id)

        # Remove versions
        if query_id in self.query_versions:
            del self.query_versions[query_id]

        # Remove performance history
        if query_id in self.performance_history:
            del self.performance_history[query_id]

        del self.queries[query_id]
        self._save_to_storage()

        return {"status": "success", "message": "Query deleted successfully"}

    def create_collection(
        self, user_id: str, collection_data: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Create a new query collection"""
        collection_id = str(uuid.uuid4())

        collection = {
            "id": collection_id,
            "name": collection_data.get("name", "Untitled Collection"),
            "description": collection_data.get("description", ""),
            "owner": user_id,
            "query_ids": collection_data.get("query_ids", []),
            "is_public": collection_data.get("is_public", False),
            "shared_with": collection_data.get("shared_with", []),
            "created_at": datetime.now().isoformat(),
            "updated_at": datetime.now().isoformat(),
            "icon": collection_data.get("icon", "folder"),
            "color": collection_data.get("color", "#1976d2"),
        }

        self.collections[collection_id] = collection
        self._save_to_storage()

        return {
            "status": "success",
            "collection": collection,
            "message": f"Collection '{collection['name']}' created successfully",
        }

    def get_user_collections(self, user_id: str) -> List[Dict[str, Any]]:
        """Get all collections for a user"""
        user_collections = []

        for collection in self.collections.values():
            if (
                collection["owner"] == user_id
                or collection["is_public"]
                or user_id in collection.get("shared_with", [])
            ):
                # Include query count
                collection_copy = collection.copy()
                collection_copy["query_count"] = len(collection.get("query_ids", []))
                user_collections.append(collection_copy)

        return user_collections

    def share_query(
        self, query_id: str, owner_id: str, share_data: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Share a query with other users"""
        query = self.queries.get(query_id)

        if not query:
            return {"status": "error", "message": "Query not found"}

        if query["owner"] != owner_id:
            return {"status": "error", "message": "Permission denied"}

        # Update sharing settings
        query["is_public"] = share_data.get("is_public", query["is_public"])
        query["shared_with"] = share_data.get("shared_with", query["shared_with"])

        # Track in shared queries
        if query["is_public"] or query["shared_with"]:
            self.shared_queries[query_id] = {
                "shared_at": datetime.now().isoformat(),
                "shared_by": owner_id,
                "access_count": 0,
            }

        self._save_to_storage()

        return {
            "status": "success",
            "message": "Query sharing updated successfully",
            "query": query,
        }

    def duplicate_query(self, query_id: str, user_id: str) -> Dict[str, Any]:
        """Duplicate an existing query"""
        original = self.get_query(query_id, user_id)

        if not original:
            return {"status": "error", "message": "Query not found or access denied"}

        # Create a copy
        new_query = original.copy()
        new_query["id"] = str(uuid.uuid4())
        new_query["name"] = f"{original['name']} (Copy)"
        new_query["owner"] = user_id
        new_query["created_at"] = datetime.now().isoformat()
        new_query["updated_at"] = datetime.now().isoformat()
        new_query["is_public"] = False
        new_query["shared_with"] = []
        new_query["execution_count"] = 0

        self.queries[new_query["id"]] = new_query
        self._save_to_storage()

        return {
            "status": "success",
            "query": new_query,
            "message": f"Query duplicated as '{new_query['name']}'",
        }

    def get_query_versions(self, query_id: str, user_id: str) -> List[Dict[str, Any]]:
        """Get version history for a query"""
        query = self.get_query(query_id, user_id)

        if not query:
            return []

        return self.query_versions.get(query_id, [])

    def restore_version(
        self, query_id: str, version_id: str, user_id: str
    ) -> Dict[str, Any]:
        """Restore a previous version of a query"""
        query = self.queries.get(query_id)

        if not query:
            return {"status": "error", "message": "Query not found"}

        if query["owner"] != user_id:
            return {"status": "error", "message": "Permission denied"}

        versions = self.query_versions.get(query_id, [])
        version = next((v for v in versions if v["version_id"] == version_id), None)

        if not version:
            return {"status": "error", "message": "Version not found"}

        # Create version of current state before restoring
        self._create_version(query_id, query)

        # Restore version
        query["sql"] = version["sql"]
        query["name"] = version.get("name", query["name"])
        query["description"] = version.get("description", query["description"])
        query["updated_at"] = datetime.now().isoformat()

        self._save_to_storage()

        return {
            "status": "success",
            "query": query,
            "message": "Query version restored successfully",
        }

    def record_execution(self, query_id: str, execution_data: Dict[str, Any]):
        """Record query execution for performance history"""
        if query_id not in self.queries:
            return

        # Update query stats
        query = self.queries[query_id]
        query["execution_count"] = query.get("execution_count", 0) + 1
        query["last_executed"] = datetime.now().isoformat()

        # Update average execution time
        execution_time = execution_data.get("execution_time", 0)
        old_avg = query.get("avg_execution_time", 0)
        old_count = query["execution_count"] - 1

        if old_count > 0:
            query["avg_execution_time"] = (
                old_avg * old_count + execution_time
            ) / query["execution_count"]
        else:
            query["avg_execution_time"] = execution_time

        # Record in performance history
        if query_id not in self.performance_history:
            self.performance_history[query_id] = []

        self.performance_history[query_id].append(
            {
                "timestamp": datetime.now().isoformat(),
                "execution_time": execution_time,
                "rows_returned": execution_data.get("rows_returned", 0),
                "database": execution_data.get("database", ""),
                "success": execution_data.get("success", True),
                "error": execution_data.get("error"),
            }
        )

        # Keep only last 100 executions
        if len(self.performance_history[query_id]) > 100:
            self.performance_history[query_id] = self.performance_history[query_id][
                -100:
            ]

        self._save_to_storage()

    def get_performance_history(
        self, query_id: str, user_id: str
    ) -> List[Dict[str, Any]]:
        """Get performance history for a query"""
        query = self.get_query(query_id, user_id)

        if not query:
            return []

        return self.performance_history.get(query_id, [])

    def search_queries(self, user_id: str, search_term: str) -> List[Dict[str, Any]]:
        """Search queries by name, description, or SQL content"""
        user_queries = self.get_user_queries(user_id)
        search_lower = search_term.lower()

        results = []
        for query in user_queries:
            if (
                search_lower in query["name"].lower()
                or search_lower in query.get("description", "").lower()
                or search_lower in query.get("sql", "").lower()
                or any(search_lower in tag.lower() for tag in query.get("tags", []))
            ):
                results.append(query)

        return results

    def get_favorite_queries(self, user_id: str) -> List[Dict[str, Any]]:
        """Get user's favorite queries"""
        user_queries = self.get_user_queries(user_id)
        return [q for q in user_queries if q.get("favorite", False)]

    def toggle_favorite(self, query_id: str, user_id: str) -> Dict[str, Any]:
        """Toggle favorite status of a query"""
        query = self.queries.get(query_id)

        if not query:
            return {"status": "error", "message": "Query not found"}

        if query["owner"] != user_id:
            return {"status": "error", "message": "Permission denied"}

        query["favorite"] = not query.get("favorite", False)
        self._save_to_storage()

        return {
            "status": "success",
            "favorite": query["favorite"],
            "message": "Favorite status updated",
        }
