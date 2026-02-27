"""
Social Media and Streaming Platform Machine Learning Models
Specialized ML for content recommendation, trend detection, and user analytics
"""

import pandas as pd
import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.decomposition import LatentDirichletAllocation, NMF
from sklearn.cluster import KMeans
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics.pairwise import cosine_similarity
import warnings

warnings.filterwarnings("ignore")

from ml_pipeline import (
    RecommendationSystem,
    AnomalyDetector,
    MLPipeline,
    CustomerSegmentation,
)


class SocialMediaAnalytics:
    """
    ML models for social media platforms
    Includes content recommendation, trend detection, and influence analysis
    """

    def __init__(self):
        self.models = {}
        self.vectorizers = {}

    def detect_trending_topics(
        self, df: pd.DataFrame, time_window: str = "1H"
    ) -> pd.DataFrame:
        """
        Detect trending topics from social media posts

        Args:
            df: DataFrame with post content and timestamps
            time_window: Time window for trend detection

        Returns:
            DataFrame with trending topics and scores
        """
        print("[OK] Detecting trending topics...")

        # Create synthetic content if not present
        if "content" not in df.columns:
            topics = [
                "technology",
                "sports",
                "music",
                "politics",
                "food",
                "travel",
                "fashion",
                "gaming",
            ]
            df["content"] = [
                f"Amazing {np.random.choice(topics)} post about {np.random.choice(['new', 'trending', 'viral', 'awesome'])} things"
                for _ in range(len(df))
            ]

        if "timestamp" not in df.columns:
            df["timestamp"] = pd.date_range(
                start="2024-01-01", periods=len(df), freq="min"
            )

        # Calculate engagement metrics
        if "likes" not in df.columns:
            df["likes"] = np.random.negative_binomial(5, 0.1, len(df))
        if "shares" not in df.columns:
            df["shares"] = np.random.negative_binomial(2, 0.3, len(df))
        if "comments" not in df.columns:
            df["comments"] = np.random.negative_binomial(3, 0.2, len(df))

        # Engagement score
        df["engagement_score"] = (
            df["likes"]
            + df["shares"] * 2  # Shares weighted higher
            + df["comments"] * 1.5
        )

        # Extract topics using TF-IDF
        vectorizer = TfidfVectorizer(
            max_features=100, stop_words="english", ngram_range=(1, 2)
        )
        tfidf_matrix = vectorizer.fit_transform(df["content"].fillna(""))
        self.vectorizers["tfidf"] = vectorizer

        # Topic modeling with LDA
        lda = LatentDirichletAllocation(n_components=10, random_state=42)
        topic_distribution = lda.fit_transform(tfidf_matrix)

        # Get top words for each topic
        feature_names = vectorizer.get_feature_names_out()
        topics = []

        for topic_idx, topic in enumerate(lda.components_):
            top_indices = topic.argsort()[-5:][::-1]
            top_words = [feature_names[i] for i in top_indices]
            topics.append(
                {
                    "topic_id": topic_idx,
                    "keywords": ", ".join(top_words),
                    "posts_count": np.sum(topic_distribution[:, topic_idx] > 0.1),
                    "total_engagement": df[topic_distribution[:, topic_idx] > 0.1][
                        "engagement_score"
                    ].sum(),
                    "avg_engagement": (
                        df[topic_distribution[:, topic_idx] > 0.1][
                            "engagement_score"
                        ].mean()
                        if np.sum(topic_distribution[:, topic_idx] > 0.1) > 0
                        else 0
                    ),
                }
            )

        topics_df = pd.DataFrame(topics)

        # Calculate trend score (engagement growth rate)
        topics_df["trend_score"] = topics_df["total_engagement"] / (
            topics_df["posts_count"] + 1
        )

        # Classify trend strength
        topics_df["trend_strength"] = pd.cut(
            topics_df["trend_score"],
            bins=[0, 10, 50, 100, float("inf")],
            labels=["emerging", "growing", "hot", "viral"],
        )

        # Sort by trend score
        topics_df = topics_df.sort_values("trend_score", ascending=False)

        print(f"[OK] Detected {len(topics_df)} trending topics")
        return topics_df

    def predict_content_virality(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Predict likelihood of content going viral

        Args:
            df: DataFrame with post features

        Returns:
            DataFrame with virality predictions
        """
        print("[OK] Predicting content virality...")

        # Content features
        features = [
            "content_length",
            "has_image",
            "has_video",
            "has_hashtags",
            "hour_posted",
            "day_of_week",
            "author_followers",
            "author_engagement_rate",
            "sentiment_score",
        ]

        # Create synthetic features if not present
        for feature in features:
            if feature not in df.columns:
                if feature == "content_length":
                    df[feature] = np.random.poisson(100, len(df))
                elif feature in ["has_image", "has_video", "has_hashtags"]:
                    df[feature] = np.random.choice([0, 1], len(df), p=[0.3, 0.7])
                elif feature == "hour_posted":
                    df[feature] = np.random.randint(0, 24, len(df))
                elif feature == "day_of_week":
                    df[feature] = np.random.randint(0, 7, len(df))
                elif feature == "author_followers":
                    df[feature] = np.random.lognormal(6, 2, len(df))
                elif feature == "author_engagement_rate":
                    df[feature] = np.random.beta(2, 5, len(df))
                elif feature == "sentiment_score":
                    df[feature] = np.random.uniform(-1, 1, len(df))

        # Create virality target based on engagement
        if "is_viral" not in df.columns:
            engagement = (
                df.get("likes", 0)
                + df.get("shares", 0) * 2
                + df.get("comments", 0) * 1.5
            )
            df["is_viral"] = engagement > np.percentile(engagement, 90)

        # Train virality prediction model
        pipeline = MLPipeline(
            model_type="random_forest",
            task_type="classification",
            features=[f for f in features if f in df.columns],
            target="is_viral",
        )

        metrics = pipeline.train(df)
        predictions = pipeline.predict(df)

        # Get probability scores
        if hasattr(pipeline.model, "predict_proba"):
            virality_prob = pipeline.model.predict_proba(
                pipeline.scaler.transform(df[pipeline.features])
            )[:, 1]
        else:
            virality_prob = predictions.astype(float)

        # Feature importance for virality factors
        feature_importance = {}
        if hasattr(pipeline.model, "feature_importances_"):
            for feat, imp in zip(
                pipeline.features, pipeline.model.feature_importances_
            ):
                feature_importance[feat] = imp

        results = pd.DataFrame(
            {
                "post_id": df.get("post_id", range(len(df))),
                "virality_probability": virality_prob,
                "will_go_viral": predictions,
                "virality_score": pd.cut(
                    virality_prob,
                    bins=[0, 0.3, 0.6, 0.8, 1.0],
                    labels=["low", "medium", "high", "very_high"],
                ),
                "top_virality_factor": (
                    max(feature_importance.items(), key=lambda x: x[1])[0]
                    if feature_importance
                    else "content_quality"
                ),
            }
        )

        print(
            f"[OK] Virality predictions complete. Accuracy: {metrics.get('accuracy', 0):.2%}"
        )
        return results

    def analyze_user_influence(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Analyze user influence and identify influencers

        Args:
            df: DataFrame with user interaction data

        Returns:
            DataFrame with influence scores and categories
        """
        print("[OK] Analyzing user influence...")

        # User metrics
        metrics = [
            "followers_count",
            "following_count",
            "posts_count",
            "avg_likes",
            "avg_shares",
            "avg_comments",
            "engagement_rate",
            "network_reach",
        ]

        # Create synthetic metrics if not present
        for metric in metrics:
            if metric not in df.columns:
                if "followers" in metric:
                    df[metric] = np.random.lognormal(5, 2, len(df))
                elif "following" in metric:
                    df[metric] = np.random.lognormal(4, 1.5, len(df))
                elif "posts_count" in metric:
                    df[metric] = np.random.negative_binomial(10, 0.1, len(df))
                elif "avg_" in metric:
                    df[metric] = np.random.lognormal(3, 1, len(df))
                elif metric == "engagement_rate":
                    df[metric] = np.random.beta(2, 8, len(df))
                elif metric == "network_reach":
                    df[metric] = df.get("followers_count", 1000) * (
                        1 + np.random.uniform(0, 2, len(df))
                    )

        # Calculate influence score
        influence_components = {
            "audience_size": np.log1p(df.get("followers_count", 0)) / 10,
            "engagement_quality": df.get("engagement_rate", 0) * 10,
            "content_frequency": np.log1p(df.get("posts_count", 0)) / 5,
            "network_effect": np.log1p(df.get("network_reach", 0)) / 12,
        }

        df["influence_score"] = sum(influence_components.values()) / len(
            influence_components
        )

        # Categorize influencers
        influence_categories = pd.cut(
            df["influence_score"],
            bins=[0, 0.3, 0.5, 0.7, 1.0],
            labels=["regular", "micro_influencer", "influencer", "macro_influencer"],
        )

        # Identify influencer types
        influencer_types = []
        for _, row in df.iterrows():
            if row.get("engagement_rate", 0) > 0.05:
                influencer_types.append("engagement_specialist")
            elif row.get("followers_count", 0) > 10000:
                influencer_types.append("reach_maximizer")
            elif row.get("posts_count", 0) > 100:
                influencer_types.append("content_creator")
            else:
                influencer_types.append("general")

        results = pd.DataFrame(
            {
                "user_id": df.get("user_id", range(len(df))),
                "influence_score": df["influence_score"],
                "influence_category": influence_categories,
                "influencer_type": influencer_types,
                "followers_count": df.get("followers_count", 0),
                "engagement_rate": df.get("engagement_rate", 0),
                "partnership_value": df["influence_score"]
                * 1000,  # Estimated value in dollars
            }
        )

        print(
            f"[OK] Identified {(results['influence_category'] != 'regular').sum()} influencers"
        )
        return results

    def detect_fake_accounts(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Detect potential fake or bot accounts

        Args:
            df: DataFrame with account features

        Returns:
            DataFrame with fake account detection results
        """
        print("[OK] Detecting fake accounts...")

        # Account features for fake detection
        features = [
            "account_age_days",
            "profile_completeness",
            "follower_following_ratio",
            "post_frequency_variance",
            "engagement_authenticity",
            "username_suspicious",
            "bio_length",
            "has_profile_pic",
        ]

        # Create synthetic features
        for feature in features:
            if feature not in df.columns:
                if feature == "account_age_days":
                    df[feature] = np.random.exponential(365, len(df))
                elif feature == "profile_completeness":
                    df[feature] = np.random.beta(7, 3, len(df))
                elif feature == "follower_following_ratio":
                    followers = np.random.lognormal(5, 2, len(df))
                    following = np.random.lognormal(4, 1.5, len(df))
                    df[feature] = followers / (following + 1)
                elif feature == "post_frequency_variance":
                    df[feature] = np.random.exponential(1, len(df))
                elif feature == "engagement_authenticity":
                    df[feature] = np.random.beta(8, 2, len(df))
                elif feature == "username_suspicious":
                    df[feature] = np.random.choice([0, 1], len(df), p=[0.9, 0.1])
                elif feature == "bio_length":
                    df[feature] = np.random.poisson(50, len(df))
                elif feature == "has_profile_pic":
                    df[feature] = np.random.choice([0, 1], len(df), p=[0.1, 0.9])

        # Calculate fake probability
        fake_score = (
            (df["account_age_days"] < 30).astype(float) * 0.2
            + (df["profile_completeness"] < 0.5).astype(float) * 0.15
            + (df["follower_following_ratio"] < 0.1).astype(float) * 0.15
            + (df["post_frequency_variance"] > 2).astype(float) * 0.1
            + (df["engagement_authenticity"] < 0.3).astype(float) * 0.2
            + df["username_suspicious"] * 0.1
            + (df["has_profile_pic"] == 0).astype(float) * 0.1
        )

        # Anomaly detection for unusual patterns
        detector = AnomalyDetector(
            method="isolation_forest",
            features=[f for f in features if f in df.columns],
            contamination=0.1,
        )

        detector.train(df)
        anomalies = detector.detect_anomalies(df)

        results = pd.DataFrame(
            {
                "user_id": df.get("user_id", range(len(df))),
                "fake_probability": fake_score,
                "is_suspicious": (fake_score > 0.6) | anomalies["is_anomaly"],
                "risk_level": pd.cut(
                    fake_score,
                    bins=[0, 0.3, 0.6, 0.8, 1.0],
                    labels=["low", "medium", "high", "critical"],
                ),
                "suspicious_factors": self._identify_suspicious_factors(df, fake_score),
                "recommended_action": np.where(
                    fake_score > 0.7,
                    "review_and_suspend",
                    np.where(fake_score > 0.5, "monitor", "no_action"),
                ),
            }
        )

        print(f"[OK] Detected {results['is_suspicious'].sum()} suspicious accounts")
        return results

    def _identify_suspicious_factors(
        self, df: pd.DataFrame, fake_score: np.ndarray
    ) -> list:
        """Identify main factors contributing to fake account detection"""
        factors = []
        for i in range(len(df)):
            account_factors = []
            if df.iloc[i].get("account_age_days", 365) < 30:
                account_factors.append("new_account")
            if df.iloc[i].get("profile_completeness", 1) < 0.5:
                account_factors.append("incomplete_profile")
            if df.iloc[i].get("follower_following_ratio", 1) < 0.1:
                account_factors.append("suspicious_ratio")
            if df.iloc[i].get("has_profile_pic", 1) == 0:
                account_factors.append("no_profile_pic")
            factors.append(", ".join(account_factors) if account_factors else "none")
        return factors


class StreamingPlatformAnalytics:
    """
    ML models for video/audio streaming platforms
    """

    def __init__(self):
        self.models = {}
        self.recommendation_engine = None

    def recommend_content(
        self, df: pd.DataFrame, user_id: int, n_recommendations: int = 10
    ) -> pd.DataFrame:
        """
        Recommend content to users based on viewing history

        Args:
            df: DataFrame with user viewing history
            user_id: User to recommend for
            n_recommendations: Number of recommendations

        Returns:
            DataFrame with content recommendations
        """
        print(f"[OK] Generating content recommendations for user {user_id}...")

        # Create viewing history if not present
        if "rating" not in df.columns:
            df["rating"] = np.random.uniform(1, 5, len(df))
        if "watch_time_percentage" not in df.columns:
            df["watch_time_percentage"] = np.random.beta(7, 3, len(df)) * 100

        # Combine rating and watch time for implicit feedback
        df["preference_score"] = (
            df["rating"] * 0.6 + (df["watch_time_percentage"] / 20) * 0.4
        )

        # Use RecommendationSystem
        self.recommendation_engine = RecommendationSystem(algorithm="als")
        self.recommendation_engine.train(df)

        recommendations = self.recommendation_engine.get_recommendations(
            user_id=user_id, n_items=n_recommendations
        )

        # Add content metadata
        content_types = ["movie", "series", "documentary", "short", "live"]
        genres = ["action", "comedy", "drama", "thriller", "sci-fi", "romance"]

        recommendations["content_type"] = np.random.choice(
            content_types, len(recommendations)
        )
        recommendations["genre"] = np.random.choice(genres, len(recommendations))
        recommendations["match_percentage"] = (recommendations["score"] * 20).clip(
            0, 100
        )
        recommendations["reason"] = self._generate_recommendation_reason(
            recommendations
        )

        print(f"[OK] Generated {len(recommendations)} recommendations")
        return recommendations

    def predict_churn(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Predict subscriber churn probability

        Args:
            df: DataFrame with subscriber behavior

        Returns:
            DataFrame with churn predictions
        """
        print("[OK] Predicting subscriber churn...")

        # Churn prediction features
        features = [
            "days_since_last_watch",
            "monthly_watch_hours",
            "content_diversity",
            "subscription_months",
            "payment_failed_count",
            "support_tickets",
            "app_crashes",
            "video_quality_issues",
            "price_sensitivity",
        ]

        # Create synthetic features
        for feature in features:
            if feature not in df.columns:
                if feature == "days_since_last_watch":
                    df[feature] = np.random.exponential(7, len(df))
                elif feature == "monthly_watch_hours":
                    df[feature] = np.random.gamma(10, 2, len(df))
                elif feature == "content_diversity":
                    df[feature] = np.random.beta(3, 2, len(df))
                elif feature == "subscription_months":
                    df[feature] = np.random.exponential(12, len(df))
                elif feature in [
                    "payment_failed_count",
                    "support_tickets",
                    "app_crashes",
                ]:
                    df[feature] = np.random.poisson(0.5, len(df))
                elif feature == "video_quality_issues":
                    df[feature] = np.random.poisson(1, len(df))
                elif feature == "price_sensitivity":
                    df[feature] = np.random.beta(5, 5, len(df))

        # Calculate churn probability
        if "churned" not in df.columns:
            df["churned"] = (
                (df["days_since_last_watch"] > 30).astype(int) * 0.3
                + (df["monthly_watch_hours"] < 5).astype(int) * 0.2
                + (df["payment_failed_count"] > 0).astype(int) * 0.2
                + (df["subscription_months"] < 3).astype(int) * 0.15
                + np.random.uniform(0, 0.15, len(df))
            ) > 0.5

        # Train churn model
        pipeline = MLPipeline(
            model_type="gradient_boosting",
            task_type="classification",
            features=[f for f in features if f in df.columns],
            target="churned",
        )

        metrics = pipeline.train(df)
        predictions = pipeline.predict(df)

        # Get churn probability
        if hasattr(pipeline.model, "predict_proba"):
            churn_prob = pipeline.model.predict_proba(
                pipeline.scaler.transform(df[pipeline.features])
            )[:, 1]
        else:
            churn_prob = predictions.astype(float)

        results = pd.DataFrame(
            {
                "subscriber_id": df.get("subscriber_id", range(len(df))),
                "churn_probability": churn_prob,
                "churn_risk": pd.cut(
                    churn_prob,
                    bins=[0, 0.3, 0.6, 0.8, 1.0],
                    labels=["low", "medium", "high", "critical"],
                ),
                "retention_priority": churn_prob > 0.6,
                "recommended_intervention": self._recommend_retention_strategy(
                    df, churn_prob
                ),
            }
        )

        print(
            f"[OK] Churn predictions complete. Model accuracy: {metrics.get('accuracy', 0):.2%}"
        )
        return results

    def optimize_video_quality(self, df: pd.DataFrame) -> pd.DataFrame:
        """
        Optimize video quality based on network conditions and user preferences

        Args:
            df: DataFrame with streaming session data

        Returns:
            Optimized video quality settings
        """
        print("[OK] Optimizing video quality settings...")

        # Network and device features
        features = [
            "bandwidth_mbps",
            "latency_ms",
            "packet_loss",
            "device_type",
            "screen_resolution",
            "battery_level",
            "user_quality_preference",
            "content_type",
        ]

        # Create synthetic features
        for feature in features:
            if feature not in df.columns:
                if feature == "bandwidth_mbps":
                    df[feature] = np.random.gamma(10, 2, len(df))
                elif feature == "latency_ms":
                    df[feature] = np.random.exponential(30, len(df))
                elif feature == "packet_loss":
                    df[feature] = np.random.beta(1, 50, len(df))
                elif feature == "device_type":
                    df[feature] = np.random.choice(
                        ["mobile", "tablet", "tv", "desktop"], len(df)
                    )
                elif feature == "screen_resolution":
                    df[feature] = np.random.choice(["720p", "1080p", "4k"], len(df))
                elif feature == "battery_level":
                    df[feature] = np.random.uniform(20, 100, len(df))
                elif feature == "user_quality_preference":
                    df[feature] = np.random.choice(
                        ["auto", "high", "medium", "low"], len(df)
                    )
                elif feature == "content_type":
                    df[feature] = np.random.choice(["movie", "sports", "news"], len(df))

        # Calculate optimal bitrate
        base_bitrate = {"720p": 2500, "1080p": 5000, "4k": 25000}

        optimal_bitrate = []
        recommended_resolution = []

        for _, row in df.iterrows():
            bandwidth = row.get("bandwidth_mbps", 10)
            screen_res = row.get("screen_resolution", "1080p")
            battery = row.get("battery_level", 50)

            # Adjust based on network conditions
            if bandwidth < 3:
                res = "720p"
                bitrate = min(1500, bandwidth * 500)
            elif bandwidth < 8:
                res = "720p" if screen_res == "720p" else "1080p"
                bitrate = min(base_bitrate.get(res, 2500), bandwidth * 500)
            elif bandwidth < 25:
                res = "4k" if screen_res == "4k" and bandwidth > 20 else "1080p"
                bitrate = min(base_bitrate.get(res, 5000), bandwidth * 500)
            else:
                res = screen_res
                bitrate = base_bitrate.get(res, 5000)

            # Adjust for battery saving
            if battery < 30 and row.get("device_type", "") == "mobile":
                bitrate *= 0.7
                res = "720p"

            optimal_bitrate.append(bitrate)
            recommended_resolution.append(res)

        results = pd.DataFrame(
            {
                "session_id": df.get("session_id", range(len(df))),
                "current_bandwidth_mbps": df.get("bandwidth_mbps", 10),
                "optimal_bitrate_kbps": optimal_bitrate,
                "recommended_resolution": recommended_resolution,
                "adaptive_streaming_enabled": True,
                "buffer_size_seconds": np.maximum(
                    2, 30 / (df.get("bandwidth_mbps", 10) + 1)
                ),
                "quality_score": (df.get("bandwidth_mbps", 10) / 25).clip(0, 1),
            }
        )

        print(f"[OK] Video quality optimization complete for {len(df)} sessions")
        return results

    def _generate_recommendation_reason(self, recommendations: pd.DataFrame) -> list:
        """Generate explanation for recommendations"""
        reasons = [
            "Because you watched similar content",
            "Trending in your favorite genre",
            "Critics' choice this week",
            "Based on your viewing history",
            "Popular with similar users",
            "New release you might like",
        ]
        return [np.random.choice(reasons) for _ in range(len(recommendations))]

    def _recommend_retention_strategy(
        self, df: pd.DataFrame, churn_prob: np.ndarray
    ) -> list:
        """Recommend retention strategies based on churn risk"""
        strategies = []
        for i, prob in enumerate(churn_prob):
            if prob > 0.8:
                strategies.append("offer_discount")
            elif prob > 0.6:
                strategies.append("personalized_content")
            elif prob > 0.4:
                strategies.append("engagement_email")
            else:
                strategies.append("maintain_quality")
        return strategies


def main():
    """Example usage of social media and streaming ML models"""
    print("=" * 60)
    print("Social Media & Streaming Platform ML Models")
    print("=" * 60)

    # Initialize analytics
    social_analytics = SocialMediaAnalytics()
    streaming_analytics = StreamingPlatformAnalytics()

    # 1. Social Media Analytics
    print("\n1. Social Media Analytics")
    print("-" * 40)

    # Create sample social media data
    social_data = pd.DataFrame(
        {
            "post_id": range(1, 101),
            "user_id": np.random.randint(1, 50, 100),
            "content": [
                f"Post about {np.random.choice(['tech', 'sports', 'music', 'food'])} topic"
                for _ in range(100)
            ],
            "timestamp": pd.date_range(start="2024-01-01", periods=100, freq="H"),
            "likes": np.random.negative_binomial(5, 0.1, 100),
            "shares": np.random.negative_binomial(2, 0.3, 100),
            "comments": np.random.negative_binomial(3, 0.2, 100),
        }
    )

    # Detect trending topics
    trends = social_analytics.detect_trending_topics(social_data)
    print("\nTrending Topics:")
    print(trends[["keywords", "posts_count", "trend_score", "trend_strength"]].head())

    # Predict virality
    virality = social_analytics.predict_content_virality(social_data)
    print("\nVirality Predictions:")
    print(f"Posts predicted to go viral: {virality['will_go_viral'].sum()}")
    print(
        f"High virality potential: {(virality['virality_score'] == 'very_high').sum()}"
    )

    # Analyze user influence
    user_data = pd.DataFrame(
        {
            "user_id": range(1, 51),
            "followers_count": np.random.lognormal(6, 2, 50),
            "posts_count": np.random.poisson(20, 50),
            "engagement_rate": np.random.beta(2, 8, 50),
        }
    )

    influence = social_analytics.analyze_user_influence(user_data)
    print("\nUser Influence Analysis:")
    print(
        f"Influencers identified: {(influence['influence_category'] != 'regular').sum()}"
    )
    print(influence.groupby("influence_category").size())

    # Detect fake accounts
    fake_detection = social_analytics.detect_fake_accounts(user_data)
    print("\nFake Account Detection:")
    print(f"Suspicious accounts: {fake_detection['is_suspicious'].sum()}")
    print(
        f"Critical risk accounts: {(fake_detection['risk_level'] == 'critical').sum()}"
    )

    # 2. Streaming Platform Analytics
    print("\n2. Streaming Platform Analytics")
    print("-" * 40)

    # Create sample streaming data
    viewing_data = pd.DataFrame(
        {
            "user_id": np.repeat(range(1, 21), 5),
            "item_id": np.random.randint(1, 100, 100),
            "rating": np.random.uniform(1, 5, 100),
            "watch_time_percentage": np.random.beta(7, 3, 100) * 100,
            "timestamp": pd.date_range(start="2024-01-01", periods=100, freq="D"),
        }
    )

    # Content recommendations
    recommendations = streaming_analytics.recommend_content(
        viewing_data, user_id=1, n_recommendations=5
    )
    print("\nContent Recommendations for User 1:")
    print(
        recommendations[
            ["item_id", "match_percentage", "content_type", "genre", "reason"]
        ]
    )

    # Churn prediction
    subscriber_data = pd.DataFrame(
        {
            "subscriber_id": range(1, 101),
            "days_since_last_watch": np.random.exponential(7, 100),
            "monthly_watch_hours": np.random.gamma(10, 2, 100),
            "subscription_months": np.random.exponential(12, 100),
            "payment_failed_count": np.random.poisson(0.2, 100),
        }
    )

    churn = streaming_analytics.predict_churn(subscriber_data)
    print("\nChurn Prediction:")
    print(f"High churn risk subscribers: {(churn['churn_risk'] == 'high').sum()}")
    print(f"Critical churn risk: {(churn['churn_risk'] == 'critical').sum()}")
    print("\nRetention strategies distribution:")
    print(pd.Series(churn["recommended_intervention"]).value_counts())

    # Video quality optimization
    session_data = pd.DataFrame(
        {
            "session_id": range(1, 51),
            "bandwidth_mbps": np.random.gamma(10, 2, 50),
            "device_type": np.random.choice(["mobile", "tablet", "tv", "desktop"], 50),
            "screen_resolution": np.random.choice(["720p", "1080p", "4k"], 50),
            "battery_level": np.random.uniform(20, 100, 50),
        }
    )

    quality = streaming_analytics.optimize_video_quality(session_data)
    print("\nVideo Quality Optimization:")
    print(quality.groupby("recommended_resolution").size())
    avg_bitrate = quality["optimal_bitrate_kbps"].mean()
    print(f"Average optimal bitrate: {avg_bitrate:.0f} kbps")
    print(f"Average quality score: {quality['quality_score'].mean():.2%}")


if __name__ == "__main__":
    main()
