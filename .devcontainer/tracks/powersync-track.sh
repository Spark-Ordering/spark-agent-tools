#!/bin/bash
set -e

# PowerSync Track: MongoDB + PowerSync Service + JWT Keys
# Depends on SparkPos track (needs Supabase Postgres running)

echo "[powersync] Starting track..."

# Wait for Supabase to be ready (provides Postgres)
while [ ! -f /tmp/sparkpos-track-done ]; do
  echo "[powersync] Waiting for Supabase..."
  sleep 2
done

WORKDIR="/workspaces/spark-agent-tools"
CONFIG_DIR="$WORKDIR/.devcontainer/powersync-config"

# Create config directory
mkdir -p "$CONFIG_DIR"

# Start MongoDB with replica set
echo "[powersync] Starting MongoDB..."
docker run -d --name mongo \
  --network host \
  mongo:7.0 --replSet rs0 --bind_ip_all --quiet

# Wait for MongoDB to be ready
echo "[powersync] Waiting for MongoDB to be ready..."
sleep 5
until docker exec mongo mongosh --eval "db.runCommand('ping').ok" --quiet 2>/dev/null; do
  echo "[powersync] Waiting for MongoDB..."
  sleep 2
done

# Initialize replica set
echo "[powersync] Initializing MongoDB replica set..."
docker exec mongo mongosh --eval "rs.initiate({_id: 'rs0', members: [{_id: 0, host: 'localhost:27017'}]})" --quiet

# Wait for replica set to be ready
sleep 3

# Generate RSA key pair and convert to JWK format
echo "[powersync] Generating JWT keys..."
node << 'KEYGEN'
const crypto = require('crypto');
const fs = require('fs');

const configDir = '/workspaces/spark-agent-tools/.devcontainer/powersync-config';

const { publicKey, privateKey } = crypto.generateKeyPairSync('rsa', {
  modulusLength: 2048,
});

const publicJwk = publicKey.export({ format: 'jwk' });
const privateJwk = privateKey.export({ format: 'jwk' });

// Add required fields for PowerSync
publicJwk.kid = 'powersync-dev-key';
publicJwk.use = 'sig';
publicJwk.alg = 'RS256';

privateJwk.kid = 'powersync-dev-key';
privateJwk.use = 'sig';
privateJwk.alg = 'RS256';

// Write public key for embedding in config
fs.writeFileSync(`${configDir}/public-jwk.json`, JSON.stringify(publicJwk, null, 2));

// Write private key for powersync-auth function
fs.writeFileSync(`${configDir}/private-jwk.json`, JSON.stringify(privateJwk));

console.log('[powersync] Keys generated successfully');
KEYGEN

# Read the public key for embedding in config
PUBLIC_KEY_N=$(node -e "console.log(require('$CONFIG_DIR/public-jwk.json').n)")
PUBLIC_KEY_E=$(node -e "console.log(require('$CONFIG_DIR/public-jwk.json').e)")

# Create powersync.yaml config with inlined JWKS and correct SSL settings
cat > "$CONFIG_DIR/powersync.yaml" << EOF
replication:
  connections:
    - id: main
      type: postgresql
      uri: postgresql://postgres:postgres@localhost:54322/postgres
      sslmode: disable

storage:
  type: mongodb
  uri: mongodb://localhost:27017/powersync

port: 8080

sync_rules:
  path: /config/sync_rules.yaml

client_auth:
  jwks:
    keys:
      - kty: RSA
        n: $PUBLIC_KEY_N
        e: $PUBLIC_KEY_E
        kid: powersync-dev-key
        use: sig
        alg: RS256
EOF

# Copy sync_rules from SparkPos
echo "[powersync] Copying sync rules..."
cp "$WORKDIR/sparkpos/powersync/sync_rules.yaml" "$CONFIG_DIR/"

# Create PostgreSQL publication for logical replication
echo "[powersync] Creating PostgreSQL publication..."
docker exec supabase_db_sparkpos psql -U postgres -c "DROP PUBLICATION IF EXISTS powersync; CREATE PUBLICATION powersync FOR ALL TABLES;" 2>/dev/null || true

# Start PowerSync service
echo "[powersync] Starting PowerSync service..."
docker run -d --name powersync \
  --network host \
  -v "$CONFIG_DIR:/config" \
  -e POWERSYNC_CONFIG_PATH=/config/powersync.yaml \
  journeyapps/powersync-service:latest \
  start -r unified

# Update sparkpos .env.local with local PowerSync URL and private key
echo "[powersync] Updating .env.local with PowerSync config..."
PRIVATE_KEY_JSON=$(cat "$CONFIG_DIR/private-jwk.json")

# Update or add POWERSYNC_URL
if grep -q "^POWERSYNC_URL=" "$WORKDIR/sparkpos/.env.local"; then
  sed -i "s|^POWERSYNC_URL=.*|POWERSYNC_URL=http://localhost:8080|" "$WORKDIR/sparkpos/.env.local"
else
  echo "POWERSYNC_URL=http://localhost:8080" >> "$WORKDIR/sparkpos/.env.local"
fi

# Update or add POWERSYNC_PRIVATE_KEY
if grep -q "^POWERSYNC_PRIVATE_KEY=" "$WORKDIR/sparkpos/.env.local"; then
  # Use perl for complex JSON replacement
  perl -i -pe "s|^POWERSYNC_PRIVATE_KEY=.*|POWERSYNC_PRIVATE_KEY='$PRIVATE_KEY_JSON'|" "$WORKDIR/sparkpos/.env.local"
else
  echo "POWERSYNC_PRIVATE_KEY='$PRIVATE_KEY_JSON'" >> "$WORKDIR/sparkpos/.env.local"
fi

# Create Supabase .env.local for edge functions
echo "[powersync] Creating Supabase functions env..."
cat > "$WORKDIR/sparkpos/supabase/.env.local" << EOF
POWERSYNC_URL=http://localhost:8080
POWERSYNC_PRIVATE_KEY=$PRIVATE_KEY_JSON
EOF

# Wait for PowerSync to be healthy
echo "[powersync] Waiting for PowerSync to be healthy..."
sleep 5
until curl -sf http://localhost:8080/probes/liveness > /dev/null 2>&1; do
  echo "[powersync] Waiting for PowerSync health check..."
  sleep 2
done

touch /tmp/powersync-track-done
echo "[powersync] Track complete!"
