import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../theme/app_colors.dart';

class MockMemoryData {
  static const sources = [
    MediaSource(
      sourceId: 'source_nas',
      sourceType: 'mounted_folder',
      displayName: 'UGREEN HomeMedia',
      rootPath: '/Volumes/UGREEN/HomeMedia',
      status: 'ready',
      lastScanAt: '2026-03-18T10:30:00Z',
    ),
    MediaSource(
      sourceId: 'source_local',
      sourceType: 'local_folder',
      displayName: 'Mac Photos Export',
      rootPath: '/Users/john/Pictures/Exports',
      status: 'ready',
      lastScanAt: '2026-03-17T09:10:00Z',
    ),
  ];

  static const heroStats = [
    MemoryStat(label: '已索引素材', value: '18,420', delta: '+184'),
    MemoryStat(label: '智能相册', value: '42', delta: '+3'),
    MemoryStat(label: '待确认人物', value: '6', delta: '2 高优先级'),
    MemoryStat(label: '今日新增', value: '184', delta: 'SMB 同步'),
  ];

  static const albums = [
    SmartAlbum(
      title: '可爱的小猫',
      count: '1,284 张',
      description: '系统识别为猫和宠物的高置信素材',
      color: Color(0xFFFFE0B2),
      coverLabel: 'CAT',
    ),
    SmartAlbum(
      title: '我的人像',
      count: '846 张',
      description: '基于人脸聚类和手动确认构建',
      color: Color(0xFFD6E4FF),
      coverLabel: 'ME',
    ),
    SmartAlbum(
      title: '旅行与风景',
      count: '2,193 张',
      description: '旅行时序和场景语义自动归档',
      color: Color(0xFFCDEFEA),
      coverLabel: 'TRIP',
    ),
    SmartAlbum(
      title: '日常记录',
      count: '3,040 张',
      description: '餐食、房间、桌面和碎片化生活片段',
      color: Color(0xFFFFD9E4),
      coverLabel: 'LIFE',
    ),
    SmartAlbum(
      title: '截图与文档',
      count: '625 张',
      description: '自动识别文字密集和界面截图素材',
      color: Color(0xFFE2E8F0),
      coverLabel: 'DOC',
    ),
    SmartAlbum(
      title: '美食与咖啡',
      count: '512 张',
      description: '适合被做成回忆摘要和日常偏好索引',
      color: Color(0xFFFFE6B8),
      coverLabel: 'FOOD',
    ),
  ];

  static const people = [
    PersonCluster(
      id: 'person_me',
      name: '我',
      assetCount: 846,
      trait: '最高频出现',
      color: AppColors.electricBlue,
      reviewState: 'confirmed',
      isSelf: true,
    ),
    PersonCluster(
      id: 'person_family',
      name: '家人',
      assetCount: 431,
      trait: '高置信簇',
      color: AppColors.aqua,
      reviewState: 'confirmed',
    ),
    PersonCluster(
      id: 'person_friends',
      name: '朋友',
      assetCount: 268,
      trait: '聚会场景常见',
      color: AppColors.rose,
      reviewState: 'confirmed',
    ),
    PersonCluster(
      id: 'person_unknown_a',
      name: '待确认人物 A',
      assetCount: 102,
      trait: '最近新增',
      color: AppColors.sand,
      reviewState: 'needs_review',
    ),
  ];

  static const memoryEvents = [
    MemoryEvent(
      id: 'memory_pet',
      date: '03 月 18 日',
      title: '猫咪相册更新',
      description: '从 NAS 新扫描 184 张素材，其中 17 张进入“可爱的小猫”。',
      tag: '宠物',
    ),
    MemoryEvent(
      id: 'memory_people',
      date: '03 月 17 日',
      title: '新人物簇待确认',
      description: '系统发现 1 个新的高频人物簇，建议你在人物页完成命名。',
      tag: '人物',
    ),
    MemoryEvent(
      id: 'memory_travel',
      date: '03 月 15 日',
      title: '杭州周末记忆卡',
      description: '一组旅行照片被聚合为事件卡片，可作为时间轴首批样式。',
      tag: '旅行',
    ),
    MemoryEvent(
      id: 'memory_cleanup',
      date: '03 月 11 日',
      title: '重复照片建议',
      description: '系统标记 38 张高度相似素材，等待你确认是否折叠整理。',
      tag: '整理',
    ),
  ];

  static const scanJobs = [
    ScanJob(
      title: 'SMB 增量扫描',
      status: '进行中',
      progress: 0.72,
      detail: '/Volumes/UGREEN/HomeMedia 过去 24 小时新增 184 项',
      sourceId: 'source_nas',
      sourceName: 'UGREEN HomeMedia',
      rootPath: '/Volumes/UGREEN/HomeMedia',
      mode: 'incremental',
    ),
    ScanJob(
      title: '缩略图生成',
      status: '排队中',
      progress: 0.41,
      detail: '等待视频封面和 HEIC 转码任务',
      sourceId: 'source_nas',
      sourceName: 'UGREEN HomeMedia',
      rootPath: '/Volumes/UGREEN/HomeMedia',
      mode: 'thumbnail',
    ),
    ScanJob(
      title: '人脸聚类复算',
      status: '已完成',
      progress: 1,
      detail: '本轮合并了 2 个相似簇，人物标签更稳定',
      sourceId: 'source_nas',
      sourceName: 'UGREEN HomeMedia',
      rootPath: '/Volumes/UGREEN/HomeMedia',
      mode: 'people',
    ),
  ];

  static const signals = [
    MemoryStat(label: '猫类识别准确率', value: '94%'),
    MemoryStat(label: '人物待确认', value: '6'),
    MemoryStat(label: '重复照片建议', value: '38'),
  ];

  static const assets = [
    MediaAsset(
      assetId: 'asset_cat_001',
      sourceId: 'source_nas',
      sourceName: 'UGREEN HomeMedia',
      fileName: 'cat_sleeping.jpg',
      relativePath: 'pets/cat_sleeping.jpg',
      mediaKind: 'image',
      smartAlbumType: 'pet',
      thumbnailUrl: null,
      sizeBytes: 245678,
      modifiedAt: '2026-03-18T10:00:00Z',
      rootPath: '/Volumes/UGREEN/HomeMedia',
    ),
    MediaAsset(
      assetId: 'asset_trip_001',
      sourceId: 'source_nas',
      sourceName: 'UGREEN HomeMedia',
      fileName: 'trip_beach.png',
      relativePath: 'travel/trip_beach.png',
      mediaKind: 'image',
      smartAlbumType: 'travel',
      thumbnailUrl: null,
      sizeBytes: 198765,
      modifiedAt: '2026-03-17T09:00:00Z',
      rootPath: '/Volumes/UGREEN/HomeMedia',
    ),
    MediaAsset(
      assetId: 'asset_doc_001',
      sourceId: 'source_nas',
      sourceName: 'UGREEN HomeMedia',
      fileName: 'screen_shot_001.png',
      relativePath: 'screens/screen_shot_001.png',
      mediaKind: 'image',
      smartAlbumType: 'document',
      thumbnailUrl: null,
      sizeBytes: 99876,
      modifiedAt: '2026-03-16T08:00:00Z',
      rootPath: '/Volumes/UGREEN/HomeMedia',
    ),
  ];

  static const corrections = [
    CorrectionRecord(
      correctionId: 'cor_001',
      assetId: 'asset_cat_001',
      kind: 'album_label',
      fromValue: 'pet',
      toValue: 'daily',
      createdAt: '2026-03-18T10:30:00Z',
    ),
  ];

  static const dashboard = DashboardData(
    stats: heroStats,
    sources: sources,
    smartAlbums: albums,
    signals: signals,
    recentEvents: memoryEvents,
    scanJobs: scanJobs,
    people: people,
  );
}
