{{flutter_js}}
{{flutter_build_config}}

// Load the renderer from this deployment. Depending on Google's CDN at app
// startup can leave Flutter's canvas blank when third-party requests are blocked.
_flutter.loader.load({
  config: {
    canvasKitBaseUrl: "canvaskit/",
  },
  onEntrypointLoaded: async function (engineInitializer) {
    try {
      const appRunner = await engineInitializer.initializeEngine();
      await appRunner.runApp();
    } catch (error) {
      window.showAppStartupError(error);
    }
  },
});
