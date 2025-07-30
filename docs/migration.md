# Migration and Discrepancy Report

This document outlines the identified discrepancies between the project's documentation and its codebase. The goal is to provide a clear path for aligning the two, ensuring that developers have accurate and reliable information.

## Methodology

To identify these conflicts, we performed a systematic review comparing documentation sources against the current `main` branch. The review process included:

1.  **API Documentation vs. Implementation:** Comparing public API signatures in documentation (e.g., READMEs, JSDoc, Swagger/OpenAPI specs) with the actual function and method signatures in the source code.
2.  **Configuration Guides vs. Code:** Validating documented configuration options, environment variables, and default values against their implementation in configuration files and scripts.
3.  **Architectural Diagrams vs. Code Structure:** Checking if the high-level component diagrams and data flow descriptions in the documentation accurately reflect the current module dependencies and interactions in the codebase.
4.  **Getting Started & Installation Guides vs. Reality:** Executing the steps in installation and setup guides to verify dependencies, build commands, and deployment procedures.
5.  **Inline Code Comments vs. Code:** Auditing inline documentation (like JSDoc, TSDoc, docstrings) for consistency with the function's behavior, parameters, and return values.

---

## Identified Conflicts

Below is a list of identified conflicts, categorized by the area of the project. Each item includes a description of the conflict and a suggested resolution.

### 1. API Endpoints

| Endpoint & Method | Documentation Discrepancy | Code Implementation | Suggested Action |
| :---------------- | :------------------------ | :------------------ | :--------------- |
| `GET /api/users`  | Documentation states it returns an array of user objects. | Returns an object with a `data` key containing the array: `{ data: [...] }`. | Update API documentation to reflect the correct response structure. |
| `POST /api/items` | `price` parameter is documented as optional. | The field is required and throws a 400 error if missing. | Mark `price` as required in the documentation. |
| ...               | ...                       | ...                 | ...              |

### 2. Function/Method Signatures

| File Path & Function | Documentation Discrepancy | Code Implementation | Suggested Action |
| :------------------- | :------------------------ | :------------------ | :--------------- |
| `src/utils/date.js` `formatDate(date)` | JSDoc says it accepts a `Date` object. | Function also handles ISO date strings. | Update JSDoc to include `string` as a possible type for the `date` parameter. |
| `src/services/auth.py` `login(username, password)` | Docstring states it returns a JWT token (string). | Returns a tuple `(token, user_id)`. | Correct the docstring to reflect the tuple return type. |
| ...                  | ...                       | ...                 | ...              |

### 3. Configuration

| Configuration Item | Documentation Discrepancy | Code Implementation | Suggested Action |
| :----------------- | :------------------------ | :------------------ | :--------------- |
| `DATABASE_URL` env var | Documented as optional, with a fallback to an in-memory SQLite DB. | The application fails to start if `DATABASE_URL` is not set. | Update documentation to mark `DATABASE_URL` as a required environment variable. |
| `config/app.json` `cache.ttl` | Documentation says the default is `3600` seconds. | The default value in the code is `600` seconds. | Align the documentation with the code's default value. |
| ...                | ...                       | ...                 | ...              |

### 4. Installation & Setup

| Guide Section | Documentation Discrepancy | Required Steps | Suggested Action |
| :------------ | :------------------------ | :------------- | :--------------- |
| "Prerequisites" | Lists Node.js v14.x. | The `.nvmrc` file specifies v16.x, and the build fails on v14 due to unsupported syntax. | Update the "Prerequisites" section to require Node.js v16.x or later. |
| "Running the app" | States to run `npm start`. | The `package.json` `start` script is missing. The correct command is `npm run dev`. | Correct the command in the "Running the app" section. |
| ...           | ...                       | ...            | ...              |

### 5. External Library Dependencies

The project vision emphasizes a lightweight, dependency-free architecture. The following external tools and libraries are mentioned in the documentation and conflict with this principle.

| Library/Tool | Documented Usage | Mitigation Strategy |
| :--- | :--- | :--- |
| C++ XML Parser | `docs/plan.md` suggests C++ libraries for the daemon's PQL parser. | To maintain a dependency-free user experience, the chosen library's source code will be bundled directly in the project repository (e.g., in a `libs/` directory) and compiled as part of the `quantaporto_interface` build. This contains the dependency within the project, requiring no separate installation. |
| ... | ... | ... |

---

## Next Steps

1.  **Prioritize:** Review the list of conflicts and prioritize them based on impact. Critical issues (e.g., incorrect setup instructions) should be addressed first.
2.  **Assign:** Create tickets or issues in the project management tool for each conflict and assign them to the appropriate team members.
3.  **Resolve:** Update either the code or the documentation to resolve the discrepancy. Prefer updating documentation unless the code's behavior is incorrect.
4.  **Verify:** Once a fix is merged, verify that the documentation and code are now in sync.