#!/bin/bash

JENKINS_URL="http://43.205.143.168:8080/"
ADMIN_USER="kkfunda"
ADMIN_TOKEN="115c91d5da2e0a569d641179ad0ee3c481"

# Format: username:password
USERS=(
  "kk1:Password123!"
  "kk2:Password123!"
  "kk3:Password123!"
)

for USER_INFO in "${USERS[@]}"; do
    USERNAME=$(echo "$USER_INFO" | cut -d':' -f1)
    PASSWORD=$(echo "$USER_INFO" | cut -d':' -f2-)

    GROOVY_SCRIPT=$(cat <<EOF
import jenkins.model.*
import hudson.security.*

def instance = Jenkins.get()
def realm = instance.getSecurityRealm()

if (realm instanceof HudsonPrivateSecurityRealm) {
    if (realm.getUser("${USERNAME}") == null) {
        realm.createAccount("${USERNAME}", "${PASSWORD}")
        println("Created user: ${USERNAME}")
    } else {
        println("User already exists: ${USERNAME}")
    }
}
EOF
)

    curl -s -X POST \
      -u "${ADMIN_USER}:${ADMIN_TOKEN}" \
      --data-urlencode "script=${GROOVY_SCRIPT}" \
      "${JENKINS_URL}/scriptText"

    echo
done
