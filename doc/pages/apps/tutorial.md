Title: Service Integrations Tutorial

[TOC]

This tutorial briefly describes creation of **a new service integration for Nuvola Player 3 from
scratch**. The goal is to write an integration script for *fake Happy Songs  service* shipped with
Nuvola Player and to prepare you to create your own service integration.
I'm looking forward to a code review ;-)

Prepare development environment
===============================

 1. Install Nuvola Player 3.
 2. Install [Nuvola SDK](https://github.com/tiliado/nuvolasdk).
    
        sudo pip3 install -U nuvolasdk

 3. Create a project directory `~/projects/nuvola-player` (or any other name, but don't forget to
    adjust paths in this tutorial).
    
        mkdir -p ~/projects/nuvola-player
     
 4. Create a new project with "nuvola://home.html" as a home URL.
    
        $ cd ~/projects/nuvola-player
        $ nuvolasdk new-project --name "Happy Songs" --url "nuvola://home.html"
        ...
        Finished!
        
        ./nuvola-app-happy-songs
        total 52
        drwxr-sr-x 1 fenryxo fenryxo   244 Dec  4 18:39 .
        drwxr-xr-x 1 fenryxo fenryxo    44 Dec  4 18:39 ..
        -rw-r--r-- 1 fenryxo fenryxo   103 Dec  4 18:39 CHANGELOG.md
        -rwxr-xr-x 1 fenryxo fenryxo    65 Dec  4 18:39 configure
        -rw-r--r-- 1 fenryxo fenryxo  3649 Dec  4 18:39 CONTRIBUTING.md
        drwxr-sr-x 1 fenryxo fenryxo   144 Dec  4 18:39 .git
        -rw-r--r-- 1 fenryxo fenryxo    91 Dec  4 18:39 .gitignore
        -rw-r--r-- 1 fenryxo fenryxo  2701 Dec  4 18:39 integrate.js
        -rw-r--r-- 1 fenryxo fenryxo  1246 Dec  3 18:57 LICENSE-BSD.txt
        -rw-r--r-- 1 fenryxo fenryxo 18424 Dec  3 18:57 LICENSE-CC-BY.txt
        -rw-r--r-- 1 fenryxo fenryxo   541 Dec  4 18:39 metadata.in.json
        -rw-r--r-- 1 fenryxo fenryxo  1079 Dec  4 18:39 README.md
        drwxr-sr-x 1 fenryxo fenryxo    60 Dec  3 18:57 src
    
 5. Copy a dumb example of a streaming website.
    
        :::sh
        cd ~/projects/nuvola-player/nuvola-app-happy-songs
        cp "$(nuvolasdk data-dir)/examples/home.html" .

 6. If you are not familiar with the [Git version control system][git],
    check [Git tutorial](https://try.github.io/levels/1/challenges/1)
    or [Pro Git Book](http://git-scm.com/book).

Metadata file
=============

**Metadata file contains basic information about your service integrations.** It uses
[JSON format](http://en.wikipedia.org/wiki/JSON) and it's called ``metadata.in.json``.
Let's look at the example:

    :::json
    {
        "id": "happy_songs",
        "name": "Happy Songs",
        "maintainer_name": "Jiří Janoušek",
        "maintainer_link": "https://github.com/fenryxo",
        "version_major": 1,
        "version_minor": 0,
        "api_major": 3,
        "api_minor": 0,
        "categories": "AudioVideo;Audio;",
        "home_url": "nuvola://home.html",
        "license": "2-Clause BSD, CC-BY-3.0",
        "build": {
            "icons": [
                "src/icon.svg SCALABLE 64 128 256", 
                "src/icon-xs.svg 16 22 24", 
                "src/icon-sm.svg 32 48"
                ]
        }

This file contains several mandatory fields:

`id`

:   Identifier of the service. It can contain only letters `a-z`, digits `0-9` and underscore `_` to
    separate words, e.g. `google_play_music` for Google Play Music, `8tracks` for 8tracks.com.
    (Nuvola Player 2 required the id must be same as the directory name of the service
    integration, but Nuvola Player 3 doesn't have this limitation.)

`name`

:   Name of the service (for humans), e.g. "Google Play Music".

`version_major`

:   Major version of the integration, must be an integer > 0. You should use
    `1` for an initial version. This number is increased, when a major change occurs.

`version_minor`

:   A minor version of service integration, an integer >= 0.  This field should
    be increased only when a new release is made. Never increase version number
    in regular commits nor pull requests, but only in release commits with 
    a commit message "Release X.Y".
    
`maintainer_name`

:   A name of the maintainer of the service integration.

`maintainer_link`

:   A link to a page with contact to maintainer (including `http://` or `https://`) or an email
    address prefixed by `mailto:`.

`api_major` and `api_minor`

:   A required version of JavaScript API, currently ``3.0``. You should update API version only
    if your script doesn't work with older API. For example, if Nuvola Player adds a new feature
    into API 3.X that is so essential for your script that it cannot function properly without it,
    you will increase API requirement to 3.X. However, all Nuvola Player versions with API less
    then 3.1 won't be able to load your script any more.

``categories``

:   [Application categories](http://standards.freedesktop.org/menu-spec/latest/apa.html) suitable
    for the web app. It is used to place a desktop launcher to proper category in applications menu.
    Nuvola Player services should be in ``"AudioVideo;Audio;"``.

`home_url`

:   Home page of your service. The dump example of a streaming website contains file `home.html`, which
    has a special address `nuvola://home.html`. You will use a real homepage later in your own
    service integration (e.g. `https://play.google.com/music/` for Google Play Music).
    
    This field is not required if you use custom function to handle home page request.
    See [Web apps with a variable home page URL](:apps/variable-home-page-url.html).

`license`

:   List of licenses that apply to your script, e.g. `"2-Clause BSD, CC-BY-3.0"`.

`requirements`

:   If your streaming service requires **Flash plugin** or **HTML5 Audio support** for playback
    (very likely), you have to
    [set a proper format requirement flag](https://github.com/tiliado/nuvolaplayer/issues/158#issuecomment-177193663).
    Although Nuvola Player 3.0 currently doesn't check this flag and enables both Flash and HTML5 Audio by default,
    this is going to be changed in the next stable release **Nuvola Player 3.2**.

`build`

:   Instructions for the build system of Nuvola SDK. It contains a list of `icons` and their sizes to generate and
    an optional list of `extra_data` containing filenames to include during installation.

This file can include also optional fields:

`window_width`, `window_height`

:   Suggested window width or height in pixels.

`allow_insecure_content` (since Nuvola Player 3.1)

:   Whether the page served over the secure HTTPS protocol depends on insecure content served over the HTTP protocol.
    As a rule of thumb, set `allow_insecure_content` to `true` if you see console warnings similar to that of Pocket Casts:
    `Runner: **CONSOLE WARN [blocked]** The page at https://play.pocketcasts.com/web **was not allowed** to display
    insecure content from http://media.scpr.org/.` The default value is `false`.

!!! danger "Extra rules for metadata.in.json"
    If you want to have your integration script maintained and distributed as a part of the Nuvola
    Player project, you have to follow rules in [Service Integrations Guidelines](:apps/guidelines.html).

Integration script
==================

**The integration script is the fundamental part of the service integration.** It's written in
JavaScript and called ``integrate.js``. This script is called once at start-up of the web app to
perform initialization of the main process and again
in the web page rendering process every-time a web page is loaded in the web view. Let's look at the
next sample integration script that doesn't actually do much, but will be used as a base for further
modifications.

```
#!js
/*
 * Copyright 2017 Your name <your e-mail>
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met: 
 * 
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer. 
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution. 
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

"use strict";

(function(Nuvola)
{

// Create media player component
var player = Nuvola.$object(Nuvola.MediaPlayer);

// Handy aliases
var PlaybackState = Nuvola.PlaybackState;
var PlayerAction = Nuvola.PlayerAction;

// Create new WebApp prototype
var WebApp = Nuvola.$WebApp();

// Initialization routines
WebApp._onInitWebWorker = function(emitter)
{
    Nuvola.WebApp._onInitWebWorker.call(this, emitter);
    
    var state = document.readyState;
    if (state === "interactive" || state === "complete")
        this._onPageReady();
    else
        document.addEventListener("DOMContentLoaded", this._onPageReady.bind(this));
}

// Page is ready for magic
WebApp._onPageReady = function()
{
    // Connect handler for signal ActionActivated
    Nuvola.actions.connect("ActionActivated", this);
    
    // Start update routine
    this.update();
}

// Extract data from the web page
WebApp.update = function()
{
    var track = {
        title: null,
        artist: null,
        album: null,
        artLocation: null,
        rating: null
    }
    
    player.setTrack(track);
    player.setPlaybackState(PlaybackState.UNKNOWN);
    
    // Schedule the next update
    setTimeout(this.update.bind(this), 500);
}

// Handler of playback actions
WebApp._onActionActivated = function(emitter, name, param)
{
}

WebApp.start();

})(this);  // function(Nuvola)
```

Lines 2-22

:   Copyright and license information. While you can choose any license for your work, it's
    recommended to use the license of Nuvola Player as shown in the example.

Line 25

:   Use [strict JavaScript mode][JS_STRICT] in your scripts.

Lines 27-28 and 86

:   Use [self-executing anonymous function][JS_SEAF] to create closure with [Nuvola object](apiref>).
    (Integration script are executed with ``Nuvola`` object bound to ``this``).

Line 31

:   Create [MediaPlayer](apiref>Nuvola.MediaPlayer) component that adds playback actions and is later used to provide playback
    details.

Line 38

:   Create new WebApp prototype object derived from the [Nuvola.WebApp](apiref>Nuvola.WebApp) prototype that contains
    handy default handlers for initialization routines and signals from Nuvola core. 
    You can override them if your web app requires more magic ;-)

Lines 41-50

:   Handler for [Nuvola.Core::InitWebWorker signal](apiref>Core%3A%3AInitWebWorker) signal that
    emitted in clear JavaScript environment with a brand new global ``window`` object. You should
    not touch it, only perform necessary initialization (usually not needed) and set your listener
    for either `document`'s `DOMContentLoaded` event (preferred) or `window`'s `load` event.

Lines 53-60

:   When document object model of a web page is ready, we register a signal handler for playback
    actions and call update() method.

Lines 63-77

:   The update() method periodically extracts playback state and track details.

Lines 81-82

:   Actions handler is used to respond to player actions.

Line 84

:   Convenience method to create and register new instance of your web app integration.

App Runner and Web Worker
=========================

Nuvola Player uses two processes for each service (web app):

  * **App Runner process** that manages user interface, desktop integration components and
    a life-cycle of the WebKitGtk WebView. On start-up, Nuvola Player executes once the integration
    script in the App Runner process to perform initialization of the web app. Note that the script
    is executed in a **bare JavaScript environment**, which means there are no `window`, `document`
    or other common object provided by a web browser engine. Therefore, make sure you don't use any of these
    objects in your top-level code.
    
    In **the previous example**, there is not any handler for the
    [Nuvola.Core::InitAppRunner signal](apiref>Nuvola.Core::InitAppRunner).
    It usually is used only for extra features such as
    [Web apps with a variable home page URL]({filename}apps/variable-home-page-url.md),
    [Initialization and Preferences Forms]({filename}apps/initialization-and-preferences-forms.md)
    or [Custom Actions]({filename}apps/custom-actions.md).
    
 
  * **Web Worker process** is created by WebKitGtk WebView and it's the place where the web
    interface of a web app lives, i.e. where the website is loaded. Nuvola Player executes the
    integration script in the Web Worker process everytime a web page is loaded in it to integrate
    the web page. The script is executed in a complete WebKit JavaScript environment with all bells
    and whistles.

Check, Build and Run Your Script
================================

First of all, make sure you have [installed all dependencies](https://github.com/tiliado/nuvolasdk#build-a-project-using-nuvola-sdk).
Then run `nuvolasdk check-project` to check there are no common errors.

```
$ nuvolasdk check-project
Checking the project...
No errors have been found.
```

Finally, execute following commands:

  * `./configure` to generate `Makefile` and `metadata.json` from `metadata.in.json`
  * `make all` to build the project

After the project have been built, you can run Nuvola Player 3 from terminal with following command and you will see a list with only one
service Happy Songs, because we told Nuvola Player to load service integrations only from directory
`~/projects/nuvola-player`.
    
    $ nuvolaplayer3 -D -A ~/projects/nuvola-player
    ...
    [Master:DEBUG    Nuvola] WebAppRegistry.vala:128: Found web app Happy Songs at /home/fenryxo/projects/nuvola-player/nuvola-app-happy-songs, version 1.0
    ...



!!! danger "Make sure all Nuvola Player instances have been closed"
    If you see following warning in terminal, there is a running instance of Nuvola Player
    that must be closed. Otherwise, the `-A` parameter is ignored.
    
    
        [Master:INFO     Nuvola] master.vala:135: Nuvola Player 3 instance is already running
        and will be activated.
        [Master:WARNING  Nuvola] master.vala:137: Some command line parameters (-D, -v, -A, -L) are
        ignored because they apply only to a new instance. You might want to close all Nuvola Player
        instances and run it again with your parameters.

![A list with single service integration](:images/guide/app_list_one_service.png)

Launch your service integration and a new window will be opened with the test service. First of all,
show **developer's sidebar** (Gear menu → Show sidebar → select "Developer" in the right 
sidebar), then enable **WebKit Web Inspector** (right-click the web page anywhere and select
"Inspect element").

![Show sidebar - GNOME Shell](:images/guide/show_sidebar_gnome_shell.png)

![Inspect element](:images/guide/inspect_element.png)

![WebKit Web Inspector](:images/guide/webkit_web_inspector.png)

You can also launch your service integration with id `happy_songs` directly.

    nuvolaplayer3 -D -A ~/projects/nuvola-player -a happy_songs

Debugging and logging messages
==============================

You might want to print some debugging messages to console during development. There are two types
of them in Nuvola Player:

  * **JavaScript console** is shown in the WebKit Web Inspector.
  * **Terminal console** is the black window with white text. Debugging messages are only printed
    if you have launched Nuvola Player with ``-D`` or ``--debug`` flag.

The are two ways how to print debugging messages:

  * [Nuvola.log()](apiref>Nuvola.log) always prints only to terminal console.
  * [console.log()](https://developer.mozilla.org/en-US/docs/Web/API/console.log) prints to JavaScript
    console only if [Window object](https://developer.mozilla.org/en/docs/Web/API/Window) is
    the the global object of the current JavaScript environment. Otherwise, Nuvola.log is used as a
    fallback and a warning is issued.

You might be wondering **why the Window object isn't always available as the global JavaScript
object**. That's because Nuvola Player executes a lot of JavaScript code in a pure JavaScript
environment outside the web view. However, the [Core::InitWebWorker signal](apiref>Core%3A%3AInitWebWorker)
and your ``WebApp._onInitWebWorker`` and ``WebApp._onActionActivated`` signal handlers are
invoked in the web view with the global window object, so feel free to use ``console.log()``.

Playback state and track details
================================

The first task of your service integration is to **extract playback state and track details from the
web page** and provide them to the media player component. There are two ways how to extract playback
state and track details:

 1. Use [Document Object Model][DOM] to get information from the HTML code of the web page.
 2. Use JavaScript API provided by the web page if there is any.

[DOM]: https://developer.mozilla.org/en-US/docs/Web/API/Document_Object_Model

The first way is more general and will be described here. The folowing methods are useful:

  * [document.getElementById](https://developer.mozilla.org/en-US/docs/Web/API/document.getElementById) -
    look-up an element by ``id`` attribute
  * [document.getElementsByName](https://developer.mozilla.org/en-US/docs/Web/API/Document.getElementsByName) -
    look-up elements by ``name`` attribute
  * [document.getElementsByClassName](https://developer.mozilla.org/en-US/docs/Web/API/document.getElementsByClassName) -
    look-up elements by ``class`` attribute
  * [document.getElementsByTagName](https://developer.mozilla.org/en-US/docs/Web/API/document.getElementsByTagName) -
    look-up elements by tag name (e.g. ``a``, ``div``, etc.)
  * [document.querySelector](https://developer.mozilla.org/en-US/docs/Web/API/document.querySelector) -
    look-up the first element that matches provided [CSS selector][B1]
  * [document.querySelectorAll](https://developer.mozilla.org/en-US/docs/Web/API/document.querySelectorAll) -
    look-up all elements that match provided [CSS selector][B1]

[B1]: https://developer.mozilla.org/en-US/docs/Web/Guide/CSS/Getting_Started/Selectors

Playback state
--------------

Looking at the code of a web page shown in the picture bellow, the code to extract playback state
might be. Playback states are defined in an enumeration
[Nuvola.PlaybackState](apiref>Nuvola.PlaybackState) and set by method
[player.setPlaybackState()](apiref>Nuvola.MediaPlayer.setPlaybackState).

```js
var PlaybackState = Nuvola.PlaybackState;

...

WebApp.update = function()
{
    ...
    
    try
    {
        switch(document.getElementById("status").innerText)
        {
            case "Playing":
                var state = PlaybackState.PLAYING;
                break;
            case "Paused":
                var state = PlaybackState.PAUSED;
                break;
            default:
                var state = PlaybackState.UNKNOWN;
                break;
        }
    }
    catch(e)
    {
        // Always expect errors, e.g. document.getElementById("status") might be null
        var state = PlaybackState.UNKNOWN;
    }
    
    player.setPlaybackState(state);
    
    ...
}
```
![Playback state](:images/guide/playback_state.png)

Track details
-------------

Similarly, we can obtain track details and pass them to method [player.setTrack()](apiref>Nuvola.MediaPlayer.setTrack)

```js
WebApp.update = function()
{
    ...
    
    var track = {
        artLocation: null, // always null
        rating: null // same
    }
    
    var idMap = {title: "track", artist: "artist", album: "album"}
    for (var key in idMap)
    {
        try
        {
            track[key] = document.getElementById(idMap[key]).innerText || null;
        }
        catch(e)
        {
            // Always expect errors, e.g. document.getElementById() might return null
            track[key] = null;
        }
    }
    
    player.setTrack(track);
    
    ...
}
```

![Track details](:images/guide/track_details.png)

Player Actions
==============

The second responsibility of a service integration is to **manage media player actions**:

 1. Set which actions are enabled.
 2. Invoke the actions when they are activated.

The first part is done via calls [player.setCanPause()](apiref>Nuvola.MediaPlayer.setCanPause),
[player.setCanPlay()](apiref>Nuvola.MediaPlayer.setCanPlay),
[player.setCanGoPrev()](apiref>Nuvola.MediaPlayer.setCanGoPrev) and
[player.setCanGoNext()](apiref>Nuvola.MediaPlayer.setCanGoNext):

```js
WebApp.update = function()
{
    ...
    
    var enabled;
    try
    {
        enabled = !document.getElementById("prev").disabled;
    }
    catch(e)
    {
        enabled = false;
    }
    player.setCanGoPrev(enabled);
    
    try
    {
        enabled  = !document.getElementById("next").disabled;
    }
    catch(e)
    {
        enabled = false;
    }
    player.setCanGoNext(enabled);
    
    var playPause = document.getElementById("pp");
    try
    {
        enabled  = playPause.innerText == "Play";
    }
    catch(e)
    {
        enabled = false;
    }
    player.setCanPlay(enabled);
    
    try
    {
        enabled  = playPause.innerText == "Pause";
    }
    catch(e)
    {
        enabled = false;
    }
    player.setCanPause(enabled);
    
    ...
}
```

![Playback actions](:images/guide/playback_actions.png)

To handle playback actions defined in an enumeration [PlayerAction](apiref>Nuvola.PlayerAction),
it is necessary to connect to [Actions::ActionActivated signal](apiref>Nuvola.Actions%3A%3AActionActivated).
You can use a convenient function [Nuvola.clickOnElement()](apiref>Nuvola.clickOnElement) to
simulate clicking.

```js
var PlayerAction = Nuvola.PlayerAction;

...

WebApp._onPageReady = function()
{
    // Connect handler for signal ActionActivated
    Nuvola.actions.connect("ActionActivated", this);
    
    // Start update routine
    this.update();
}

...

WebApp._onActionActivated = function(emitter, name, param)
{
    switch (name)
    {
    case PlayerAction.TOGGLE_PLAY:
    case PlayerAction.PLAY:
    case PlayerAction.PAUSE:
    case PlayerAction.STOP:
        Nuvola.clickOnElement(document.getElementById("pp"));
        break;
    case PlayerAction.PREV_SONG:
        Nuvola.clickOnElement(document.getElementById("prev"));
        break;
    case PlayerAction.NEXT_SONG:
        Nuvola.clickOnElement(document.getElementById("next"));
        break;
    }
}
```

!!! danger "Always test playback actions"
    You should click action buttons in the developer's sidebar to be sure they are working as expected.

!!! info "Custom actions"
    Service integrations can also create [custom Actions](:apps/custom-actions.html) like thumbs
    up/down or star rating.

Push your work upstream
=======================

If you would like to have your service integration **maintained as a part of Nuvola
Player project** and distributed in Nuvola Player repository, follow these steps:

  * Make sure your script follows the [Service Integration Guidelines](:apps/guidelines.html).
  * Make sure your ``integrate.js`` contain proper copyright information 
    "Copyright 2014 Your name &lt;your e-mail&gt;".
  * The test service used in tutorial and guide contains 2-Clause BSD license. If you have severe
    reasons to choose a different license, update license text in both ``integrate.js`` and
    ``LICENSE`` files.
  *  Create an empty remote repository named "nuvola-app-{app-id}" on GitHub.
     See [GitHub For Beginners: Don't Get Scared, Get Started][A1] for help.
  * Push content of your local repository to the remote repository.
    
        :::sh
        git remote add origin git@github.com:fenryxo/nuvola-app-test.git
        git push -u origin master

  * Create new issue in your repository titled "Push to Nuvola Player project"
  * Create new issue at [Nuvola Player repository](https://github.com/tiliado/nuvolaplayer/issues/new)
    with subject "Code review: You Service Name integration" and post a link the the issue created
    above.
 
[A1]: http://readwrite.com/2013/09/30/understanding-github-a-journey-for-beginners-part-1
[A2]: http://readwrite.com/2013/10/02/github-for-beginners-part-2

What to do next
===============

Supposing you have followed this tutorial, you have enough knowledge to create your own service
integration. You are encouraged to take a look at articles in advanced section to spice up your work:

  * [URL Filtering (URL Sandbox)](:apps/url-filtering.html):
    Decide which urls are opened in a default web browser instead of Nuvola Player.
  * [Configuration and session storage](:apps/configuration-and-session-storage.html):
    Nuvola Player 3 allows service integrations to store both a persistent configuration and a temporary session information.
  * [Initialization and Preferences Forms](:apps/initialization-and-preferences-forms.html):
    These forms are useful when you need to get user input.
  * [Web apps with a variable home page URL](:apps/variable-home-page-url.html):
    This article covers Web apps that don't have a single (constant) home page URL, so their home page has to be specified by user.
  * [Custom Actions](:apps/custom-actions.html):
    This article covers API that allows you to add custom actions like thumbs up/down rating.
  * [Translations](:apps/translations.html): How to mark translatable strings for 
    [Gettext-based](http://www.gnu.org/software/gettext/manual/gettext.html)
    translations framework for service integration scripts.


[git]: http://git-scm.com/
[me]: http://fenryxo.cz
[JS_STRICT]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Functions_and_function_scope/Strict_mode
[JS_SEAF]: http://markdalgleish.com/2011/03/self-executing-anonymous-functions/
