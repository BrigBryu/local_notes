# Local Notes

An offline-only Flutter app for fast local note management with full-text search.

## Overview

Local Notes is built for **speed** and **privacy** - everything stays on your device. No network calls, no cloud sync, just lightning-fast local storage with SQLite + FTS5.

### Key Features

- ✅ **Offline-first**: No network dependencies
- ⚡ **Ultra-fast search**: < 50ms for 1000+ notes using FTS5
- 📝 **Markdown support**: Rich text notes with tags
- 🔒 **Privacy-focused**: All data stays local
- 🎯 **Performance-optimized**: Cold start < 500ms

## Performance Benchmarks

Our performance tests validate these requirements:

- **Search Performance**: All searches complete in < 50ms
- **Bulk Operations**: 1000 notes inserted in ~200ms
- **Memory Efficient**: SQLite with optimized indices
- **FTS5 Integration**: Full-text search with ranking

### Database Schema

```sql
-- Notes table
CREATE TABLE notes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  body_md TEXT NOT NULL,
  tags TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

-- FTS5 virtual table for full-text search
CREATE VIRTUAL TABLE notes_fts USING fts5(
  title, 
  body_md, 
  content='notes', 
  content_rowid='id'
);
```

## Architecture

- **Domain Layer**: `lib/domain/` - Core entities (Note)
- **Data Layer**: `lib/data/` - Database provider with SQLite
- **Provider Layer**: `lib/providers/` - Riverpod state management
- **Tests**: Comprehensive unit tests with performance benchmarks

## Getting Started

### Prerequisites

- Flutter 3.22+ with Dart 3.x
- SQLite support (built-in on all platforms)

### Installation

```bash
# Clone the repository
git clone git@github.com:BrigBryu/local_notes.git
cd local_notes

# Install dependencies
flutter pub get

# Run tests
flutter test

# Run performance benchmark
cd tool && dart run seed_and_benchmark.dart

# Run the app
flutter run
```

### Development

```bash
# Run tests with coverage
flutter test --coverage

# Analyze code
flutter analyze

# Format code
dart format .
```

## Performance Results

Latest benchmark results from CI:

- ✅ **1000 notes** inserted and indexed
- ✅ **All searches < 50ms** (avg ~1-2ms)
- ✅ **FTS5 ranking** working correctly
- ✅ **Edge cases** handled (empty search, no results)

## Tech Stack

- **Flutter 3.22** - UI framework
- **Dart 3.x** - Programming language  
- **SQLite + FTS5** - Local database with full-text search
- **Riverpod** - State management
- **sqflite** - SQLite plugin for Flutter
- **sqflite_common_ffi** - Testing with in-memory database

## License

This project is a demonstration of high-performance local data management in Flutter.
