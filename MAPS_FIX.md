# Google Maps Authorization Fix

## Current Issue
Google Maps SDK showing blank screen with authorization failure:
```
E/Google Android Maps SDK: Authorization failure
E/Google Android Maps SDK: API Key: [empty]
```

## Your Configuration
- **Package Name**: `lpg.ops.arungas`
- **SHA-1 Fingerprint**: `09:80:C0:40:9A:AE:9D:84:65:2A:17:E1:CA:BD:BB:59:50:27:E5:7D`
- **API Key**: `AIzaSyAtp2o9WzKooAuCp68rMKhMcdtr6BRNQjs`

## Step-by-Step Fix

### 1. Configure Google Cloud Console

Go to: https://console.cloud.google.com/

#### Step 1.1: Enable Maps SDK for Android
1. Navigate to **APIs & Services** > **Library**
2. Search for "Maps SDK for Android"
3. Click on it and press **ENABLE** (if not already enabled)

#### Step 1.2: Configure API Key Restrictions
1. Go to **APIs & Services** > **Credentials**
2. Find your API key: `AIzaSyAtp2o9WzKooAuCp68rMKhMcdtr6BRNQjs`
3. Click on the key to edit it
4. Under **Application restrictions**:
   - Select **Android apps**
   - Click **+ Add an item**
   - Enter:
     - **Package name**: `lpg.ops.arungas`
     - **SHA-1 certificate fingerprint**: `09:80:C0:40:9A:AE:9D:84:65:2A:17:E1:CA:BD:BB:59:50:27:E5:7D`
5. Under **API restrictions**:
   - Select **Restrict key**
   - Check **Maps SDK for Android**
   - Check **Places API** (if using place search)
   - Check **Directions API** (if using directions)
6. Click **SAVE**

### 2. Rebuild the App

After configuring Google Cloud Console:

```bash
# Clean build
cd C:\Users\om\Documents\AndroidStudioProjects\domestic_app
flutter clean
flutter pub get

# Rebuild
flutter build apk --debug
```

Or in Android Studio:
1. Build > Clean Project
2. Build > Rebuild Project
3. Run the app

### 3. Verify API Key is Loaded

When you rebuild, check the build output for:
```
Maps API Key loaded: AIzaSyAtp2...
```

This confirms the key is being read from `local.properties`.

### 4. Test Maps

1. Launch the app
2. Navigate to **Ujjwala Installations**
3. Switch to **Map View** tab
4. You should see markers on the map

### 5. Troubleshooting

#### If still showing blank:

**Check Logcat for specific errors:**
```bash
adb logcat | grep -i "maps\|authorization"
```

**Common issues:**

1. **API key not configured in Cloud Console**
   - Solution: Follow Step 1 above carefully

2. **Wrong SHA-1 fingerprint**
   - Debug keystore SHA-1: `09:80:C0:40:9A:AE:9D:84:65:2A:17:E1:CA:BD:BB:59:50:27:E5:7D`
   - Get your actual SHA-1:
     ```bash
     cd C:\Users\om\.android
     keytool -list -v -keystore debug.keystore -alias androiddebugkey -storepass android -keypass android
     ```
   - Update in Google Cloud Console if different

3. **Maps SDK not enabled**
   - Go to Cloud Console > APIs & Services > Dashboard
   - Verify "Maps SDK for Android" shows as enabled

4. **Billing not enabled**
   - Google Maps requires billing to be enabled (free tier available)
   - Go to Cloud Console > Billing
   - Enable billing for your project

5. **API key restrictions too strict**
   - Temporarily remove all restrictions to test
   - If it works, add restrictions back one by one

#### If key is still empty in logs:

**Verify local.properties:**
```bash
type android\local.properties | findstr MAPS
```

Should show: `MAPS_API_KEY=AIzaSyAtp2o9WzKooAuCp68rMKhMcdtr6BRNQjs`

**Check manifestPlaceholders:**
Open `android/app/build/intermediates/merged_manifests/debug/AndroidManifest.xml` after build and search for `com.google.android.geo.API_KEY` - it should show your actual key, not `${mapsApiKey}`.

### 6. Alternative: Hardcode for Testing (NOT for production)

If you want to test quickly, you can temporarily hardcode the key in AndroidManifest.xml:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="AIzaSyAtp2o9WzKooAuCp68rMKhMcdtr6BRNQjs"/>
```

**WARNING**: Don't commit this! Revert to `${mapsApiKey}` before committing.

## Expected Result

After fixing, you should see:
- ✅ Map loads with proper tiles
- ✅ Markers showing at installation locations
- ✅ No authorization errors in logcat
- ✅ Map interaction (zoom, pan) works smoothly

## Getting SHA-1 for Production

For release builds, you'll need the release keystore SHA-1:

```bash
keytool -list -v -keystore C:\path\to\your\release.keystore -alias your_alias
```

Add this SHA-1 to Google Cloud Console as well for production builds to work.

## Next Steps

1. **Now**: Configure Google Cloud Console (Step 1)
2. **Then**: Rebuild app (Step 2)
3. **Test**: Open Map View in app
4. **If issues**: Check troubleshooting section (Step 5)

## Important Notes

- Google Maps requires **billing enabled** (free tier: $200/month credit)
- Changes in Google Cloud Console may take **5-10 minutes** to propagate
- Always keep `local.properties` in `.gitignore` (it already is)
- For production, use environment variables or secure key management

---

**Status**: Configuration updated in build.gradle. Next: Configure Google Cloud Console.
