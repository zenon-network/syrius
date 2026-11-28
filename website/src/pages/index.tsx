import type {ReactNode} from 'react';
import clsx from 'clsx';
import Link from '@docusaurus/Link';
import useBaseUrl from '@docusaurus/useBaseUrl';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import Layout from '@theme/Layout';
import Heading from '@theme/Heading';

import styles from './index.module.css';

interface JourneyCard {
  title: string;
  description: string;
  to: string;
  badge: string;
  secondaryLink?: {
    label: string;
    to: string;
  };
  icon: ReactNode;
}

function ShieldIcon(): ReactNode {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
      <path d="m9 12 2 2 4-4" />
    </svg>
  );
}

function AlertTriangleIcon(): ReactNode {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3Z" />
      <line x1="12" y1="9" x2="12" y2="13" />
      <line x1="12" y1="17" x2="12.01" y2="17" />
    </svg>
  );
}

function DownloadIcon(): ReactNode {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
      <polyline points="7 10 12 15 17 10" />
      <line x1="12" y1="15" x2="12" y2="3" />
    </svg>
  );
}

function WalletIcon(): ReactNode {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <rect x="2" y="5" width="20" height="14" rx="2" />
      <path d="M16 12h.01" />
      <path d="M2 10h20" />
    </svg>
  );
}

function HardwareIcon(): ReactNode {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <rect x="4" y="4" width="16" height="16" rx="2" />
      <rect x="9" y="9" width="6" height="6" />
      <path d="M9 1v3M15 1v3M9 20v3M15 20v3M20 9h3M20 14h3M1 9h3M1 14h3" />
    </svg>
  );
}

function TerminalIcon(): ReactNode {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <polyline points="4 17 10 11 4 5" />
      <line x1="12" y1="19" x2="20" y2="19" />
    </svg>
  );
}

function LayersIcon(): ReactNode {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <polygon points="12 2 2 7 12 12 22 7 12 2" />
      <polyline points="2 17 12 22 22 17" />
      <polyline points="2 12 12 17 22 12" />
    </svg>
  );
}

function FlaskIcon(): ReactNode {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d="M9 3h6" />
      <path d="M10 3v6.5L4.8 18.2A2 2 0 0 0 6.5 21h11a2 2 0 0 0 1.7-2.8L14 9.5V3" />
      <path d="M8.5 14h7" />
    </svg>
  );
}

function GitPullRequestIcon(): ReactNode {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <circle cx="18" cy="18" r="3" />
      <circle cx="6" cy="6" r="3" />
      <path d="M13 6h3a2 2 0 0 1 2 2v7" />
      <line x1="6" y1="9" x2="6" y2="21" />
    </svg>
  );
}

const USER_CARDS: JourneyCard[] = [
  {
    title: 'Install & Setup',
    badge: 'Getting Started',
    description:
      'Download Syrius for macOS, Windows, or Linux, verify checksums, and create or restore your wallet with a 12- or 24-word seed phrase.',
    to: '/docs/user-guide/getting-started/installation',
    secondaryLink: {
      label: 'Create or Restore Wallet',
      to: '/docs/user-guide/getting-started/create-or-restore-wallet',
    },
    icon: <DownloadIcon />,
  },
  {
    title: 'Core Wallet Features',
    badge: 'Daily Use',
    description:
      'Send and receive ZNN, QSR, and ZTS tokens with feeless Plasma, stake for QSR rewards, delegate to Pillars, and run trustless HTLC P2P swaps.',
    to: '/docs/user-guide/intro',
    icon: <WalletIcon />,
  },
  {
    title: 'Hardware & Nodes',
    badge: 'Sovereignty',
    description:
      'Connect a Ledger hardware wallet (including Linux udev setup) and choose between the Embedded Full Node, a Local Node, or Remote Nodes.',
    to: '/docs/user-guide/hardware-and-nodes/ledger-hardware-wallet',
    secondaryLink: {
      label: 'Node Modes Guide',
      to: '/docs/user-guide/hardware-and-nodes/node-modes',
    },
    icon: <HardwareIcon />,
  },
  {
    title: 'Security & FAQ',
    badge: 'Protection',
    description:
      'Safeguard recovery phrases and keystore files, understand platform storage directories, and resolve common sync or connection issues.',
    to: '/docs/user-guide/security-and-support/security-and-backups',
    secondaryLink: {
      label: 'Troubleshooting & FAQ',
      to: '/docs/user-guide/security-and-support/troubleshooting-and-faq',
    },
    icon: <ShieldIcon />,
  },
];

const DEVELOPER_CARDS: JourneyCard[] = [
  {
    title: 'Build & Setup',
    badge: 'Toolchain',
    description:
      'Set up the pinned Flutter/Dart toolchain, desktop build requirements, native FFI libraries, and compile-time Git metadata.',
    to: '/docs/developers/getting-started/environment-setup',
    icon: <TerminalIcon />,
  },
  {
    title: 'Architecture & BLoC',
    badge: 'Engineering',
    description:
      'Explore DI wiring, FFI bridges (go-zenon, Argon2, PoW, Ledger), and the feature-based BLoC rearchitecture replacing legacy MVVM code.',
    to: '/docs/developers/architecture/overview',
    secondaryLink: {
      label: 'BLoC Rearchitecture',
      to: '/docs/developers/architecture/bloc-rearchitecture',
    },
    icon: <LayersIcon />,
  },
  {
    title: 'Testing & Devnet',
    badge: 'Quality',
    description:
      'Run unit and BLoC tests alongside widget-driven Gherkin (bdd_widget_test) blockchain integration tests against a Dockerized devnet.',
    to: '/docs/developers/testing/blockchain-integration-tests',
    icon: <FlaskIcon />,
  },
  {
    title: 'Contributing',
    badge: 'Open Source',
    description:
      'Follow localization (l10n) key conventions, build_runner codegen checks, PR validation rules, and docs contribution workflows.',
    to: '/docs/developers/contributing/contributing-guide',
    icon: <GitPullRequestIcon />,
  },
];

function HeroSection(): ReactNode {
  const logoSrc = useBaseUrl('/img/syrius-logo.svg');

  const focusNavbarSearch = () => {
    const input = document.querySelector<HTMLInputElement>('.navbar__search-input');
    if (input) {
      input.focus();
      input.select();
    }
  };

  return (
    <header className={styles.heroWrapper}>
      <div className="container">
        <div className={styles.heroPanel}>
          <div className={styles.heroTopRow}>
            <div className={styles.heroEyebrow}>
              <img
                src={logoSrc}
                alt="Syrius Wallet Logo"
                className={styles.heroLogo}
                width={20}
                height={20}
              />
              <span className={styles.heroWordmark}>SYRIUS</span>
              <span className={styles.eyebrowDivider} aria-hidden="true">
                ·
              </span>
              <span className={styles.heroNetworkLabel}>
                ZENON NETWORK · ALPHANET
              </span>
            </div>
            <div className={styles.tokenChips} aria-hidden="true">
              <span className={styles.tokenChip}>
                <span className={clsx(styles.tokenDot, styles.tokenDotZnn)} />
                ZNN
              </span>
              <span className={styles.tokenChip}>
                <span className={clsx(styles.tokenDot, styles.tokenDotQsr)} />
                QSR
              </span>
              <span className={styles.tokenChip}>
                <span className={clsx(styles.tokenDot, styles.tokenDotZts)} />
                ZTS
              </span>
            </div>
          </div>

          <div className={styles.heroBody}>
            <div className={styles.heroCopy}>
              <Heading as="h1" className={styles.heroTitle}>
                Syrius Wallet Documentation
              </Heading>
              <p className={styles.heroSubtitle}>
                The official user guide and developer reference for the
                cross-platform, non-custodial Flutter desktop wallet for Zenon
                Network.
              </p>
            </div>
            <div className={styles.heroActions}>
              <Link
                className={styles.primaryCta}
                to="/docs/user-guide/intro">
                Start User Guide
              </Link>
              <Link
                className={styles.secondaryCta}
                to="/docs/developers/intro">
                Explore Developer Docs
              </Link>
            </div>
          </div>

          <div className={styles.statusStrip}>
            <div className={styles.statusMeta}>
              <span className={styles.statusLive}>
                <span className={styles.statusDot} aria-hidden="true" />
                <span>v0.3.0</span>
              </span>
              <span className={styles.statusSep} aria-hidden="true">
                ·
              </span>
              <span>macOS · Windows · Linux</span>
              <span className={styles.statusSep} aria-hidden="true">
                ·
              </span>
              <span>Non-Custodial</span>
              <span className={styles.statusSep} aria-hidden="true">
                ·
              </span>
              <span>Ledger</span>
              <span className={styles.statusSep} aria-hidden="true">
                ·
              </span>
              <span>Embedded Full Node</span>
            </div>
            <button
              type="button"
              className={styles.shortcutHint}
              onClick={focusNavbarSearch}>
              <span>Press</span>
              <kbd className={styles.shortcutKey}>Ctrl K</kbd>
              <span>to search</span>
            </button>
          </div>
        </div>
      </div>
    </header>
  );
}

function SecurityBanner(): ReactNode {
  return (
    <section
      className={styles.securitySection}
      aria-label="Non-custodial security notice">
      <div className="container">
        <div className={styles.securityBanner}>
          <div className={styles.securityIcon}>
            <AlertTriangleIcon />
          </div>
          <div className={styles.securityBody}>
            <span className={styles.securityEyebrow}>
              Non-Custodial Security Notice
            </span>
            <Heading as="h2" className={styles.securityTitle}>
              Your keys never leave your device
            </Heading>
            <p className={styles.securityText}>
              Syrius never transmits your 12- or 24-word recovery phrase,
              keystore file, or wallet password to any server. No developer,
              moderator, or community member will ever ask for your seed phrase.
              Always verify releases from the official{' '}
              <a
                href="https://github.com/zenon-network/syrius/releases"
                target="_blank"
                rel="noopener noreferrer"
                className={styles.securityLink}>
                zenon-network/syrius
              </a>{' '}
              repository.
            </p>
          </div>
          <Link
            className={styles.securityAction}
            to="/docs/user-guide/security-and-support/security-and-backups">
            Security &amp; Backups →
          </Link>
        </div>
      </div>
    </section>
  );
}

function JourneyTrack({
  id,
  eyebrow,
  title,
  subtitle,
  overviewLabel,
  overviewTo,
  cards,
  accent,
}: {
  id: string;
  eyebrow: string;
  title: string;
  subtitle: string;
  overviewLabel: string;
  overviewTo: string;
  cards: JourneyCard[];
  accent: 'znn' | 'qsr';
}): ReactNode {
  return (
    <section id={id} className={styles.trackSection}>
      <div className="container">
        <div className={styles.trackHeader}>
          <div>
            <span
              className={clsx(
                styles.trackEyebrow,
                accent === 'qsr' ? styles.trackEyebrowQsr : styles.trackEyebrowZnn,
              )}>
              {eyebrow}
            </span>
            <Heading as="h2" className={styles.trackTitle}>
              {title}
            </Heading>
            <p className={styles.trackSubtitle}>{subtitle}</p>
          </div>
          <Link className={styles.trackOverviewLink} to={overviewTo}>
            {overviewLabel} →
          </Link>
        </div>
        <div className={styles.cardGrid}>
          {cards.map((card) => (
            <article key={card.title} className={styles.card}>
              <div className={styles.cardTop}>
                <div
                  className={clsx(
                    styles.cardIcon,
                    accent === 'qsr' ? styles.cardIconQsr : styles.cardIconZnn,
                  )}>
                  {card.icon}
                </div>
                <span className={styles.cardBadge}>{card.badge}</span>
              </div>
              <Heading as="h3" className={styles.cardTitle}>
                <Link to={card.to} className={styles.cardTitleLink}>
                  {card.title}
                </Link>
              </Heading>
              <p className={styles.cardDescription}>{card.description}</p>
              <div className={styles.cardFooter}>
                <Link to={card.to} className={styles.cardPrimaryLink}>
                  Read guide →
                </Link>
                {card.secondaryLink && (
                  <Link
                    to={card.secondaryLink.to}
                    className={styles.cardSecondaryLink}>
                    {card.secondaryLink.label}
                  </Link>
                )}
              </div>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}

export default function Home(): ReactNode {
  const {siteConfig} = useDocusaurusContext();
  return (
    <Layout
      title={siteConfig.title}
      description="Official User Guide and Developer Documentation for the Syrius Zenon Network desktop wallet.">
      <div className={styles.pageShell}>
        <HeroSection />
        <main className={styles.main}>
          <SecurityBanner />
          <JourneyTrack
            id="user-guide"
            eyebrow="End-User Wallet Guide"
            title="Get Started with Syrius"
            subtitle="Step-by-step guides for installing Syrius, securing your seed phrase, using Plasma, staking, hardware wallets, and running nodes."
            overviewLabel="Browse User Guide"
            overviewTo="/docs/user-guide/intro"
            cards={USER_CARDS}
            accent="znn"
          />
          <JourneyTrack
            id="developers"
            eyebrow="Developer Documentation"
            title="Build & Contribute to Syrius"
            subtitle="Technical architecture, Flutter & FFI build workflows, BLoC rearchitecture guidelines, devnet integration testing, and contributor standards."
            overviewLabel="Browse Developer Docs"
            overviewTo="/docs/developers/intro"
            cards={DEVELOPER_CARDS}
            accent="qsr"
          />
        </main>
      </div>
    </Layout>
  );
}
