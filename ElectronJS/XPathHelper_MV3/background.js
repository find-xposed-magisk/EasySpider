/**
 * Copyright 2011 Google Inc. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/**
 * @author opensource@google.com
 * @license Apache License, Version 2.0.
 *
 * Modified by the EasySpider project in 2026 for Chrome Manifest V3:
 * use an extension service worker and chrome.action.
 */

'use strict';

function handleRequest(request, sender, cb) {
  // Simply relay the request. This lets content.js talk to bar.js.
  if (!sender.tab || sender.tab.id === undefined) {
    return false;
  }
  chrome.tabs.sendMessage(sender.tab.id, request, cb);
  return true;
}
chrome.runtime.onMessage.addListener(handleRequest);

chrome.action.onClicked.addListener(function(tab) {
  chrome.tabs.sendMessage(tab.id, {type: 'toggleBar'});
});
