import { Text as SwiftText } from "@expo/ui/swift-ui";
import {
  Animation,
  animation,
  contentTransition,
  font,
  foregroundStyle,
  lineLimit,
  multilineTextAlignment,
} from "@expo/ui/swift-ui/modifiers";
import { memo, useRef } from "react";
import type { IContentTransition } from "./interface";
import { Host } from "@expo/ui/swift-ui";

const MatchedText: React.MemoExoticComponent<React.FC<IContentTransition>> =
  memo(
    ({
      texts,
      index,
      fontSize = 17,
      weight = "medium",
      align = "leading",
      maxLines,
      color = "#FFFFFF",
    }: IContentTransition): React.ReactNode &
      React.JSX.Element &
      React.ReactElement => {
      const value = texts[index] ?? "";

      const prev = useRef(value);
      const trigger = useRef(0);
      if (prev.current !== value) {
        prev.current = value;
        trigger.current += 1;
      }

      return (
        <Host matchContents>
          <SwiftText
            modifiers={[
              font({ size: fontSize, weight, design: "rounded" }),

              foregroundStyle(color),
              multilineTextAlignment(align),
              ...(maxLines === undefined ? [] : [lineLimit(maxLines)]),
              contentTransition("numericText"),
              animation(
                Animation.spring({
                  response: 0.8,
                  dampingFraction: 1,
                }),
                trigger.current,
              ),
            ]}
          >
            {value}
          </SwiftText>
        </Host>
      );
    },
  );

export { MatchedText };
