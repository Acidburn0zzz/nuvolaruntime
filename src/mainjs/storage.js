/*
 * Copyright 2014 Jiří Janoušek <janousek.jiri@gmail.com>
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

require("prototype");
require("signals");

var KeyValueStorage = $prototype(null);

KeyValueStorage.$init = function(index)
{
	this.index = index;
}

KeyValueStorage.setDefault = function(key, value)
{
	Nuvola._keyValueStorageSetDefaultValue(this.index, key, value);
}

KeyValueStorage.hasKey = function(key)
{
	return Nuvola._keyValueStorageHasKey(this.index, key);
}

KeyValueStorage.get = function(key)
{
	return Nuvola._keyValueStorageGetValue(this.index, key);
}

KeyValueStorage.set = function(key, value)
{
	Nuvola._keyValueStorageSetValue(this.index, key, value);
}

var ConfigStorage = $prototype(KeyValueStorage, SignalsMixin);

ConfigStorage.$init = function()
{
	KeyValueStorage.$init.call(this, 0);
	this.registerSignals(["ConfigChanged"]);
}

var SessionStorage = $prototype(KeyValueStorage);

SessionStorage.$init = function()
{
	KeyValueStorage.$init.call(this, 1);
}

// export public items
Nuvola.KeyValueStorage = KeyValueStorage;
Nuvola.ConfigStorage = ConfigStorage;
Nuvola.SessionStorage = SessionStorage;

/**
 * Instance object of @link{SessionStorage} prototype connected to Nuvola backend.
 */
Nuvola.session = $object(SessionStorage);

/**
 * Instance object of @link{ConfigStorage} prototype connected to Nuvola backend.
 */
Nuvola.config = $object(ConfigStorage);

