workspace {
    name "Mock PVE API Architecture"
    description "C4 Architecture Model for Mock Proxmox VE API Server"

    model {
        properties {
            "structurizr.groupSeparator" "/"
        }

        # External Actors
        developer = person "Developer" "Developer testing PVE client libraries or automation scripts" "Developer"
        ciSystem = softwareSystem "CI/CD System" "Continuous Integration system running automated tests" "CI/CD"
        clientLibrary = softwareSystem "PVE Client Library" "Client library for Proxmox VE (Python, JavaScript, Go, Elixir, etc.)" "Client"
        
        # Main System  
        mockPveApi = softwareSystem "Mock PVE API Server" "Containerized mock server simulating Proxmox VE REST API with Foundation ADR Sequence (ADR-0001: Architecture Decisions, ADR-0002: Development Best Practices, ADR-0003: Elixir/OTP Choice) and comprehensive supply chain security through SBOM generation" {
            tags "MockServer"
            
            # Containers
            webContainer = container "Web Server" "HTTP server handling API requests" "Elixir, Plug, Cowboy" {
                tags "WebServer"
            }
            
            stateContainer = container "State Manager" "In-memory state management for simulated resources" "Elixir, GenServer, ETS" {
                tags "StateManager"
            }
            
            capabilityContainer = container "Capability Engine" "Version-specific feature detection and validation" "Elixir" {
                tags "CapabilityEngine"
            }
            
            # Components within Web Server
            webContainer {
                router = component "HTTP Router" "Routes API requests to appropriate handlers" "Plug.Router"
                versionHandler = component "Version Handler" "Handles /api2/json/version endpoint" "Elixir Module"
                nodesHandler = component "Nodes Handler" "Handles /api2/json/nodes/* endpoints" "Elixir Module"
                clusterHandler = component "Cluster Handler" "Handles /api2/json/cluster/* endpoints" "Elixir Module"
                sdnHandler = component "SDN Handler" "Handles SDN endpoints (PVE 8.0+)" "Elixir Module"
                poolsHandler = component "Pools Handler" "Handles /api2/json/pools endpoints" "Elixir Module"
                accessHandler = component "Access Handler" "Handles /api2/json/access/* endpoints" "Elixir Module"
                middlewareHandler = component "Middleware Stack" "Logging, parsing, CORS handling" "Plug Middleware"
            }
            
            # Components within State Manager
            stateContainer {
                stateGenServer = component "State GenServer" "Serializes state modifications" "GenServer"
                etsStore = component "ETS Store" "Fast concurrent read access to state" "ETS Tables"
                resourceModeler = component "Resource Modeler" "Models VMs, containers, storage, etc." "Elixir Structs"
                stateValidator = component "State Validator" "Ensures state consistency" "Elixir Module"
            }
            
            # Components within Capability Engine
            capabilityContainer {
                versionMatrix = component "Version Matrix" "Maps features to PVE versions" "Elixir Map/Atoms"
                featureDetector = component "Feature Detector" "Checks if features are available for version" "Elixir Module"
                errorGenerator = component "Error Generator" "Generates appropriate HTTP errors for unsupported features" "Elixir Module"
            }
        }
        
        # External Systems
        containerRuntime = softwareSystem "Container Runtime" "Podman, Docker, or Kubernetes running the mock server" "Infrastructure"
        ociRegistry = softwareSystem "OCI Registry" "Container registry hosting mock-pve-api images (Docker Hub, Quay.io, etc.)" "Registry"
        
        # Relationships - External to System
        developer -> mockPveApi "Uses for local development and testing" "HTTP/REST"
        ciSystem -> mockPveApi "Integrates for automated testing" "HTTP/REST" 
        clientLibrary -> mockPveApi "Sends API requests to" "HTTP/REST"
        developer -> containerRuntime "Runs containers using" "Podman/Docker CLI"
        containerRuntime -> ociRegistry "Pulls images from" "HTTPS"
        containerRuntime -> mockPveApi "Runs and manages" "Container Lifecycle"
        
        # Relationships - System to Container
        webContainer -> stateContainer "Queries and updates resource state" "GenServer Calls"
        webContainer -> capabilityContainer "Checks feature availability" "Function Calls"
        stateContainer -> capabilityContainer "Validates state against version capabilities" "Function Calls"
        
        # Relationships - Within Web Container
        router -> middlewareHandler "Processes requests through" "Function Pipeline"
        router -> versionHandler "Routes version requests to" "Function Calls"
        router -> nodesHandler "Routes node requests to" "Function Calls" 
        router -> clusterHandler "Routes cluster requests to" "Function Calls"
        router -> sdnHandler "Routes SDN requests to" "Function Calls"
        router -> poolsHandler "Routes pool requests to" "Function Calls"
        router -> accessHandler "Routes access requests to" "Function Calls"
        
        # Handler to State relationships
        versionHandler -> stateGenServer "Gets version info from" "GenServer Calls"
        nodesHandler -> stateGenServer "Manages node resources in" "GenServer Calls"
        clusterHandler -> stateGenServer "Queries cluster state from" "GenServer Calls"
        sdnHandler -> stateGenServer "Manages SDN resources in" "GenServer Calls"
        poolsHandler -> stateGenServer "Manages resource pools in" "GenServer Calls"
        accessHandler -> stateGenServer "Manages users/groups in" "GenServer Calls"
        
        # Handler to Capability relationships
        versionHandler -> featureDetector "Gets capability info from" "Function Calls"
        nodesHandler -> featureDetector "Checks node feature availability" "Function Calls"
        sdnHandler -> featureDetector "Validates SDN feature availability" "Function Calls"
        poolsHandler -> featureDetector "Checks pool feature availability" "Function Calls"
        
        # Within State Manager
        stateGenServer -> etsStore "Stores state in" "ETS Operations"
        stateGenServer -> resourceModeler "Creates/updates resources using" "Function Calls"
        stateGenServer -> stateValidator "Validates state changes with" "Function Calls"
        etsStore -> resourceModeler "Retrieves modeled resources from" "ETS Lookups"
        
        # Within Capability Engine
        featureDetector -> versionMatrix "Looks up capabilities in" "Map Access"
        featureDetector -> errorGenerator "Creates error responses using" "Function Calls"
        errorGenerator -> versionMatrix "References version requirements from" "Map Access"
        
        # External system interactions
        clientLibrary -> router "Sends HTTP requests to" "HTTP/REST"
        router -> clientLibrary "Returns JSON responses to" "HTTP/REST"
        
        # Deployment Views
        deploymentEnvironment "Development" {
            deploymentNode "Developer Machine" "Docker Desktop or Podman" "Computer" {
                deploymentNode "Mock Container" "Alpine Linux + Elixir Runtime" "Container" {
                    containerInstance mockPveApi.webContainer
                    containerInstance mockPveApi.stateContainer
                    containerInstance mockPveApi.capabilityContainer
                }
            }
        }
        
        deploymentEnvironment "CI/CD Pipeline" {
            deploymentNode "CI Runner" "GitHub Actions, GitLab CI, etc." "CI Server" {
                deploymentNode "Service Container" "Mock PVE API for testing" "Container" {
                    containerInstance mockPveApi.webContainer 1
                    containerInstance mockPveApi.stateContainer 1
                    containerInstance mockPveApi.capabilityContainer 1
                    properties {
                        "CPU" "0.5 cores"
                        "Memory" "128MB"
                        "Port" "8006"
                    }
                }
                deploymentNode "Test Container" "Test runner executing tests" "Container" {
                    softwareSystemInstance clientLibrary
                }
            }
        }
        
        deploymentEnvironment "Production Testing" {
            deploymentNode "Kubernetes Cluster" "Production-like K8s environment" "K8s Cluster" {
                deploymentNode "Mock PVE Pod" "Kubernetes Pod running mock server" "K8s Pod" {
                    containerInstance mockPveApi.webContainer 2
                    containerInstance mockPveApi.stateContainer 2  
                    containerInstance mockPveApi.capabilityContainer 2
                    properties {
                        "Replicas" "2"
                        "CPU Limit" "500m"
                        "Memory Limit" "256Mi"
                        "Service Port" "8006"
                    }
                }
            }
        }
    }

    views {
        # System Context View
        systemContext mockPveApi "SystemContext" {
            title "Mock PVE API Server - System Context"
            description "High-level view of the Mock PVE API Server and its relationships"
            include *
            autoLayout lr
        }
        
        # Container View
        container mockPveApi "Container" {
            title "Mock PVE API Server - Container View"  
            description "Container-level view showing the internal structure"
            include *
            autoLayout tb
        }
        
        # Component View - Web Server
        component webContainer "WebServerComponents" {
            title "Web Server - Component View"
            description "Detailed view of HTTP request handling components"
            include *
            autoLayout tb
        }
        
        # Component View - State Manager
        component stateContainer "StateManagerComponents" {
            title "State Manager - Component View"
            description "Detailed view of state management components"
            include *
            autoLayout lr
        }
        
        # Component View - Capability Engine
        component capabilityContainer "CapabilityEngineComponents" {
            title "Capability Engine - Component View"
            description "Detailed view of version compatibility components"
            include *
            autoLayout lr
        }
        
        # Deployment Views
        deployment mockPveApi "Development" "DevelopmentDeployment" {
            title "Development Deployment"
            description "Local development environment deployment"
            include *
            autoLayout tb
        }
        
        deployment mockPveApi "CI/CD Pipeline" "CIPipelineDeployment" {
            title "CI/CD Pipeline Deployment"
            description "Continuous integration testing environment"
            include *
            autoLayout lr
        }
        
        deployment mockPveApi "Production Testing" "ProductionDeployment" {
            title "Production Testing Deployment"
            description "Production-like Kubernetes deployment for load testing"
            include *
            autoLayout tb
        }
        
        # Dynamic Views
        dynamic mockPveApi "APIRequestFlow" {
            title "API Request Processing Flow"
            description "How a typical API request is processed through the system"
            
            clientLibrary -> webContainer.router "1. Sends HTTP request (e.g., GET /api2/json/nodes)"
            webContainer.router -> webContainer.middlewareHandler "2. Process through middleware (logging, parsing)"
            webContainer.middlewareHandler -> webContainer.nodesHandler "3. Route to appropriate handler"
            webContainer.nodesHandler -> capabilityContainer.featureDetector "4. Check feature availability for PVE version"
            capabilityContainer.featureDetector -> capabilityContainer.versionMatrix "5. Look up capabilities"
            webContainer.nodesHandler -> stateContainer.stateGenServer "6. Query node state"
            stateContainer.stateGenServer -> stateContainer.etsStore "7. Retrieve from ETS tables"
            stateContainer.etsStore -> stateContainer.resourceModeler "8. Get modeled resources"
            stateContainer.resourceModeler -> webContainer.nodesHandler "9. Return node data"
            webContainer.nodesHandler -> clientLibrary "10. Send JSON response"
            
            autoLayout lr
        }
        
        dynamic mockPveApi "StateUpdateFlow" {
            title "State Update Flow"
            description "How resource state is updated when clients create/modify resources"
            
            clientLibrary -> webContainer.router "1. Send POST request (e.g., create VM)"
            webContainer.router -> webContainer.nodesHandler "2. Route to handler"
            webContainer.nodesHandler -> capabilityContainer.featureDetector "3. Validate feature support"
            webContainer.nodesHandler -> stateContainer.stateGenServer "4. Request state update"
            stateContainer.stateGenServer -> stateContainer.stateValidator "5. Validate state change"
            stateContainer.stateValidator -> stateContainer.resourceModeler "6. Create/update resource model"
            stateContainer.stateGenServer -> stateContainer.etsStore "7. Persist to ETS"
            stateContainer.stateGenServer -> webContainer.nodesHandler "8. Confirm update"
            webContainer.nodesHandler -> clientLibrary "9. Return success response"
            
            autoLayout lr
        }
        
        dynamic mockPveApi "VersionCompatibilityFlow" {
            title "Version Compatibility Check Flow"
            description "How version-specific features are validated"
            
            clientLibrary -> webContainer.router "1. Request SDN endpoint (PVE 8.0+ only)"
            webContainer.router -> webContainer.sdnHandler "2. Route to SDN handler" 
            webContainer.sdnHandler -> capabilityContainer.featureDetector "3. Check SDN capability"
            capabilityContainer.featureDetector -> capabilityContainer.versionMatrix "4. Look up version capabilities"
            capabilityContainer.versionMatrix -> capabilityContainer.errorGenerator "5. Feature not available (PVE 7.x)"
            capabilityContainer.errorGenerator -> webContainer.sdnHandler "6. Generate 501 error"
            webContainer.sdnHandler -> clientLibrary "7. Return 'Not Implemented' response"
            
            autoLayout lr
        }

        # Filtered views for different audiences
        filtered "SimplifiedView" {
            title "Simplified System View"
            description "Simplified view for non-technical stakeholders"
            mode exclude
            tags "Internal,Implementation"
        }
        
        styles {
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Developer" {
                background #1168bd
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "MockServer" {
                background #2e8b57
                color #ffffff
            }
            element "Client" {
                background #ff6b6b
            }
            element "CI/CD" {
                background #4ecdc4
            }
            element "Infrastructure" {
                background #95a5a6
            }
            element "Registry" {
                background #f39c12
            }
            element "Container" {
                background #3498db
                color #ffffff
            }
            element "WebServer" {
                background #e74c3c
                color #ffffff
            }
            element "StateManager" {
                background #9b59b6
                color #ffffff
            }
            element "CapabilityEngine" {
                background #f1c40f
                color #000000
            }
            element "Component" {
                background #85C1E9
                color #000000
            }
            element "Computer" {
                shape WebBrowser
                background #232323
                color #ffffff
            }
            element "CI Server" {
                background #4ecdc4
                shape Robot
            }
            element "K8s Cluster" {
                background #326ce5
                shape Cylinder
            }
            element "K8s Pod" {
                background #85C1E9
                shape Component
            }
            relationship "Relationship" {
                routing orthogonal
            }
        }
    }
    
    configuration {
        scope softwaresystem
    }
}