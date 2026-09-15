"""Release guard regressions; no Apple account or public server required."""
import json
from pathlib import Path
import plistlib
import tempfile
import unittest
from unittest.mock import patch, MagicMock

import ios_release as release


class ReleaseTests(unittest.TestCase):
    def test_rejects_unusable_or_credentialed_endpoints(self):
        for value in ['http://sahsindan.com/api', 'https://localhost/api',
                      'https://192.168.1.2/api', 'https://example.com/api',
                      'https://app.example.com/api', 'https://app.test/api',
                      'https://sahsindan.com', 'https://sahsindan.com/api?key=secret',
                      'https://user:pass@sahsindan.com/api']:
            with self.subTest(value=value), self.assertRaises(ValueError):
                release.validate_url(value)

    def test_normalizes_valid_url(self):
        self.assertEqual(release.validate_url('https://sahsindan.com/api/'), 'https://sahsindan.com/api')

    @patch.object(release.socket, 'getaddrinfo', return_value=[(0, 0, 0, '', ('127.0.0.1', 443))])
    def test_rejects_private_dns(self, _):
        with self.assertRaises(ValueError):
            release.preflight('https://sahsindan.com/api')

    def test_rejects_secrets_in_flutter_asset(self):
        with tempfile.TemporaryDirectory() as directory, patch.object(release, 'MOBILE', Path(directory)):
            env = Path(directory) / '.env'
            for text in ['JWT_SECRET=private', 'API_BASE_URL=https://u:p@host/api',
                         'API_BASE_URL=https://host/api?token=private']:
                env.write_text(text)
                with self.assertRaises(ValueError):
                    release.check_asset_env()
            env.write_text('API_BASE_URL=http://localhost:8080/api\nLOG_NETWORK=true\n')
            release.check_asset_env()

    def test_http_redirects_are_not_followed(self):
        self.assertIsNone(release.NoRedirects().redirect_request(None, None, 302, '', {}, 'http://other/api'))

    @patch.object(release.socket, 'getaddrinfo', return_value=[(0, 0, 0, '', ('1.1.1.1', 443))])
    def test_preflight_checks_readiness_contract_and_auth(self, _):
        responses = []
        for status, body in [(200, {'status': 'ready'}), (401, {'error': {}}), (401, {'error': {}})]:
            response = MagicMock(status=status)
            response.__enter__.return_value = response
            response.read.return_value = json.dumps(body).encode()
            responses.append(response)
        with patch.object(release, 'build_opener') as opener:
            opener.return_value.open.side_effect = responses
            release.preflight('https://sahsindan.com/api')
            self.assertEqual(opener.return_value.open.call_count, 3)
            responses[0].read.return_value = b'{"status":"down"}'
            opener.return_value.open.side_effect = responses
            with self.assertRaises(ValueError):
                release.preflight('https://sahsindan.com/api')

    def test_native_release_keeps_ats_and_photo_permission(self):
        root = release.MOBILE / 'ios/Runner'
        live = plistlib.loads((root / 'Info.plist').read_bytes())
        debug = plistlib.loads((root / 'Info-Debug.plist').read_bytes())
        self.assertNotIn('NSAppTransportSecurity', live)
        self.assertTrue(live['NSPhotoLibraryUsageDescription'])
        self.assertTrue(debug.pop('NSAppTransportSecurity')['NSAllowsArbitraryLoads'])
        debug.pop('NSLocalNetworkUsageDescription')
        self.assertEqual(live, debug)

    def test_archive_rejects_stale_build_or_insecure_networking(self):
        with tempfile.TemporaryDirectory() as directory:
            archive = Path(directory)
            app = archive / 'Products/Applications/Runner.app'
            app.mkdir(parents=True)
            info = {'CFBundleIdentifier': 'com.sahsindan.app', 'CFBundleVersion': '7',
                    'NSPhotoLibraryUsageDescription': 'Select a listing photo'}
            for changes in [{'CFBundleVersion': '6'}, {'CFBundleIdentifier': 'com.example.app'},
                            {'NSAppTransportSecurity': {'NSAllowsArbitraryLoads': True}},
                            {'NSPhotoLibraryUsageDescription': ''}]:
                (app / 'Info.plist').write_bytes(plistlib.dumps({**info, **changes}))
                with self.subTest(changes=changes), self.assertRaises(ValueError):
                    release.validate_archive(archive, '7')
            (app / 'Info.plist').write_bytes(plistlib.dumps(info))
            with patch.object(release.subprocess, 'run') as verify:
                release.validate_archive(archive, '7')
                verify.assert_called_once()


if __name__ == '__main__':
    unittest.main()
