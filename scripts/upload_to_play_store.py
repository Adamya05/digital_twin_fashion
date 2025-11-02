#!/usr/bin/env python3
"""
Google Play Store Upload Script
Uploads Android App Bundle to Google Play Console
"""

import os
import sys
import json
import time
from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload


class PlayStoreUploader:
    def __init__(self, credentials_file, package_name):
        self.credentials_file = credentials_file
        self.package_name = package_name
        self.service = None
        self.edit_id = None
        
    def authenticate(self):
        """Authenticate with Google Play Console API"""
        try:
            credentials = service_account.Credentials.from_service_account_file(
                self.credentials_file,
                scopes=['https://www.googleapis.com/auth/androidpublisher']
            )
            self.service = build('androidpublisher', 'v3', credentials=credentials)
            print("✅ Authentication successful")
            return True
        except Exception as e:
            print(f"❌ Authentication failed: {e}")
            return False
    
    def upload_bundle(self, aab_file, track='internal'):
        """Upload App Bundle to Google Play"""
        try:
            # Create a new edit
            edit_request = self.service.edits().insert(
                packageName=self.package_name,
                body={}
            )
            edit_response = edit_request.execute()
            self.edit_id = edit_response['id']
            print(f"✅ Created edit: {self.edit_id}")
            
            # Upload bundle
            media = MediaFileUpload(aab_file, mimetype='application/octet-stream')
            upload_request = self.service.edits().bundles().upload(
                editId=self.edit_id,
                packageName=self.package_name,
                media_body=media
            )
            bundle_response = upload_request.execute()
            version_code = bundle_response['versionCode']
            print(f"✅ Uploaded bundle, version code: {version_code}")
            
            # Update track
            track_request = self.service.edits().tracks().update(
                editId=self.edit_id,
                packageName=self.package_name,
                track=track,
                body={'releases': [{'versionCodes': [version_code], 'status': 'draft'}]}
            )
            track_response = track_request.execute()
            print(f"✅ Updated track to: {track}")
            
            # Commit the edit
            commit_request = self.service.edits().commit(
                editId=self.edit_id,
                packageName=self.package_name
            )
            commit_response = commit_request.execute()
            print(f"✅ Edit committed successfully")
            
            return True
            
        except Exception as e:
            print(f"❌ Upload failed: {e}")
            return False
    
    def cleanup(self):
        """Cleanup temporary files"""
        if os.path.exists(self.credentials_file):
            os.remove(self.credentials_file)


def main():
    # Configuration
    service_account_file = 'service-account.json'
    package_name = os.getenv('PLAY_CONSOLE_PACKAGE_NAME', 'com.example.digital_twin_fashion')
    aab_file = 'app-release.aab'
    track = 'internal'  # internal, alpha, beta, production
    
    # Check required files
    if not os.path.exists(aab_file):
        print(f"❌ AAB file not found: {aab_file}")
        sys.exit(1)
    
    # Initialize uploader
    uploader = PlayStoreUploader(service_account_file, package_name)
    
    try:
        # Authenticate and upload
        if uploader.authenticate():
            if uploader.upload_bundle(aab_file, track):
                print("🎉 Upload completed successfully!")
            else:
                print("❌ Upload failed")
                sys.exit(1)
        else:
            sys.exit(1)
            
    finally:
        uploader.cleanup()


if __name__ == '__main__':
    main()