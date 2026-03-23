from collections import defaultdict
from typing import Any

from fastapi import HTTPException, status
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

POST_SELECT_COLUMNS = """
    cp.id::text as id,
    cp.user_id::text as user_id,
    cp.content,
    cp.image_path,
    cp.hidden_by_admin,
    cp.created_at,
    cp.updated_at,
    p.display_name as author_display_name,
    p.avatar_path as author_avatar_path
"""

COMMENT_SELECT_COLUMNS = """
    cc.id::text as id,
    cc.post_id::text as post_id,
    cc.user_id::text as user_id,
    cc.content,
    cc.hidden_by_admin,
    cc.created_at,
    cc.updated_at,
    p.display_name as author_display_name,
    p.avatar_path as author_avatar_path
"""


class CommunityService:
    async def list_posts(
        self,
        session: AsyncSession,
        *,
        current_user_id: str,
        include_hidden: bool = False,
        limit: int = 20,
        offset: int = 0,
    ) -> list[dict[str, Any]]:
        hidden_clause = "" if include_hidden else "where cp.hidden_by_admin = false"
        query = text(
            f"""
            select {POST_SELECT_COLUMNS}
            from public.community_posts cp
            join public.profiles p on p.id = cp.user_id
            {hidden_clause}
            order by cp.created_at desc
            limit :limit offset :offset
            """
        )
        result = await session.execute(query, {"limit": limit, "offset": offset})
        posts = [dict(row) for row in result.mappings().all()]
        return await self._enrich_posts(
            session,
            posts,
            current_user_id=current_user_id,
            include_hidden=include_hidden,
        )

    async def get_post(
        self,
        session: AsyncSession,
        post_id: str,
        *,
        current_user_id: str,
        include_hidden: bool = False,
    ) -> dict[str, Any]:
        hidden_clause = "" if include_hidden else "and cp.hidden_by_admin = false"
        query = text(
            f"""
            select {POST_SELECT_COLUMNS}
            from public.community_posts cp
            join public.profiles p on p.id = cp.user_id
            where cp.id = cast(:post_id as uuid)
              {hidden_clause}
            """
        )
        result = await session.execute(query, {"post_id": post_id})
        post = result.mappings().first()
        if not post:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Post not found",
            )
        enriched = await self._enrich_posts(
            session,
            [dict(post)],
            current_user_id=current_user_id,
            include_hidden=include_hidden,
        )
        return enriched[0]

    async def create_post(
        self,
        session: AsyncSession,
        *,
        user_id: str,
        payload: dict[str, Any],
    ) -> dict[str, Any]:
        query = text(
            """
            insert into public.community_posts (
                user_id,
                content,
                image_path
            )
            values (
                cast(:user_id as uuid),
                :content,
                :image_path
            )
            returning id::text as id
            """
        )
        result = await session.execute(query, {**payload, "user_id": user_id})
        created = result.mappings().first()
        await session.commit()
        if not created:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Unable to create post",
            )
        return await self.get_post(
            session,
            created["id"],
            current_user_id=user_id,
            include_hidden=True,
        )

    async def create_comment(
        self,
        session: AsyncSession,
        *,
        user_id: str,
        post_id: str,
        content: str,
    ) -> dict[str, Any]:
        await self.get_post(session, post_id, current_user_id=user_id, include_hidden=False)
        query = text(
            """
            insert into public.community_comments (
                post_id,
                user_id,
                content
            )
            values (
                cast(:post_id as uuid),
                cast(:user_id as uuid),
                :content
            )
            returning id::text as id
            """
        )
        result = await session.execute(
            query,
            {"post_id": post_id, "user_id": user_id, "content": content},
        )
        comment = result.mappings().first()
        await session.commit()
        if not comment:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Unable to create comment",
            )
        return await self.get_comment(session, comment["id"], include_hidden=True)

    async def like_post(
        self,
        session: AsyncSession,
        *,
        user_id: str,
        post_id: str,
    ) -> dict[str, Any]:
        await self.get_post(session, post_id, current_user_id=user_id, include_hidden=False)
        query = text(
            """
            insert into public.community_post_likes (post_id, user_id)
            values (cast(:post_id as uuid), cast(:user_id as uuid))
            on conflict (post_id, user_id) do nothing
            """
        )
        await session.execute(query, {"post_id": post_id, "user_id": user_id})
        await session.commit()
        return await self.get_post(session, post_id, current_user_id=user_id, include_hidden=False)

    async def unlike_post(
        self,
        session: AsyncSession,
        *,
        user_id: str,
        post_id: str,
    ) -> dict[str, Any]:
        query = text(
            """
            delete from public.community_post_likes
            where post_id = cast(:post_id as uuid)
              and user_id = cast(:user_id as uuid)
            """
        )
        await session.execute(query, {"post_id": post_id, "user_id": user_id})
        await session.commit()
        return await self.get_post(session, post_id, current_user_id=user_id, include_hidden=False)

    async def set_post_visibility(
        self,
        session: AsyncSession,
        *,
        post_id: str,
        hidden_by_admin: bool,
        current_user_id: str,
    ) -> dict[str, Any]:
        query = text(
            """
            update public.community_posts
            set hidden_by_admin = :hidden_by_admin
            where id = cast(:post_id as uuid)
            returning id::text as id
            """
        )
        result = await session.execute(
            query,
            {"post_id": post_id, "hidden_by_admin": hidden_by_admin},
        )
        updated = result.mappings().first()
        if not updated:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Post not found",
            )
        await self._log_action(
            session,
            admin_user_id=current_user_id,
            action="hide_post" if hidden_by_admin else "restore_post",
            entity_type="community_post",
            entity_id=post_id,
        )
        await session.commit()
        return await self.get_post(
            session,
            updated["id"],
            current_user_id=current_user_id,
            include_hidden=True,
        )

    async def set_comment_visibility(
        self,
        session: AsyncSession,
        *,
        comment_id: str,
        hidden_by_admin: bool,
        admin_user_id: str,
    ) -> dict[str, Any]:
        query = text(
            """
            update public.community_comments
            set hidden_by_admin = :hidden_by_admin
            where id = cast(:comment_id as uuid)
            returning id::text as id
            """
        )
        result = await session.execute(
            query,
            {"comment_id": comment_id, "hidden_by_admin": hidden_by_admin},
        )
        updated = result.mappings().first()
        if not updated:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Comment not found",
            )
        await self._log_action(
            session,
            admin_user_id=admin_user_id,
            action="hide_comment" if hidden_by_admin else "restore_comment",
            entity_type="community_comment",
            entity_id=comment_id,
        )
        await session.commit()
        return await self.get_comment(session, updated["id"], include_hidden=True)

    async def get_comment(
        self,
        session: AsyncSession,
        comment_id: str,
        *,
        include_hidden: bool,
    ) -> dict[str, Any]:
        hidden_clause = "" if include_hidden else "and cc.hidden_by_admin = false"
        query = text(
            f"""
            select {COMMENT_SELECT_COLUMNS}
            from public.community_comments cc
            join public.profiles p on p.id = cc.user_id
            where cc.id = cast(:comment_id as uuid)
              {hidden_clause}
            """
        )
        result = await session.execute(query, {"comment_id": comment_id})
        comment = result.mappings().first()
        if not comment:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Comment not found",
            )
        return self._format_comment(dict(comment))

    async def _enrich_posts(
        self,
        session: AsyncSession,
        posts: list[dict[str, Any]],
        *,
        current_user_id: str,
        include_hidden: bool,
    ) -> list[dict[str, Any]]:
        if not posts:
            return []

        comments_by_post_id: dict[str, list[dict[str, Any]]] = defaultdict(list)
        likes_count_by_post_id: dict[str, int] = defaultdict(int)
        liked_post_ids: set[str] = set()

        comments_clause = "" if include_hidden else "and cc.hidden_by_admin = false"
        comments_query = text(
            f"""
            select {COMMENT_SELECT_COLUMNS}
            from public.community_comments cc
            join public.profiles p on p.id = cc.user_id
            where cc.post_id = cast(:post_id as uuid)
              {comments_clause}
            order by cc.created_at asc
            """
        )
        likes_count_query = text(
            """
            select count(*)::int as likes_count
            from public.community_post_likes
            where post_id = cast(:post_id as uuid)
            """
        )
        liked_query = text(
            """
            select exists(
                select 1
                from public.community_post_likes
                where post_id = cast(:post_id as uuid)
                  and user_id = cast(:user_id as uuid)
            ) as liked_by_me
            """
        )

        for post in posts:
            comments_result = await session.execute(comments_query, {"post_id": post["id"]})
            comments = [self._format_comment(dict(row)) for row in comments_result.mappings().all()]
            comments_by_post_id[post["id"]] = comments

            likes_count_result = await session.execute(likes_count_query, {"post_id": post["id"]})
            likes_count_by_post_id[post["id"]] = int(likes_count_result.scalar_one() or 0)

            liked_result = await session.execute(
                liked_query,
                {"post_id": post["id"], "user_id": current_user_id},
            )
            if bool(liked_result.scalar_one()):
                liked_post_ids.add(post["id"])

        enriched = []
        for post in posts:
            post_comments = comments_by_post_id.get(post["id"], [])
            enriched.append(
                {
                    "id": post["id"],
                    "user_id": post["user_id"],
                    "content": post["content"],
                    "image_path": post["image_path"],
                    "hidden_by_admin": post["hidden_by_admin"],
                    "created_at": post["created_at"],
                    "updated_at": post["updated_at"],
                    "author": {
                        "id": post["user_id"],
                        "display_name": post["author_display_name"],
                        "avatar_path": post["author_avatar_path"],
                    },
                    "comments": post_comments,
                    "likes_count": likes_count_by_post_id.get(post["id"], 0),
                    "comments_count": len(post_comments),
                    "liked_by_me": post["id"] in liked_post_ids,
                }
            )
        return enriched

    def _format_comment(self, row: dict[str, Any]) -> dict[str, Any]:
        return {
            "id": row["id"],
            "post_id": row["post_id"],
            "user_id": row["user_id"],
            "content": row["content"],
            "hidden_by_admin": row["hidden_by_admin"],
            "created_at": row["created_at"],
            "updated_at": row["updated_at"],
            "author": {
                "id": row["user_id"],
                "display_name": row["author_display_name"],
                "avatar_path": row["author_avatar_path"],
            },
        }

    # ── Audit Logging ──────────────────────────────────────────────────

    async def _log_action(
        self,
        session: AsyncSession,
        *,
        admin_user_id: str,
        action: str,
        entity_type: str,
        entity_id: str | None = None,
        metadata: dict[str, Any] | None = None,
    ) -> None:
        query = text(
            """
            insert into public.admin_audit_logs (
                admin_user_id, action, entity_type, entity_id, metadata
            )
            values (
                cast(:admin_user_id as uuid),
                :action,
                :entity_type,
                :entity_id,
                cast(:metadata as jsonb)
            )
            """
        )
        import json as _json

        await session.execute(
            query,
            {
                "admin_user_id": admin_user_id,
                "action": action,
                "entity_type": entity_type,
                "entity_id": entity_id,
                "metadata": _json.dumps(metadata or {}),
            },
        )

    async def list_audit_log(
        self,
        session: AsyncSession,
        *,
        limit: int = 100,
    ) -> list[dict[str, Any]]:
        query = text(
            """
            select
                al.id::text as id,
                al.admin_user_id::text as admin_user_id,
                p.display_name as admin_display_name,
                al.action,
                al.entity_type,
                al.entity_id,
                al.metadata,
                al.created_at
            from public.admin_audit_logs al
            join public.profiles p on p.id = al.admin_user_id
            order by al.created_at desc
            limit :limit
            """
        )
        result = await session.execute(query, {"limit": limit})
        return [dict(row) for row in result.mappings().all()]

    # ── Delete Operations ──────────────────────────────────────────────

    async def delete_post(
        self,
        session: AsyncSession,
        *,
        post_id: str,
        user_id: str,
    ) -> None:
        """Delete a post only if the requesting user is the owner."""
        query = text(
            """
            delete from public.community_posts
            where id = cast(:post_id as uuid)
              and user_id = cast(:user_id as uuid)
            returning id::text as id
            """
        )
        result = await session.execute(
            query, {"post_id": post_id, "user_id": user_id}
        )
        deleted = result.mappings().first()
        if not deleted:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Post not found or you are not the owner",
            )
        await session.commit()

    async def delete_comment(
        self,
        session: AsyncSession,
        *,
        comment_id: str,
        user_id: str,
    ) -> None:
        """Delete a comment only if the requesting user is the owner."""
        query = text(
            """
            delete from public.community_comments
            where id = cast(:comment_id as uuid)
              and user_id = cast(:user_id as uuid)
            returning id::text as id
            """
        )
        result = await session.execute(
            query, {"comment_id": comment_id, "user_id": user_id}
        )
        deleted = result.mappings().first()
        if not deleted:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Comment not found or you are not the owner",
            )
        await session.commit()

    async def admin_delete_post(
        self,
        session: AsyncSession,
        *,
        post_id: str,
        admin_user_id: str,
    ) -> None:
        """Hard-delete a post as admin."""
        query = text(
            """
            delete from public.community_posts
            where id = cast(:post_id as uuid)
            returning id::text as id
            """
        )
        result = await session.execute(query, {"post_id": post_id})
        deleted = result.mappings().first()
        if not deleted:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Post not found",
            )
        await self._log_action(
            session,
            admin_user_id=admin_user_id,
            action="delete_post",
            entity_type="community_post",
            entity_id=post_id,
        )
        await session.commit()

    async def admin_delete_comment(
        self,
        session: AsyncSession,
        *,
        comment_id: str,
        admin_user_id: str,
    ) -> None:
        """Hard-delete a comment as admin."""
        query = text(
            """
            delete from public.community_comments
            where id = cast(:comment_id as uuid)
            returning id::text as id
            """
        )
        result = await session.execute(query, {"comment_id": comment_id})
        deleted = result.mappings().first()
        if not deleted:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Comment not found",
            )
        await self._log_action(
            session,
            admin_user_id=admin_user_id,
            action="delete_comment",
            entity_type="community_comment",
            entity_id=comment_id,
        )
        await session.commit()

    # ── Reporting ──────────────────────────────────────────────────────

    async def report_post(
        self,
        session: AsyncSession,
        *,
        post_id: str,
        reporter_user_id: str,
        reason: str,
    ) -> dict[str, Any]:
        # Verify post exists and is visible
        await self.get_post(
            session, post_id, current_user_id=reporter_user_id, include_hidden=False
        )
        query = text(
            """
            insert into public.community_reports (
                post_id, reporter_user_id, reason
            )
            values (
                cast(:post_id as uuid),
                cast(:reporter_user_id as uuid),
                :reason
            )
            returning
                id::text as id,
                post_id::text as post_id,
                comment_id::text as comment_id,
                reporter_user_id::text as reporter_user_id,
                reason,
                status,
                reviewed_by::text as reviewed_by,
                created_at,
                updated_at
            """
        )
        result = await session.execute(
            query,
            {
                "post_id": post_id,
                "reporter_user_id": reporter_user_id,
                "reason": reason,
            },
        )
        report = result.mappings().first()
        await session.commit()
        if not report:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Unable to create report",
            )
        return dict(report)

    async def report_comment(
        self,
        session: AsyncSession,
        *,
        comment_id: str,
        reporter_user_id: str,
        reason: str,
    ) -> dict[str, Any]:
        # Verify comment exists and is visible
        await self.get_comment(session, comment_id, include_hidden=False)
        query = text(
            """
            insert into public.community_reports (
                comment_id, reporter_user_id, reason
            )
            values (
                cast(:comment_id as uuid),
                cast(:reporter_user_id as uuid),
                :reason
            )
            returning
                id::text as id,
                post_id::text as post_id,
                comment_id::text as comment_id,
                reporter_user_id::text as reporter_user_id,
                reason,
                status,
                reviewed_by::text as reviewed_by,
                created_at,
                updated_at
            """
        )
        result = await session.execute(
            query,
            {
                "comment_id": comment_id,
                "reporter_user_id": reporter_user_id,
                "reason": reason,
            },
        )
        report = result.mappings().first()
        await session.commit()
        if not report:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Unable to create report",
            )
        return dict(report)

    async def list_reports(
        self,
        session: AsyncSession,
        *,
        status_filter: str | None = None,
    ) -> list[dict[str, Any]]:
        status_clause = ""
        params: dict[str, Any] = {}
        if status_filter:
            status_clause = "where cr.status = :status_filter"
            params["status_filter"] = status_filter

        query = text(
            f"""
            select
                cr.id::text as id,
                cr.post_id::text as post_id,
                cr.comment_id::text as comment_id,
                cr.reporter_user_id::text as reporter_user_id,
                cr.reason,
                cr.status,
                cr.reviewed_by::text as reviewed_by,
                cr.created_at,
                cr.updated_at,
                rp.display_name as reporter_display_name,
                rp.avatar_path as reporter_avatar_path,
                cp.content as post_content,
                cc.content as comment_content,
                coalesce(ap.id, acp.id)::text as target_author_id,
                coalesce(ap.display_name, acp.display_name) as target_author_display_name,
                coalesce(ap.avatar_path, acp.avatar_path) as target_author_avatar_path
            from public.community_reports cr
            join public.profiles rp on rp.id = cr.reporter_user_id
            left join public.community_posts cp on cp.id = cr.post_id
            left join public.profiles ap on ap.id = cp.user_id
            left join public.community_comments cc on cc.id = cr.comment_id
            left join public.profiles acp on acp.id = cc.user_id
            {status_clause}
            order by cr.created_at desc
            """
        )
        result = await session.execute(query, params)
        rows = result.mappings().all()
        reports = []
        for row in rows:
            r = dict(row)
            report: dict[str, Any] = {
                "id": r["id"],
                "post_id": r["post_id"],
                "comment_id": r["comment_id"],
                "reporter_user_id": r["reporter_user_id"],
                "reason": r["reason"],
                "status": r["status"],
                "reviewed_by": r["reviewed_by"],
                "created_at": r["created_at"],
                "updated_at": r["updated_at"],
                "reporter": {
                    "id": r["reporter_user_id"],
                    "display_name": r["reporter_display_name"],
                    "avatar_path": r["reporter_avatar_path"],
                },
                "post_content": r["post_content"],
                "comment_content": r["comment_content"],
                "target_author": {
                    "id": r["target_author_id"],
                    "display_name": r["target_author_display_name"],
                    "avatar_path": r["target_author_avatar_path"],
                } if r["target_author_id"] else None,
            }
            reports.append(report)
        return reports

    async def update_report_status(
        self,
        session: AsyncSession,
        *,
        report_id: str,
        new_status: str,
        admin_user_id: str,
    ) -> dict[str, Any]:
        query = text(
            """
            update public.community_reports
            set status = :new_status,
                reviewed_by = cast(:admin_user_id as uuid)
            where id = cast(:report_id as uuid)
            returning
                id::text as id,
                post_id::text as post_id,
                comment_id::text as comment_id,
                reporter_user_id::text as reporter_user_id,
                reason,
                status,
                reviewed_by::text as reviewed_by,
                created_at,
                updated_at
            """
        )
        result = await session.execute(
            query,
            {
                "report_id": report_id,
                "new_status": new_status,
                "admin_user_id": admin_user_id,
            },
        )
        updated = result.mappings().first()
        if not updated:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Report not found",
            )
        await self._log_action(
            session,
            admin_user_id=admin_user_id,
            action=f"report_{new_status}",
            entity_type="community_report",
            entity_id=report_id,
        )
        await session.commit()
        return dict(updated)


community_service = CommunityService()

