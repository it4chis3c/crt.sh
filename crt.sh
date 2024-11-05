#!/bin/bash

echo "
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|               crt.sh                |
+   site : crt.sh Certificate Search  +
|         Twitter: it4chis3c          |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
"

# Function: Help
# Purpose: Display the help message with usage instructions.
Help() {
    echo "Options:"
    echo ""
    echo "-h          Help"
    echo "-d          Search Domain Name  ( $0 -d hackerone.com )"
    echo "-org        Search Organization Name ( $0 -org hackerone+inc )"
    echo "-f <file>   Specify file with list of domains to search"
    echo "-o          Specify output file to save results"
    echo ""
}

# Function: CleanResults
# Purpose: Clean and filter the results by removing unwanted characters and duplicates.
CleanResults() {
    sed 's/\\n/\n/g' | \
    sed 's/\*.//g' | \
    sed -r 's/([A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4})//g' | \
    sort | uniq
}

# Function: Domain
# Purpose: Search for certificates associated with a specific domain name.
Domain() {
    local domain="$1"
    local output_file="$2"

    response=$(curl -s "https://crt.sh?q=%.$domain&output=json")

    if [ -z "$response" ]; then
        echo "No results found for domain $domain"
        return
    fi

    results=$(echo "$response" | jq -r ".[].common_name,.[].name_value" | CleanResults)

    if [ -z "$results" ]; then
        echo "No valid results found for domain $domain"
        return
    fi

    echo "$results" >> "$output_file"
    echo -e "\e[32m[+]\e[0m Total results for $domain: \e[31m$(echo "$results" | wc -l)\e[0m"
}

# Function: Organization
# Purpose: Search for certificates associated with a specific organization name.
Organization() {
    local organization="$1"
    local output_file="$2"

    response=$(curl -s "https://crt.sh?q=$organization&output=json")

    if [ -z "$response" ]; then
        echo "No results found for organization $organization"
        return
    fi

    results=$(echo "$response" | jq -r ".[].common_name" | CleanResults)

    if [ -z "$results" ]; then
        echo "No valid results found for organization $organization"
        return
    fi

    echo "$results" >> "$output_file"
    echo -e "\e[32m[+]\e[0m Total results for $organization: \e[31m$(echo "$results" | wc -l)\e[0m"
}

# Main Script Logic
output_file="output/results.txt"

while getopts "h:d:o:f:-:" option; do
    case $option in
        h) # Display help
            Help
            exit
            ;;
        d) # Search for a single domain
            req=$OPTARG
            Domain "$req" "$output_file"
            ;;
        o) # Custom output file
            output_file=$OPTARG
            ;;
        f) # File containing a list of domains
            file=$OPTARG
            if [ -f "$file" ]; then
                while IFS= read -r line; do
                    Domain "$line" "$output_file"
                done < "$file"
            else
                echo "Error: File $file not found."
                exit 1
            fi
            ;;
        -) # Handle long options
            case "$OPTARG" in
                org) # Search for organization name
                    val="${!OPTIND}"; OPTIND=$((OPTIND + 1))
                    Organization "$val" "$output_file"
                    ;;
                *) # Invalid option, display help
                    Help
                    exit 1
                    ;;
            esac
            ;;
        *) # Invalid option, display help
            Help
            exit 1
            ;;
    esac
done

# Display final output location
echo -e "\e[32m[+]\e[0m Results saved in $output_file"
