#!/bin/bash

# seed-test-restaurant.sh - Seeds Athens Wok Local franchise and restaurant into local MySQL
# This enables placing test orders against the same restaurant data used in staging
#
# Usage: ./seed-test-restaurant.sh
# Must be run from within Codespace (or will use cloud DB if run locally)

set -e

# Detect environment
if [ -d /workspaces ]; then
  # Running in Codespace - use docker exec
  MYSQL_CMD="docker exec -i mysql_sparkpos mysql -uroot -proot spark_backend_development"
else
  echo "This script should be run from within a Codespace."
  echo "Run it via: gh codespace ssh -c <codespace-name> -- 'cd /workspaces/spark-agent-tools && ./seed-test-restaurant.sh'"
  exit 1
fi

echo "Seeding Athens Wok Local franchise and restaurant..."

# Insert or update franchise (franchise_id=25)
$MYSQL_CMD <<'EOF'
INSERT INTO franchises (
  franchise_id, logo_asset_id, cover_photo_asset_id, name, created_at, updated_at,
  url_path, active, place_method, restaurant_pay_method, tax_remit_type,
  delivery_service_fee_percentage, pickup_service_fee_percentage, business_delivery_fee,
  distance_fee_charge_method, food_category_id, pickup_type, pickup_tipping_type,
  domain, delivery_type, card_processing_percentage, card_processing_flat,
  delivery_fee, place_category_id
) VALUES (
  25, 9, NULL, 'Athens Wok Local', NOW(), NOW(),
  'awlocal', 1, NULL, NULL, 1,
  10, 10, 8,
  1, 1, 3, 1,
  'localhost', 2, NULL, NULL,
  NULL, 1
) ON DUPLICATE KEY UPDATE
  name = VALUES(name),
  url_path = VALUES(url_path),
  active = VALUES(active),
  domain = VALUES(domain),
  updated_at = NOW();
EOF

echo "✓ Franchise seeded (franchise_id=25)"

# Insert or update restaurant (restaurant_id=23)
$MYSQL_CMD <<'EOF'
INSERT INTO restaurants (
  restaurant_id, franchise_id, phone_number, fax_number, logo_asset_id, cover_photo_asset_id,
  sales_tax_percentage, order_confirmation_manner, created_at, updated_at,
  address_id, restaurant_group_id, county_id, active_status, partner_status,
  restaurant_pay_method, online_ordering_link, sales_stage, account_id,
  sales_rejection_reason, sales_rejection_other, restaurant_type,
  pickup_message_approved, pickup_message_suggested, pickup_message_read,
  automated_sms_message, external_order_email, external_order_receive_status,
  label, min_cook_time, max_cook_time, email_address, show_label_in_cartwheel,
  delivery_address_id, restaurant_time_zone, delivery_enabled, restaurant_delivery_send_order,
  eta_button_1, eta_button_2, eta_button_3, eta_button_4
) VALUES (
  23, 25, 14049328883, NULL, NULL, NULL,
  NULL, 2, NOW(), NOW(),
  2, 1, 2, 1, 0,
  0, '', NULL, NULL,
  NULL, NULL, 0,
  '', NULL, 1,
  NULL, '', NULL,
  'test', 10, 20, 'testathens_wok@sparkordering.com', 0,
  NULL, NULL, 1, 0,
  NULL, NULL, NULL, NULL
) ON DUPLICATE KEY UPDATE
  franchise_id = VALUES(franchise_id),
  active_status = VALUES(active_status),
  label = VALUES(label),
  updated_at = NOW();
EOF

echo "✓ Restaurant seeded (restaurant_id=23)"

echo ""
echo "Done! Athens Wok Local is now available at: http://localhost:3000/awlocal"
