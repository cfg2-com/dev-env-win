# Git Commit Skill

This skill guides the agent in creating a conventional and descriptive git commit message.

## Procedure

1.  **Stage and Analyze Changes:**
    *   Execute `git add .` to stage all changed files.
    *   Execute `git diff --staged` to get the full diff of changes to be committed.
    *   Review the diff to understand the scope and nature of the changes.

2.  **Write the Subject Line:**
    *   The subject line must be a single line of 50 characters or less.
    *   Use the format: `<scope>: <subject>`
        *   `<scope>` indicates the part of the codebase affected (e.g., `api`, `ui`, `parser`, `misc`). Use `misc` by default if a specific scope can not be determined.
        *   `<subject>` is a short, imperative-mood description of the change (e.g., "add user login endpoint", not "added user login endpoint").
    *   Example: `api: add user login endpoint`

3.  **Write the Body (Optional):**
    *   If the change is complex, provide a more detailed explanation in the body.
    *   Separate the subject from the body with a blank line.
    *   Explain the "what" and "why" of the change, not the "how". The code itself shows the "how".
    *   Wrap lines at 72 characters.

4.  **Write the Footer (Optional):**
    *   Separate the body from the footer with a blank line.
    *   Use the footer for two main purposes:
        *   **Breaking Changes:** Start with `BREAKING CHANGE:` followed by a description of the breaking change.
        *   **Issue References:** Reference issues that this commit closes (e.g., `Closes #123`, `Fixes #456`).

5.  **Assemble the Commit Message:**
    *   Combine the subject, body, and footer into a single message.
    *   Example:
        ```
        auth: implement JWT-based authentication

        The previous session-based authentication was not scalable for the
        new microservices architecture. This commit introduces JWT for
        stateless authentication.

        - A new /login endpoint is created to issue tokens.
        - Middleware is added to protect routes.

        Closes #42
        ```

6.  **Commit the Changes:**
    *   Use the generated message to commit the changes:
        ```bash
        git commit -m "<subject>" -m "<body>" -m "<footer>"
        ```
    *   Alternatively, save the message to a file and use `git commit -F <file>`.