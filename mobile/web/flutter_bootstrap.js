{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}},
  },
  onEntrypointLoaded: async function(engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine({
      canvasKitBaseUrl: "https://cdn.jsdelivr.net/npm/canvaskit-wasm@0.39.1/bin/full/",
    });
    await appRunner.runApp();
  }
});
