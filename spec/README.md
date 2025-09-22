# RSpec Tests for Posts Feature

This directory contains comprehensive RSpec tests for the post functionality in the Loopin habit-tracking application.

## Test Structure

### Model Tests (`spec/models/post_spec.rb`)
Tests for the `Post` model covering:
- **Associations**: Relations with User, Habit, Tags, and Likes
- **Validations**: Content presence and length validation
- **Scopes**: Recent ordering, association includes, and tag filtering
- **Methods**: 
  - `tag_list` - Returns comma-separated tag names
  - `tag_list=` - Parses and assigns tags from comma-separated string
  - `liked_by?` - Checks if a user has liked the post
- **Ransack Configuration**: Search attributes and associations

### Request Tests (`spec/requests/posts_api_spec.rb`)
Integration tests for the `PostsController` covering:
- **GET /posts**: Index page with filtering and search
- **GET /posts/liked**: Liked posts page 
- **GET /posts/new**: New post form
- **POST /posts**: Post creation with validation
- **GET /posts/:id/edit**: Edit form with authorization
- **PATCH /posts/:id**: Post updates with authorization
- **DELETE /posts/:id**: Post deletion with authorization
- **Authentication**: All endpoints require user authentication

## Factories (`spec/factories/`)
Test data factories for:
- `users.rb` - User accounts with authentication
- `habits.rb` - Habit entries linked to users
- `tags.rb` - Tags for categorizing posts
- `posts.rb` - Posts with optional tag associations
- `likes.rb` - Like relationships between users and posts

## Test Configuration
- **RSpec Rails** setup with Devise integration
- **FactoryBot** for test data generation
- **Shoulda Matchers** for concise validation and association tests
- **SQLite** database for test isolation
- **Asset compilation** configured for view rendering tests

## Running Tests

```bash
# Run all post-related tests
bundle exec rspec spec/

# Run only model tests
bundle exec rspec spec/models/post_spec.rb

# Run only request tests  
bundle exec rspec spec/requests/posts_api_spec.rb

# Run with documentation format
bundle exec rspec spec/ --format documentation
```

## Test Coverage
- ✅ 23 model tests covering all associations, validations, and methods
- ✅ 28 request tests covering all controller actions and edge cases
- ✅ Authentication and authorization scenarios
- ✅ Error handling and validation failures
- ✅ CRUD operations with proper permissions

All tests pass successfully, ensuring the post functionality works correctly.