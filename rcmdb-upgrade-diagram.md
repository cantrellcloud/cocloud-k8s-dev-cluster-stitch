```mermaid
flowchart TD
    %% STYLE & LAYOUT DIRECTIVES
    classDef phase fill:#f4f4f4,stroke:#0d47a1,stroke-width:1px,color:#0d47a1,rounded-corners,shadow;
    classDef action fill:#ffffff,stroke:#1976d2,stroke-width:1px,color:#000;
    linkStyle default stroke-width:1px;

    %% LEGACY START
    subgraph P0["Phase 0 – Current State<br/>RHEL 8 VM (Docker)"]:::phase
        A1["Rocket.Chat 6.4.5<br/><i class='lucide lucide-message-circle'/>"]:::action
        A2["MongoDB 5.0.23<br/><i class='lucide lucide-database'/>"]:::action
        A1 --> A2
    end

    %% MIGRATE DATABASE
    subgraph P1["Phase 1 – DB Lift & Shift"]:::phase
        B1["<b>mongodump + uploads</b><br/>export"]:::action
        B2["Restore to K8s<br/>MongoDB 5.0.23<br/>(StatefulSet)"]:::action
        B1 --> B2
    end
    P0 -->|“Air‑gap data freight”| P1

    %% APP CUT‑OVER
    subgraph P2["Phase 2 – App Cut‑Over"]:::phase
        C1["Deploy RC 6.4.5<br/>→ points to K8s DB"]:::action
    end
    P1 -->|“Re‑point connection string”| P2

    %% DB UPGRADES
    subgraph P3["Phase 3 – DB Upgrade 5 → 6"]:::phase
        D1["Rolling upgrade<br/>Mongo 6.0.13"]:::action
    end
    subgraph P4["Phase 4 – DB Upgrade 6 → 7"]:::phase
        E1["Rolling upgrade<br/>Mongo 7.0.19"]:::action
    end
    P2 --> P3 --> P4

    %% APP UPGRADES
    subgraph P5["Phase 5 – App Upgrade<br/>6.4.5 → 6.15.x"]:::phase
        F1["RC 6.15.x<br/>(latest LTS)"]:::action
    end
    subgraph P6["Phase 6 – App Upgrade<br/>6.15 → 7.0.x"]:::phase
        G1["RC 7.0.0"]:::action
    end
    subgraph P7["Phase 7 – App Patch<br/>7.0.x → 7.6.0"]:::phase
        H1["RC 7.6.0"]:::action
    end
    P4 --> P5 --> P6 --> P7

    %% DECOMMISSION
    subgraph P8["Phase 8 – Legacy VM Sunset"]:::phase
        I1["Archive & power‑off<br/>RHEL 8 VM"]:::action
    end
    P7 -->|“Cut‑over stable | 30‑day soak”| P8
```
