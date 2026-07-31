import { requireNativeView } from "expo";
import type { ComponentType } from "react";

const CACHE_KEY = "__expoLiquidGlassNativeViews__";

type TNativeViewCache = Map<string, ComponentType<any>>;

const getCache = (): TNativeViewCache => {
  const scope = globalThis as Record<string, unknown>;
  if (!scope[CACHE_KEY]) {
    scope[CACHE_KEY] = new Map<string, ComponentType<any>>();
  }
  return scope[CACHE_KEY] as TNativeViewCache;
};

const requireNativeViewOnce = <Props>(
  moduleName: string,
  viewName?: string,
): ComponentType<Props> => {
  const key = `${moduleName}/${viewName ?? "default"}`;
  const registry = getCache();

  const existing = registry.get(key);
  if (existing) {
    return existing as ComponentType<Props>;
  }

  const view = requireNativeView<Props>(moduleName, viewName);
  registry.set(key, view as ComponentType<any>);
  return view;
};

export { requireNativeViewOnce };
