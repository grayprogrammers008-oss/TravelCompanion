# Unsplash API Setup Guide

This guide will help you set up the Unsplash API to fetch real destination images for the Travel Crew app.

---

## 🎯 What You'll Get

Beautiful, high-quality travel destination images that automatically load for:
- Bali
- Paris
- Tokyo
- New York
- London
- Rome
- Dubai
- Singapore
- And many more destinations!

---

## 📝 Step-by-Step Setup (5 Minutes)

### Step 1: Create Unsplash Developer Account

1. Go to: **https://unsplash.com/developers**
2. Click **"Register as a developer"** (or **"Sign up"** if you don't have an account)
3. Fill in your details and verify your email

### Step 2: Create a New Application

1. Once logged in, go to: **https://unsplash.com/oauth/applications**
2. Click **"New Application"**
3. Read and accept the terms:
   - ✅ **API Use Terms**
   - ✅ **Unsplash API Guidelines**
4. Click **"Accept terms"**

### Step 3: Fill in Application Details

**Application name**: `Travel Crew MVP`

**Description**:
```
Travel planning and group travel management app that displays beautiful destination images to inspire travelers.
```

Click **"Create application"**

### Step 4: Get Your Access Key

1. Once created, you'll see your application dashboard
2. Scroll down to find **"Keys"** section
3. Copy your **"Access Key"** (it starts with something like `abcd1234...`)

**IMPORTANT**: Keep this key secret! Don't share it publicly.

### Step 5: Add Key to Your App

Open the file:
```
lib/core/services/image_service.dart
```

Find this line (around line 18):
```dart
static const String _accessKey = 'YOUR_UNSPLASH_ACCESS_KEY_HERE';
```

Replace `YOUR_UNSPLASH_ACCESS_KEY_HERE` with your actual access key:
```dart
static const String _accessKey = 'abcd1234yourrealkeyhere';
```

**Save the file!**

---

## ✅ You're Done!

The app will now fetch beautiful destination images from Unsplash!

---

## 🎨 How It Works

### Automatic Image Fetching
When a trip card is displayed, the app:
1. Checks if we already have a cached image
2. If not, searches Unsplash for destination images
3. Downloads and displays the image
4. Caches it for 7 days to reduce API calls

### Smart Search Queries
The service automatically maps destinations to better search terms:
- "Bali" → "bali indonesia temple beach"
- "Paris" → "paris eiffel tower france"
- "Tokyo" → "tokyo japan skyline"
- And more...

### Graceful Fallback
If the API is unavailable or rate-limited:
- Shows beautiful gradient backgrounds (no errors!)
- App continues working perfectly
- Images will load when API is available again

---

## 📊 API Limits (Free Tier)

**Unsplash Free Tier**:
- ✅ 50 requests per hour
- ✅ 5,000 requests per month
- ✅ Perfect for development and testing!

**Tips to stay within limits**:
- Images are cached for 7 days
- Only new destinations trigger API calls
- Most users will see cached images

**For production** (when you have many users):
- Consider upgrading to Unsplash Plus ($9.99/month)
- Or implement your own image storage with user uploads

---

## 🧪 Testing

### Test That Images Load

1. Run the app:
   ```bash
   flutter run
   ```

2. Create a new trip with destination:
   - "Bali"
   - "Paris"
   - "Tokyo"

3. You should see beautiful real images instead of gradients!

### Check the Console

You should see logs like:
```
📸 Image by John Doe on Unsplash
```

If you see warnings:
```
⚠️  Unsplash API key not configured. Using gradient fallback.
```
→ Double-check that you added your API key correctly

---

## 🔒 Security Best Practices

### For Development
✅ It's okay to hardcode the key in `image_service.dart`
✅ Just don't commit it to public GitHub repos

### For Production
1. **Use Environment Variables**:
   ```dart
   static const String _accessKey = String.fromEnvironment('UNSPLASH_KEY');
   ```

2. **Add to `.gitignore`**:
   ```
   .env
   *.key
   ```

3. **Use Flutter Secrets**:
   - Consider using `flutter_dotenv` package
   - Store keys in `.env` file
   - Load at runtime

---

## 🐛 Troubleshooting

### Images Not Loading?

**Check 1**: API Key
- Make sure you copied the entire key
- No extra spaces before/after the key
- Key should be between quotes: `'your-key-here'`

**Check 2**: Internet Connection
- Images won't load without internet
- Gradients will show as fallback

**Check 3**: Rate Limit
- Free tier: 50 requests/hour
- Wait an hour if limit reached
- Cached images will still work

**Check 4**: Console Logs
Look for error messages:
- `❌ Error fetching image` → Check your key
- `⚠️  API rate limit reached` → Wait or upgrade plan
- `📸 Image by...` → Working correctly! ✅

### Still Having Issues?

1. **Test the API key** at: https://api.unsplash.com/photos/random?client_id=YOUR_KEY
   - Replace `YOUR_KEY` with your actual key
   - Should return JSON data

2. **Check application status** at: https://unsplash.com/oauth/applications
   - Make sure your app is "Active"

3. **Regenerate key** if needed:
   - Go to your application dashboard
   - Scroll to Keys section
   - Click "Regenerate" if needed

---

## 📸 Attribution

Unsplash requires that we give credit to photographers. Our app automatically:
- Logs photographer names in console
- (Future): Display "Photo by X on Unsplash" in image metadata

---

## 🎯 Next Steps

Once images are working:
1. ✅ Test with various destinations
2. ✅ Check that caching works (images load faster on 2nd view)
3. ✅ Try with network off (gradients should appear)
4. ✅ Move on to next feature!

---

## 🔗 Useful Links

- **Unsplash Developers**: https://unsplash.com/developers
- **API Documentation**: https://unsplash.com/documentation
- **Guidelines**: https://help.unsplash.com/en/collections/1463188-unsplash-api
- **Rate Limits**: https://unsplash.com/documentation#rate-limiting

---

**Enjoy beautiful destination images in your Travel Crew app!** 🎉✈️
