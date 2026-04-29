library(DiagrammeR)

mermaid("
        graph LR
          A[User Input] --> B[Kimi]
          B[Kimi] --> C{Valid JSON}
          C{Valid JSON} -->|Yes| D[Save and Parse JSON]
          C{Valid JSON} -->|No| B[Kimi]
        ")
