# Parallel

> **Two paths. One choice. Explore two believable futures.**

Parallel is a reflective decision-exploration app that helps you visualize the consequences of your choices through AI-generated narrative fiction. Simply describe a decision you're facing, and Parallel will craft two intimate stories: one where you act, and one where you don't.

<p align="center">
  <img src="assets/app_icon.png" alt="Parallel Logo" width="120"/>
</p>

---

## 🔑 Quick API Setup

> [!IMPORTANT]
> ### ⚡ Required Configuration Before Running
> Parallel uses **Google Gemini (Free Tier)** as its primary narrative intelligence engine. To run the app, you need a free API key from Google AI Studio.
> 
> 1. **Copy the environment template:**
>    ```bash
>    cp .env.example .env
>    ```
> 2. **Add your free Google Gemini API key to `.env`:**
>    ```env
>    GEMINI_API_KEY=your_actual_gemini_api_key_here
>    ```
>    👉 Get a free Gemini API key in seconds: **[Google AI Studio](https://aistudio.google.com/)** *(No credit card required)*
> 
> > [!NOTE]
> > Never commit your `.env` file to Git. The `.gitignore` file is pre-configured to keep your keys safe.

---

## ✨ Features

- **Dual Narrative Generation** — AI-powered stories exploring both paths of your decision (Act vs. Don't Act)
- **Primary AI: Gemini 3.5 Flash** — High-speed (~5s) reflective storytelling with zero token hallucination
- **Seamless Fallback** — Secondary fallback powered by OpenRouter (`nvidia/nemotron-3-super-120b-a12b:free`)
- **Tone Selection** — Choose between *Reflective* (serious, introspective) or *Light* (depth without gravity)
- **Multi-Language & Dialect Matching** — Detects and writes in your exact language/dialect (English, French, Arabic, Tunisian Derja)
- **Parallel Path Animation** — Custom 60fps vector animation visualizing the diverging streams of choice
- **Memory Continuity** — Subtly recognizes recurring themes across past decisions
- **Keyboard-Adaptive UX** — Docked action bar with safe space that automatically floats above the keyboard
- **Local History & Privacy** — Up to 50 past explorations stored entirely on-device (FIFO storage)

---

## 📱 Screenshots

<p align="center">
  <img src="screens/1.png" alt="Splash Screen" width="200"/>
  <img src="screens/2.png" alt="Launch Screen" width="200"/>
  <img src="screens/3.png" alt="Input Screen" width="200"/>
</p>

<p align="center">
  <img src="screens/4.png" alt="Result Screen" width="200"/>
  <img src="screens/5.png" alt="History Screen" width="200"/>
</p>

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.10.3 or higher
- A free Google Gemini API key from [Google AI Studio](https://aistudio.google.com/)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Maher-Tec/Parallel.git
   cd Parallel
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure environment**
   ```bash
   cp .env.example .env
   ```
   Open `.env` and paste your key:
   ```env
   GEMINI_API_KEY=your_gemini_api_key_here
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

---

## 🏗️ Project Structure

```
lib/
├── main.dart                      # App entry point, .env loading & theme setup
├── theme/
│   └── app_theme.dart             # Dark literary palette & typography
├── screens/
│   ├── splash_screen.dart         # Startup brand animation
│   ├── launch_screen.dart         # Intro screen with mini path motif
│   ├── input_screen.dart          # Decision input, tone chips, docked CTA bar
│   ├── pause_screen.dart          # Async AI loading with ParallelPathAnimation
│   ├── result_screen.dart         # Dual-tab narrative reading view
│   ├── history_screen.dart        # Saved reflections repository
│   └── about_screen.dart          # Philosophy & app info
├── services/
│   ├── ai_service.dart            # Primary Gemini 3.5 Flash integration
│   ├── fallback_service.dart      # OpenRouter Nemotron fallback
│   ├── memory_service.dart        # Tag extraction & continuity matching
│   ├── input_validator.dart       # Layer 2 gibberish/repetition heuristics
│   └── intent_gatekeeper.dart     # Layer 1 decision-worthiness filter
├── models/
│   └── decision_entry.dart        # Local decision entry model
├── storage/
│   └── local_store.dart           # SharedPreferences FIFO repository
└── widgets/
    ├── ambient_background.dart    # Ambient background particles
    └── parallel_path_animation.dart # Custom 60fps vector bifurcating path
```

---

## 🎨 Design Philosophy

- **Literary Aesthetic** — Inspired by opening a physical book, not an app
- **Emotional Safety** — No advice, no judgment, no moral conclusions
- **Grounded Realism** — Concrete sensory details and human consequence
- **Calm Contrast** — Deep obsidian (`#0A0A0A`) with warm parchment typography (`#F5F0E8`)

---

## 📄 License

Distributed under the MIT License. See [LICENSE](LICENSE) for more information.

---

## 👨‍💻 Author

**Maher Ahmed**  
[GitHub](https://github.com/Maher-Tec)

---

<p align="center">
  <i>"The future is not a single line. It branches."</i>
</p>
