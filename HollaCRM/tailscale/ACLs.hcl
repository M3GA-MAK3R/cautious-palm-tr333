# Tailscale ACLs for HollaCRM
# Separate ACLs for dev, staging, and production environments

# Groups for different access levels
{
    "groups": [
        {
            "name": "group:admins",
            "users": ["admin@hollacrm.com"],
        },
        {
            "name": "group:developers",
            "users": [
                "dev1@hollacrm.com",
                "dev2@hollacrm.com",
                "cicd@hollacrm.com"
            ],
        },
        {
            "name": "group:devops",
            "users": [
                "ops1@hollacrm.com",
                "ops2@hollacrm.com"
            ],
        },
        {
            "name": "group:qa",
            "users": [
                "qa1@hollacrm.com",
                "qa2@hollacrm.com"
            ],
        },
        {
            "name": "group:customers",
            "users": [
                # Auto-populated with customer emails
            ],
        },
    ],
    
    "tagOwners": {
        "tag:hollacrm": ["group:admins", "group:devops"],
        "tag:hollacrm-dev": ["group:developers"],
        "tag:hollacrm-staging": ["group:qa", "group:devops"],
        "tag:hollacrm-prod": ["group:admins", "group:devops"],
    },

    "acls": [
        # Development environment access
        {
            "action": "accept",
            "src":    ["group:developers", "group:devops"],
            "dst":    ["tag:hollacrm-dev:*"],
        },
        
        # Staging environment access
        {
            "action": "accept",
            "src":    ["group:qa", "group:developers", "group:devops"],
            "dst":    ["tag:hollacrm-staging:*"],
        },
        
        # Production environment access (restricted)
        {
            "action": "accept",
            "src":    ["group:admins", "group:devops"],
            "dst":    ["tag:hollacrm-prod:*"],
        },
        
        # Customer access (to specific instances only)
        {
            "action": "accept",
            "src":    ["group:customers"],
            "dst":    ["autogroup:member"],
            "expr": [
                {"name": "prefix", "operator": "contains", "value": "customer-"}
            ],
        },
        
        # CI/CD server access
        {
            "action": "accept",
            "src":    ["autogroup:internet"],
            "dst":    ["tag:hollacrm:443"],
            "expr": [
                {"name": "tailscale_ip", "operator": "=", "value": "100.64.0.100"}
            ],
        },
    ],

    "ssh": [
        # SSH access to production servers (restricted)
        {
            "action":     "check",
            "src":        ["group:admins", "group:devops"],
            "dst":        ["tag:hollacrm-prod:*"],
            "users":      ["ubuntu", "root"],
            "checkPeriod": "1h",
        },
        
        # SSH access to staging servers
        {
            "action":     "check",
            "src":        ["group:qa", "group:developers", "group:devops"],
            "dst":        ["tag:hollacrm-staging:*"],
            "users":      ["ubuntu", "root"],
            "checkPeriod": "30m",
        },
        
        # SSH access to development servers
        {
            "action": "accept",
            "src":    ["group:developers", "group:devops"],
            "dst":    ["tag:hollacrm-dev:*"],
            "users":  ["ubuntu", "root"],
        },
    ],

    # ACL for exit nodes (if needed)
    "nodeAttrs": [
        {
            "target": ["tag:hollacrm-prod"],
            "attr":   ["exit-node"],
            "value":  ["true"],
        },
    ],
}