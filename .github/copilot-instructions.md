# Agent Working Instructions

## Project files and workspace

- The project is developed locally on macOS in Android Studio.
- Use the IDE workspace tools (`list_dir`, `read_file`, `file_search`, `grep_search`, `open_file`) when inspecting or modifying project files.
- Do not assume that the OpenClaw workspace filesystem is the same filesystem as the IDE workspace.
- Never conclude that the project is inaccessible merely because `/Users/...` does not exist in the OpenClaw execution environment.
- The IDE workspace is the authoritative source for the project files.

## Terminal and development commands

- `run_in_terminal` may be used for development commands such as Flutter, Dart, Git, Android SDK, ADB, builds, tests, formatting, linting, and emulator operations.
- Before using `run_in_terminal` for a project-related operation, determine whether the terminal is running on the local macOS machine.
- Do not use the terminal to locate project source files when IDE workspace tools can access them.
- If the terminal is not the macOS development machine, do not use it as evidence that the project does not exist.
- Never claim that a build, test, emulator, or command was executed unless it was actually executed successfully.

## Code review

- When asked to review, assess, audit, or inspect the project, inspect the actual source code.
- Do not rely only on README files, project structure, previous assessments, or assumptions.
- Verify important findings against the implementation.
- For significant findings provide:
    - exact file path
    - class/function
    - current behavior
    - why it matters
    - severity
    - concrete recommended fix
    - tests or verification steps

## Implementation

- Before modifying code, inspect the relevant existing implementation.
- Follow the existing architecture and conventions.
- Prefer minimal, idiomatic changes over unnecessary rewrites.
- Do not introduce dependencies or abstractions unless they are justified by the existing project.
- When implementing a fix, inspect related code and call sites before changing it.

## Testing

- After making changes, run the relevant analyzer, formatter, tests, or build when appropriate.
- Use the terminal for commands that genuinely need execution.
- Use workspace tools for inspecting source files.
- Report actual command results rather than assuming success.

## Safety

- If the user asks for a review, assessment, investigation, or explanation only, do not modify files.
- Do not invent access to files, commands, devices, emulators, or tools.
- If a required tool is unavailable, state exactly which capability is unavailable and why.