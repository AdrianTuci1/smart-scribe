"use strict";

// src/preload/index.ts
var import_electron = require("electron");
import_electron.contextBridge.exposeInMainWorld("electron", {
  ipcRenderer: {
    send: (channel, ...args) => import_electron.ipcRenderer.send(channel, ...args),
    on: (channel, func) => {
      const subscription = (_event, ...args) => func(...args);
      import_electron.ipcRenderer.on(channel, subscription);
      return () => import_electron.ipcRenderer.removeListener(channel, subscription);
    },
    invoke: (channel, data) => import_electron.ipcRenderer.invoke(channel, data),
    // Permission APIs
    checkAccessibility: () => import_electron.ipcRenderer.invoke("check-accessibility"),
    requestAccessibility: () => import_electron.ipcRenderer.invoke("request-accessibility"),
    checkMicrophone: () => import_electron.ipcRenderer.invoke("check-microphone"),
    requestMicrophone: () => import_electron.ipcRenderer.invoke("request-microphone"),
    resizeWindow: (width, height) => import_electron.ipcRenderer.invoke("resize-window", width, height),
    openWaveform: () => import_electron.ipcRenderer.invoke("open-waveform"),
    getSettings: (key) => import_electron.ipcRenderer.invoke("get-settings", key),
    setSetting: (key, value) => import_electron.ipcRenderer.invoke("set-setting", key, value),
    getAllSettings: () => import_electron.ipcRenderer.invoke("get-all-settings"),
    // Helper Features
    getActiveApp: () => import_electron.ipcRenderer.invoke("get-active-app"),
    insertText: (text) => import_electron.ipcRenderer.invoke("insert-text", text),
    checkPermissions: () => import_electron.ipcRenderer.invoke("check-permissions")
  }
});
