-- Athens Wok Local Test Data
-- Auto-generated from staging database
-- Franchise ID: 25, Restaurant ID: 23
--
-- To regenerate: ./export-test-restaurant.sh (run locally on Mac)

SET FOREIGN_KEY_CHECKS = 0;
SET SQL_MODE = 'NO_AUTO_VALUE_ON_ZERO';


-- franchises
-- MySQL dump 10.13  Distrib 9.3.0, for macos14.7 (arm64)
--
-- Host: stage-database.cluster-c01bnweqtr8m.us-east-2.rds.amazonaws.com    Database: SPARK
-- ------------------------------------------------------
-- Server version	8.0.39

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
SET @MYSQLDUMP_TEMP_LOG_BIN = @@SESSION.SQL_LOG_BIN;
SET @@SESSION.SQL_LOG_BIN= 0;

--
-- GTID state at the beginning of the backup 
--

SET @@GLOBAL.GTID_PURGED=/*!80000 '+'*/ '';

--
-- Dumping data for table `franchises`
--
-- WHERE:  franchise_id = 25

LOCK TABLES `franchises` WRITE;
/*!40000 ALTER TABLE `franchises` DISABLE KEYS */;
REPLACE INTO `franchises` (`franchise_id`, `logo_asset_id`, `cover_photo_asset_id`, `name`, `created_at`, `updated_at`, `url_path`, `active`, `place_method`, `restaurant_pay_method`, `tax_remit_type`, `delivery_service_fee_percentage`, `pickup_service_fee_percentage`, `business_delivery_fee`, `distance_fee_charge_method`, `food_category_id`, `pickup_type`, `pickup_tipping_type`, `domain`, `delivery_type`, `card_processing_percentage`, `card_processing_flat`, `delivery_fee`, `place_category_id`) VALUES (25,9,NULL,'Athens Wok Local','2024-04-07 23:54:10','2025-07-15 18:29:17','awlocal',1,NULL,NULL,1,10,10,8,1,1,3,1,'localhost',2,NULL,NULL,NULL,1);
/*!40000 ALTER TABLE `franchises` ENABLE KEYS */;
UNLOCK TABLES;
SET @@SESSION.SQL_LOG_BIN = @MYSQLDUMP_TEMP_LOG_BIN;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-01-19 13:11:47

-- restaurants
-- MySQL dump 10.13  Distrib 9.3.0, for macos14.7 (arm64)
--
-- Host: stage-database.cluster-c01bnweqtr8m.us-east-2.rds.amazonaws.com    Database: SPARK
-- ------------------------------------------------------
-- Server version	8.0.39

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
SET @MYSQLDUMP_TEMP_LOG_BIN = @@SESSION.SQL_LOG_BIN;
SET @@SESSION.SQL_LOG_BIN= 0;

--
-- GTID state at the beginning of the backup 
--

SET @@GLOBAL.GTID_PURGED=/*!80000 '+'*/ '';

--
-- Dumping data for table `restaurants`
--
-- WHERE:  restaurant_id = 23

LOCK TABLES `restaurants` WRITE;
/*!40000 ALTER TABLE `restaurants` DISABLE KEYS */;
REPLACE INTO `restaurants` (`restaurant_id`, `franchise_id`, `phone_number`, `fax_number`, `logo_asset_id`, `cover_photo_asset_id`, `sales_tax_percentage`, `order_confirmation_manner`, `created_at`, `updated_at`, `address_id`, `restaurant_group_id`, `county_id`, `active_status`, `partner_status`, `restaurant_pay_method`, `online_ordering_link`, `sales_stage`, `account_id`, `sales_rejection_reason`, `sales_rejection_other`, `restaurant_type`, `pickup_message_approved`, `pickup_message_suggested`, `pickup_message_read`, `automated_sms_message`, `external_order_email`, `external_order_receive_status`, `label`, `min_cook_time`, `max_cook_time`, `email_address`, `show_label_in_cartwheel`, `delivery_address_id`, `restaurant_time_zone`, `delivery_enabled`, `restaurant_delivery_send_order`, `eta_button_1`, `eta_button_2`, `eta_button_3`, `eta_button_4`) VALUES (23,25,14049328883,NULL,NULL,NULL,NULL,2,'2024-04-07 23:54:10','2024-11-10 20:07:10',2,1,2,1,0,0,'',NULL,NULL,NULL,NULL,0,'',NULL,1,NULL,'',NULL,'test',10,20,'testathens_wok@sparkordering.com',0,NULL,NULL,1,0,NULL,NULL,NULL,NULL);
/*!40000 ALTER TABLE `restaurants` ENABLE KEYS */;
UNLOCK TABLES;
SET @@SESSION.SQL_LOG_BIN = @MYSQLDUMP_TEMP_LOG_BIN;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-01-19 13:11:48

-- menu_categories
-- MySQL dump 10.13  Distrib 9.3.0, for macos14.7 (arm64)
--
-- Host: stage-database.cluster-c01bnweqtr8m.us-east-2.rds.amazonaws.com    Database: SPARK
-- ------------------------------------------------------
-- Server version	8.0.39

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
SET @MYSQLDUMP_TEMP_LOG_BIN = @@SESSION.SQL_LOG_BIN;
SET @@SESSION.SQL_LOG_BIN= 0;

--
-- GTID state at the beginning of the backup 
--

SET @@GLOBAL.GTID_PURGED=/*!80000 '+'*/ '';

--
-- Dumping data for table `menu_categories`
--
-- WHERE:  franchise_id = 25

LOCK TABLES `menu_categories` WRITE;
/*!40000 ALTER TABLE `menu_categories` DISABLE KEYS */;
REPLACE INTO `menu_categories` (`menu_category_id`, `name`, `description`, `category_type`, `list_order`, `created_at`, `updated_at`, `franchise_id`, `restaurant_id`, `active`, `start_time_minute`, `end_time_minute`, `delivery_service_fee`, `pickup_service_fee`) VALUES (396,'Appetizers','',0,1,'2024-04-07 23:54:21','2024-04-07 23:54:21',25,0,1,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_categories` (`menu_category_id`, `name`, `description`, `category_type`, `list_order`, `created_at`, `updated_at`, `franchise_id`, `restaurant_id`, `active`, `start_time_minute`, `end_time_minute`, `delivery_service_fee`, `pickup_service_fee`) VALUES (397,'Wings Only','',1,1,'2024-04-07 23:54:21','2024-04-07 23:54:21',25,0,1,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_categories` (`menu_category_id`, `name`, `description`, `category_type`, `list_order`, `created_at`, `updated_at`, `franchise_id`, `restaurant_id`, `active`, `start_time_minute`, `end_time_minute`, `delivery_service_fee`, `pickup_service_fee`) VALUES (398,'Wing Combo','',1,2,'2024-04-07 23:54:22','2024-04-07 23:54:22',25,0,1,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_categories` (`menu_category_id`, `name`, `description`, `category_type`, `list_order`, `created_at`, `updated_at`, `franchise_id`, `restaurant_id`, `active`, `start_time_minute`, `end_time_minute`, `delivery_service_fee`, `pickup_service_fee`) VALUES (399,'Philly (Steak,Chicken,Shrimp,K-BBQ)','',1,3,'2024-04-07 23:54:22','2024-04-07 23:54:22',25,0,1,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_categories` (`menu_category_id`, `name`, `description`, `category_type`, `list_order`, `created_at`, `updated_at`, `franchise_id`, `restaurant_id`, `active`, `start_time_minute`, `end_time_minute`, `delivery_service_fee`, `pickup_service_fee`) VALUES (400,'Fried Rice','',1,4,'2024-04-07 23:54:22','2024-04-07 23:54:22',25,0,1,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_categories` (`menu_category_id`, `name`, `description`, `category_type`, `list_order`, `created_at`, `updated_at`, `franchise_id`, `restaurant_id`, `active`, `start_time_minute`, `end_time_minute`, `delivery_service_fee`, `pickup_service_fee`) VALUES (401,'Gyro ( Lamb or Beef or Chicken)','',1,5,'2024-04-07 23:54:22','2024-04-07 23:54:22',25,0,1,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_categories` (`menu_category_id`, `name`, `description`, `category_type`, `list_order`, `created_at`, `updated_at`, `franchise_id`, `restaurant_id`, `active`, `start_time_minute`, `end_time_minute`, `delivery_service_fee`, `pickup_service_fee`) VALUES (402,'Something Fried','',1,6,'2024-04-07 23:54:22','2024-04-07 23:54:22',25,0,1,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_categories` (`menu_category_id`, `name`, `description`, `category_type`, `list_order`, `created_at`, `updated_at`, `franchise_id`, `restaurant_id`, `active`, `start_time_minute`, `end_time_minute`, `delivery_service_fee`, `pickup_service_fee`) VALUES (403,'Side Order','',1,7,'2024-04-07 23:54:22','2024-04-07 23:54:22',25,0,1,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_categories` (`menu_category_id`, `name`, `description`, `category_type`, `list_order`, `created_at`, `updated_at`, `franchise_id`, `restaurant_id`, `active`, `start_time_minute`, `end_time_minute`, `delivery_service_fee`, `pickup_service_fee`) VALUES (404,'Lunch Special','',1,8,'2024-04-07 23:54:22','2024-04-07 23:54:22',25,0,1,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_categories` (`menu_category_id`, `name`, `description`, `category_type`, `list_order`, `created_at`, `updated_at`, `franchise_id`, `restaurant_id`, `active`, `start_time_minute`, `end_time_minute`, `delivery_service_fee`, `pickup_service_fee`) VALUES (405,'Lunch Special','',1,9,'2024-04-07 23:54:22','2024-04-07 23:54:22',25,0,1,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_categories` (`menu_category_id`, `name`, `description`, `category_type`, `list_order`, `created_at`, `updated_at`, `franchise_id`, `restaurant_id`, `active`, `start_time_minute`, `end_time_minute`, `delivery_service_fee`, `pickup_service_fee`) VALUES (406,'Lunch Special','',1,10,'2024-04-07 23:54:22','2024-04-07 23:54:22',25,0,1,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_categories` (`menu_category_id`, `name`, `description`, `category_type`, `list_order`, `created_at`, `updated_at`, `franchise_id`, `restaurant_id`, `active`, `start_time_minute`, `end_time_minute`, `delivery_service_fee`, `pickup_service_fee`) VALUES (407,'Lunch Special','',1,11,'2024-04-07 23:54:22','2024-04-07 23:54:22',25,0,1,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_categories` (`menu_category_id`, `name`, `description`, `category_type`, `list_order`, `created_at`, `updated_at`, `franchise_id`, `restaurant_id`, `active`, `start_time_minute`, `end_time_minute`, `delivery_service_fee`, `pickup_service_fee`) VALUES (408,'Lunch Special','',1,12,'2024-04-07 23:54:22','2024-04-07 23:54:22',25,0,1,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_categories` (`menu_category_id`, `name`, `description`, `category_type`, `list_order`, `created_at`, `updated_at`, `franchise_id`, `restaurant_id`, `active`, `start_time_minute`, `end_time_minute`, `delivery_service_fee`, `pickup_service_fee`) VALUES (409,'Lunch Special','',1,13,'2024-04-07 23:54:22','2024-04-07 23:54:22',25,0,1,NULL,NULL,NULL,NULL);
/*!40000 ALTER TABLE `menu_categories` ENABLE KEYS */;
UNLOCK TABLES;
SET @@SESSION.SQL_LOG_BIN = @MYSQLDUMP_TEMP_LOG_BIN;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-01-19 13:11:50

-- menu_items
-- MySQL dump 10.13  Distrib 9.3.0, for macos14.7 (arm64)
--
-- Host: stage-database.cluster-c01bnweqtr8m.us-east-2.rds.amazonaws.com    Database: SPARK
-- ------------------------------------------------------
-- Server version	8.0.39

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
SET @MYSQLDUMP_TEMP_LOG_BIN = @@SESSION.SQL_LOG_BIN;
SET @@SESSION.SQL_LOG_BIN= 0;

--
-- GTID state at the beginning of the backup 
--

SET @@GLOBAL.GTID_PURGED=/*!80000 '+'*/ '';

--
-- Dumping data for table `menu_items`
--
-- WHERE:  menu_category_id IN (396,397,398,399,400,401,402,403,404,405,406,407,408,409)

LOCK TABLES `menu_items` WRITE;
/*!40000 ALTER TABLE `menu_items` DISABLE KEYS */;
REPLACE INTO `menu_items` (`menu_item_id`, `base_price`, `description`, `name`, `created_at`, `updated_at`, `menu_category_id`, `active`, `list_order`, `item_type`, `kitchen_short_code`, `kitchen_name`, `is_kitchen_short_code_valid`, `product_image_asset_id`, `store_item_id`, `next_menu_item_id`, `list_order_secondary`, `restore_date`, `asset_id`, `delivery_service_fee`, `pickup_service_fee`, `small_image_asset_id`) VALUES (2768,6598,' ','Crab Rangoon Long Name Long Name Lolng Name Long B','2024-04-07 23:54:21','2024-04-07 23:54:21',396,1,1,NULL,'%N','',1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_items` (`menu_item_id`, `base_price`, `description`, `name`, `created_at`, `updated_at`, `menu_category_id`, `active`, `list_order`, `item_type`, `kitchen_short_code`, `kitchen_name`, `is_kitchen_short_code_valid`, `product_image_asset_id`, `store_item_id`, `next_menu_item_id`, `list_order_secondary`, `restore_date`, `asset_id`, `delivery_service_fee`, `pickup_service_fee`, `small_image_asset_id`) VALUES (2769,2599,' ','Pumpkin Pie','2024-04-07 23:54:21','2024-04-07 23:54:21',396,1,2,NULL,'%P','pkpie',0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_items` (`menu_item_id`, `base_price`, `description`, `name`, `created_at`, `updated_at`, `menu_category_id`, `active`, `list_order`, `item_type`, `kitchen_short_code`, `kitchen_name`, `is_kitchen_short_code_valid`, `product_image_asset_id`, `store_item_id`, `next_menu_item_id`, `list_order_secondary`, `restore_date`, `asset_id`, `delivery_service_fee`, `pickup_service_fee`, `small_image_asset_id`) VALUES (2770,2399,'Comes With 2 Dressings and Celery','20 Wings Only','2024-04-07 23:54:21','2024-04-07 23:54:21',397,1,1,0,'%N',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_items` (`menu_item_id`, `base_price`, `description`, `name`, `created_at`, `updated_at`, `menu_category_id`, `active`, `list_order`, `item_type`, `kitchen_short_code`, `kitchen_name`, `is_kitchen_short_code_valid`, `product_image_asset_id`, `store_item_id`, `next_menu_item_id`, `list_order_secondary`, `restore_date`, `asset_id`, `delivery_service_fee`, `pickup_service_fee`, `small_image_asset_id`) VALUES (2771,1399,'Comes With 1 Dressing and Celery','10 Wings Only','2024-04-07 23:54:21','2024-07-03 10:25:46',397,1,2,0,'%N',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_items` (`menu_item_id`, `base_price`, `description`, `name`, `created_at`, `updated_at`, `menu_category_id`, `active`, `list_order`, `item_type`, `kitchen_short_code`, `kitchen_name`, `is_kitchen_short_code_valid`, `product_image_asset_id`, `store_item_id`, `next_menu_item_id`, `list_order_secondary`, `restore_date`, `asset_id`, `delivery_service_fee`, `pickup_service_fee`, `small_image_asset_id`) VALUES (2772,3499,'Comes With 3 Dressings and Celery','30 Wings Only','2024-04-07 23:54:21','2024-04-07 23:54:21',397,1,3,0,'%N',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_items` (`menu_item_id`, `base_price`, `description`, `name`, `created_at`, `updated_at`, `menu_category_id`, `active`, `list_order`, `item_type`, `kitchen_short_code`, `kitchen_name`, `is_kitchen_short_code_valid`, `product_image_asset_id`, `store_item_id`, `next_menu_item_id`, `list_order_secondary`, `restore_date`, `asset_id`, `delivery_service_fee`, `pickup_service_fee`, `small_image_asset_id`) VALUES (2773,1898,'Comes With 2 Dressings and Celery','15 Wings Only','2024-04-07 23:54:21','2024-04-07 23:54:21',397,1,4,0,'%N',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_items` (`menu_item_id`, `base_price`, `description`, `name`, `created_at`, `updated_at`, `menu_category_id`, `active`, `list_order`, `item_type`, `kitchen_short_code`, `kitchen_name`, `is_kitchen_short_code_valid`, `product_image_asset_id`, `store_item_id`, `next_menu_item_id`, `list_order_secondary`, `restore_date`, `asset_id`, `delivery_service_fee`, `pickup_service_fee`, `small_image_asset_id`) VALUES (2774,999,'Comes With 1 Dressing and Celery','6 Wings Only','2024-04-07 23:54:22','2024-04-07 23:54:22',397,1,5,0,'%N',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_items` (`menu_item_id`, `base_price`, `description`, `name`, `created_at`, `updated_at`, `menu_category_id`, `active`, `list_order`, `item_type`, `kitchen_short_code`, `kitchen_name`, `is_kitchen_short_code_valid`, `product_image_asset_id`, `store_item_id`, `next_menu_item_id`, `list_order_secondary`, `restore_date`, `asset_id`, `delivery_service_fee`, `pickup_service_fee`, `small_image_asset_id`) VALUES (2775,1199,'Comes With 1 Dressing and Celery','8 Wings Only','2024-04-07 23:54:22','2024-04-07 23:54:22',397,1,6,0,'%N',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_items` (`menu_item_id`, `base_price`, `description`, `name`, `created_at`, `updated_at`, `menu_category_id`, `active`, `list_order`, `item_type`, `kitchen_short_code`, `kitchen_name`, `is_kitchen_short_code_valid`, `product_image_asset_id`, `store_item_id`, `next_menu_item_id`, `list_order_secondary`, `restore_date`, `asset_id`, `delivery_service_fee`, `pickup_service_fee`, `small_image_asset_id`) VALUES (2776,4599,'Comes With 4 Dressings and Celery','40 Wings Only','2024-04-07 23:54:22','2024-04-07 23:54:22',397,1,7,0,'%N',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_items` (`menu_item_id`, `base_price`, `description`, `name`, `created_at`, `updated_at`, `menu_category_id`, `active`, `list_order`, `item_type`, `kitchen_short_code`, `kitchen_name`, `is_kitchen_short_code_valid`, `product_image_asset_id`, `store_item_id`, `next_menu_item_id`, `list_order_secondary`, `restore_date`, `asset_id`, `delivery_service_fee`, `pickup_service_fee`, `small_image_asset_id`) VALUES (2777,5699,'Comes With 5 Dressings and Celery','50 Wings Only','2024-04-07 23:54:22','2024-04-07 23:54:22',397,1,8,0,'%N',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_items` (`menu_item_id`, `base_price`, `description`, `name`, `created_at`, `updated_at`, `menu_category_id`, `active`, `list_order`, `item_type`, `kitchen_short_code`, `kitchen_name`, `is_kitchen_short_code_valid`, `product_image_asset_id`, `store_item_id`, `next_menu_item_id`, `list_order_secondary`, `restore_date`, `asset_id`, `delivery_service_fee`, `pickup_service_fee`, `small_image_asset_id`) VALUES (2778,10999,'Comes With 10 Dressings and Celery','100 Wings Only','2024-04-07 23:54:22','2024-04-07 23:54:22',397,1,9,0,'%N',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_items` (`menu_item_id`, `base_price`, `description`, `name`, `created_at`, `updated_at`, `menu_category_id`, `active`, `list_order`, `item_type`, `kitchen_short_code`, `kitchen_name`, `is_kitchen_short_code_valid`, `product_image_asset_id`, `store_item_id`, `next_menu_item_id`, `list_order_secondary`, `restore_date`, `asset_id`, `delivery_service_fee`, `pickup_service_fee`, `small_image_asset_id`) VALUES (2779,8000,'Comes With 8 Dressings and Celery','75 Wings Only','2024-04-07 23:54:22','2024-04-07 23:54:22',397,1,10,0,'%N',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_items` (`menu_item_id`, `base_price`, `description`, `name`, `created_at`, `updated_at`, `menu_category_id`, `active`, `list_order`, `item_type`, `kitchen_short_code`, `kitchen_name`, `is_kitchen_short_code_valid`, `product_image_asset_id`, `store_item_id`, `next_menu_item_id`, `list_order_secondary`, `restore_date`, `asset_id`, `delivery_service_fee`, `pickup_service_fee`, `small_image_asset_id`) VALUES (3253,100,' One Dolla','One Dolla','2024-11-17 21:46:37','2024-11-17 21:46:37',397,1,11,NULL,'%N','',1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_items` (`menu_item_id`, `base_price`, `description`, `name`, `created_at`, `updated_at`, `menu_category_id`, `active`, `list_order`, `item_type`, `kitchen_short_code`, `kitchen_name`, `is_kitchen_short_code_valid`, `product_image_asset_id`, `store_item_id`, `next_menu_item_id`, `list_order_secondary`, `restore_date`, `asset_id`, `delivery_service_fee`, `pickup_service_fee`, `small_image_asset_id`) VALUES (2780,1599,'Includes Fries and Drink','10 Pc Wing Combo','2024-04-07 23:54:22','2024-04-07 23:54:22',398,1,1,0,'%N',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_items` (`menu_item_id`, `base_price`, `description`, `name`, `created_at`, `updated_at`, `menu_category_id`, `active`, `list_order`, `item_type`, `kitchen_short_code`, `kitchen_name`, `is_kitchen_short_code_valid`, `product_image_asset_id`, `store_item_id`, `next_menu_item_id`, `list_order_secondary`, `restore_date`, `asset_id`, `delivery_service_fee`, `pickup_service_fee`, `small_image_asset_id`) VALUES (2781,2599,'Includes Fries and Drink','20 Pc Wing Combo','2024-04-07 23:54:22','2024-04-07 23:54:22',398,1,2,0,'%N',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_items` (`menu_item_id`, `base_price`, `description`, `name`, `created_at`, `updated_at`, `menu_category_id`, `active`, `list_order`, `item_type`, `kitchen_short_code`, `kitchen_name`, `is_kitchen_short_code_valid`, `product_image_asset_id`, `store_item_id`, `next_menu_item_id`, `list_order_secondary`, `restore_date`, `asset_id`, `delivery_service_fee`, `pickup_service_fee`, `small_image_asset_id`) VALUES (2782,2099,'Includes Fries and Drink','15 Pc Wing Combo','2024-04-07 23:54:22','2024-04-07 23:54:22',398,1,3,0,'%N',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_items` (`menu_item_id`, `base_price`, `description`, `name`, `created_at`, `updated_at`, `menu_category_id`, `active`, `list_order`, `item_type`, `kitchen_short_code`, `kitchen_name`, `is_kitchen_short_code_valid`, `product_image_asset_id`, `store_item_id`, `next_menu_item_id`, `list_order_secondary`, `restore_date`, `asset_id`, `delivery_service_fee`, `pickup_service_fee`, `small_image_asset_id`) VALUES (2783,1199,'Includes Fries and Drink','6 Pc Wing Combo','2024-04-07 23:54:22','2024-04-07 23:54:22',398,1,4,0,'%N',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_items` (`menu_item_id`, `base_price`, `description`, `name`, `created_at`, `updated_at`, `menu_category_id`, `active`, `list_order`, `item_type`, `kitchen_short_code`, `kitchen_name`, `is_kitchen_short_code_valid`, `product_image_asset_id`, `store_item_id`, `next_menu_item_id`, `list_order_secondary`, `restore_date`, `asset_id`, `delivery_service_fee`, `pickup_service_fee`, `small_image_asset_id`) VALUES (2784,1399,'Includes Fries and Drink','8 Pc Wing Combo','2024-04-07 23:54:22','2024-04-07 23:54:22',398,1,5,0,'%N',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_items` (`menu_item_id`, `base_price`, `description`, `name`, `created_at`, `updated_at`, `menu_category_id`, `active`, `list_order`, `item_type`, `kitchen_short_code`, `kitchen_name`, `is_kitchen_short_code_valid`, `product_image_asset_id`, `store_item_id`, `next_menu_item_id`, `list_order_secondary`, `restore_date`, `asset_id`, `delivery_service_fee`, `pickup_service_fee`, `small_image_asset_id`) VALUES (2785,1299,'Includes Fries and Drink','Philly Combo','2024-04-07 23:54:22','2024-04-07 23:54:22',399,1,1,0,'%N',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_items` (`menu_item_id`, `base_price`, `description`, `name`, `created_at`, `updated_at`, `menu_category_id`, `active`, `list_order`, `item_type`, `kitchen_short_code`, `kitchen_name`, `is_kitchen_short_code_valid`, `product_image_asset_id`, `store_item_id`, `next_menu_item_id`, `list_order_secondary`, `restore_date`, `asset_id`, `delivery_service_fee`, `pickup_service_fee`, `small_image_asset_id`) VALUES (2786,1099,'','Philly Only','2024-04-07 23:54:22','2024-04-07 23:54:22',399,1,2,0,'%N',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_items` (`menu_item_id`, `base_price`, `description`, `name`, `created_at`, `updated_at`, `menu_category_id`, `active`, `list_order`, `item_type`, `kitchen_short_code`, `kitchen_name`, `is_kitchen_short_code_valid`, `product_image_asset_id`, `store_item_id`, `next_menu_item_id`, `list_order_secondary`, `restore_date`, `asset_id`, `delivery_service_fee`, `pickup_service_fee`, `small_image_asset_id`) VALUES (2787,600,'','Add 5 Wing','2024-04-07 23:54:22','2024-04-07 23:54:22',399,1,3,0,'%N',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_items` (`menu_item_id`, `base_price`, `description`, `name`, `created_at`, `updated_at`, `menu_category_id`, `active`, `list_order`, `item_type`, `kitchen_short_code`, `kitchen_name`, `is_kitchen_short_code_valid`, `product_image_asset_id`, `store_item_id`, `next_menu_item_id`, `list_order_secondary`, `restore_date`, `asset_id`, `delivery_service_fee`, `pickup_service_fee`, `small_image_asset_id`) VALUES (2788,499,'','Small Vegetable Fried Rice','2024-04-07 23:54:22','2024-04-07 23:54:22',400,1,1,0,'%N',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_items` (`menu_item_id`, `base_price`, `description`, `name`, `created_at`, `updated_at`, `menu_category_id`, `active`, `list_order`, `item_type`, `kitchen_short_code`, `kitchen_name`, `is_kitchen_short_code_valid`, `product_image_asset_id`, `store_item_id`, `next_menu_item_id`, `list_order_secondary`, `restore_date`, `asset_id`, `delivery_service_fee`, `pickup_service_fee`, `small_image_asset_id`) VALUES (2789,699,'','Small Chicken Fried Rice','2024-04-07 23:54:22','2024-04-07 23:54:22',400,1,2,0,'%N',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_items` (`menu_item_id`, `base_price`, `description`, `name`, `created_at`, `updated_at`, `menu_category_id`, `active`, `list_order`, `item_type`, `kitchen_short_code`, `kitchen_name`, `is_kitchen_short_code_valid`, `product_image_asset_id`, `store_item_id`, `next_menu_item_id`, `list_order_secondary`, `restore_date`, `asset_id`, `delivery_service_fee`, `pickup_service_fee`, `small_image_asset_id`) VALUES (2790,1099,'','Large Chicken Fried Rice','2024-04-07 23:54:22','2024-04-07 23:54:22',400,1,3,0,'%N',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_items` (`menu_item_id`, `base_price`, `description`, `name`, `created_at`, `updated_at`, `menu_category_id`, `active`, `list_order`, `item_type`, `kitchen_short_code`, `kitchen_name`, `is_kitchen_short_code_valid`, `product_image_asset_id`, `store_item_id`, `next_menu_item_id`, `list_order_secondary`, `restore_date`, `asset_id`, `delivery_service_fee`, `pickup_service_fee`, `small_image_asset_id`) VALUES (2791,1599,'','Large House Rice','2024-04-07 23:54:22','2024-04-07 23:54:22',400,1,4,0,'%N',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_items` (`menu_item_id`, `base_price`, `description`, `name`, `created_at`, `updated_at`, `menu_category_id`, `active`, `list_order`, `item_type`, `kitchen_short_code`, `kitchen_name`, `is_kitchen_short_code_valid`, `product_image_asset_id`, `store_item_id`, `next_menu_item_id`, `list_order_secondary`, `restore_date`, `asset_id`, `delivery_service_fee`, `pickup_service_fee`, `small_image_asset_id`) VALUES (2792,699,'','Small Shrimp Fried Rice','2024-04-07 23:54:22','2024-04-07 23:54:22',400,1,5,0,'%N',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_items` (`menu_item_id`, `base_price`, `description`, `name`, `created_at`, `updated_at`, `menu_category_id`, `active`, `list_order`, `item_type`, `kitchen_short_code`, `kitchen_name`, `is_kitchen_short_code_valid`, `product_image_asset_id`, `store_item_id`, `next_menu_item_id`, `list_order_secondary`, `restore_date`, `asset_id`, `delivery_service_fee`, `pickup_service_fee`, `small_image_asset_id`) VALUES (2793,1099,'','Small House Rice','2024-04-07 23:54:22','2024-04-07 23:54:22',400,1,6,0,'%N',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_items` (`menu_item_id`, `base_price`, `description`, `name`, `created_at`, `updated_at`, `menu_category_id`, `active`, `list_order`, `item_type`, `kitchen_short_code`, `kitchen_name`, `is_kitchen_short_code_valid`, `product_image_asset_id`, `store_item_id`, `next_menu_item_id`, `list_order_secondary`, `restore_date`, `asset_id`, `delivery_service_fee`, `pickup_service_fee`, `small_image_asset_id`) VALUES (2794,1099,'','Large Shrimp Fried Rice','2024-04-07 23:54:22','2024-04-07 23:54:22',400,1,7,0,'%N',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_items` (`menu_item_id`, `base_price`, `description`, `name`, `created_at`, `updated_at`, `menu_category_id`, `active`, `list_order`, `item_type`, `kitchen_short_code`, `kitchen_name`, `is_kitchen_short_code_valid`, `product_image_asset_id`, `store_item_id`, `next_menu_item_id`, `list_order_secondary`, `restore_date`, `asset_id`, `delivery_service_fee`, `pickup_service_fee`, `small_image_asset_id`) VALUES (2795,899,'','Large Vegetable Fried Rice','2024-04-07 23:54:22','2024-04-07 23:54:22',400,1,8,0,'%N',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_items` (`menu_item_id`, `base_price`, `description`, `name`, `created_at`, `updated_at`, `menu_category_id`, `active`, `list_order`, `item_type`, `kitchen_short_code`, `kitchen_name`, `is_kitchen_short_code_valid`, `product_image_asset_id`, `store_item_id`, `next_menu_item_id`, `list_order_secondary`, `restore_date`, `asset_id`, `delivery_service_fee`, `pickup_service_fee`, `small_image_asset_id`) VALUES (2796,600,'','Add 5 Wing','2024-04-07 23:54:22','2024-04-07 23:54:22',400,1,9,0,'%N',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_items` (`menu_item_id`, `base_price`, `description`, `name`, `created_at`, `updated_at`, `menu_category_id`, `active`, `list_order`, `item_type`, `kitchen_short_code`, `kitchen_name`, `is_kitchen_short_code_valid`, `product_image_asset_id`, `store_item_id`, `next_menu_item_id`, `list_order_secondary`, `restore_date`, `asset_id`, `delivery_service_fee`, `pickup_service_fee`, `small_image_asset_id`) VALUES (2797,699,'','Small Beef Fried Rice','2024-04-07 23:54:22','2024-04-07 23:54:22',400,1,10,0,'%N',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_items` (`menu_item_id`, `base_price`, `description`, `name`, `created_at`, `updated_at`, `menu_category_id`, `active`, `list_order`, `item_type`, `kitchen_short_code`, `kitchen_name`, `is_kitchen_short_code_valid`, `product_image_asset_id`, `store_item_id`, `next_menu_item_id`, `list_order_secondary`, `restore_date`, `asset_id`, `delivery_service_fee`, `pickup_service_fee`, `small_image_asset_id`) VALUES (2798,1099,'','Large Beef Fried Rice','2024-04-07 23:54:22','2024-04-07 23:54:22',400,1,11,0,'%N',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_items` (`menu_item_id`, `base_price`, `description`, `name`, `created_at`, `updated_at`, `menu_category_id`, `active`, `list_order`, `item_type`, `kitchen_short_code`, `kitchen_name`, `is_kitchen_short_code_valid`, `product_image_asset_id`, `store_item_id`, `next_menu_item_id`, `list_order_secondary`, `restore_date`, `asset_id`, `delivery_service_fee`, `pickup_service_fee`, `small_image_asset_id`) VALUES (2799,1399,'SERVED WITH 2 PIECES CATFISH 3 JUMBO SHRIMPS,FRIES AND HUSHPUPPIES.','CATFISH(2) JUMBO SHRIMPS(3) W/SIDES','2024-04-07 23:54:22','2024-04-07 23:54:22',402,1,1,0,'%N',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_items` (`menu_item_id`, `base_price`, `description`, `name`, `created_at`, `updated_at`, `menu_category_id`, `active`, `list_order`, `item_type`, `kitchen_short_code`, `kitchen_name`, `is_kitchen_short_code_valid`, `product_image_asset_id`, `store_item_id`, `next_menu_item_id`, `list_order_secondary`, `restore_date`, `asset_id`, `delivery_service_fee`, `pickup_service_fee`, `small_image_asset_id`) VALUES (2800,1399,'SERVED WITH 4 PIECES OF FISH, FRIES AND HUSH PUPPY.','CATFISH (4PCS) W/SIDES','2024-04-07 23:54:22','2024-04-07 23:54:22',402,1,2,0,'%N',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_items` (`menu_item_id`, `base_price`, `description`, `name`, `created_at`, `updated_at`, `menu_category_id`, `active`, `list_order`, `item_type`, `kitchen_short_code`, `kitchen_name`, `is_kitchen_short_code_valid`, `product_image_asset_id`, `store_item_id`, `next_menu_item_id`, `list_order_secondary`, `restore_date`, `asset_id`, `delivery_service_fee`, `pickup_service_fee`, `small_image_asset_id`) VALUES (2801,1798,'SERVED WITH 2 FISH AND 5 SHRIMPS FRIED. SIDES WILL COME WITH FRIES AND HUSH PUPPY.','CATFISH & SHRIMPS/FRIED W/SIDES','2024-04-07 23:54:22','2024-04-07 23:54:22',402,1,3,0,'%N',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_items` (`menu_item_id`, `base_price`, `description`, `name`, `created_at`, `updated_at`, `menu_category_id`, `active`, `list_order`, `item_type`, `kitchen_short_code`, `kitchen_name`, `is_kitchen_short_code_valid`, `product_image_asset_id`, `store_item_id`, `next_menu_item_id`, `list_order_secondary`, `restore_date`, `asset_id`, `delivery_service_fee`, `pickup_service_fee`, `small_image_asset_id`) VALUES (2802,1798,'SIDES SERVED with French fires, hush puppy,.SERVED WITH 2 FISH,3 JUMBO SHRIMPS AND 3 OYSTERS.','Catfish, Shrimp, and Oyster W/SIDES','2024-04-07 23:54:22','2024-04-07 23:54:22',402,1,4,0,'%N',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_items` (`menu_item_id`, `base_price`, `description`, `name`, `created_at`, `updated_at`, `menu_category_id`, `active`, `list_order`, `item_type`, `kitchen_short_code`, `kitchen_name`, `is_kitchen_short_code_valid`, `product_image_asset_id`, `store_item_id`, `next_menu_item_id`, `list_order_secondary`, `restore_date`, `asset_id`, `delivery_service_fee`, `pickup_service_fee`, `small_image_asset_id`) VALUES (2803,1798,'SERVED WITH 10 JUMBO SHRIMP,FRIES AND HUSH PUPPIES.','10 JUMBO FRIED SHRIMP W/SIDES','2024-04-07 23:54:22','2024-04-07 23:54:22',402,1,5,0,'%N',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_items` (`menu_item_id`, `base_price`, `description`, `name`, `created_at`, `updated_at`, `menu_category_id`, `active`, `list_order`, `item_type`, `kitchen_short_code`, `kitchen_name`, `is_kitchen_short_code_valid`, `product_image_asset_id`, `store_item_id`, `next_menu_item_id`, `list_order_secondary`, `restore_date`, `asset_id`, `delivery_service_fee`, `pickup_service_fee`, `small_image_asset_id`) VALUES (2804,1399,'SERVED WITH 6 JUMBO SHRIMPS, FRIES AND HUSH PUPPY.','6 JUMBO FRIED SHRIMPS W/SIDES','2024-04-07 23:54:22','2024-04-07 23:54:22',402,1,6,0,'%N',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_items` (`menu_item_id`, `base_price`, `description`, `name`, `created_at`, `updated_at`, `menu_category_id`, `active`, `list_order`, `item_type`, `kitchen_short_code`, `kitchen_name`, `is_kitchen_short_code_valid`, `product_image_asset_id`, `store_item_id`, `next_menu_item_id`, `list_order_secondary`, `restore_date`, `asset_id`, `delivery_service_fee`, `pickup_service_fee`, `small_image_asset_id`) VALUES (2805,4699,'SERVED WITH 3 FILETS,10 SHRIMPS & 10 OYSTERS .SIDES SERVED WITH 4 SERVING OF FRIES AND HUSH PUPPY.','Fried Sampler (Serves 3-4)','2024-04-07 23:54:22','2024-04-07 23:54:22',402,1,7,0,'%N',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_items` (`menu_item_id`, `base_price`, `description`, `name`, `created_at`, `updated_at`, `menu_category_id`, `active`, `list_order`, `item_type`, `kitchen_short_code`, `kitchen_name`, `is_kitchen_short_code_valid`, `product_image_asset_id`, `store_item_id`, `next_menu_item_id`, `list_order_secondary`, `restore_date`, `asset_id`, `delivery_service_fee`, `pickup_service_fee`, `small_image_asset_id`) VALUES (2806,1399,'SERVED WITH 6 OYSTERS,FRIES AND HUSH PUPPY.','6 OYSTERS W/SIDE','2024-04-07 23:54:22','2024-04-07 23:54:22',402,1,8,0,'%N',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_items` (`menu_item_id`, `base_price`, `description`, `name`, `created_at`, `updated_at`, `menu_category_id`, `active`, `list_order`, `item_type`, `kitchen_short_code`, `kitchen_name`, `is_kitchen_short_code_valid`, `product_image_asset_id`, `store_item_id`, `next_menu_item_id`, `list_order_secondary`, `restore_date`, `asset_id`, `delivery_service_fee`, `pickup_service_fee`, `small_image_asset_id`) VALUES (2807,599,'SERVED WITH 3 BOUDAIN BALLS.','3 BOUDAIN BALL','2024-04-07 23:54:22','2024-04-07 23:54:22',403,1,1,0,'%N',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_items` (`menu_item_id`, `base_price`, `description`, `name`, `created_at`, `updated_at`, `menu_category_id`, `active`, `list_order`, `item_type`, `kitchen_short_code`, `kitchen_name`, `is_kitchen_short_code_valid`, `product_image_asset_id`, `store_item_id`, `next_menu_item_id`, `list_order_secondary`, `restore_date`, `asset_id`, `delivery_service_fee`, `pickup_service_fee`, `small_image_asset_id`) VALUES (2808,1099,'SERVED WITH 6 BOUDAIN BALLS','6 BOUDAIN BALLS','2024-04-07 23:54:22','2024-04-07 23:54:22',403,1,2,0,'%N',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_items` (`menu_item_id`, `base_price`, `description`, `name`, `created_at`, `updated_at`, `menu_category_id`, `active`, `list_order`, `item_type`, `kitchen_short_code`, `kitchen_name`, `is_kitchen_short_code_valid`, `product_image_asset_id`, `store_item_id`, `next_menu_item_id`, `list_order_secondary`, `restore_date`, `asset_id`, `delivery_service_fee`, `pickup_service_fee`, `small_image_asset_id`) VALUES (2809,999,'','5pc Shrimp & Small Fired Rice (Vege)','2024-04-07 23:54:22','2024-04-07 23:54:22',404,1,1,0,'%N',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_items` (`menu_item_id`, `base_price`, `description`, `name`, `created_at`, `updated_at`, `menu_category_id`, `active`, `list_order`, `item_type`, `kitchen_short_code`, `kitchen_name`, `is_kitchen_short_code_valid`, `product_image_asset_id`, `store_item_id`, `next_menu_item_id`, `list_order_secondary`, `restore_date`, `asset_id`, `delivery_service_fee`, `pickup_service_fee`, `small_image_asset_id`) VALUES (2810,1099,'','7pc Wings & Fries','2024-04-07 23:54:22','2024-04-07 23:54:22',404,1,2,0,'%N',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_items` (`menu_item_id`, `base_price`, `description`, `name`, `created_at`, `updated_at`, `menu_category_id`, `active`, `list_order`, `item_type`, `kitchen_short_code`, `kitchen_name`, `is_kitchen_short_code_valid`, `product_image_asset_id`, `store_item_id`, `next_menu_item_id`, `list_order_secondary`, `restore_date`, `asset_id`, `delivery_service_fee`, `pickup_service_fee`, `small_image_asset_id`) VALUES (2811,1199,'Small vegetable Fried Rice.','7pc Wings & Small Fried Rice (Vege.)','2024-04-07 23:54:22','2024-04-07 23:54:22',404,1,3,0,'%N',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_items` (`menu_item_id`, `base_price`, `description`, `name`, `created_at`, `updated_at`, `menu_category_id`, `active`, `list_order`, `item_type`, `kitchen_short_code`, `kitchen_name`, `is_kitchen_short_code_valid`, `product_image_asset_id`, `store_item_id`, `next_menu_item_id`, `list_order_secondary`, `restore_date`, `asset_id`, `delivery_service_fee`, `pickup_service_fee`, `small_image_asset_id`) VALUES (2812,1099,'','2pc Whiting Fish & Fries','2024-04-07 23:54:22','2024-04-07 23:54:22',404,1,4,0,'%N',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_items` (`menu_item_id`, `base_price`, `description`, `name`, `created_at`, `updated_at`, `menu_category_id`, `active`, `list_order`, `item_type`, `kitchen_short_code`, `kitchen_name`, `is_kitchen_short_code_valid`, `product_image_asset_id`, `store_item_id`, `next_menu_item_id`, `list_order_secondary`, `restore_date`, `asset_id`, `delivery_service_fee`, `pickup_service_fee`, `small_image_asset_id`) VALUES (2813,999,'','5pc Shrimp & Small Fired Rice (Vege)','2024-04-07 23:54:22','2024-04-07 23:54:22',405,1,1,0,'%N',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_items` (`menu_item_id`, `base_price`, `description`, `name`, `created_at`, `updated_at`, `menu_category_id`, `active`, `list_order`, `item_type`, `kitchen_short_code`, `kitchen_name`, `is_kitchen_short_code_valid`, `product_image_asset_id`, `store_item_id`, `next_menu_item_id`, `list_order_secondary`, `restore_date`, `asset_id`, `delivery_service_fee`, `pickup_service_fee`, `small_image_asset_id`) VALUES (2814,1099,'','7pc Wings & Fries','2024-04-07 23:54:22','2024-04-07 23:54:22',405,1,2,0,'%N',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_items` (`menu_item_id`, `base_price`, `description`, `name`, `created_at`, `updated_at`, `menu_category_id`, `active`, `list_order`, `item_type`, `kitchen_short_code`, `kitchen_name`, `is_kitchen_short_code_valid`, `product_image_asset_id`, `store_item_id`, `next_menu_item_id`, `list_order_secondary`, `restore_date`, `asset_id`, `delivery_service_fee`, `pickup_service_fee`, `small_image_asset_id`) VALUES (2815,999,'','5pc Shrimp & Small Fired Rice (Vege)','2024-04-07 23:54:22','2024-04-07 23:54:22',406,1,1,0,'%N',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_items` (`menu_item_id`, `base_price`, `description`, `name`, `created_at`, `updated_at`, `menu_category_id`, `active`, `list_order`, `item_type`, `kitchen_short_code`, `kitchen_name`, `is_kitchen_short_code_valid`, `product_image_asset_id`, `store_item_id`, `next_menu_item_id`, `list_order_secondary`, `restore_date`, `asset_id`, `delivery_service_fee`, `pickup_service_fee`, `small_image_asset_id`) VALUES (2816,1099,'','7pc Wings & Fries','2024-04-07 23:54:22','2024-04-07 23:54:22',406,1,2,0,'%N',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_items` (`menu_item_id`, `base_price`, `description`, `name`, `created_at`, `updated_at`, `menu_category_id`, `active`, `list_order`, `item_type`, `kitchen_short_code`, `kitchen_name`, `is_kitchen_short_code_valid`, `product_image_asset_id`, `store_item_id`, `next_menu_item_id`, `list_order_secondary`, `restore_date`, `asset_id`, `delivery_service_fee`, `pickup_service_fee`, `small_image_asset_id`) VALUES (2817,1199,'Small vegetable Fried Rice.','7pc Wings & Small Fried Rice (Vege.)','2024-04-07 23:54:22','2024-04-07 23:54:22',406,1,3,0,'%N',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_items` (`menu_item_id`, `base_price`, `description`, `name`, `created_at`, `updated_at`, `menu_category_id`, `active`, `list_order`, `item_type`, `kitchen_short_code`, `kitchen_name`, `is_kitchen_short_code_valid`, `product_image_asset_id`, `store_item_id`, `next_menu_item_id`, `list_order_secondary`, `restore_date`, `asset_id`, `delivery_service_fee`, `pickup_service_fee`, `small_image_asset_id`) VALUES (2818,999,'','5pc Shrimp & Small Fired Rice (Vege)','2024-04-07 23:54:22','2024-04-07 23:54:22',407,1,1,0,'%N',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_items` (`menu_item_id`, `base_price`, `description`, `name`, `created_at`, `updated_at`, `menu_category_id`, `active`, `list_order`, `item_type`, `kitchen_short_code`, `kitchen_name`, `is_kitchen_short_code_valid`, `product_image_asset_id`, `store_item_id`, `next_menu_item_id`, `list_order_secondary`, `restore_date`, `asset_id`, `delivery_service_fee`, `pickup_service_fee`, `small_image_asset_id`) VALUES (2819,1099,'','7pc Wings & Fries','2024-04-07 23:54:22','2024-04-07 23:54:22',407,1,2,0,'%N',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_items` (`menu_item_id`, `base_price`, `description`, `name`, `created_at`, `updated_at`, `menu_category_id`, `active`, `list_order`, `item_type`, `kitchen_short_code`, `kitchen_name`, `is_kitchen_short_code_valid`, `product_image_asset_id`, `store_item_id`, `next_menu_item_id`, `list_order_secondary`, `restore_date`, `asset_id`, `delivery_service_fee`, `pickup_service_fee`, `small_image_asset_id`) VALUES (2820,1199,'Small vegetable Fried Rice.','7pc Wings & Small Fried Rice (Vege.)','2024-04-07 23:54:22','2024-04-07 23:54:22',407,1,3,0,'%N',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_items` (`menu_item_id`, `base_price`, `description`, `name`, `created_at`, `updated_at`, `menu_category_id`, `active`, `list_order`, `item_type`, `kitchen_short_code`, `kitchen_name`, `is_kitchen_short_code_valid`, `product_image_asset_id`, `store_item_id`, `next_menu_item_id`, `list_order_secondary`, `restore_date`, `asset_id`, `delivery_service_fee`, `pickup_service_fee`, `small_image_asset_id`) VALUES (2821,999,'','5pc Shrimp & Small Fired Rice (Vege)','2024-04-07 23:54:22','2024-04-07 23:54:22',408,1,1,0,'%N',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_items` (`menu_item_id`, `base_price`, `description`, `name`, `created_at`, `updated_at`, `menu_category_id`, `active`, `list_order`, `item_type`, `kitchen_short_code`, `kitchen_name`, `is_kitchen_short_code_valid`, `product_image_asset_id`, `store_item_id`, `next_menu_item_id`, `list_order_secondary`, `restore_date`, `asset_id`, `delivery_service_fee`, `pickup_service_fee`, `small_image_asset_id`) VALUES (2822,999,'','5pc Shrimp & Small Fired Rice (Vege)','2024-04-07 23:54:22','2024-04-07 23:54:22',409,1,1,0,'%N',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_items` (`menu_item_id`, `base_price`, `description`, `name`, `created_at`, `updated_at`, `menu_category_id`, `active`, `list_order`, `item_type`, `kitchen_short_code`, `kitchen_name`, `is_kitchen_short_code_valid`, `product_image_asset_id`, `store_item_id`, `next_menu_item_id`, `list_order_secondary`, `restore_date`, `asset_id`, `delivery_service_fee`, `pickup_service_fee`, `small_image_asset_id`) VALUES (2823,1099,'','7pc Wings & Fries','2024-04-07 23:54:22','2024-04-07 23:54:22',409,1,2,0,'%N',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
REPLACE INTO `menu_items` (`menu_item_id`, `base_price`, `description`, `name`, `created_at`, `updated_at`, `menu_category_id`, `active`, `list_order`, `item_type`, `kitchen_short_code`, `kitchen_name`, `is_kitchen_short_code_valid`, `product_image_asset_id`, `store_item_id`, `next_menu_item_id`, `list_order_secondary`, `restore_date`, `asset_id`, `delivery_service_fee`, `pickup_service_fee`, `small_image_asset_id`) VALUES (2824,1199,'Small vegetable Fried Rice.','7pc Wings & Small Fried Rice (Vege.)','2024-04-07 23:54:22','2024-04-07 23:54:22',409,1,3,0,'%N',NULL,1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
/*!40000 ALTER TABLE `menu_items` ENABLE KEYS */;
UNLOCK TABLES;
SET @@SESSION.SQL_LOG_BIN = @MYSQLDUMP_TEMP_LOG_BIN;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-01-19 13:11:52

-- option_questions
-- MySQL dump 10.13  Distrib 9.3.0, for macos14.7 (arm64)
--
-- Host: stage-database.cluster-c01bnweqtr8m.us-east-2.rds.amazonaws.com    Database: SPARK
-- ------------------------------------------------------
-- Server version	8.0.39

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
SET @MYSQLDUMP_TEMP_LOG_BIN = @@SESSION.SQL_LOG_BIN;
SET @@SESSION.SQL_LOG_BIN= 0;

--
-- GTID state at the beginning of the backup 
--

SET @@GLOBAL.GTID_PURGED=/*!80000 '+'*/ '';

--
-- Dumping data for table `option_questions`
--
-- WHERE:  franchise_id = 25

LOCK TABLES `option_questions` WRITE;
/*!40000 ALTER TABLE `option_questions` DISABLE KEYS */;
REPLACE INTO `option_questions` (`option_question_id`, `question`, `created_at`, `updated_at`, `franchise_id`, `scale_min_value`, `scale_max_value`, `scale_cost_per_quantity`, `answer_type`, `option_question_type`) VALUES (1691,'Cup','2024-04-07 23:54:17','2024-04-07 23:54:17',25,NULL,NULL,0,0,NULL);
REPLACE INTO `option_questions` (`option_question_id`, `question`, `created_at`, `updated_at`, `franchise_id`, `scale_min_value`, `scale_max_value`, `scale_cost_per_quantity`, `answer_type`, `option_question_type`) VALUES (1692,'Cup','2024-04-07 23:54:18','2024-04-07 23:54:18',25,NULL,NULL,0,1,1);
REPLACE INTO `option_questions` (`option_question_id`, `question`, `created_at`, `updated_at`, `franchise_id`, `scale_min_value`, `scale_max_value`, `scale_cost_per_quantity`, `answer_type`, `option_question_type`) VALUES (1693,'Wings Extra Dressing Options','2024-04-07 23:54:18','2024-04-07 23:54:18',25,NULL,5,0,5,1);
REPLACE INTO `option_questions` (`option_question_id`, `question`, `created_at`, `updated_at`, `franchise_id`, `scale_min_value`, `scale_max_value`, `scale_cost_per_quantity`, `answer_type`, `option_question_type`) VALUES (1694,'Wings and Fries Cook Options','2024-04-07 23:54:18','2024-04-07 23:54:18',25,NULL,2,0,5,1);
REPLACE INTO `option_questions` (`option_question_id`, `question`, `created_at`, `updated_at`, `franchise_id`, `scale_min_value`, `scale_max_value`, `scale_cost_per_quantity`, `answer_type`, `option_question_type`) VALUES (1695,'Wings Extra Flavor Options','2024-04-07 23:54:18','2024-04-07 23:54:18',25,NULL,10,0,5,1);
REPLACE INTO `option_questions` (`option_question_id`, `question`, `created_at`, `updated_at`, `franchise_id`, `scale_min_value`, `scale_max_value`, `scale_cost_per_quantity`, `answer_type`, `option_question_type`) VALUES (1696,'Wings Extra Dressing Options','2024-04-07 23:54:18','2024-04-07 23:54:18',25,NULL,5,0,5,1);
REPLACE INTO `option_questions` (`option_question_id`, `question`, `created_at`, `updated_at`, `franchise_id`, `scale_min_value`, `scale_max_value`, `scale_cost_per_quantity`, `answer_type`, `option_question_type`) VALUES (1697,'Wings and Fries Cook Options','2024-04-07 23:54:18','2024-04-07 23:54:18',25,NULL,2,0,5,1);
REPLACE INTO `option_questions` (`option_question_id`, `question`, `created_at`, `updated_at`, `franchise_id`, `scale_min_value`, `scale_max_value`, `scale_cost_per_quantity`, `answer_type`, `option_question_type`) VALUES (1698,'Wings Extra Flavor Options','2024-04-07 23:54:18','2024-04-07 23:54:18',25,NULL,10,0,5,1);
REPLACE INTO `option_questions` (`option_question_id`, `question`, `created_at`, `updated_at`, `franchise_id`, `scale_min_value`, `scale_max_value`, `scale_cost_per_quantity`, `answer_type`, `option_question_type`) VALUES (1699,'Wings Extra Dressing Options','2024-04-07 23:54:18','2024-04-07 23:54:18',25,NULL,5,0,5,1);
REPLACE INTO `option_questions` (`option_question_id`, `question`, `created_at`, `updated_at`, `franchise_id`, `scale_min_value`, `scale_max_value`, `scale_cost_per_quantity`, `answer_type`, `option_question_type`) VALUES (1700,'Wings and Fries Cook Options','2024-04-07 23:54:18','2024-04-07 23:54:18',25,NULL,2,0,5,1);
REPLACE INTO `option_questions` (`option_question_id`, `question`, `created_at`, `updated_at`, `franchise_id`, `scale_min_value`, `scale_max_value`, `scale_cost_per_quantity`, `answer_type`, `option_question_type`) VALUES (1701,'Wings Extra Flavor Options','2024-04-07 23:54:18','2024-04-07 23:54:18',25,NULL,10,0,5,1);
REPLACE INTO `option_questions` (`option_question_id`, `question`, `created_at`, `updated_at`, `franchise_id`, `scale_min_value`, `scale_max_value`, `scale_cost_per_quantity`, `answer_type`, `option_question_type`) VALUES (1702,'Wings Extra Dressing Options','2024-04-07 23:54:18','2024-04-07 23:54:18',25,NULL,5,0,5,1);
REPLACE INTO `option_questions` (`option_question_id`, `question`, `created_at`, `updated_at`, `franchise_id`, `scale_min_value`, `scale_max_value`, `scale_cost_per_quantity`, `answer_type`, `option_question_type`) VALUES (1703,'Wings and Fries Cook Options','2024-04-07 23:54:18','2024-04-07 23:54:18',25,NULL,2,0,5,1);
REPLACE INTO `option_questions` (`option_question_id`, `question`, `created_at`, `updated_at`, `franchise_id`, `scale_min_value`, `scale_max_value`, `scale_cost_per_quantity`, `answer_type`, `option_question_type`) VALUES (1704,'Wings Extra Flavor Options','2024-04-07 23:54:18','2024-04-07 23:54:18',25,NULL,10,0,5,1);
REPLACE INTO `option_questions` (`option_question_id`, `question`, `created_at`, `updated_at`, `franchise_id`, `scale_min_value`, `scale_max_value`, `scale_cost_per_quantity`, `answer_type`, `option_question_type`) VALUES (1705,'Wings Extra Dressing Options','2024-04-07 23:54:19','2024-04-07 23:54:19',25,NULL,5,0,5,1);
REPLACE INTO `option_questions` (`option_question_id`, `question`, `created_at`, `updated_at`, `franchise_id`, `scale_min_value`, `scale_max_value`, `scale_cost_per_quantity`, `answer_type`, `option_question_type`) VALUES (1706,'Wings and Fries Cook Options','2024-04-07 23:54:19','2024-04-07 23:54:19',25,NULL,2,0,5,1);
REPLACE INTO `option_questions` (`option_question_id`, `question`, `created_at`, `updated_at`, `franchise_id`, `scale_min_value`, `scale_max_value`, `scale_cost_per_quantity`, `answer_type`, `option_question_type`) VALUES (1707,'Wings Extra Flavor Options','2024-04-07 23:54:19','2024-04-07 23:54:19',25,NULL,10,0,5,1);
REPLACE INTO `option_questions` (`option_question_id`, `question`, `created_at`, `updated_at`, `franchise_id`, `scale_min_value`, `scale_max_value`, `scale_cost_per_quantity`, `answer_type`, `option_question_type`) VALUES (1708,'Wings Extra Dressing Options','2024-04-07 23:54:19','2024-04-07 23:54:19',25,NULL,5,0,5,1);
REPLACE INTO `option_questions` (`option_question_id`, `question`, `created_at`, `updated_at`, `franchise_id`, `scale_min_value`, `scale_max_value`, `scale_cost_per_quantity`, `answer_type`, `option_question_type`) VALUES (1709,'Wings and Fries Cook Options','2024-04-07 23:54:19','2024-04-07 23:54:19',25,NULL,2,0,5,1);
REPLACE INTO `option_questions` (`option_question_id`, `question`, `created_at`, `updated_at`, `franchise_id`, `scale_min_value`, `scale_max_value`, `scale_cost_per_quantity`, `answer_type`, `option_question_type`) VALUES (1710,'Wings Extra Flavor Options','2024-04-07 23:54:19','2024-04-07 23:54:19',25,NULL,10,0,5,1);
REPLACE INTO `option_questions` (`option_question_id`, `question`, `created_at`, `updated_at`, `franchise_id`, `scale_min_value`, `scale_max_value`, `scale_cost_per_quantity`, `answer_type`, `option_question_type`) VALUES (1711,'Wings Extra Dressing Options','2024-04-07 23:54:19','2024-04-07 23:54:19',25,NULL,5,0,5,1);
REPLACE INTO `option_questions` (`option_question_id`, `question`, `created_at`, `updated_at`, `franchise_id`, `scale_min_value`, `scale_max_value`, `scale_cost_per_quantity`, `answer_type`, `option_question_type`) VALUES (1712,'Wings and Fries Cook Options','2024-04-07 23:54:19','2024-04-07 23:54:19',25,NULL,2,0,5,1);
REPLACE INTO `option_questions` (`option_question_id`, `question`, `created_at`, `updated_at`, `franchise_id`, `scale_min_value`, `scale_max_value`, `scale_cost_per_quantity`, `answer_type`, `option_question_type`) VALUES (1713,'Wings Extra Flavor Options','2024-04-07 23:54:19','2024-04-07 23:54:19',25,NULL,10,0,5,1);
REPLACE INTO `option_questions` (`option_question_id`, `question`, `created_at`, `updated_at`, `franchise_id`, `scale_min_value`, `scale_max_value`, `scale_cost_per_quantity`, `answer_type`, `option_question_type`) VALUES (1714,'Wings Extra Dressing Options','2024-04-07 23:54:19','2024-04-07 23:54:19',25,NULL,5,0,5,1);
REPLACE INTO `option_questions` (`option_question_id`, `question`, `created_at`, `updated_at`, `franchise_id`, `scale_min_value`, `scale_max_value`, `scale_cost_per_quantity`, `answer_type`, `option_question_type`) VALUES (1715,'Wings and Fries Cook Options','2024-04-07 23:54:19','2024-04-07 23:54:19',25,NULL,2,0,5,1);
REPLACE INTO `option_questions` (`option_question_id`, `question`, `created_at`, `updated_at`, `franchise_id`, `scale_min_value`, `scale_max_value`, `scale_cost_per_quantity`, `answer_type`, `option_question_type`) VALUES (1716,'Wings Extra Flavor Options','2024-04-07 23:54:20','2024-04-07 23:54:20',25,NULL,10,0,5,1);
REPLACE INTO `option_questions` (`option_question_id`, `question`, `created_at`, `updated_at`, `franchise_id`, `scale_min_value`, `scale_max_value`, `scale_cost_per_quantity`, `answer_type`, `option_question_type`) VALUES (1717,'Wings Extra Dressing Options','2024-04-07 23:54:20','2024-04-07 23:54:20',25,NULL,5,0,5,1);
REPLACE INTO `option_questions` (`option_question_id`, `question`, `created_at`, `updated_at`, `franchise_id`, `scale_min_value`, `scale_max_value`, `scale_cost_per_quantity`, `answer_type`, `option_question_type`) VALUES (1718,'Wings and Fries Cook Options','2024-04-07 23:54:20','2024-04-07 23:54:20',25,NULL,2,0,5,1);
REPLACE INTO `option_questions` (`option_question_id`, `question`, `created_at`, `updated_at`, `franchise_id`, `scale_min_value`, `scale_max_value`, `scale_cost_per_quantity`, `answer_type`, `option_question_type`) VALUES (1719,'Wings Extra Flavor Options','2024-04-07 23:54:20','2024-04-07 23:54:20',25,NULL,10,0,5,1);
REPLACE INTO `option_questions` (`option_question_id`, `question`, `created_at`, `updated_at`, `franchise_id`, `scale_min_value`, `scale_max_value`, `scale_cost_per_quantity`, `answer_type`, `option_question_type`) VALUES (1720,'Wings Extra Flavor Options','2024-04-07 23:54:20','2024-04-07 23:54:20',25,NULL,10,0,5,1);
REPLACE INTO `option_questions` (`option_question_id`, `question`, `created_at`, `updated_at`, `franchise_id`, `scale_min_value`, `scale_max_value`, `scale_cost_per_quantity`, `answer_type`, `option_question_type`) VALUES (1721,'Wings and Fries Cook Options','2024-04-07 23:54:20','2024-04-07 23:54:20',25,NULL,2,0,5,1);
REPLACE INTO `option_questions` (`option_question_id`, `question`, `created_at`, `updated_at`, `franchise_id`, `scale_min_value`, `scale_max_value`, `scale_cost_per_quantity`, `answer_type`, `option_question_type`) VALUES (1722,'Wings Extra Dressing Options','2024-04-07 23:54:20','2024-04-07 23:54:20',25,NULL,5,0,5,1);
REPLACE INTO `option_questions` (`option_question_id`, `question`, `created_at`, `updated_at`, `franchise_id`, `scale_min_value`, `scale_max_value`, `scale_cost_per_quantity`, `answer_type`, `option_question_type`) VALUES (1723,'Wings Extra Flavor Options','2024-04-07 23:54:20','2024-04-07 23:54:20',25,NULL,10,0,5,1);
REPLACE INTO `option_questions` (`option_question_id`, `question`, `created_at`, `updated_at`, `franchise_id`, `scale_min_value`, `scale_max_value`, `scale_cost_per_quantity`, `answer_type`, `option_question_type`) VALUES (1724,'Wings and Fries Cook Options','2024-04-07 23:54:20','2024-04-07 23:54:20',25,NULL,2,0,5,1);
REPLACE INTO `option_questions` (`option_question_id`, `question`, `created_at`, `updated_at`, `franchise_id`, `scale_min_value`, `scale_max_value`, `scale_cost_per_quantity`, `answer_type`, `option_question_type`) VALUES (1725,'Wings Extra Dressing Options','2024-04-07 23:54:20','2024-04-07 23:54:20',25,NULL,5,0,5,1);
REPLACE INTO `option_questions` (`option_question_id`, `question`, `created_at`, `updated_at`, `franchise_id`, `scale_min_value`, `scale_max_value`, `scale_cost_per_quantity`, `answer_type`, `option_question_type`) VALUES (1726,'Wings Extra Flavor Options','2024-04-07 23:54:20','2024-04-07 23:54:20',25,NULL,10,0,5,1);
REPLACE INTO `option_questions` (`option_question_id`, `question`, `created_at`, `updated_at`, `franchise_id`, `scale_min_value`, `scale_max_value`, `scale_cost_per_quantity`, `answer_type`, `option_question_type`) VALUES (1727,'Wings and Fries Cook Options','2024-04-07 23:54:21','2024-04-07 23:54:21',25,NULL,2,0,5,1);
REPLACE INTO `option_questions` (`option_question_id`, `question`, `created_at`, `updated_at`, `franchise_id`, `scale_min_value`, `scale_max_value`, `scale_cost_per_quantity`, `answer_type`, `option_question_type`) VALUES (1728,'Wings Extra Dressing Options','2024-04-07 23:54:21','2024-04-07 23:54:21',25,NULL,5,0,5,1);
REPLACE INTO `option_questions` (`option_question_id`, `question`, `created_at`, `updated_at`, `franchise_id`, `scale_min_value`, `scale_max_value`, `scale_cost_per_quantity`, `answer_type`, `option_question_type`) VALUES (1729,'Wings Extra Flavor Options','2024-04-07 23:54:21','2024-04-07 23:54:21',25,NULL,10,0,5,1);
REPLACE INTO `option_questions` (`option_question_id`, `question`, `created_at`, `updated_at`, `franchise_id`, `scale_min_value`, `scale_max_value`, `scale_cost_per_quantity`, `answer_type`, `option_question_type`) VALUES (1730,'Wings and Fries Cook Options','2024-04-07 23:54:21','2024-04-07 23:54:21',25,NULL,2,0,5,1);
REPLACE INTO `option_questions` (`option_question_id`, `question`, `created_at`, `updated_at`, `franchise_id`, `scale_min_value`, `scale_max_value`, `scale_cost_per_quantity`, `answer_type`, `option_question_type`) VALUES (1731,'Wings Extra Dressing Options','2024-04-07 23:54:21','2024-04-07 23:54:21',25,NULL,5,0,5,1);
REPLACE INTO `option_questions` (`option_question_id`, `question`, `created_at`, `updated_at`, `franchise_id`, `scale_min_value`, `scale_max_value`, `scale_cost_per_quantity`, `answer_type`, `option_question_type`) VALUES (1732,'Wings Extra Flavor Options','2024-04-07 23:54:21','2024-04-07 23:54:21',25,NULL,10,0,5,1);
REPLACE INTO `option_questions` (`option_question_id`, `question`, `created_at`, `updated_at`, `franchise_id`, `scale_min_value`, `scale_max_value`, `scale_cost_per_quantity`, `answer_type`, `option_question_type`) VALUES (1733,'Wings and Fries Cook Options','2024-04-07 23:54:21','2024-04-07 23:54:21',25,NULL,2,0,5,1);
REPLACE INTO `option_questions` (`option_question_id`, `question`, `created_at`, `updated_at`, `franchise_id`, `scale_min_value`, `scale_max_value`, `scale_cost_per_quantity`, `answer_type`, `option_question_type`) VALUES (1734,'Wings Extra Dressing Options','2024-04-07 23:54:21','2024-04-07 23:54:21',25,NULL,5,0,5,1);
REPLACE INTO `option_questions` (`option_question_id`, `question`, `created_at`, `updated_at`, `franchise_id`, `scale_min_value`, `scale_max_value`, `scale_cost_per_quantity`, `answer_type`, `option_question_type`) VALUES (1735,'ADD YOUR SAUCES AND SIDES','2024-04-07 23:54:21','2024-04-07 23:54:21',25,NULL,4,0,5,1);
/*!40000 ALTER TABLE `option_questions` ENABLE KEYS */;
UNLOCK TABLES;
SET @@SESSION.SQL_LOG_BIN = @MYSQLDUMP_TEMP_LOG_BIN;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-01-19 13:11:53

-- option_answers
-- MySQL dump 10.13  Distrib 9.3.0, for macos14.7 (arm64)
--
-- Host: stage-database.cluster-c01bnweqtr8m.us-east-2.rds.amazonaws.com    Database: SPARK
-- ------------------------------------------------------
-- Server version	8.0.39

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
SET @MYSQLDUMP_TEMP_LOG_BIN = @@SESSION.SQL_LOG_BIN;
SET @@SESSION.SQL_LOG_BIN= 0;

--
-- GTID state at the beginning of the backup 
--

SET @@GLOBAL.GTID_PURGED=/*!80000 '+'*/ '';

--
-- Dumping data for table `option_answers`
--
-- WHERE:  option_question_id IN (1691,1692,1693,1694,1695,1696,1697,1698,1699,1700,1701,1702,1703,1704,1705,1706,1707,1708,1709,1710,1711,1712,1713,1714,1715,1716,1717,1718,1719,1720,1721,1722,1723,1724,1725,1726,1727,1728,1729,1730,1731,1732,1733,1734,1735)

LOCK TABLES `option_answers` WRITE;
/*!40000 ALTER TABLE `option_answers` DISABLE KEYS */;
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17496,1691,'ABC 1',2.99,'2024-04-07 23:54:17','2024-04-07 23:54:17',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17497,1691,'ACD 2',0.11,'2024-04-07 23:54:17','2024-04-07 23:54:17',2,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17498,1692,'Option Text',48.11,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17499,1692,'Option B',59,'2024-04-07 23:54:18','2024-04-07 23:54:18',2,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17500,1692,'Option C',444,'2024-04-07 23:54:18','2024-04-07 23:54:18',3,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17501,1693,'Extra Celery+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17502,1693,'Extra Honey Mustard Dressing+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17503,1693,'Extra Bleu Cheese Dressing+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17504,1693,'Extra Ranch Dressing+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17505,1694,'Crispy Fries',0,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17506,1694,'Soft Fries',0,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17507,1694,'X Crispy Wings',0,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17508,1694,'Crispy Wings',0,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17509,1694,'Regular Wings',0,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17510,1694,'Soft Wings',0,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17511,1695,'Honey Garlic+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17512,1695,'Mango Habanero+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17513,1695,'Hot Teriyaki+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17514,1695,'Spicy BBQ+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17515,1695,'Honey Lemon Pepper+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17516,1695,'Lemon Pepper Dry+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17517,1695,'Honey Hot+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17518,1695,'Honey Medium+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17519,1695,'Honey Mild+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17520,1695,'Honey BBQ+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17521,1695,'Honey Gold+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17522,1695,'Lemon Pepper Wet+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17523,1695,'Sweet Chili+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17524,1695,'Teriyaki+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17525,1695,'Ranch Wings+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17526,1695,'Garlic Parmesan+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17527,1695,'Extra Hot+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17528,1695,'Hot+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17529,1695,'Medium+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17530,1695,'Mild+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17531,1695,'4/1 Flavors',0,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17532,1695,'1/3 Flavors',0,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17533,1695,'1/2 Flavors',0,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17534,1695,'Mix Sauce',0,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17535,1695,'Extra Wet Sauce+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17536,1695,'Light Sauce',0,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17537,1696,'Extra Celery+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17538,1696,'Extra Honey Mustard Dressing+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17539,1696,'Extra Bleu Cheese Dressing+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17540,1696,'Extra Ranch Dressing+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17541,1697,'Crispy Fries',0,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17542,1697,'Soft Fries',0,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17543,1697,'X Crispy Wings',0,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17544,1697,'Crispy Wings',0,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17545,1697,'Regular Wings',0,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17546,1697,'Soft Wings',0,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17547,1698,'Honey Garlic+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17548,1698,'Mango Habanero+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17549,1698,'Hot Teriyaki+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17550,1698,'Spicy BBQ+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17551,1698,'Honey Lemon Pepper+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17552,1698,'Lemon Pepper Dry+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17553,1698,'Honey Hot+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17554,1698,'Honey Medium+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17555,1698,'Honey Mild+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17556,1698,'Honey BBQ+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17557,1698,'Honey Gold+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17558,1698,'Lemon Pepper Wet+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17559,1698,'Sweet Chili+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17560,1698,'Teriyaki+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17561,1698,'Ranch Wings+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17562,1698,'Garlic Parmesan+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17563,1698,'Extra Hot+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17564,1698,'Hot+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17565,1698,'Medium+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17566,1698,'Mild+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17567,1698,'4/1 Flavors',0,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17568,1698,'1/3 Flavors',0,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17569,1698,'1/2 Flavors',0,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17570,1698,'Mix Sauce',0,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17571,1698,'Extra Wet Sauce+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17572,1698,'Light Sauce',0,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17573,1699,'Extra Celery+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17574,1699,'Extra Honey Mustard Dressing+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17575,1699,'Extra Bleu Cheese Dressing+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17576,1699,'Extra Ranch Dressing+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17577,1700,'Crispy Fries',0,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17578,1700,'Soft Fries',0,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17579,1700,'X Crispy Wings',0,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17580,1700,'Crispy Wings',0,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17581,1700,'Regular Wings',0,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17582,1700,'Soft Wings',0,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17583,1701,'Honey Garlic+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17584,1701,'Mango Habanero+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17585,1701,'Hot Teriyaki+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17586,1701,'Spicy BBQ+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17587,1701,'Honey Lemon Pepper+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17588,1701,'Lemon Pepper Dry+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17589,1701,'Honey Hot+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17590,1701,'Honey Medium+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17591,1701,'Honey Mild+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17592,1701,'Honey BBQ+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17593,1701,'Honey Gold+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17594,1701,'Lemon Pepper Wet+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17595,1701,'Sweet Chili+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17596,1701,'Teriyaki+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17597,1701,'Ranch Wings+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17598,1701,'Garlic Parmesan+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17599,1701,'Extra Hot+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17600,1701,'Hot+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17601,1701,'Medium+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17602,1701,'Mild+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17603,1701,'4/1 Flavors',0,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17604,1701,'1/3 Flavors',0,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17605,1701,'1/2 Flavors',0,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17606,1701,'Mix Sauce',0,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17607,1701,'Extra Wet Sauce+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17608,1701,'Light Sauce',0,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17609,1702,'Extra Celery+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17610,1702,'Extra Honey Mustard Dressing+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17611,1702,'Extra Bleu Cheese Dressing+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17612,1702,'Extra Ranch Dressing+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17613,1703,'Crispy Fries',0,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17614,1703,'Soft Fries',0,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17615,1703,'X Crispy Wings',0,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17616,1703,'Crispy Wings',0,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17617,1703,'Regular Wings',0,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17618,1703,'Soft Wings',0,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17619,1704,'Honey Garlic+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17620,1704,'Mango Habanero+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17621,1704,'Hot Teriyaki+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17622,1704,'Spicy BBQ+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17623,1704,'Honey Lemon Pepper+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17624,1704,'Lemon Pepper Dry+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17625,1704,'Honey Hot+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17626,1704,'Honey Medium+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17627,1704,'Honey Mild+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17628,1704,'Honey BBQ+',1,'2024-04-07 23:54:18','2024-04-07 23:54:18',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17629,1704,'Honey Gold+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17630,1704,'Lemon Pepper Wet+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17631,1704,'Sweet Chili+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17632,1704,'Teriyaki+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17633,1704,'Ranch Wings+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17634,1704,'Garlic Parmesan+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17635,1704,'Extra Hot+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17636,1704,'Hot+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17637,1704,'Medium+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17638,1704,'Mild+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17639,1704,'4/1 Flavors',0,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17640,1704,'1/3 Flavors',0,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17641,1704,'1/2 Flavors',0,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17642,1704,'Mix Sauce',0,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17643,1704,'Extra Wet Sauce+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17644,1704,'Light Sauce',0,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17645,1705,'Extra Celery+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17646,1705,'Extra Honey Mustard Dressing+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17647,1705,'Extra Bleu Cheese Dressing+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17648,1705,'Extra Ranch Dressing+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17649,1706,'Crispy Fries',0,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17650,1706,'Soft Fries',0,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17651,1706,'X Crispy Wings',0,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17652,1706,'Crispy Wings',0,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17653,1706,'Regular Wings',0,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17654,1706,'Soft Wings',0,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17655,1707,'Honey Garlic+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17656,1707,'Mango Habanero+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17657,1707,'Hot Teriyaki+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17658,1707,'Spicy BBQ+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17659,1707,'Honey Lemon Pepper+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17660,1707,'Lemon Pepper Dry+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17661,1707,'Honey Hot+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17662,1707,'Honey Medium+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17663,1707,'Honey Mild+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17664,1707,'Honey BBQ+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17665,1707,'Honey Gold+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17666,1707,'Lemon Pepper Wet+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17667,1707,'Sweet Chili+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17668,1707,'Teriyaki+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17669,1707,'Ranch Wings+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17670,1707,'Garlic Parmesan+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17671,1707,'Extra Hot+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17672,1707,'Hot+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17673,1707,'Medium+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17674,1707,'Mild+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17675,1707,'4/1 Flavors',0,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17676,1707,'1/3 Flavors',0,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17677,1707,'1/2 Flavors',0,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17678,1707,'Mix Sauce',0,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17679,1707,'Extra Wet Sauce+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17680,1707,'Light Sauce',0,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17681,1708,'Extra Celery+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17682,1708,'Extra Honey Mustard Dressing+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17683,1708,'Extra Bleu Cheese Dressing+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17684,1708,'Extra Ranch Dressing+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17685,1709,'Crispy Fries',0,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17686,1709,'Soft Fries',0,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17687,1709,'X Crispy Wings',0,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17688,1709,'Crispy Wings',0,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17689,1709,'Regular Wings',0,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17690,1709,'Soft Wings',0,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17691,1710,'Honey Garlic+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17692,1710,'Mango Habanero+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17693,1710,'Hot Teriyaki+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17694,1710,'Spicy BBQ+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17695,1710,'Honey Lemon Pepper+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17696,1710,'Lemon Pepper Dry+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17697,1710,'Honey Hot+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17698,1710,'Honey Medium+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17699,1710,'Honey Mild+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17700,1710,'Honey BBQ+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17701,1710,'Honey Gold+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17702,1710,'Lemon Pepper Wet+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17703,1710,'Sweet Chili+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17704,1710,'Teriyaki+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17705,1710,'Ranch Wings+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17706,1710,'Garlic Parmesan+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17707,1710,'Extra Hot+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17708,1710,'Hot+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17709,1710,'Medium+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17710,1710,'Mild+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17711,1710,'4/1 Flavors',0,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17712,1710,'1/3 Flavors',0,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17713,1710,'1/2 Flavors',0,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17714,1710,'Mix Sauce',0,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17715,1710,'Extra Wet Sauce+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17716,1710,'Light Sauce',0,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17717,1711,'Extra Celery+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17718,1711,'Extra Honey Mustard Dressing+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17719,1711,'Extra Bleu Cheese Dressing+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17720,1711,'Extra Ranch Dressing+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17721,1712,'Crispy Fries',0,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17722,1712,'Soft Fries',0,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17723,1712,'X Crispy Wings',0,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17724,1712,'Crispy Wings',0,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17725,1712,'Regular Wings',0,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17726,1712,'Soft Wings',0,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17727,1713,'Honey Garlic+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17728,1713,'Mango Habanero+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17729,1713,'Hot Teriyaki+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17730,1713,'Spicy BBQ+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17731,1713,'Honey Lemon Pepper+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17732,1713,'Lemon Pepper Dry+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17733,1713,'Honey Hot+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17734,1713,'Honey Medium+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17735,1713,'Honey Mild+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17736,1713,'Honey BBQ+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17737,1713,'Honey Gold+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17738,1713,'Lemon Pepper Wet+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17739,1713,'Sweet Chili+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17740,1713,'Teriyaki+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17741,1713,'Ranch Wings+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17742,1713,'Garlic Parmesan+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17743,1713,'Extra Hot+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17744,1713,'Hot+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17745,1713,'Medium+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17746,1713,'Mild+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17747,1713,'4/1 Flavors',0,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17748,1713,'1/3 Flavors',0,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17749,1713,'1/2 Flavors',0,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17750,1713,'Mix Sauce',0,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17751,1713,'Extra Wet Sauce+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17752,1713,'Light Sauce',0,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17753,1714,'Extra Celery+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17754,1714,'Extra Honey Mustard Dressing+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17755,1714,'Extra Bleu Cheese Dressing+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17756,1714,'Extra Ranch Dressing+',1,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17757,1715,'Crispy Fries',0,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17758,1715,'Soft Fries',0,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17759,1715,'X Crispy Wings',0,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17760,1715,'Crispy Wings',0,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17761,1715,'Regular Wings',0,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17762,1715,'Soft Wings',0,'2024-04-07 23:54:19','2024-04-07 23:54:19',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17763,1716,'Honey Garlic+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17764,1716,'Mango Habanero+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17765,1716,'Hot Teriyaki+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17766,1716,'Spicy BBQ+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17767,1716,'Honey Lemon Pepper+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17768,1716,'Lemon Pepper Dry+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17769,1716,'Honey Hot+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17770,1716,'Honey Medium+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17771,1716,'Honey Mild+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17772,1716,'Honey BBQ+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17773,1716,'Honey Gold+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17774,1716,'Lemon Pepper Wet+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17775,1716,'Sweet Chili+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17776,1716,'Teriyaki+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17777,1716,'Ranch Wings+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17778,1716,'Garlic Parmesan+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17779,1716,'Extra Hot+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17780,1716,'Hot+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17781,1716,'Medium+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17782,1716,'Mild+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17783,1716,'4/1 Flavors',0,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17784,1716,'1/3 Flavors',0,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17785,1716,'1/2 Flavors',0,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17786,1716,'Mix Sauce',0,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17787,1716,'Extra Wet Sauce+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17788,1716,'Light Sauce',0,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17789,1717,'Extra Celery+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17790,1717,'Extra Honey Mustard Dressing+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17791,1717,'Extra Bleu Cheese Dressing+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17792,1717,'Extra Ranch Dressing+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17793,1718,'Crispy Fries',0,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17794,1718,'Soft Fries',0,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17795,1718,'X Crispy Wings',0,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17796,1718,'Crispy Wings',0,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17797,1718,'Regular Wings',0,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17798,1718,'Soft Wings',0,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17799,1719,'Honey Garlic+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17800,1719,'Mango Habanero+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17801,1719,'Hot Teriyaki+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17802,1719,'Spicy BBQ+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17803,1719,'Honey Lemon Pepper+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17804,1719,'Lemon Pepper Dry+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17805,1719,'Honey Hot+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17806,1719,'Honey Medium+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17807,1719,'Honey Mild+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17808,1719,'Honey BBQ+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17809,1719,'Honey Gold+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17810,1719,'Lemon Pepper Wet+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17811,1719,'Sweet Chili+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17812,1719,'Teriyaki+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17813,1719,'Ranch Wings+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17814,1719,'Garlic Parmesan+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17815,1719,'Extra Hot+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17816,1719,'Hot+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17817,1719,'Medium+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17818,1719,'Mild+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17819,1719,'4/1 Flavors',0,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17820,1719,'1/3 Flavors',0,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17821,1719,'1/2 Flavors',0,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17822,1719,'Mix Sauce',0,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17823,1719,'Extra Wet Sauce+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17824,1719,'Light Sauce',0,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17825,1720,'Honey Garlic+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17826,1720,'Mango Habanero+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17827,1720,'Hot Teriyaki+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17828,1720,'Spicy BBQ+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17829,1720,'Honey Lemon Pepper+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17830,1720,'Lemon Pepper Dry+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17831,1720,'Honey Hot+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17832,1720,'Honey Medium+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17833,1720,'Honey Mild+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17834,1720,'Honey BBQ+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17835,1720,'Honey Gold+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17836,1720,'Lemon Pepper Wet+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17837,1720,'Sweet Chili+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17838,1720,'Teriyaki+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17839,1720,'Ranch Wings+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17840,1720,'Garlic Parmesan+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17841,1720,'Extra Hot+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17842,1720,'Hot+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17843,1720,'Medium+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17844,1720,'Mild+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17845,1720,'4/1 Flavors',0,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17846,1720,'1/3 Flavors',0,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17847,1720,'1/2 Flavors',0,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17848,1720,'Mix Sauce',0,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17849,1720,'Extra Wet Sauce+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17850,1720,'Light Sauce',0,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17851,1721,'Crispy Fries',0,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17852,1721,'Soft Fries',0,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17853,1721,'X Crispy Wings',0,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17854,1721,'Crispy Wings',0,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17855,1721,'Regular Wings',0,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17856,1721,'Soft Wings',0,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17857,1722,'Extra Celery+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17858,1722,'Extra Honey Mustard Dressing+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17859,1722,'Extra Bleu Cheese Dressing+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17860,1722,'Extra Ranch Dressing+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17861,1723,'Honey Garlic+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17862,1723,'Mango Habanero+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17863,1723,'Hot Teriyaki+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17864,1723,'Spicy BBQ+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17865,1723,'Honey Lemon Pepper+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17866,1723,'Lemon Pepper Dry+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17867,1723,'Honey Hot+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17868,1723,'Honey Medium+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17869,1723,'Honey Mild+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17870,1723,'Honey BBQ+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17871,1723,'Honey Gold+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17872,1723,'Lemon Pepper Wet+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17873,1723,'Sweet Chili+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17874,1723,'Teriyaki+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17875,1723,'Ranch Wings+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17876,1723,'Garlic Parmesan+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17877,1723,'Extra Hot+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17878,1723,'Hot+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17879,1723,'Medium+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17880,1723,'Mild+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17881,1723,'4/1 Flavors',0,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17882,1723,'1/3 Flavors',0,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17883,1723,'1/2 Flavors',0,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17884,1723,'Mix Sauce',0,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17885,1723,'Extra Wet Sauce+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17886,1723,'Light Sauce',0,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17887,1724,'Crispy Fries',0,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17888,1724,'Soft Fries',0,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17889,1724,'X Crispy Wings',0,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17890,1724,'Crispy Wings',0,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17891,1724,'Regular Wings',0,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17892,1724,'Soft Wings',0,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17893,1725,'Extra Celery+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17894,1725,'Extra Honey Mustard Dressing+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17895,1725,'Extra Bleu Cheese Dressing+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17896,1725,'Extra Ranch Dressing+',1,'2024-04-07 23:54:20','2024-04-07 23:54:20',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17897,1726,'Honey Garlic+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17898,1726,'Mango Habanero+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17899,1726,'Hot Teriyaki+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17900,1726,'Spicy BBQ+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17901,1726,'Honey Lemon Pepper+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17902,1726,'Lemon Pepper Dry+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17903,1726,'Honey Hot+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17904,1726,'Honey Medium+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17905,1726,'Honey Mild+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17906,1726,'Honey BBQ+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17907,1726,'Honey Gold+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17908,1726,'Lemon Pepper Wet+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17909,1726,'Sweet Chili+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17910,1726,'Teriyaki+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17911,1726,'Ranch Wings+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17912,1726,'Garlic Parmesan+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17913,1726,'Extra Hot+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17914,1726,'Hot+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17915,1726,'Medium+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17916,1726,'Mild+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17917,1726,'4/1 Flavors',0,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17918,1726,'1/3 Flavors',0,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17919,1726,'1/2 Flavors',0,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17920,1726,'Mix Sauce',0,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17921,1726,'Extra Wet Sauce+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17922,1726,'Light Sauce',0,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17923,1727,'Crispy Fries',0,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17924,1727,'Soft Fries',0,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17925,1727,'X Crispy Wings',0,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17926,1727,'Crispy Wings',0,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17927,1727,'Regular Wings',0,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17928,1727,'Soft Wings',0,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17929,1728,'Extra Celery+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17930,1728,'Extra Honey Mustard Dressing+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17931,1728,'Extra Bleu Cheese Dressing+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17932,1728,'Extra Ranch Dressing+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17933,1729,'Honey Garlic+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17934,1729,'Mango Habanero+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17935,1729,'Hot Teriyaki+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17936,1729,'Spicy BBQ+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17937,1729,'Honey Lemon Pepper+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17938,1729,'Lemon Pepper Dry+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17939,1729,'Honey Hot+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17940,1729,'Honey Medium+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17941,1729,'Honey Mild+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17942,1729,'Honey BBQ+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17943,1729,'Honey Gold+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17944,1729,'Lemon Pepper Wet+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17945,1729,'Sweet Chili+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17946,1729,'Teriyaki+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17947,1729,'Ranch Wings+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17948,1729,'Garlic Parmesan+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17949,1729,'Extra Hot+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17950,1729,'Hot+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17951,1729,'Medium+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17952,1729,'Mild+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17953,1729,'4/1 Flavors',0,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17954,1729,'1/3 Flavors',0,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17955,1729,'1/2 Flavors',0,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17956,1729,'Mix Sauce',0,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17957,1729,'Extra Wet Sauce+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17958,1729,'Light Sauce',0,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17959,1730,'Crispy Fries',0,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17960,1730,'Soft Fries',0,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17961,1730,'X Crispy Wings',0,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17962,1730,'Crispy Wings',0,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17963,1730,'Regular Wings',0,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17964,1730,'Soft Wings',0,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17965,1731,'Extra Celery+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17966,1731,'Extra Honey Mustard Dressing+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17967,1731,'Extra Bleu Cheese Dressing+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17968,1731,'Extra Ranch Dressing+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17969,1732,'Honey Garlic+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17970,1732,'Mango Habanero+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17971,1732,'Hot Teriyaki+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17972,1732,'Spicy BBQ+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17973,1732,'Honey Lemon Pepper+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17974,1732,'Lemon Pepper Dry+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17975,1732,'Honey Hot+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17976,1732,'Honey Medium+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17977,1732,'Honey Mild+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17978,1732,'Honey BBQ+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17979,1732,'Honey Gold+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17980,1732,'Lemon Pepper Wet+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17981,1732,'Sweet Chili+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17982,1732,'Teriyaki+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17983,1732,'Ranch Wings+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17984,1732,'Garlic Parmesan+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17985,1732,'Extra Hot+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17986,1732,'Hot+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17987,1732,'Medium+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17988,1732,'Mild+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17989,1732,'4/1 Flavors',0,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17990,1732,'1/3 Flavors',0,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17991,1732,'1/2 Flavors',0,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17992,1732,'Mix Sauce',0,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17993,1732,'Extra Wet Sauce+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17994,1732,'Light Sauce',0,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17995,1733,'Crispy Fries',0,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17996,1733,'Soft Fries',0,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17997,1733,'X Crispy Wings',0,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17998,1733,'Crispy Wings',0,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (17999,1733,'Regular Wings',0,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (18000,1733,'Soft Wings',0,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (18001,1734,'Extra Celery+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (18002,1734,'Extra Honey Mustard Dressing+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (18003,1734,'Extra Bleu Cheese Dressing+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (18004,1734,'Extra Ranch Dressing+',1,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (18005,1735,'TARTAR SAUCE',0.5,'2024-04-07 23:54:21','2024-04-07 23:54:21',1,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (18006,1735,'SPICY COCKTAIL SAUCE',0.5,'2024-04-07 23:54:21','2024-04-07 23:54:21',2,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (18007,1735,'COCKTAIL SAUCE',0.5,'2024-04-07 23:54:21','2024-04-07 23:54:21',3,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (18008,1735,'CUP OF GARLIC BUTTER',1.49,'2024-04-07 23:54:21','2024-04-07 23:54:21',4,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (18009,1735,'3 BEIGNETS',4.99,'2024-04-07 23:54:21','2024-04-07 23:54:21',5,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (18010,1735,'3 BOUDAIN BALL',5.99,'2024-04-07 23:54:21','2024-04-07 23:54:21',6,NULL);
REPLACE INTO `option_answers` (`option_answer_id`, `option_question_id`, `answer`, `additional_cost`, `created_at`, `updated_at`, `list_order`, `kitchen_name`) VALUES (18011,1735,'16 OUNCES GARLIC BUTTER',8.99,'2024-04-07 23:54:21','2024-04-07 23:54:21',7,NULL);
/*!40000 ALTER TABLE `option_answers` ENABLE KEYS */;
UNLOCK TABLES;
SET @@SESSION.SQL_LOG_BIN = @MYSQLDUMP_TEMP_LOG_BIN;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-01-19 13:11:55

-- option_question_groups
-- MySQL dump 10.13  Distrib 9.3.0, for macos14.7 (arm64)
--
-- Host: stage-database.cluster-c01bnweqtr8m.us-east-2.rds.amazonaws.com    Database: SPARK
-- ------------------------------------------------------
-- Server version	8.0.39

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
SET @MYSQLDUMP_TEMP_LOG_BIN = @@SESSION.SQL_LOG_BIN;
SET @@SESSION.SQL_LOG_BIN= 0;

--
-- GTID state at the beginning of the backup 
--

SET @@GLOBAL.GTID_PURGED=/*!80000 '+'*/ '';

--
-- Dumping data for table `option_question_groups`
--
-- WHERE:  franchise_id = 25

LOCK TABLES `option_question_groups` WRITE;
/*!40000 ALTER TABLE `option_question_groups` DISABLE KEYS */;
REPLACE INTO `option_question_groups` (`option_question_group_id`, `franchise_id`, `group_type`, `quantity`, `name`, `created_at`, `updated_at`) VALUES (33,25,NULL,NULL,'group','2024-04-07 23:54:21','2024-04-07 23:54:21');
/*!40000 ALTER TABLE `option_question_groups` ENABLE KEYS */;
UNLOCK TABLES;
SET @@SESSION.SQL_LOG_BIN = @MYSQLDUMP_TEMP_LOG_BIN;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-01-19 13:11:56

-- option_question_group_links
-- MySQL dump 10.13  Distrib 9.3.0, for macos14.7 (arm64)
--
-- Host: stage-database.cluster-c01bnweqtr8m.us-east-2.rds.amazonaws.com    Database: SPARK
-- ------------------------------------------------------
-- Server version	8.0.39

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
SET @MYSQLDUMP_TEMP_LOG_BIN = @@SESSION.SQL_LOG_BIN;
SET @@SESSION.SQL_LOG_BIN= 0;

--
-- GTID state at the beginning of the backup 
--

SET @@GLOBAL.GTID_PURGED=/*!80000 '+'*/ '';

--
-- Dumping data for table `option_question_group_links`
--
-- WHERE:  option_question_group_id IN (33)

LOCK TABLES `option_question_group_links` WRITE;
/*!40000 ALTER TABLE `option_question_group_links` DISABLE KEYS */;
/*!40000 ALTER TABLE `option_question_group_links` ENABLE KEYS */;
UNLOCK TABLES;
SET @@SESSION.SQL_LOG_BIN = @MYSQLDUMP_TEMP_LOG_BIN;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-01-19 13:11:58

-- option_question_menu_items
-- MySQL dump 10.13  Distrib 9.3.0, for macos14.7 (arm64)
--
-- Host: stage-database.cluster-c01bnweqtr8m.us-east-2.rds.amazonaws.com    Database: SPARK
-- ------------------------------------------------------
-- Server version	8.0.39

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
SET @MYSQLDUMP_TEMP_LOG_BIN = @@SESSION.SQL_LOG_BIN;
SET @@SESSION.SQL_LOG_BIN= 0;

--
-- GTID state at the beginning of the backup 
--

SET @@GLOBAL.GTID_PURGED=/*!80000 '+'*/ '';

--
-- Dumping data for table `option_question_menu_items`
--
-- WHERE:  menu_item_id IN (2768,2769,2770,2771,2772,2773,2774,2775,2776,2777,2778,2779,3253,2780,2781,2782,2783,2784,2785,2786,2787,2788,2789,2790,2791,2792,2793,2794,2795,2796,2797,2798,2799,2800,2801,2802,2803,2804,2805,2806,2807,2808,2809,2810,2811,2812,2813,2814,2815,2816,2817,2818,2819,2820,2821,2822,2823,2824)

LOCK TABLES `option_question_menu_items` WRITE;
/*!40000 ALTER TABLE `option_question_menu_items` DISABLE KEYS */;
REPLACE INTO `option_question_menu_items` (`option_question_menu_item_id`, `menu_item_id`, `option_question_id`, `created_at`, `updated_at`, `list_order`, `option_question_group_id`, `customer_list_order`, `restaurant_list_order`) VALUES (2890,2769,1691,'2024-04-07 23:54:21','2024-04-07 23:54:21',NULL,NULL,1,1);
REPLACE INTO `option_question_menu_items` (`option_question_menu_item_id`, `menu_item_id`, `option_question_id`, `created_at`, `updated_at`, `list_order`, `option_question_group_id`, `customer_list_order`, `restaurant_list_order`) VALUES (2891,2771,1693,'2024-04-07 23:54:21','2024-04-07 23:54:21',NULL,NULL,1,1);
REPLACE INTO `option_question_menu_items` (`option_question_menu_item_id`, `menu_item_id`, `option_question_id`, `created_at`, `updated_at`, `list_order`, `option_question_group_id`, `customer_list_order`, `restaurant_list_order`) VALUES (2892,2771,1694,'2024-04-07 23:54:21','2024-04-07 23:54:21',NULL,NULL,2,2);
REPLACE INTO `option_question_menu_items` (`option_question_menu_item_id`, `menu_item_id`, `option_question_id`, `created_at`, `updated_at`, `list_order`, `option_question_group_id`, `customer_list_order`, `restaurant_list_order`) VALUES (2893,2771,1695,'2024-04-07 23:54:21','2024-04-07 23:54:21',NULL,NULL,3,3);
REPLACE INTO `option_question_menu_items` (`option_question_menu_item_id`, `menu_item_id`, `option_question_id`, `created_at`, `updated_at`, `list_order`, `option_question_group_id`, `customer_list_order`, `restaurant_list_order`) VALUES (2894,2772,1696,'2024-04-07 23:54:21','2024-04-07 23:54:21',NULL,NULL,1,1);
REPLACE INTO `option_question_menu_items` (`option_question_menu_item_id`, `menu_item_id`, `option_question_id`, `created_at`, `updated_at`, `list_order`, `option_question_group_id`, `customer_list_order`, `restaurant_list_order`) VALUES (2895,2772,1697,'2024-04-07 23:54:21','2024-04-07 23:54:21',NULL,NULL,2,2);
REPLACE INTO `option_question_menu_items` (`option_question_menu_item_id`, `menu_item_id`, `option_question_id`, `created_at`, `updated_at`, `list_order`, `option_question_group_id`, `customer_list_order`, `restaurant_list_order`) VALUES (2896,2772,1698,'2024-04-07 23:54:21','2024-04-07 23:54:21',NULL,NULL,3,3);
REPLACE INTO `option_question_menu_items` (`option_question_menu_item_id`, `menu_item_id`, `option_question_id`, `created_at`, `updated_at`, `list_order`, `option_question_group_id`, `customer_list_order`, `restaurant_list_order`) VALUES (2897,2773,1699,'2024-04-07 23:54:21','2024-04-07 23:54:21',NULL,NULL,1,1);
REPLACE INTO `option_question_menu_items` (`option_question_menu_item_id`, `menu_item_id`, `option_question_id`, `created_at`, `updated_at`, `list_order`, `option_question_group_id`, `customer_list_order`, `restaurant_list_order`) VALUES (2898,2773,1700,'2024-04-07 23:54:21','2024-04-07 23:54:21',NULL,NULL,2,2);
REPLACE INTO `option_question_menu_items` (`option_question_menu_item_id`, `menu_item_id`, `option_question_id`, `created_at`, `updated_at`, `list_order`, `option_question_group_id`, `customer_list_order`, `restaurant_list_order`) VALUES (2899,2773,1701,'2024-04-07 23:54:21','2024-04-07 23:54:21',NULL,NULL,3,3);
REPLACE INTO `option_question_menu_items` (`option_question_menu_item_id`, `menu_item_id`, `option_question_id`, `created_at`, `updated_at`, `list_order`, `option_question_group_id`, `customer_list_order`, `restaurant_list_order`) VALUES (2900,2774,1702,'2024-04-07 23:54:22','2024-04-07 23:54:22',NULL,NULL,1,1);
REPLACE INTO `option_question_menu_items` (`option_question_menu_item_id`, `menu_item_id`, `option_question_id`, `created_at`, `updated_at`, `list_order`, `option_question_group_id`, `customer_list_order`, `restaurant_list_order`) VALUES (2901,2774,1703,'2024-04-07 23:54:22','2024-04-07 23:54:22',NULL,NULL,2,2);
REPLACE INTO `option_question_menu_items` (`option_question_menu_item_id`, `menu_item_id`, `option_question_id`, `created_at`, `updated_at`, `list_order`, `option_question_group_id`, `customer_list_order`, `restaurant_list_order`) VALUES (2902,2774,1704,'2024-04-07 23:54:22','2024-04-07 23:54:22',NULL,NULL,3,3);
REPLACE INTO `option_question_menu_items` (`option_question_menu_item_id`, `menu_item_id`, `option_question_id`, `created_at`, `updated_at`, `list_order`, `option_question_group_id`, `customer_list_order`, `restaurant_list_order`) VALUES (2903,2775,1705,'2024-04-07 23:54:22','2024-04-07 23:54:22',NULL,NULL,1,1);
REPLACE INTO `option_question_menu_items` (`option_question_menu_item_id`, `menu_item_id`, `option_question_id`, `created_at`, `updated_at`, `list_order`, `option_question_group_id`, `customer_list_order`, `restaurant_list_order`) VALUES (2904,2775,1706,'2024-04-07 23:54:22','2024-04-07 23:54:22',NULL,NULL,2,2);
REPLACE INTO `option_question_menu_items` (`option_question_menu_item_id`, `menu_item_id`, `option_question_id`, `created_at`, `updated_at`, `list_order`, `option_question_group_id`, `customer_list_order`, `restaurant_list_order`) VALUES (2905,2775,1707,'2024-04-07 23:54:22','2024-04-07 23:54:22',NULL,NULL,3,3);
REPLACE INTO `option_question_menu_items` (`option_question_menu_item_id`, `menu_item_id`, `option_question_id`, `created_at`, `updated_at`, `list_order`, `option_question_group_id`, `customer_list_order`, `restaurant_list_order`) VALUES (2906,2776,1708,'2024-04-07 23:54:22','2024-04-07 23:54:22',NULL,NULL,1,1);
REPLACE INTO `option_question_menu_items` (`option_question_menu_item_id`, `menu_item_id`, `option_question_id`, `created_at`, `updated_at`, `list_order`, `option_question_group_id`, `customer_list_order`, `restaurant_list_order`) VALUES (2907,2776,1709,'2024-04-07 23:54:22','2024-04-07 23:54:22',NULL,NULL,2,2);
REPLACE INTO `option_question_menu_items` (`option_question_menu_item_id`, `menu_item_id`, `option_question_id`, `created_at`, `updated_at`, `list_order`, `option_question_group_id`, `customer_list_order`, `restaurant_list_order`) VALUES (2908,2776,1710,'2024-04-07 23:54:22','2024-04-07 23:54:22',NULL,NULL,3,3);
REPLACE INTO `option_question_menu_items` (`option_question_menu_item_id`, `menu_item_id`, `option_question_id`, `created_at`, `updated_at`, `list_order`, `option_question_group_id`, `customer_list_order`, `restaurant_list_order`) VALUES (2909,2777,1711,'2024-04-07 23:54:22','2024-04-07 23:54:22',NULL,NULL,1,1);
REPLACE INTO `option_question_menu_items` (`option_question_menu_item_id`, `menu_item_id`, `option_question_id`, `created_at`, `updated_at`, `list_order`, `option_question_group_id`, `customer_list_order`, `restaurant_list_order`) VALUES (2910,2777,1712,'2024-04-07 23:54:22','2024-04-07 23:54:22',NULL,NULL,2,2);
REPLACE INTO `option_question_menu_items` (`option_question_menu_item_id`, `menu_item_id`, `option_question_id`, `created_at`, `updated_at`, `list_order`, `option_question_group_id`, `customer_list_order`, `restaurant_list_order`) VALUES (2911,2777,1713,'2024-04-07 23:54:22','2024-04-07 23:54:22',NULL,NULL,3,3);
REPLACE INTO `option_question_menu_items` (`option_question_menu_item_id`, `menu_item_id`, `option_question_id`, `created_at`, `updated_at`, `list_order`, `option_question_group_id`, `customer_list_order`, `restaurant_list_order`) VALUES (2912,2778,1714,'2024-04-07 23:54:22','2024-04-07 23:54:22',NULL,NULL,1,1);
REPLACE INTO `option_question_menu_items` (`option_question_menu_item_id`, `menu_item_id`, `option_question_id`, `created_at`, `updated_at`, `list_order`, `option_question_group_id`, `customer_list_order`, `restaurant_list_order`) VALUES (2913,2778,1715,'2024-04-07 23:54:22','2024-04-07 23:54:22',NULL,NULL,2,2);
REPLACE INTO `option_question_menu_items` (`option_question_menu_item_id`, `menu_item_id`, `option_question_id`, `created_at`, `updated_at`, `list_order`, `option_question_group_id`, `customer_list_order`, `restaurant_list_order`) VALUES (2914,2778,1716,'2024-04-07 23:54:22','2024-04-07 23:54:22',NULL,NULL,3,3);
REPLACE INTO `option_question_menu_items` (`option_question_menu_item_id`, `menu_item_id`, `option_question_id`, `created_at`, `updated_at`, `list_order`, `option_question_group_id`, `customer_list_order`, `restaurant_list_order`) VALUES (2915,2779,1717,'2024-04-07 23:54:22','2024-04-07 23:54:22',NULL,NULL,1,1);
REPLACE INTO `option_question_menu_items` (`option_question_menu_item_id`, `menu_item_id`, `option_question_id`, `created_at`, `updated_at`, `list_order`, `option_question_group_id`, `customer_list_order`, `restaurant_list_order`) VALUES (2916,2779,1718,'2024-04-07 23:54:22','2024-04-07 23:54:22',NULL,NULL,2,2);
REPLACE INTO `option_question_menu_items` (`option_question_menu_item_id`, `menu_item_id`, `option_question_id`, `created_at`, `updated_at`, `list_order`, `option_question_group_id`, `customer_list_order`, `restaurant_list_order`) VALUES (2917,2779,1719,'2024-04-07 23:54:22','2024-04-07 23:54:22',NULL,NULL,3,3);
REPLACE INTO `option_question_menu_items` (`option_question_menu_item_id`, `menu_item_id`, `option_question_id`, `created_at`, `updated_at`, `list_order`, `option_question_group_id`, `customer_list_order`, `restaurant_list_order`) VALUES (2918,2780,1720,'2024-04-07 23:54:22','2024-04-07 23:54:22',NULL,NULL,1,1);
REPLACE INTO `option_question_menu_items` (`option_question_menu_item_id`, `menu_item_id`, `option_question_id`, `created_at`, `updated_at`, `list_order`, `option_question_group_id`, `customer_list_order`, `restaurant_list_order`) VALUES (2919,2780,1721,'2024-04-07 23:54:22','2024-04-07 23:54:22',NULL,NULL,2,2);
REPLACE INTO `option_question_menu_items` (`option_question_menu_item_id`, `menu_item_id`, `option_question_id`, `created_at`, `updated_at`, `list_order`, `option_question_group_id`, `customer_list_order`, `restaurant_list_order`) VALUES (2920,2780,1722,'2024-04-07 23:54:22','2024-04-07 23:54:22',NULL,NULL,3,3);
REPLACE INTO `option_question_menu_items` (`option_question_menu_item_id`, `menu_item_id`, `option_question_id`, `created_at`, `updated_at`, `list_order`, `option_question_group_id`, `customer_list_order`, `restaurant_list_order`) VALUES (2921,2781,1723,'2024-04-07 23:54:22','2024-04-07 23:54:22',NULL,NULL,1,1);
REPLACE INTO `option_question_menu_items` (`option_question_menu_item_id`, `menu_item_id`, `option_question_id`, `created_at`, `updated_at`, `list_order`, `option_question_group_id`, `customer_list_order`, `restaurant_list_order`) VALUES (2922,2781,1724,'2024-04-07 23:54:22','2024-04-07 23:54:22',NULL,NULL,2,2);
REPLACE INTO `option_question_menu_items` (`option_question_menu_item_id`, `menu_item_id`, `option_question_id`, `created_at`, `updated_at`, `list_order`, `option_question_group_id`, `customer_list_order`, `restaurant_list_order`) VALUES (2923,2781,1725,'2024-04-07 23:54:22','2024-04-07 23:54:22',NULL,NULL,3,3);
REPLACE INTO `option_question_menu_items` (`option_question_menu_item_id`, `menu_item_id`, `option_question_id`, `created_at`, `updated_at`, `list_order`, `option_question_group_id`, `customer_list_order`, `restaurant_list_order`) VALUES (2924,2782,1726,'2024-04-07 23:54:22','2024-04-07 23:54:22',NULL,NULL,1,1);
REPLACE INTO `option_question_menu_items` (`option_question_menu_item_id`, `menu_item_id`, `option_question_id`, `created_at`, `updated_at`, `list_order`, `option_question_group_id`, `customer_list_order`, `restaurant_list_order`) VALUES (2925,2782,1727,'2024-04-07 23:54:22','2024-04-07 23:54:22',NULL,NULL,2,2);
REPLACE INTO `option_question_menu_items` (`option_question_menu_item_id`, `menu_item_id`, `option_question_id`, `created_at`, `updated_at`, `list_order`, `option_question_group_id`, `customer_list_order`, `restaurant_list_order`) VALUES (2926,2782,1728,'2024-04-07 23:54:22','2024-04-07 23:54:22',NULL,NULL,3,3);
REPLACE INTO `option_question_menu_items` (`option_question_menu_item_id`, `menu_item_id`, `option_question_id`, `created_at`, `updated_at`, `list_order`, `option_question_group_id`, `customer_list_order`, `restaurant_list_order`) VALUES (2927,2783,1729,'2024-04-07 23:54:22','2024-04-07 23:54:22',NULL,NULL,1,1);
REPLACE INTO `option_question_menu_items` (`option_question_menu_item_id`, `menu_item_id`, `option_question_id`, `created_at`, `updated_at`, `list_order`, `option_question_group_id`, `customer_list_order`, `restaurant_list_order`) VALUES (2928,2783,1730,'2024-04-07 23:54:22','2024-04-07 23:54:22',NULL,NULL,2,2);
REPLACE INTO `option_question_menu_items` (`option_question_menu_item_id`, `menu_item_id`, `option_question_id`, `created_at`, `updated_at`, `list_order`, `option_question_group_id`, `customer_list_order`, `restaurant_list_order`) VALUES (2929,2783,1731,'2024-04-07 23:54:22','2024-04-07 23:54:22',NULL,NULL,3,3);
REPLACE INTO `option_question_menu_items` (`option_question_menu_item_id`, `menu_item_id`, `option_question_id`, `created_at`, `updated_at`, `list_order`, `option_question_group_id`, `customer_list_order`, `restaurant_list_order`) VALUES (2930,2784,1732,'2024-04-07 23:54:22','2024-04-07 23:54:22',NULL,NULL,1,1);
REPLACE INTO `option_question_menu_items` (`option_question_menu_item_id`, `menu_item_id`, `option_question_id`, `created_at`, `updated_at`, `list_order`, `option_question_group_id`, `customer_list_order`, `restaurant_list_order`) VALUES (2931,2784,1733,'2024-04-07 23:54:22','2024-04-07 23:54:22',NULL,NULL,2,2);
REPLACE INTO `option_question_menu_items` (`option_question_menu_item_id`, `menu_item_id`, `option_question_id`, `created_at`, `updated_at`, `list_order`, `option_question_group_id`, `customer_list_order`, `restaurant_list_order`) VALUES (2932,2784,1734,'2024-04-07 23:54:22','2024-04-07 23:54:22',NULL,NULL,3,3);
REPLACE INTO `option_question_menu_items` (`option_question_menu_item_id`, `menu_item_id`, `option_question_id`, `created_at`, `updated_at`, `list_order`, `option_question_group_id`, `customer_list_order`, `restaurant_list_order`) VALUES (2933,2799,1735,'2024-04-07 23:54:22','2024-04-07 23:54:22',NULL,NULL,1,1);
REPLACE INTO `option_question_menu_items` (`option_question_menu_item_id`, `menu_item_id`, `option_question_id`, `created_at`, `updated_at`, `list_order`, `option_question_group_id`, `customer_list_order`, `restaurant_list_order`) VALUES (2934,2800,1735,'2024-04-07 23:54:22','2024-04-07 23:54:22',NULL,NULL,1,1);
REPLACE INTO `option_question_menu_items` (`option_question_menu_item_id`, `menu_item_id`, `option_question_id`, `created_at`, `updated_at`, `list_order`, `option_question_group_id`, `customer_list_order`, `restaurant_list_order`) VALUES (2935,2801,1735,'2024-04-07 23:54:22','2024-04-07 23:54:22',NULL,NULL,1,1);
REPLACE INTO `option_question_menu_items` (`option_question_menu_item_id`, `menu_item_id`, `option_question_id`, `created_at`, `updated_at`, `list_order`, `option_question_group_id`, `customer_list_order`, `restaurant_list_order`) VALUES (2936,2802,1735,'2024-04-07 23:54:22','2024-04-07 23:54:22',NULL,NULL,1,1);
REPLACE INTO `option_question_menu_items` (`option_question_menu_item_id`, `menu_item_id`, `option_question_id`, `created_at`, `updated_at`, `list_order`, `option_question_group_id`, `customer_list_order`, `restaurant_list_order`) VALUES (2937,2803,1735,'2024-04-07 23:54:22','2024-04-07 23:54:22',NULL,NULL,1,1);
REPLACE INTO `option_question_menu_items` (`option_question_menu_item_id`, `menu_item_id`, `option_question_id`, `created_at`, `updated_at`, `list_order`, `option_question_group_id`, `customer_list_order`, `restaurant_list_order`) VALUES (2938,2804,1735,'2024-04-07 23:54:22','2024-04-07 23:54:22',NULL,NULL,1,1);
REPLACE INTO `option_question_menu_items` (`option_question_menu_item_id`, `menu_item_id`, `option_question_id`, `created_at`, `updated_at`, `list_order`, `option_question_group_id`, `customer_list_order`, `restaurant_list_order`) VALUES (2939,2805,1735,'2024-04-07 23:54:22','2024-04-07 23:54:22',NULL,NULL,1,1);
REPLACE INTO `option_question_menu_items` (`option_question_menu_item_id`, `menu_item_id`, `option_question_id`, `created_at`, `updated_at`, `list_order`, `option_question_group_id`, `customer_list_order`, `restaurant_list_order`) VALUES (2940,2806,1735,'2024-04-07 23:54:22','2024-04-07 23:54:22',NULL,NULL,1,1);
/*!40000 ALTER TABLE `option_question_menu_items` ENABLE KEYS */;
UNLOCK TABLES;
SET @@SESSION.SQL_LOG_BIN = @MYSQLDUMP_TEMP_LOG_BIN;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-01-19 13:12:00

-- open_times
-- MySQL dump 10.13  Distrib 9.3.0, for macos14.7 (arm64)
--
-- Host: stage-database.cluster-c01bnweqtr8m.us-east-2.rds.amazonaws.com    Database: SPARK
-- ------------------------------------------------------
-- Server version	8.0.39

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
SET @MYSQLDUMP_TEMP_LOG_BIN = @@SESSION.SQL_LOG_BIN;
SET @@SESSION.SQL_LOG_BIN= 0;

--
-- GTID state at the beginning of the backup 
--

SET @@GLOBAL.GTID_PURGED=/*!80000 '+'*/ '';

--
-- Dumping data for table `open_times`
--
-- WHERE:  restaurant_id = 23

LOCK TABLES `open_times` WRITE;
/*!40000 ALTER TABLE `open_times` DISABLE KEYS */;
-- Always open: all days (255), 0:00-23:59, open_or_closed=1 (OPEN)
-- Note: open_or_closed=0 means OPEN, open_or_closed=1 means CLOSED
REPLACE INTO `open_times` (`open_time_id`, `restaurant_id`, `menu_category_id`, `days_mask`, `start_time_minute`, `end_time_minute`, `open_or_closed`, `date`, `created_at`, `updated_at`) VALUES (583,23,NULL,255,0,1439,0,NULL,'2024-04-27 00:27:29','2024-09-02 04:49:31');
/*!40000 ALTER TABLE `open_times` ENABLE KEYS */;
UNLOCK TABLES;
SET @@SESSION.SQL_LOG_BIN = @MYSQLDUMP_TEMP_LOG_BIN;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-01-19 13:12:01

-- addresses (required for restaurant location - loadRestaurants() JOINs on this)
REPLACE INTO `addresses` (`address_id`, `addr_line_1`, `apartment_number`, `city`, `zip_code`, `longitude`, `latitude`, `address_type`, `created_at`, `updated_at`, `verified_status`, `original_addr_line_1`, `suggested_addr_line_1`, `state`, `city_id`, `address_status`, `pending_address_status`, `address_lookup_type`, `version`) VALUES
(2, '493 east clayton st', NULL, 'Athens', '30601', -83.3733, 33.9592, 0, NOW(), NOW(), 1, '493 East Clayton Street', '493 east clayton st', 9, 2, 0, 0, 0, 1);

-- counties (required for sales tax - loadRestaurants() JOINs on this)
REPLACE INTO `counties` (`county_id`, `name`, `state`, `sales_tax_percent`, `created_at`, `updated_at`) VALUES
(2, 'Oconee', 9, 7.000, NOW(), NOW());

-- payment_merchant_accounts (required for card payments)
-- Using test Stripe keys; payment_merchant_account_type=1 is Stripe
REPLACE INTO `payment_merchant_accounts` (`payment_merchant_account_id`, `restaurant_id`, `payment_merchant_account_type`, `created_at`, `updated_at`, `external_id`, `private_key`, `public_key`) VALUES
(1000, 23, 1, NOW(), NOW(), NULL, 'sk_test_51Mqzx8CMuwMc3J0pVpU0r0wPbsWHJD5a5VIP78zwEOEyUzuGIy0vpgoovpL2lSc16MFlZ6rqC9bsmW5yaWK3L3N400D6dcs85C', 'pk_test_51Mqzx8CMuwMc3J0ptq2xar9gDD2Nue6WQx4FU1LZCIQUDx9t2wfPjB66a9a89WkXTfqhqfQfb2ArU036S1OLhVOB00XUJ1mTdO');

SET FOREIGN_KEY_CHECKS = 1;
