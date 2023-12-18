# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- 新增解析帖子楼层正文`postmessage`中的隐藏部分。
- 新增解析帖子中由于积分不足而隐藏的部分。
- 新增解析帖子中回复后才可见的部分。

### Fixed

- 修复无法在具有多个隐藏部分的帖子中购买的问题。
- 修复在github构建流水线中发布release时描述信息被空信息覆盖的问题。
- 修复当帖子的回复评分为扣分时显示总评分为空的问题。

## [0.1.1] - 2023-12-17

### Fixed

- 修复主页帖子跳转失败的问题。

## [0.1.0] - 2023-12-16

### Added

- 首个release，新增基本的登录，看帖，回复等功能。
