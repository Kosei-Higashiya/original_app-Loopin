# Next Steps for Graph Fix Migration

## What Was Done

This PR successfully migrates the graph display functionality from jsbundling-rails/esbuild to importmap-rails with CDN loading. All code changes are complete and have passed security analysis.

## What You Need to Do

### 1. Install the New Gem

After merging this PR, run:

```bash
bundle install
```

This will install the `importmap-rails` gem and remove `jsbundling-rails`.

### 2. Optional: Clean Up Node Modules (if any)

Since we no longer need npm dependencies, you can optionally remove:

```bash
rm -rf node_modules
rm yarn.lock  # or package-lock.json if using npm
```

Note: We kept package.json with minimal content to avoid breaking any existing workflows that might expect it.

### 3. Test the Graph Functionality

1. Start the Rails server:
   ```bash
   ./bin/dev
   # or
   rails server
   ```

2. Navigate to the graphs page:
   - Go to `/habits` (habits list page)
   - Click "📊 グラフを見る" button
   - Or directly visit `/habits/graphs`

3. Verify both charts display correctly:
   - **日別達成率（直近30日間）** - Line chart showing daily achievement rate
   - **習慣別達成率（直近30日間）** - Bar chart showing per-habit achievement rate

### 4. What to Look For

✅ **Expected Behavior:**
- Both charts should render without errors
- Console should show: "✅ chart_controller connected"
- Hovering over charts should show tooltips with achievement data
- No JavaScript errors in browser console
- No need to run any build commands

❌ **If You See Issues:**
- Check browser console for JavaScript errors
- Verify internet connection (charts load from CDN)
- Clear browser cache and reload
- Check that the importmap tags are present in page source

### 5. Browser Developer Tools Check

Open browser DevTools (F12) and check:

1. **Console Tab**: Should show "✅ chart_controller connected" (2 times, one for each chart)
2. **Network Tab**: Should show successful loads from cdn.jsdelivr.net for:
   - turbo-rails
   - stimulus
   - chart.js
3. **No Errors**: No red error messages

### 6. Production Deployment Notes

When deploying to production:

1. Run `bundle install` on the production server
2. No need to run any JavaScript build commands
3. Ensure Content Security Policy (if configured) allows loading from:
   - `https://cdn.jsdelivr.net`
4. The application will work immediately without any additional setup

### 7. Rollback Plan (if needed)

If you need to rollback for any reason:

```bash
git revert HEAD~4..HEAD
bundle install
yarn install
yarn build
```

See `docs/GRAPH_FIX_MIGRATION.md` for detailed rollback instructions.

## Benefits of This Change

- ✅ No build process required
- ✅ Faster development cycle
- ✅ Simplified deployment
- ✅ Reduced complexity
- ✅ Fixed bug in second chart
- ✅ Smaller repository (no node_modules)

## Support

If you encounter any issues after merging:

1. Check `docs/GRAPH_FIX_MIGRATION.md` for detailed technical information
2. Review `docs/GRAPH_FEATURE.md` for updated feature documentation
3. Verify browser console for specific error messages
4. Ensure internet connectivity for CDN access

## Migration Verification Checklist

After merging and deploying, verify:

- [ ] `bundle install` completed successfully
- [ ] Rails server starts without errors
- [ ] Graphs page loads at `/habits/graphs`
- [ ] Both charts display correctly
- [ ] Tooltips work when hovering over charts
- [ ] No JavaScript errors in console
- [ ] Page loads quickly without build delay

If all items are checked, the migration is successful! ✅
