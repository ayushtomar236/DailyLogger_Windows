# Spec Delta

## Purpose

Provides a distraction-free, floating daily reflection desktop prompt with full visual and behavioral fidelity to the macOS HUD interface, including glassmorphism styling, history view, and keyboard-first navigation.

## ADDED Requirements

### Requirement: Floating HUD Window Geometry
The application window SHALL render as a floating, borderless desktop window measuring 540x380 pixels with a 14-pixel corner radius, centered on the user's active monitor, and set as topmost during active reflection.

#### Scenario: Window appearance on launch
- **WHEN** the application opens for reflection
- **THEN** the window displays centered with dimensions 540x380, 14px rounded corners, and above standard desktop windows

### Requirement: Visual HUD Header and Aesthetics
The header SHALL display a 44x44 rounded square icon with an indigo-to-purple gradient and white pencil glyph, a bold "Daily Reflection" title, a subtitle showing the target logical date ("What did you do today? • YYYY-MM-DD"), and a translucent dark HUD background.

#### Scenario: Header visual elements
- **WHEN** the prompt window is visible
- **THEN** the header renders the gradient icon, title, target logical date subtitle, and translucent backdrop

### Requirement: Prompt and History Toggle View
The UI SHALL provide a toggle action allowing the user to switch seamlessly between the active reflection editor and a history view displaying recent reflections.

#### Scenario: Toggle to history view
- **WHEN** user clicks the "History" button in the header
- **THEN** the content view switches to display past reflection cards and changes the button label to "Prompt"

#### Scenario: Toggle back to prompt editor
- **WHEN** user clicks the "Prompt" button from the history view
- **THEN** the content view switches back to the text editor preserving any previously entered unsaved draft text

### Requirement: Multiline Reflection Editor
The editor SHALL provide a multiline text area with subtle borders, comfortable line spacing, and placeholder text ("Write your accomplishments, key moments, learnings, or thoughts...\n(Press Ctrl + Enter to save)") visible when empty.

#### Scenario: Placeholder visibility
- **WHEN** the editor contains no text
- **THEN** the placeholder guidance is displayed, and hides immediately as soon as text is entered

### Requirement: Keyboard-First Save and Dismiss Actions
The prompt window SHALL support `Ctrl + Enter` to save the reflection and dismiss the prompt upon successful write, and `Esc` to dismiss immediately without saving.

#### Scenario: Save via keyboard shortcut
- **WHEN** user enters reflection text and presses `Ctrl + Enter`
- **THEN** the Save button displays a loading spinner, commits the record, and closes the window on confirmation

#### Scenario: Dismiss via Escape key
- **WHEN** user presses `Esc`
- **THEN** the prompt closes immediately without modifying or creating any log entries
