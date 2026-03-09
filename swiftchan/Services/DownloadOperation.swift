//
//  DownloadOperation.swift
//  swiftchan
//
//  Created on 5/9/21.
//

// This file is intentionally left minimal.
// Download management has moved to VideoPrefetcher which manages
// URLSessionDownloadTask instances directly, eliminating the
// NSOperation KVO race that caused EXC_BAD_ACCESS in __NSOQSchedule.
