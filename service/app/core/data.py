from __future__ import annotations

from app.schemas.models import AlbumItem, PersonItem, StatItem, TimelineItem


HERO_STATS = [
    StatItem(label="已索引素材", value="18,420", delta="+184"),
    StatItem(label="智能相册", value="42", delta="+3"),
    StatItem(label="待确认人物", value="6", delta="2 高优先级"),
    StatItem(label="今日新增", value="184", delta="SMB 同步"),
]

SIGNALS = [
    StatItem(label="猫类识别准确率", value="94%"),
    StatItem(label="人物待确认", value="6"),
    StatItem(label="重复照片建议", value="38"),
]

ALBUMS = [
    AlbumItem(
        id="album_cat",
        title="可爱的小猫",
        count="1,284 张",
        description="系统识别为猫和宠物的高置信素材",
        color="#FFE0B2",
        cover_label="CAT",
        confidence=0.94,
        type="pet",
    ),
    AlbumItem(
        id="album_self",
        title="我的人像",
        count="846 张",
        description="基于人脸聚类和手动确认构建",
        color="#D6E4FF",
        cover_label="ME",
        confidence=0.91,
        type="portrait",
    ),
    AlbumItem(
        id="album_trip",
        title="旅行与风景",
        count="2,193 张",
        description="旅行时序和场景语义自动归档",
        color="#CDEFEA",
        cover_label="TRIP",
        confidence=0.89,
        type="travel",
    ),
    AlbumItem(
        id="album_daily",
        title="日常记录",
        count="3,040 张",
        description="餐食、房间、桌面和碎片化生活片段",
        color="#FFD9E4",
        cover_label="LIFE",
        confidence=0.83,
        type="daily",
    ),
    AlbumItem(
        id="album_doc",
        title="截图与文档",
        count="625 张",
        description="自动识别文字密集和界面截图素材",
        color="#E2E8F0",
        cover_label="DOC",
        confidence=0.97,
        type="document",
    ),
    AlbumItem(
        id="album_food",
        title="美食与咖啡",
        count="512 张",
        description="适合被做成回忆摘要和日常偏好索引",
        color="#FFE6B8",
        cover_label="FOOD",
        confidence=0.85,
        type="food",
    ),
]

PEOPLE = [
    PersonItem(
        id="person_me",
        name="我",
        asset_count=846,
        trait="最高频出现",
        color="#3D6BFF",
        review_state="confirmed",
        is_self=True,
    ),
    PersonItem(
        id="person_family",
        name="家人",
        asset_count=431,
        trait="高置信簇",
        color="#82E6E2",
        review_state="confirmed",
    ),
    PersonItem(
        id="person_friends",
        name="朋友",
        asset_count=268,
        trait="聚会场景常见",
        color="#FFC9D8",
        review_state="confirmed",
    ),
    PersonItem(
        id="person_unknown_a",
        name="待确认人物 A",
        asset_count=102,
        trait="最近新增",
        color="#FFE6B8",
        review_state="needs_review",
    ),
]

TIMELINE = [
    TimelineItem(
        id="event_20260318_cat",
        date="03 月 18 日",
        title="猫咪相册更新",
        description="从 NAS 新扫描 184 张素材，其中 17 张进入“可爱的小猫”。",
        tag="宠物",
    ),
    TimelineItem(
        id="event_20260317_people",
        date="03 月 17 日",
        title="新人物簇待确认",
        description="系统发现 1 个新的高频人物簇，建议你在人物页完成命名。",
        tag="人物",
    ),
    TimelineItem(
        id="event_20260315_trip",
        date="03 月 15 日",
        title="杭州周末记忆卡",
        description="一组旅行照片被聚合为事件卡片，可作为时间轴首批样式。",
        tag="旅行",
    ),
    TimelineItem(
        id="event_20260311_cleanup",
        date="03 月 11 日",
        title="重复照片建议",
        description="系统标记 38 张高度相似素材，等待你确认是否折叠整理。",
        tag="整理",
    ),
]

