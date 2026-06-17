"use client";

import { useState, useEffect } from "react";

export function useLatestRelease() {
  const [downloadUrl, setDownloadUrl] = useState("https://github.com/Prahlad10Bhat/APPUPDATE/releases/latest");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch("https://api.github.com/repos/Prahlad10Bhat/APPUPDATE/releases/latest")
      .then((res) => {
        if (!res.ok) throw new Error("Failed to fetch latest release");
        return res.json();
      })
      .then((data) => {
        // Find Windows asset (.exe, .msi, or .zip)
        const windowsAsset = data.assets?.find((asset: any) => 
          asset.name.endsWith(".exe") || 
          asset.name.endsWith(".msi") || 
          asset.name.endsWith(".zip")
        );
        if (windowsAsset?.browser_download_url) {
          setDownloadUrl(windowsAsset.browser_download_url);
        } else if (data.assets?.[0]?.browser_download_url) {
          setDownloadUrl(data.assets[0].browser_download_url);
        }
      })
      .catch((err) => {
        console.error("Error fetching latest release:", err);
      })
      .finally(() => {
        setLoading(false);
      });
  }, []);

  return { downloadUrl, loading };
}
