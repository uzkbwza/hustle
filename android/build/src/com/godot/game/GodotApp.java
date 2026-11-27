/*************************************************************************/
/*  GodotApp.java                                                        */
/*************************************************************************/
/*                       This file is part of:                           */
/*                           GODOT ENGINE                                */
/*                      https://godotengine.org                          */
/*************************************************************************/
/* Copyright (c) 2007-2022 Juan Linietsky, Ariel Manzur.                 */
/* Copyright (c) 2014-2022 Godot Engine contributors (cf. AUTHORS.md).   */
/*                                                                       */
/* Permission is hereby granted, free of charge, to any person obtaining */
/* a copy of this software and associated documentation files (the       */
/* "Software"), to deal in the Software without restriction, including   */
/* without limitation the rights to use, copy, modify, merge, publish,   */
/* distribute, sublicense, and/or sell copies of the Software, and to    */
/* permit persons to whom the Software is furnished to do so, subject to */
/* the following conditions:                                             */
/*                                                                       */
/* The above copyright notice and this permission notice shall be        */
/* included in all copies or substantial portions of the Software.       */
/*                                                                       */
/* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,       */
/* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF    */
/* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.*/
/* IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY  */
/* CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,  */
/* TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE     */
/* SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                */
/*************************************************************************/

package com.godot.game;

import org.godotengine.godot.FullScreenGodotApp;

import android.os.Build;
import android.os.Bundle;
import android.util.Log;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;

/**
 * Template activity for Godot Android custom builds.
 * Feel free to extend and modify this class for your custom logic.
 */
public class GodotApp extends FullScreenGodotApp {
	private static final String TAG = "GodotApp";
	private static final String DATA_DIR_NAME = "YourOnlyMoveIsHUSTLE";

	private Object backInvokedCallback;
	private File dataRoot;

	@Override
	public void onCreate(Bundle savedInstanceState) {
		setTheme(R.style.GodotAppMainTheme);
		migrateUserData();
		Log.i(TAG, "Player data folder: " + resolveDataRoot());
		super.onCreate(savedInstanceState);
		registerBackInvokedCallback();
	}

	@Override
	public File getFilesDir() {
		return resolveDataRoot();
	}

	private File resolveDataRoot() {
		if (dataRoot == null) {
			File media = resolveMediaRoot();
			if (media != null) {
				dataRoot = media;
			} else {
				File external = getExternalFilesDir(DATA_DIR_NAME);
				if (external != null && (external.isDirectory() || external.mkdirs())) {
					dataRoot = external;
				} else {
					dataRoot = super.getFilesDir();
				}
			}
		}
		return dataRoot;
	}

	private File resolveMediaRoot() {
		File[] mediaDirs = getExternalMediaDirs();
		if (mediaDirs == null) {
			return null;
		}
		for (File mediaDir : mediaDirs) {
			if (mediaDir == null) {
				continue;
			}
			File candidate = new File(mediaDir, DATA_DIR_NAME);
			if (candidate.isDirectory() || candidate.mkdirs()) {
				return candidate;
			}
		}
		return null;
	}

	private void migrateUserData() {
		File destination = resolveDataRoot();
		if (destination == null) {
			return;
		}
		File marker = new File(destination, ".migrated");
		if (marker.exists()) {
			return;
		}
		File previousExternal = getExternalFilesDir(DATA_DIR_NAME);
		if (previousExternal != null && !previousExternal.equals(destination)) {
			copyDirectory(previousExternal, destination);
		}
		File internal = super.getFilesDir();
		if (internal != null && !internal.equals(destination)) {
			copyDirectory(internal, destination);
		}
		try {
			if (!marker.exists()) {
				marker.createNewFile();
			}
		} catch (IOException e) {
			Log.w(TAG, "Could not write migration marker", e);
		}
	}

	private void copyDirectory(File source, File destination) {
		File[] files = source.listFiles();
		if (files == null || (!destination.isDirectory() && !destination.mkdirs())) {
			return;
		}
		for (File file : files) {
			File target = new File(destination, file.getName());
			if (file.isDirectory()) {
				copyDirectory(file, target);
			} else if (!target.exists()) {
				copyFile(file, target);
			}
		}
	}

	private void copyFile(File source, File destination) {
		File parent = destination.getParentFile();
		if (parent != null && !parent.isDirectory() && !parent.mkdirs()) {
			return;
		}
		FileInputStream input = null;
		FileOutputStream output = null;
		try {
			input = new FileInputStream(source);
			output = new FileOutputStream(destination);
			byte[] buffer = new byte[8192];
			int length;
			while ((length = input.read(buffer)) > 0) {
				output.write(buffer, 0, length);
			}
		} catch (IOException e) {
			Log.w(TAG, "Could not migrate " + source, e);
		} finally {
			if (input != null) {
				try {
					input.close();
				} catch (IOException ignored) {
				}
			}
			if (output != null) {
				try {
					output.close();
				} catch (IOException ignored) {
				}
			}
		}
	}

	private void registerBackInvokedCallback() {
		if (Build.VERSION.SDK_INT < 33) {
			return;
		}
		try {
			Class<?> callbackClass = Class.forName("android.window.OnBackInvokedCallback");
			Class<?> dispatcherClass = Class.forName("android.window.OnBackInvokedDispatcher");
			Object dispatcher = getClass().getMethod("getOnBackInvokedDispatcher").invoke(this);
			backInvokedCallback = Proxy.newProxyInstance(getClass().getClassLoader(), new Class<?>[] { callbackClass }, new InvocationHandler() {
				@Override
				public Object invoke(Object proxy, Method method, Object[] args) {
					String name = method.getName();
					if ("onBackInvoked".equals(name)) {
						onBackPressed();
						return null;
					}
					if ("hashCode".equals(name)) {
						return System.identityHashCode(proxy);
					}
					if ("equals".equals(name)) {
						return proxy == args[0];
					}
					if ("toString".equals(name)) {
						return "GodotAppBackInvokedCallback";
					}
					return null;
				}
			});
			dispatcherClass.getMethod("registerOnBackInvokedCallback", int.class, callbackClass).invoke(dispatcher, 0, backInvokedCallback);
		} catch (Throwable ignored) {
		}
	}
}
