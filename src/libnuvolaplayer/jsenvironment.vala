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

public class JsEnvironment: GLib.Object
{

	public unowned JS.GlobalContext context {get; private set;}
	private unowned JS.Object? _main_object = null;
	public unowned JS.Object? main_object
	{
		get
		{
			return _main_object;
		}
		set
		{
			if (_main_object != null)
				_main_object.unprotect(context);
			
			_main_object = value;
			if (_main_object != null)
				_main_object.protect(context);
		}
	}
	
	public JsEnvironment(JS.GlobalContext context, JS.Object? main_object)
	{
		this.context = context;
		context.retain();
		this.main_object = main_object;
	}
	
	~JsEnvironment()
	{
		main_object = null;
		context.release();
	}
	
	/**
	 * Executes script from file.
	 * 
	 * The script will be executed in a context returned by {@link get_context().
	 * The "this" keyword will refer to {@link object_this} if provided.
	 * 
	 * @param file    script to execute
	 * @return        return value of the script
	 * @throw         JSError on failure
	 */
	public unowned Value execute_script_from_file(File file) throws JSError
	{
		string code;
		try
		{
			code = Diorite.System.read_file(file);
		}
		catch (Error e)
		{
			throw new JSError.READ_ERROR("Unable to read script %s: %s",
				file.get_path(), e.message);
		}
		return execute_script(code, file.get_uri(), 1);
	}
	
	/**
	 * Executes script.
	 * 
	 * The script will be executed in a context returned by {@link get_context()}.
	 * The "this" keyword will refer to {@link object_this} if provided.
	 * 
	 * @param script    script to execute
	 * @return          return value of the script
	 * @throw           JSError on failure
	 */
	public unowned Value execute_script(string script, string path = "about:blank", int line=1) throws JSError
	{ 
		JS.Value exception = null;
		unowned Value value = context.evaluate_script(new JS.String(script), main_object, new JS.String(path), line=0, out exception);
		if (exception != null)
			throw new JSError.EXCEPTION(JSTools.exception_to_string(context, exception));
		return value;
	}
}

} // namespace Nuvola