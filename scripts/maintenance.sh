#!/bin/bash

# Human Benchmark Maintenance Mode Controller
# This script provides easy access to control maintenance mode

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if Node.js script exists
SCRIPT_PATH="scripts/set_maintenance_mode.js"
if [ ! -f "$SCRIPT_PATH" ]; then
    print_error "Maintenance script not found at $SCRIPT_PATH"
    exit 1
fi

# Check if service account key exists
SERVICE_ACCOUNT="serviceAccountKey.json"
if [ ! -f "$SERVICE_ACCOUNT" ]; then
    print_warning "Service account key not found at $SERVICE_ACCOUNT"
    print_info "Please download your Firebase service account key from:"
    print_info "https://console.firebase.google.com/project/human-benchmark-80a9a/settings/serviceaccounts/adminsdk"
    print_info "And save it as 'serviceAccountKey.json' in the project root"
    exit 1
fi

# Main function
main() {
    local command="$1"
    local message="$2"
    
    case "$command" in
        "enable")
            if [ -z "$message" ]; then
                message="App is under maintenance"
            fi
            print_info "Enabling maintenance mode with message: $message"
            node "$SCRIPT_PATH" enable "$message"
            ;;
            
        "disable")
            print_info "Disabling maintenance mode"
            node "$SCRIPT_PATH" disable
            ;;
            
        "status")
            print_info "Checking maintenance status"
            node "$SCRIPT_PATH" status
            ;;
            
        *)
            echo -e "${BLUE}🔧 Human Benchmark Maintenance Mode Controller${NC}"
            echo ""
            echo "Usage:"
            echo "  $0 enable [message]  - Enable maintenance mode"
            echo "  $0 disable           - Disable maintenance mode"
            echo "  $0 status            - Check current status"
            echo ""
            echo "Examples:"
            echo "  $0 enable \"Scheduled maintenance - back in 2 hours\""
            echo "  $0 disable"
            echo "  $0 status"
            echo ""
            echo "Note: Make sure you have the Firebase service account key (serviceAccountKey.json)"
            echo "      in the project root directory."
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
