# Graph Display Fix - Migration to Importmap + CDN

## Issue
グラフ機能のJavaScriptの読み込み方をStimulus(現在)だと表示されないので、Importmap + CDNのやり方に変更しました。

## Summary of Changes

This migration changes the JavaScript loading strategy from jsbundling-rails/esbuild to importmap-rails with CDN loading. This eliminates the need for a JavaScript build process and simplifies the development workflow.

## Files Changed

### 1. Gemfile
- **Removed**: `gem 'jsbundling-rails'`
- **Added**: `gem 'importmap-rails'`

### 2. config/importmap.rb (New File)
Created importmap configuration that pins:
- `@hotwired/turbo-rails` from jsDelivr CDN
- `@hotwired/stimulus` from jsDelivr CDN  
- `chart.js` from jsDelivr CDN (ESM version)
- All Stimulus controller files

### 3. app/views/layouts/application.html.erb
- **Changed**: `<%= javascript_include_tag "application", "data-turbo-track": "reload", type: "module" %>`
- **To**: `<%= javascript_importmap_tags %>`

### 4. app/javascript/application.js
- **Changed**: `import "./controllers"` 
- **To**: `import "controllers/index"`

### 5. app/javascript/controllers/index.js
Updated import paths:
- **Changed**: `import { application } from "./application"`
- **To**: `import { application } from "controllers/application"`
- Same for controller imports

### 6. app/javascript/controllers/chart_controller.js
- **Removed**: `import { Chart, registerables } from "chart.js"`
- **Removed**: `Chart.register(...registerables)`
- **Changed to**: `import { Chart } from "chart.js"`

The ESM version of Chart.js from CDN has all components pre-registered.

### 7. app/views/habits/graphs.html.erb
**Bug Fix**: The second chart (習慣別達成率) was using incorrect data:
- **Changed**: `data-chart-type-value="line"` → `data-chart-type-value="bar"`
- **Changed**: `data-chart-data-value="<%= daily_chart_data.to_json %>"` → `data-chart-data-value="<%= habit_chart_data.to_json %>"`
- **Changed**: `data-chart-options-value="<%= daily_chart_options.to_json %>"` → `data-chart-options-value="<%= habit_chart_options.to_json %>"`

### 8. package.json
Simplified to minimal configuration:
- **Removed**: All dependencies (esbuild, stimulus, turbo-rails, chart.js)
- **Removed**: Build script
- Now contains only name and private flag

### 9. Procfile.dev
- **Removed**: `js: yarn build --watch` line
- Only web server process remains

## Benefits

1. **No Build Process**: No need to run `yarn build` or watch for changes
2. **Faster Development**: Changes to JavaScript files are immediately available
3. **CDN Performance**: Libraries loaded from fast CDN networks
4. **Smaller Repository**: No `node_modules` directory needed
5. **Simpler Deployment**: No JavaScript build step in deployment pipeline
6. **Bug Fix**: Corrected the second chart to display proper habit-specific data

## How It Works

### Before (jsbundling-rails)
```
JavaScript files → esbuild bundler → app/assets/builds/application.js → Browser
```

### After (importmap-rails)
```
JavaScript files → Importmap pins → Browser loads from CDN and local files directly
```

## Testing

The application should now:
1. Load faster in development (no build step)
2. Display both graphs correctly:
   - Daily achievement rate (line chart)
   - Habit-specific achievement rate (bar chart)
3. Show proper tooltips with achievement percentages

## Rollback Instructions

If needed to rollback:
1. Revert Gemfile changes
2. Restore original package.json
3. Restore original application.html.erb
4. Restore original JavaScript import paths
5. Delete config/importmap.rb
6. Run `bundle install` and `yarn install`
7. Restart with build process

## Notes

- The importmap approach is recommended by Rails 7+ for most applications
- CDN loading provides good performance and reliability
- For production, ensure proper Content Security Policy (CSP) settings allow CDN sources
- The jsDelivr CDN is highly reliable and provides automatic fallbacks

## Security

CodeQL analysis was run and found 0 security issues with these changes.
