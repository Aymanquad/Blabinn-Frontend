// Debug script to identify duplicate notification issue
void main() {
  print('🔍 Debugging Duplicate Notification Issue...\n');

  print('📋 Possible Sources of "Someone Sent an image" notification:');
  print('1. _showNotificationForMessage() - Old message handler');
  print('2. _handleNewMessageEvent() - New message handler');
  print('3. Background notification handler');
  print('4. Multiple notification streams');
  print('5. Other notification triggers\n');

  print('🔍 Debug Steps:');
  print('1. Check logs for "Called from:" messages');
  print('2. Look for multiple "showInAppNotificationForMessage called" entries');
  print('3. Check if both handlers are being triggered');
  print('4. Verify message content is empty for image messages');
  print('5. Check if notification stream is being triggered multiple times\n');

  print('📋 Expected Logs:');
  print('✅ Single notification:');
  print('   🔔 [SOCKET NOTIFICATION DEBUG] Called from: _handleNewMessageEvent');
  print('   🔔 [NOTIFICATION SERVICE DEBUG] showInAppNotificationForMessage called');
  print('   🔔 [APP DEBUG] *** NOTIFICATION RECEIVED IN STREAM ***\n');

  print('❌ Duplicate notification (problem):');
  print('   🔔 [SOCKET NOTIFICATION DEBUG] Called from: _showNotificationForMessage');
  print('   🔔 [SOCKET NOTIFICATION DEBUG] Called from: _handleNewMessageEvent');
  print('   🔔 [NOTIFICATION SERVICE DEBUG] showInAppNotificationForMessage called (2x)');
  print('   🔔 [APP DEBUG] *** NOTIFICATION RECEIVED IN STREAM *** (2x)\n');

  print('🎯 Solution:');
  print('- If both handlers are called: Disable one');
  print('- If stream triggered multiple times: Check for multiple listeners');
  print('- If message content empty: Check image message handling');
  print('- If background handler: Check Firebase messaging');

  print('\n✅ Run the app and check the logs to identify the source!');
}