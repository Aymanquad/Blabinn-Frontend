# Special Characters Fix in Friends Chat

## Problem
Users were unable to send special characters like `:`, `;`, `@`, etc. in friends chat. The characters were being replaced with random HTML entities or not displaying correctly.

## Root Cause
The backend was sanitizing message content by converting special characters to HTML entities (e.g., `:` becomes `&#x3A;`, `@` becomes `&#x40;`) to prevent XSS attacks. However, the frontend was not decoding these entities back to their original characters.

## Solution
1. **Created HTML Decoder Utility** (`lib/utils/html_decoder.dart`):
   - Added `HtmlDecoder.decodeHtmlEntities()` method to convert HTML entities back to original characters
   - Handles common HTML entities like `&lt;`, `&gt;`, `&quot;`, `&#x27;`, `&#x2F;`, `&amp;`

2. **Updated Message Model** (`lib/models/message.dart`):
   - Modified `fromJson()` method to decode HTML entities when parsing message content
   - Updated `displayContent` getter to ensure decoded content is always returned

3. **Updated Chat Bubble Widget** (`lib/widgets/chat_bubble.dart`):
   - Changed all instances of `message.content` to `message.displayContent` to use decoded content
   - This affects text messages, image captions, video captions, and system messages

4. **Updated Random Chat Screen** (`lib/screens/random_chat_screen.dart`):
   - Added HTML decoder import
   - Modified `_handleNewMessage()` to decode HTML entities when processing incoming messages
   - Updated message display to decode HTML entities in the UI

5. **Updated Chat Model** (`lib/models/chat.dart`):
   - Changed system message display to use `displayContent` instead of `content`

## Files Modified
- `lib/utils/html_decoder.dart` (new file)
- `lib/models/message.dart`
- `lib/widgets/chat_bubble.dart`
- `lib/screens/random_chat_screen.dart`
- `lib/models/chat.dart`

## Testing
The fix ensures that special characters like `:`, `;`, `@`, `&`, `<`, `>`, `"`, `'`, `/` are now displayed correctly in both friend chats and random chats.

## Backward Compatibility
The fix is backward compatible - messages that don't contain HTML entities will display normally, and messages with HTML entities will be properly decoded. 