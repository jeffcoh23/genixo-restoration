package com.genixo.restoration;

import android.app.DownloadManager;
import android.content.Context;
import android.net.Uri;
import android.os.Bundle;
import android.os.Environment;
import android.os.Message;
import android.webkit.CookieManager;
import android.webkit.DownloadListener;
import android.webkit.URLUtil;
import android.webkit.WebResourceRequest;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Toast;

import com.getcapacitor.BridgeActivity;
import com.getcapacitor.BridgeWebChromeClient;

/**
 * The web app is loaded remotely (capacitor.config.ts server.url). Two things the hosted
 * app relies on don't work in a bare Android WebView the way they do in iOS WKWebView:
 *
 *  1. File downloads — the photos ZIP (<a download>), the DFR report PDF
 *     (window.open(_blank)) and blob attachment links (target="_blank"). A plain WebView
 *     ignores download/_blank navigations.
 *  2. (Camera capture is handled by Capacitor's BridgeWebChromeClient once the CAMERA
 *     permission is declared in the manifest — we preserve it by subclassing, not replacing.)
 *
 * This adds a DownloadListener (with the session cookie forwarded so authenticated
 * endpoints succeed) and an onCreateWindow handler that routes _blank targets back into
 * the main WebView so they share the same cookie jar.
 */
public class MainActivity extends BridgeActivity {

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        WebView webView = getBridge().getWebView();

        // _blank / window.open targets must open in-app: external browsers don't carry the
        // HttpOnly session cookie and would 401 on the authenticated report/blob endpoints.
        webView.getSettings().setSupportMultipleWindows(true);
        webView.getSettings().setJavaScriptCanOpenWindowsAutomatically(true);

        configureDownloads(webView);
        configureWindowHandling(webView);
    }

    /**
     * Routes WebView downloads through Android's DownloadManager, forwarding the WebView's
     * cookies. The session cookie is HttpOnly (invisible to JS) but CookieManager can read
     * it natively, so authenticated downloads (photos ZIP, DFR PDF, blob attachments) work.
     * DownloadManager follows redirects, covering rails_blob -> signed S3 in production.
     */
    private void configureDownloads(WebView webView) {
        webView.setDownloadListener(new DownloadListener() {
            @Override
            public void onDownloadStart(String url, String userAgent, String contentDisposition,
                                        String mimeType, long contentLength) {
                try {
                    String fileName = URLUtil.guessFileName(url, contentDisposition, mimeType);

                    DownloadManager.Request request = new DownloadManager.Request(Uri.parse(url));
                    String cookies = CookieManager.getInstance().getCookie(url);
                    if (cookies != null) {
                        request.addRequestHeader("Cookie", cookies);
                    }
                    if (userAgent != null) {
                        request.addRequestHeader("User-Agent", userAgent);
                    }
                    request.setMimeType(mimeType);
                    request.setTitle(fileName);
                    request.allowScanningByMediaScanner();
                    request.setNotificationVisibility(
                            DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED);
                    request.setDestinationInExternalPublicDir(
                            Environment.DIRECTORY_DOWNLOADS, fileName);

                    DownloadManager dm =
                            (DownloadManager) getSystemService(Context.DOWNLOAD_SERVICE);
                    if (dm != null) {
                        dm.enqueue(request);
                        Toast.makeText(getApplicationContext(),
                                "Downloading " + fileName, Toast.LENGTH_SHORT).show();
                    }
                } catch (Exception e) {
                    Toast.makeText(getApplicationContext(),
                            "Download failed", Toast.LENGTH_SHORT).show();
                }
            }
        });
    }

    /**
     * Capacitor's BridgeWebChromeClient handles camera/file-chooser permission prompts, so we
     * subclass it (rather than replace it) and add only onCreateWindow. When the page opens a
     * _blank target (e.g. the DFR report's window.open, or attachment links), we capture the
     * URL and load it back into the main WebView — keeping the session cookie. Attachment
     * responses then trip the DownloadListener; inline blobs render in-app.
     */
    private void configureWindowHandling(WebView webView) {
        webView.setWebChromeClient(new BridgeWebChromeClient(getBridge()) {
            @Override
            public boolean onCreateWindow(WebView view, boolean isDialog,
                                          boolean isUserGesture, Message resultMsg) {
                WebView href = new WebView(view.getContext());
                href.setWebViewClient(new WebViewClient() {
                    @Override
                    public boolean shouldOverrideUrlLoading(WebView tempView,
                                                            WebResourceRequest request) {
                        view.loadUrl(request.getUrl().toString());
                        return true;
                    }
                });
                WebView.WebViewTransport transport = (WebView.WebViewTransport) resultMsg.obj;
                transport.setWebView(href);
                resultMsg.sendToTarget();
                return true;
            }
        });
    }
}
