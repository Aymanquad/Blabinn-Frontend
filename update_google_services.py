#!/usr/bin/env python3
"""
Script to update SHA-1 fingerprint in google-services.json
"""

import json
import os

def update_google_services():
    # Your current SHA-1 fingerprint from the signing report
    current_sha1 = "C5:8C:49:8B:5B:35:6A:93:D0:18:1B:37:AD:E7:73:78:39:42:ED:EF"
    
    # Remove colons and convert to lowercase for Firebase format
    formatted_sha1 = current_sha1.replace(":", "").lower()
    
    print(f"Current SHA-1: {current_sha1}")
    print(f"Formatted SHA-1: {formatted_sha1}")
    
    # Path to google-services.json
    google_services_path = "android/app/google-services.json"
    
    if not os.path.exists(google_services_path):
        print("❌ google-services.json not found!")
        return
    
    try:
        # Read the current file
        with open(google_services_path, 'r') as f:
            data = json.load(f)
        
        # Update the certificate hash in the first client
        if 'client' in data and len(data['client']) > 0:
            client = data['client'][0]
            if 'oauth_client' in client and len(client['oauth_client']) > 0:
                oauth_client = client['oauth_client'][0]
                if 'android_info' in oauth_client:
                    old_hash = oauth_client['android_info']['certificate_hash']
                    oauth_client['android_info']['certificate_hash'] = formatted_sha1
                    print(f"✅ Updated SHA-1 from {old_hash} to {formatted_sha1}")
        
        # Write the updated file
        with open(google_services_path, 'w') as f:
            json.dump(data, f, indent=2)
        
        print("✅ google-services.json updated successfully!")
        print("🔄 Please restart your app and try Google Sign-In again.")
        
    except Exception as e:
        print(f"❌ Error updating google-services.json: {e}")

if __name__ == "__main__":
    update_google_services() 