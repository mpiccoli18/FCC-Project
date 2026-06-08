# Automated Distaster Recovery and Secure BackUps

## Group Project

Members of this group:
- Piccoli Marco
- Santaniello Mattia.

## The idea

Real world applications often rely on virtualization systems in order to maintain the offered service alive across faults and other issues. Kubernetes supports the definition and the management of multiple containers, following a duplication mechanism where a single part of the application is distributed among different replicas. Although this process increases the resiliency of the service, it is still possible that crashes could compromise the whole system; for this reason, it is fundamental to provide a crash recovery process by implementing a backup mechanism. This project aims to implement such a system by deploying a stateful application and simulating a crash scenario.

## UML Design

To understand better how the diffenent services are connected to each other, a UML diagram is presented below: 

```mermaid
flowchart TB
    Client((Client)) -- "HTTP Requests (Port 5000)" --> API

    subgraph IaaS["OpenNebula (IaaS / Virtual Machines)"]
        subgraph K8s["Kubernetes Cluster (Custom PaaS)"]
            
            API["Flask CRUD API\n(Deployment)"] -- "SQL Queries" --> DB[("MySQL Database\n")]

            subgraph Recovery["Disaster Recovery System"]
                direction LR
                Velero["Velero Server\n(Backup Controller)"] -. "Snapshots Volumes" .-> DB
                Velero -- "S3 API Uploads" --> MinIO[("MinIO Tenant\n(Object Storage)")]
            end
        end
    end
    
    classDef external fill:#f9f9f9,stroke:#333,stroke-width:2px;
    classDef paas fill:#e1f5fe,stroke:#0288d1,stroke-width:2px;
    classDef iaas fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px;
    
    class Client external;
    class K8s paas;
    class IaaS iaas;
```
While, in the following figure, is illustrated how the backups actually works. As you can see, there are two main phases: **Snapshot** and **Upload**.

```mermaid
sequenceDiagram
    autonumber
    actor Clock as Velero Cron Scheduler
    participant K8s as Kubernetes API
    participant Velero as Velero Server
    participant DB as MySQL (Persistent Volume)
    participant MinIO as MinIO (Object Storage)

    Clock->>Velero: Time = 02:00 AM (Trigger daily-cluster-backup)
    
    rect rgb(243, 229, 245)
        note right of Velero: Phase 1: Snapshot State & Data
        Velero->>K8s: Query cluster metadata (Secrets, Deployments)
        K8s-->>Velero: Return YAML configurations
        Velero->>DB: Trigger storage provisioner for volume snapshot
        DB-->>Velero: Snapshot complete
    end
    
    rect rgb(225, 245, 254)
        note right of Velero: Phase 2: Secure Upload
        Velero->>Velero: Compress metadata and snapshot into tarball
        Velero->>MinIO: Upload backup artifacts (S3 API)
        MinIO-->>Velero: Upload Successful (200 OK)
    end

    Velero->>K8s: Update Backup Status to "Completed"
    K8s-->>Velero: Log successful automated run
```
Instead, to retrieve correctly the backups we made before, we simply **Fetch** and **Rebuild** the architecture with the last Snapshot available, as presented in the figure below:

```mermaid
sequenceDiagram
    autonumber
    actor Admin as System Admin (CLI)
    participant K8s as Kubernetes API
    participant Velero as Velero Server
    participant MinIO as MinIO (Object Storage)
    participant DB as MySQL (Persistent Volume)

    Admin->>K8s: Run `velero restore create --from-backup <name>`
    K8s->>Velero: Trigger Restore Controller
    
    rect rgb(225, 245, 254)
        note right of Velero: Phase 1: Fetch Artifacts
        Velero->>MinIO: Request backup tarball & metadata (S3 API)
        MinIO-->>Velero: Download successful
    end
    
    rect rgb(243, 229, 245)
        note right of Velero: Phase 2: Rebuild Infrastructure & Data
        Velero->>K8s: Apply YAML configurations (Recreate Secrets, Deployments)
        Velero->>DB: Trigger storage provisioner to restore volume snapshot
        DB-->>Velero: Volume data restored
        K8s-->>DB: Spin up MySQL pods attached to restored volume
    end

    Velero->>K8s: Update Restore Status to "Completed"
    K8s-->>Admin: System fully restored!
```

## How to build the system?

In this section is illustrated the way to create and setup each and every single one of the services inside the architecture. 

### Velero
### MinIO
### MySQL
### Kubernetes
### CRUD API
