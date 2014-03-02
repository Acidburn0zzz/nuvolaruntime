/*
 * Copyright 2011-2014 Jiří Janoušek <janousek.jiri@gmail.com>
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

namespace Nuvola
{

/**
 *  WebAppRegistry deals with management and loading of service integrations.
 */
public class WebAppRegistry: GLib.Object
{
	private Diorite.Storage storage;
	/**
	 * Name of file with metadata.
	 */
	private static const string METADATA_FILENAME = "metadata.json";
	
	/**
	 * Regular expression to check validity of service identifier
	 */
	private static Regex id_regex;
	
	
	public bool allow_management{ get; private set; }
	
	/**
	 * Creates new web app registry
	 * 
	 * @param storage             storage with service integrations
	 * @param allow_management    whether to allow services management (add/remove)
	 */
	public WebAppRegistry(Diorite.Storage storage, bool allow_management=true)
	{
		this.storage = storage;
		this.allow_management = allow_management;
	}
	
	/**
	 * Emitted when a service has been installed
	 * 
	 * @param id    service's id
	 */
	public signal void app_installed(string id);
	
	/**
	 * Emitted when a service has been removed
	 * 
	 * @param id    service's id
	 */
	public signal void app_removed(string id);
	
	/**
	 * Loads service by id.
	 * 
	 * @param id service id
	 * @return service
	 */
	public WebApp? get_app(string id)
	{
		if  (!check_id(id))
		{
			warning("Service id '%s' is invalid.", id);
			return null;
		}
		WebApp? app = null;
		WebApp? item;
		WebAppMeta? meta = null;
		var app_storage = storage.get_child(id);
		
		var user_dir = app_storage.user_data_dir;
		if (user_dir != null)
		{
			try
			{
				app = load_web_app_from_dir(user_dir, allow_management);
				meta = app.meta;
				debug("Found web app %s at %s, version %u.%u", 
				meta.name, user_dir.get_path(), meta.version_major, meta.version_minor);
			}
			catch (WebAppError e)
			{
				warning("Unable to load web app from %s: %s", user_dir.get_path(), e.message);
			}
		}
		
		foreach (var dir in app_storage.data_dirs)
		{
			try
			{
				item = load_web_app_from_dir(dir);
				meta = item.meta;
				debug("Found app %s at %s, version %u.%u",
				meta.name, dir.get_path(), meta.version_major, meta.version_minor);
				if (app == null || meta.version_major > app.meta.version_major
				|| meta.version_major == app.meta.version_major && meta.version_minor > app.meta.version_minor)
				{
					app = item;
				}
			}
			catch (WebAppError e)
			{
				warning("Unable to load web app from %s: %s", dir.get_path(), e.message);
			}
		}
		
		if (app != null)
			message("Using web app %s, version %u.%u", app.meta.name, app.meta.version_major, app.meta.version_minor);
		
		else
			message("Web App %s not found.", id);
		
		return app;
	}
	
	public WebAppMeta load_web_app_meta_from_dir(File dir) throws WebAppError
	{
		if (dir.query_file_type(0) != FileType.DIRECTORY)
			throw new WebAppError.LOADING_FAILED(@"$(dir.get_path()) is not a directory");
				
		var metadata_file = dir.get_child(METADATA_FILENAME);
		if (metadata_file.query_file_type(0) != FileType.REGULAR)
			throw new WebAppError.LOADING_FAILED(@"$(metadata_file.get_path()) is not a file");
		
		string metadata;
		try
		{
			metadata = Diorite.System.read_file(metadata_file);
		}
		catch (GLib.Error e)
		{
			throw new WebAppError.LOADING_FAILED("Cannot read '%s'. %s", metadata_file.get_path(), e.message);
		}
		
		WebAppMeta? meta;
		try
		{
			meta = Json.gobject_from_data(typeof(WebAppMeta), metadata) as WebAppMeta;
		}
		catch (GLib.Error e)
		{
			throw new WebAppError.INVALID_METADATA("Invalid metadata file '%s'. %s", metadata_file.get_path(), e.message);
		}
		
		meta.check();
		var id = dir.get_basename();
		if (id != meta.id)
			throw new WebAppError.INVALID_METADATA("Invalid metadata file '%s'. Id mismatch.", metadata_file.get_path());
		//			FIXME:
//~ 		if(!JSApi.is_supported(api_major, api_minor)){
//~ 			throw new ServiceError.LOADING_FAILED(
//~ 				"Requested unsupported api: %d.%d'".printf(api_major, api_minor));
//~ 		}
		return meta;
	}
		
	public WebApp load_web_app_from_dir(File dir, bool removable=false) throws WebAppError
	{
		var meta = load_web_app_meta_from_dir(dir);
		var config_dir = storage.get_config_path(meta.id);
		return new WebApp(meta, config_dir, dir, removable);
	}
	
	/**
	 * Lists available services
	 * 
	 * @return hash table of service id - metadata pairs
	 */
	public HashTable<string, WebApp> list_web_apps()
	{
		HashTable<string,  WebApp> result = new HashTable<string, WebApp>(str_hash, str_equal);
		FileInfo file_info;
		WebApp? app;
		WebApp? tmp_app;
		var user_dir = storage.user_data_dir;
		
		if (user_dir.query_exists())
		{
			try
			{
				var enumerator = user_dir.enumerate_children(FileAttribute.STANDARD_NAME, 0);
				while ((file_info = enumerator.next_file()) != null)
				{
					string name = file_info.get_name();
					if (!check_id(name))
						continue;
					
					var app_dir = user_dir.get_child(name);
					if (app_dir.query_file_type(0) != FileType.DIRECTORY)
						continue;
					
					try
					{
						app = load_web_app_from_dir(app_dir, allow_management);
						debug("Found web app %s at %s, version %u.%u",
						app.meta.name, app_dir.get_path(), app.meta.version_major, app.meta.version_minor);
						result.insert(name, app);
					}
					catch (WebAppError e)
					{
						warning("Unable to load app from %s: %s", app_dir.get_path(), e.message);
					}
				}
			}
			catch (GLib.Error e)
			{
				warning("Filesystem error: %s", e.message);
			}
		}
		
		foreach (var dir in storage.data_dirs)
		{
			try
			{
				var enumerator = dir.enumerate_children(FileAttribute.STANDARD_NAME, 0);
				while ((file_info = enumerator.next_file()) != null)
				{
					string name = file_info.get_name();
					if (!check_id(name))
						continue;
					
					var app_dir = dir.get_child(name);
					if (app_dir.query_file_type(0) != FileType.DIRECTORY)
						continue;
					
					try
					{
						app = load_web_app_from_dir(app_dir);
					}
					catch(WebAppError e)
					{
						warning("Unable to load web app from %s: %s", app_dir.get_path(), e.message);
						continue;
					}
					
					debug("Found web app %s at %s, version %u.%u",
					app.meta.name, app_dir.get_path(), app.meta.version_major, app.meta.version_minor);
					
					tmp_app = result.lookup(name);
					
					// Insert new value, if web app has not been added yet,
					// or override previous web app integration, if
					// the new one has greater version.
					if(tmp_app == null
					|| app.meta.version_major > tmp_app.meta.version_major
					|| app.meta.version_major == tmp_app.meta.version_major && app.meta.version_minor > tmp_app.meta.version_minor)
						result.insert(name, app);
				}
			}
			catch (Error e)
			{
				warning("Filesystem error: %s", e.message);
			}
		}
		
		return result;
	}
	
	/**
	 * Check if the service identifier is valid
	 * 
	 * @param id service identifier
	 * @return true if id is valid
	 */
	public static bool check_id(string id)
	{
		if (id_regex == null)
		{
			try
			{
				id_regex = new Regex("^\\w+$");
			}
			catch (RegexError e)
			{
				error("Unable to compile regular expression /^\\w+$/.");
			}
		}
		return id_regex.match(id);
	}
}

public errordomain WebAppError
{
	INVALID_METADATA,
	LOADING_FAILED,
	COMMAND_FAILED,
	INVALID_FILE,
	IOERROR,
	NOT_ALLOWED,
	SERVER_ERROR,
	SERVER_ERROR_MESSAGE;
}

} // namespace Nuvola