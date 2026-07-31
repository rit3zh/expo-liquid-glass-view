"use strict";

interface IContentTransition {
  texts: string[];
  index: number;
  width?: number;
  fontSize?: number;
  color?: string;
  weight?: "regular" | "medium" | "semibold" | "bold";
  align?: "leading" | "center" | "trailing";
  maxLines?: number;
}

export type { IContentTransition };
