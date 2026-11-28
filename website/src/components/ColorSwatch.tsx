import type {ReactNode} from 'react';
import clsx from 'clsx';

import styles from './ColorSwatch.module.css';

export interface ColorSwatchProps {
  /** Hex string displayed in monospace (e.g. `#4FD166` or Flutter ARGB `0x284FD166`). */
  hex: string;
  /** Optional CSS color override when `hex` is a Flutter ARGB literal like `0x284FD166`. */
  cssColor?: string;
  /** Optional short human-readable label displayed after the hex value. */
  label?: string;
  /** Optional backdrop under translucent swatches (`dark`, `light`, or `checker`). */
  backdrop?: 'dark' | 'light' | 'checker';
}

/**
 * Inline color token swatch displaying a crisp 1px-bordered color chip alongside
 * its tabular monospace hex value.
 */
export function ColorSwatch({
  hex,
  cssColor,
  label,
  backdrop,
}: ColorSwatchProps): ReactNode {
  const resolvedColor = cssColor ?? hex;
  const backdropClass =
    backdrop === 'dark'
      ? styles.chipDarkBackdrop
      : backdrop === 'light'
        ? styles.chipLightBackdrop
        : backdrop === 'checker'
          ? styles.chipChecker
          : undefined;

  return (
    <span className={styles.swatch} title={resolvedColor}>
      <span
        className={clsx(styles.chip, backdropClass)}
        aria-hidden="true">
        <span
          className={styles.chipFill}
          style={{backgroundColor: resolvedColor}}
        />
      </span>
      <span className={styles.hex}>{hex}</span>
      {label ? <span className={styles.label}>{label}</span> : null}
    </span>
  );
}

export interface GradientStop {
  /** Short role or position label for the stop (e.g. `0%`, `Left`, `ZNN`). */
  label: string;
  /** Displayed hex or ARGB value. */
  hex: string;
  /** Optional CSS color used to render the stop indicator dot. */
  cssColor?: string;
}

export interface GradientBannerProps {
  /** Specimen title displayed on the preview surface. */
  title: string;
  /** Optional uppercase eyebrow tag above the title. */
  eyebrow?: string;
  /** Optional explanatory subtitle rendered inside the preview. */
  subtitle?: string;
  /** CSS `background` expression for the gradient or multi-layer radial wash. */
  background: string;
  /** Foreground text color rendered on the preview surface (or pill CTA). */
  foreground?: string;
  /** Optional explicit stage backdrop when rendering a pill specimen inside a frame. */
  stageBackground?: string;
  /** Optional stage foreground text color when `pillLabel` is set. */
  stageForeground?: string;
  /** When set, renders a pill CTA preview styled with `background` and `foreground`. */
  pillLabel?: string;
  /** Optional secondary caption shown next to the pill CTA specimen. */
  pillCaption?: string;
  /** Dart/CSS token identifier shown in the metadata strip. */
  tokenName?: string;
  /** Ordered color stops shown in the metadata strip. */
  stops?: readonly GradientStop[];
  /** Optional compact height mode. */
  compact?: boolean;
}

/**
 * Visual preview card for Syrius brand gradients, hero dual-wash surfaces,
 * and multi-corner ambient backdrops.
 */
export function GradientBanner({
  title,
  eyebrow,
  subtitle,
  background,
  foreground = '#F0F2F0',
  stageBackground,
  stageForeground,
  pillLabel,
  pillCaption,
  tokenName,
  stops,
  compact = false,
}: GradientBannerProps): ReactNode {
  const isPillMode = Boolean(pillLabel);

  return (
    <div className={styles.gradientCard} role="region" aria-label={title}>
      <div
        className={clsx(
          styles.gradientStage,
          compact && styles.gradientStageCompact,
        )}
        style={{
          background: isPillMode
            ? (stageBackground ?? 'var(--syrius-surface)')
            : background,
          color: isPillMode
            ? (stageForeground ?? 'var(--syrius-text-primary)')
            : foreground,
        }}>
        <div className={styles.gradientStageHeader}>
          <div>
            {eyebrow ? (
              <div className={styles.gradientEyebrow}>{eyebrow}</div>
            ) : null}
            <div className={styles.gradientTitle}>{title}</div>
          </div>
        </div>

        {isPillMode ? (
          <div className={styles.pillSpecimenRow}>
            <span
              className={styles.pillSpecimen}
              style={{background, color: foreground}}>
              {pillLabel}
            </span>
            {pillCaption ? (
              <span className={styles.pillCaption}>{pillCaption}</span>
            ) : null}
          </div>
        ) : null}

        {subtitle ? (
          <div className={styles.gradientSubtitle}>{subtitle}</div>
        ) : null}
      </div>

      {tokenName || (stops && stops.length > 0) ? (
        <div className={styles.gradientMeta}>
          {tokenName ? (
            <span className={styles.gradientTokenName}>{tokenName}</span>
          ) : null}
          {stops && stops.length > 0 ? (
            <div className={styles.gradientStops}>
              {stops.map((stop) => (
                <span key={`${stop.label}-${stop.hex}`} className={styles.stopItem}>
                  <span className={styles.stopDot} aria-hidden="true">
                    <span
                      className={styles.chipFill}
                      style={{backgroundColor: stop.cssColor ?? stop.hex}}
                    />
                  </span>
                  <span>
                    {stop.label} {stop.hex}
                  </span>
                </span>
              ))}
            </div>
          ) : null}
        </div>
      ) : null}
    </div>
  );
}

/**
 * Responsive two-column wrapper for comparing Dark and Light gradient specimens
 * side by side.
 */
export function GradientBannerGrid({
  children,
}: {
  children: ReactNode;
}): ReactNode {
  return <div className={styles.gradientGrid}>{children}</div>;
}
