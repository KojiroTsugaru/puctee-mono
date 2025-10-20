# Supabase Realtime Setup Guide

This guide explains how to set up Supabase Realtime for real-time location sharing, replacing the current Redis-based WebSocket implementation.

## Why Migrate to Supabase Realtime?

- ✅ **No Redis needed**: Supabase Realtime replaces Redis Pub/Sub
- ✅ **Simpler architecture**: Direct database-to-client communication
- ✅ **Cost savings**: Eliminate Redis hosting costs
- ✅ **Better scalability**: Supabase handles connection management
- ✅ **Built-in features**: Presence, broadcast, and postgres_changes

## Architecture Comparison

### Current (Redis-based):
```
iOS App → FastAPI WebSocket → Redis Pub/Sub → FastAPI → PostgreSQL
```

### With Supabase Realtime:
```
iOS App → Supabase Realtime → PostgreSQL
         ↓
FastAPI → PostgreSQL (for REST API only)
```

## Step 1: Enable Realtime in Supabase

1. Go to your Supabase Dashboard
2. Navigate to **Database** > **Replication**
3. Enable replication for the `locations` table:
   - Click on the `locations` table
   - Toggle "Enable Replication"
   - Save changes

## Step 2: Configure Row Level Security (RLS)

Enable RLS for the `locations` table to secure real-time updates:

```sql
-- Enable RLS
ALTER TABLE locations ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to read all locations for their plans
CREATE POLICY "Users can view locations for their plans"
ON locations FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM plan_participants pp
    WHERE pp.plan_id = locations.plan_id
    AND pp.user_id = auth.uid()::integer
  )
);

-- Allow authenticated users to insert their own locations
CREATE POLICY "Users can insert their own locations"
ON locations FOR INSERT
WITH CHECK (user_id = auth.uid()::integer);

-- Allow users to update their own locations
CREATE POLICY "Users can update their own locations"
ON locations FOR UPDATE
USING (user_id = auth.uid()::integer);
```

**Note**: If you're not using Supabase Auth, you can use a simpler policy or disable RLS for development.

## Step 3: iOS App Integration

### Install Supabase Swift SDK

Add to your `Package.swift` or Xcode:

```swift
dependencies: [
    .package(url: "https://github.com/supabase/supabase-swift", from: "2.0.0")
]
```

### Initialize Supabase Client

```swift
import Supabase

let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://your-project.supabase.co")!,
    supabaseKey: "your-anon-key"
)
```

### Subscribe to Location Updates

```swift
// Subscribe to location changes for a specific plan
let channel = supabase.realtime.channel("locations:\(planId)")

channel
    .on(.postgresChanges(
        event: .insert,
        schema: "public",
        table: "locations",
        filter: "plan_id=eq.\(planId)"
    )) { payload in
        // Handle new location
        if let location = payload.new as? [String: Any] {
            print("New location: \(location)")
            // Update UI with new location
        }
    }
    .on(.postgresChanges(
        event: .update,
        schema: "public",
        table: "locations",
        filter: "plan_id=eq.\(planId)"
    )) { payload in
        // Handle location update
        if let location = payload.new as? [String: Any] {
            print("Updated location: \(location)")
            // Update UI
        }
    }
    .subscribe()

// Don't forget to unsubscribe when done
// channel.unsubscribe()
```

### Send Location Updates

Instead of sending through WebSocket, use the REST API:

```swift
// Update location via FastAPI
let locationData = LocationUpdateRequest(
    latitude: location.coordinate.latitude,
    longitude: location.coordinate.longitude,
    name: "Current Location"
)

// POST to /api/plans/{planId}/location
// This will insert into the database, and Supabase Realtime
// will automatically broadcast to all subscribers
```

## Step 4: Backend Changes (Optional)

The FastAPI backend can remain mostly unchanged. The WebSocket endpoints can be:

1. **Kept as-is**: For backward compatibility
2. **Removed**: If fully migrating to Supabase Realtime
3. **Simplified**: Remove Redis dependency, keep WebSocket for other features

### Option A: Remove WebSocket Endpoints

If fully migrating to Supabase Realtime:

```bash
# Remove WebSocket router
rm app/api/routers/websocket.py  # if exists

# Remove Redis dependency
# Update requirements.txt to remove redis
```

### Option B: Keep WebSocket for Other Features

If you want to keep WebSocket for non-location features:

```python
# app/api/routers/websocket.py
# Keep the WebSocket implementation but remove location-specific code
# Use for other real-time features like notifications, typing indicators, etc.
```

## Step 5: Testing

### Test Realtime Connection

```swift
// In your iOS app
let channel = supabase.realtime.channel("test")
channel.on(.system) { message in
    print("System message: \(message)")
}
channel.subscribe { status, error in
    if status == .subscribed {
        print("✅ Connected to Supabase Realtime")
    } else if let error = error {
        print("❌ Error: \(error)")
    }
}
```

### Test Location Broadcasting

1. Open the app on two devices/simulators
2. Join the same plan
3. Move one device
4. Verify the other device receives the location update in real-time

## Step 6: Monitor Performance

In Supabase Dashboard:

1. Go to **Settings** > **Usage**
2. Monitor:
   - Realtime connections
   - Realtime messages
   - Database bandwidth

## Troubleshooting

### Connection Issues

```
Error: WebSocket connection failed
```

**Solution**:
- Check SUPABASE_URL and SUPABASE_ANON_KEY are correct
- Verify Replication is enabled for `locations` table
- Check network connectivity

### RLS Policy Errors

```
Error: new row violates row-level security policy
```

**Solution**:
- Verify RLS policies are correctly configured
- For development, you can temporarily disable RLS:
  ```sql
  ALTER TABLE locations DISABLE ROW LEVEL SECURITY;
  ```

### No Updates Received

```
Connected but not receiving location updates
```

**Solution**:
- Verify the filter in your subscription matches the data
- Check that Replication is enabled
- Ensure the channel name is correct

## Migration Checklist

- [ ] Enable Replication for `locations` table in Supabase
- [ ] Configure RLS policies (or disable for development)
- [ ] Install Supabase Swift SDK in iOS app
- [ ] Update iOS app to use Supabase Realtime
- [ ] Test real-time location updates
- [ ] Remove Redis dependency (optional)
- [ ] Update deployment scripts
- [ ] Monitor performance in Supabase Dashboard

## Cost Comparison

### Before (Redis + FastAPI WebSocket):
- Redis (Upstash): ~$5-10/month
- Additional complexity in deployment

### After (Supabase Realtime):
- Included in Supabase Free tier
- Up to 200 concurrent connections
- 2GB bandwidth/month

**Savings**: ~$5-10/month + reduced complexity

## Additional Resources

- [Supabase Realtime Docs](https://supabase.com/docs/guides/realtime)
- [Supabase Swift SDK](https://github.com/supabase/supabase-swift)
- [Realtime Broadcast](https://supabase.com/docs/guides/realtime/broadcast)
- [Postgres Changes](https://supabase.com/docs/guides/realtime/postgres-changes)
