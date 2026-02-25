-- Demo data for logistics_db
USE logistics_db;

SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE warehouses;
TRUNCATE TABLE shipments;
TRUNCATE TABLE packages;
SET FOREIGN_KEY_CHECKS = 1;

-- Insert warehouses
INSERT INTO warehouses (warehouse_id, name, address, city, state, capacity, current_inventory) VALUES
('WH001', 'Warehouse Millsport', '9601 Corey Harbors Apt. 929', 'Hendersonfurt', 'NV', 23374, 32894),
('WH002', 'Warehouse Timothyshire', '8469 Cook Square', 'North Erin', 'ND', 18786, 32913),
('WH003', 'Warehouse Carriebury', '464 Travis Union Suite 722', 'Courtneyborough', 'LA', 79449, 42263),
('WH004', 'Warehouse North Charles', '352 Desiree Crescent Apt. 350', 'Christinebury', 'AL', 57060, 10111),
('WH005', 'Warehouse New Victoria', '76818 Rachel Manor Apt. 026', 'Lake Mollyland', 'PA', 84008, 33821),
('WH006', 'Warehouse Markhaven', '2402 Jason Glens', 'Cookshire', 'IA', 36297, 48113),
('WH007', 'Warehouse Brownstad', '85022 Christine View', 'Cassandrahaven', 'CO', 49758, 13448),
('WH008', 'Warehouse Lake Francismouth', '350 Todd Green Apt. 758', 'Shafferberg', 'NM', 71206, 9030),
('WH009', 'Warehouse New Veronica', '65156 Thornton Mews Apt. 649', 'North Patriciaview', 'VT', 29009, 47261),
('WH010', 'Warehouse Harrisville', '3094 Chase Keys Suite 015', 'North Amandabury', 'ID', 49588, 30468);

-- Insert shipments
INSERT INTO shipments (shipment_id, origin_warehouse, destination_address, status, shipped_date, estimated_delivery, actual_delivery, carrier, tracking_number) VALUES
('SHIP00000001', 'WH001', '1748 Pittman Hills Apt. 089
Gilesland, VI 78319', 'in_transit', '2026-02-20', '2026-02-26', '2026-02-25', 'UPS', '26029e07-624e-452d-8'),
('SHIP00000002', 'WH009', '7573 Gibbs Mall
Sandovalbury, MO 32496', 'returned', '2026-02-14', '2026-02-20', '2026-02-18', 'Amazon', '386ed213-2218-4371-8'),
('SHIP00000003', 'WH006', 'USS Coleman
FPO AA 63962', 'in_transit', '2026-02-07', '2026-02-09', NULL, 'UPS', '3dd8970c-fd66-44c2-b'),
('SHIP00000004', 'WH009', '48450 Johns Ridges Suite 605
Christinetown, NH 56823', 'delivered', '2026-01-31', '2026-02-05', '2026-02-06', 'USPS', '073de574-82b7-4029-a'),
('SHIP00000005', 'WH001', '40340 James Forges
East Williamberg, NY 79528', 'returned', '2026-02-02', '2026-02-08', '2026-02-09', 'Amazon', 'ddd3a578-5f0d-453b-a'),
('SHIP00000006', 'WH007', '215 Molly Point
North Zoe, ME 92554', 'returned', '2026-02-20', '2026-02-24', '2026-02-22', 'FedEx', 'a03512ce-661f-4439-8'),
('SHIP00000007', 'WH009', '730 Christopher Walks
Markshire, NJ 28510', 'lost', '2026-02-17', '2026-02-18', '2026-02-18', 'DHL', '4c45f513-c983-477e-9'),
('SHIP00000008', 'WH007', '8715 Michael Row Apt. 609
West Kathryn, MT 16989', 'in_transit', '2026-02-04', '2026-02-07', NULL, 'UPS', '5228c1a0-94e7-43de-a'),
('SHIP00000009', 'WH006', '9625 Dakota Ranch Suite 471
North Erikmouth, AL 59336', 'lost', '2026-02-04', '2026-02-05', '2026-02-04', 'USPS', 'ef9cf211-2dac-4c54-a'),
('SHIP00000010', 'WH009', '590 Lewis Junctions
Zunigachester, DC 59678', 'returned', '2026-02-16', '2026-02-23', NULL, 'Amazon', '607553b5-01c0-4afc-9'),
('SHIP00000011', 'WH008', '817 Green Points Apt. 320
North Wayne, PW 51894', 'delivered', '2026-02-01', '2026-02-08', NULL, 'DHL', 'f1446c77-37ed-4167-9'),
('SHIP00000012', 'WH007', '289 George Point Suite 982
West Carolville, AZ 85228', 'pending', '2026-01-31', '2026-02-06', '2026-02-07', 'UPS', 'ece88a05-65bc-490e-8'),
('SHIP00000013', 'WH001', '435 Philip Stream
South Luis, MS 00792', 'delivered', '2026-02-04', '2026-02-08', '2026-02-08', 'USPS', 'c623c62d-228b-4264-a'),
('SHIP00000014', 'WH004', '35277 Leah Run
Schmittchester, RI 94235', 'returned', '2026-02-08', '2026-02-15', '2026-02-15', 'FedEx', 'c3f74cb3-dda5-47bf-a'),
('SHIP00000015', 'WH006', '4318 Clark Fork
Tammyland, FM 29221', 'delivered', '2026-02-04', '2026-02-09', '2026-02-12', 'Amazon', '2bfaae94-7304-4d60-b'),
('SHIP00000016', 'WH010', '982 Jackson Route Apt. 129
New Juantown, NJ 11925', 'in_transit', '2026-01-31', '2026-02-05', NULL, 'DHL', '49df76af-dcaa-469f-9'),
('SHIP00000017', 'WH004', 'USNV Woodward
FPO AA 34387', 'in_transit', '2026-02-03', '2026-02-08', '2026-02-08', 'UPS', '2efcda52-d931-4197-b'),
('SHIP00000018', 'WH004', '57004 Paul Ports
Elizabethview, IL 43206', 'in_transit', '2026-02-19', '2026-02-23', '2026-02-26', 'UPS', '93efb8da-3855-461b-b'),
('SHIP00000019', 'WH005', '89239 Linda Keys Suite 313
West Beckytown, UT 34395', 'delivered', '2026-02-22', '2026-02-24', '2026-02-22', 'DHL', 'fe265a0a-1ae7-4067-8'),
('SHIP00000020', 'WH008', '83424 Felicia Manors Suite 410
Lake Christophermouth, TN 40993', 'delivered', '2026-01-28', '2026-02-02', NULL, 'USPS', 'ab95372c-e6a8-4478-b'),
('SHIP00000021', 'WH010', '0220 Romero Cape
Thomasmouth, WI 42532', 'returned', '2026-01-26', '2026-01-29', NULL, 'USPS', '67ec4861-df8d-4516-9'),
('SHIP00000022', 'WH002', '4666 Christopher Trail Apt. 496
Millerland, FL 69079', 'pending', '2026-01-29', '2026-02-01', NULL, 'USPS', '98b63861-887f-4cf3-8'),
('SHIP00000023', 'WH003', '8937 Cobb Viaduct
Port Alex, ID 07560', 'in_transit', '2026-02-13', '2026-02-14', '2026-02-14', 'FedEx', 'a414d18d-6b9e-4e20-b'),
('SHIP00000024', 'WH002', '92801 Ball Mission Apt. 973
South Samanthamouth, MH 33895', 'lost', '2026-02-09', '2026-02-14', '2026-02-16', 'FedEx', 'b44dcd95-5620-412f-a'),
('SHIP00000025', 'WH005', '54381 Rhonda Flats
Lake Mary, VA 82739', 'returned', '2026-02-20', '2026-02-27', '2026-03-01', 'DHL', '24ee46f5-99cd-44ff-9'),
('SHIP00000026', 'WH004', '9959 George Rue Suite 646
Catherinebury, FL 16259', 'in_transit', '2026-02-20', '2026-02-26', NULL, 'Amazon', 'eaa079a1-8ae7-440b-9'),
('SHIP00000027', 'WH005', 'PSC 4936, Box 8152
APO AE 78868', 'returned', '2026-01-26', '2026-01-29', '2026-01-27', 'Amazon', '9905df1e-358b-4814-a'),
('SHIP00000028', 'WH002', '8951 Rachel Mount
Lawrenceberg, CA 84561', 'pending', '2026-01-27', '2026-02-02', '2026-02-03', 'DHL', '475381ac-5c21-4637-a'),
('SHIP00000029', 'WH007', '3341 Kelly Course Apt. 995
Lisamouth, SC 80494', 'in_transit', '2026-02-23', '2026-03-02', '2026-03-02', 'DHL', '9196d69a-88ba-434e-8'),
('SHIP00000030', 'WH002', '8055 Rosario Vista
Hayesfurt, MH 53118', 'in_transit', '2026-02-03', '2026-02-09', '2026-02-09', 'Amazon', 'fd46f13c-cf6d-4062-9'),
('SHIP00000031', 'WH001', 'USNS Murphy
FPO AP 87436', 'in_transit', '2026-02-16', '2026-02-21', NULL, 'UPS', 'c97eed5e-8644-48b6-8'),
('SHIP00000032', 'WH010', 'Unit 6047 Box 8505
DPO AE 99828', 'returned', '2026-02-18', '2026-02-19', NULL, 'DHL', '45621d13-252c-4f32-9'),
('SHIP00000033', 'WH005', '478 Walker Street Apt. 099
Danielview, MH 66064', 'in_transit', '2026-02-13', '2026-02-20', NULL, 'UPS', '1303e2e2-e6d7-4c83-b'),
('SHIP00000034', 'WH004', '0191 Aaron Mall Suite 861
West Cynthia, AK 30219', 'returned', '2026-01-26', '2026-01-29', '2026-01-27', 'USPS', '9c3b5108-656b-41b9-9'),
('SHIP00000035', 'WH006', 'USS Waters
FPO AA 16305', 'returned', '2026-02-20', '2026-02-21', '2026-02-19', 'UPS', '6a5519d2-8cfa-43d2-b'),
('SHIP00000036', 'WH010', '9483 Amanda Ridge
New Bridgetfort, GU 08239', 'in_transit', '2026-02-12', '2026-02-18', NULL, 'FedEx', 'f65468aa-e243-4fcf-b'),
('SHIP00000037', 'WH007', '540 Todd Forge Suite 552
Port Penny, NV 76562', 'lost', '2026-02-20', '2026-02-21', '2026-02-22', 'UPS', '77c8608e-79e4-4d12-9'),
('SHIP00000038', 'WH002', '843 Crystal Street Apt. 199
Bryantside, KY 35599', 'returned', '2026-02-12', '2026-02-17', '2026-02-15', 'Amazon', '06ca954e-5f59-4855-a'),
('SHIP00000039', 'WH008', '043 Diamond Mills
New Maxwell, HI 80930', 'pending', '2026-02-08', '2026-02-15', '2026-02-17', 'Amazon', 'a1ebccb4-6729-4f9e-a'),
('SHIP00000040', 'WH007', '010 Grimes Mall
New Alexisstad, TX 36860', 'delivered', '2026-01-26', '2026-01-27', '2026-01-30', 'UPS', '2ab459d5-cb53-4630-9'),
('SHIP00000041', 'WH008', 'Unit 5265 Box 2978
DPO AP 16750', 'delivered', '2026-01-31', '2026-02-06', NULL, 'USPS', '7184aecf-f0d6-4656-9'),
('SHIP00000042', 'WH008', '23616 Kidd Road Apt. 565
Lake Lisa, TX 05260', 'delivered', '2026-02-24', '2026-02-25', '2026-02-26', 'USPS', 'f9a023cd-5546-4325-9'),
('SHIP00000043', 'WH002', '643 Jonathan Mountains Apt. 862
East Ericburgh, VI 26605', 'lost', '2026-01-27', '2026-02-03', '2026-02-04', 'UPS', '08254216-6fc9-4fa5-8'),
('SHIP00000044', 'WH004', '35273 Jimmy Ramp
Henryton, NY 43501', 'delivered', '2026-01-30', '2026-02-02', '2026-01-31', 'USPS', 'cd8ed87c-16cc-4e91-b'),
('SHIP00000045', 'WH006', '86548 Russell Brook
Houseberg, IL 63229', 'pending', '2026-02-23', '2026-03-02', '2026-02-28', 'USPS', '6fa8b2a2-26f2-4598-a'),
('SHIP00000046', 'WH001', '201 Weaver Port Suite 514
Johntown, DC 31362', 'returned', '2026-01-28', '2026-01-29', '2026-01-27', 'Amazon', 'b2cd3926-e58c-465b-b'),
('SHIP00000047', 'WH003', '683 Jackson Dam Apt. 140
Gibsonmouth, MI 15192', 'delivered', '2026-02-18', '2026-02-23', '2026-02-26', 'DHL', '31b1de3d-3dc4-4056-b'),
('SHIP00000048', 'WH005', '3390 William Loaf Apt. 586
Ronaldtown, FL 67397', 'returned', '2026-02-14', '2026-02-16', NULL, 'Amazon', 'ebaa5a9f-a5fa-4745-b'),
('SHIP00000049', 'WH008', '64424 Heather Brooks
New Ashley, TN 19484', 'delivered', '2026-02-14', '2026-02-21', NULL, 'UPS', 'd24781e5-cddc-4a01-9'),
('SHIP00000050', 'WH006', '273 Kane Mount Apt. 233
Martinburgh, NV 48898', 'delivered', '2026-01-27', '2026-02-03', '2026-02-03', 'USPS', '9a18c9ff-4a4d-4993-8'),
('SHIP00000051', 'WH002', '7753 Jonathan Divide
North Luisview, WA 54764', 'pending', '2026-02-18', '2026-02-21', '2026-02-20', 'USPS', '0426a264-b647-45d4-8'),
('SHIP00000052', 'WH008', '206 Greer Mill
New Andrewstad, GA 35984', 'delivered', '2026-02-05', '2026-02-06', '2026-02-07', 'USPS', 'afecdaf6-8e0c-4ec9-9'),
('SHIP00000053', 'WH005', '395 Lisa Road Suite 270
South Patrickfurt, WA 33456', 'in_transit', '2026-02-08', '2026-02-14', NULL, 'DHL', 'cc9ee4ab-c42d-4919-8'),
('SHIP00000054', 'WH003', '62853 Joanna Branch
North Maryland, GA 15672', 'returned', '2026-02-03', '2026-02-07', NULL, 'DHL', '589513c9-8327-4fe5-9'),
('SHIP00000055', 'WH006', '62231 Jared Locks
New Brooke, FM 15433', 'lost', '2026-02-16', '2026-02-20', '2026-02-20', 'UPS', '2aeea801-79a9-4d02-b'),
('SHIP00000056', 'WH010', '16779 Rebecca Causeway Apt. 520
North Jimmyhaven, CO 96028', 'returned', '2026-02-17', '2026-02-22', '2026-02-22', 'DHL', '7b5a2502-a809-4e79-b'),
('SHIP00000057', 'WH003', '28374 Phillips Mountains
Wendyfort, AZ 90863', 'delivered', '2026-01-26', '2026-02-01', '2026-02-02', 'UPS', '2cd64f2a-3084-4a60-8'),
('SHIP00000058', 'WH008', '349 Amanda Drive Suite 910
Johnsonhaven, OR 71686', 'in_transit', '2026-02-16', '2026-02-17', '2026-02-16', 'DHL', 'ca2869ba-fe7e-46b2-b'),
('SHIP00000059', 'WH002', '121 Stephen Circle
Rileyview, PA 62076', 'returned', '2026-02-22', '2026-02-25', '2026-02-27', 'Amazon', '92618140-6d1c-4bc9-8'),
('SHIP00000060', 'WH005', '3192 Barrera Corners Suite 622
Meltonville, MI 34580', 'delivered', '2026-02-08', '2026-02-12', '2026-02-10', 'UPS', '2e20d6d6-f9ea-43d4-8'),
('SHIP00000061', 'WH005', '300 Kathryn Haven
Georgestad, NV 48141', 'in_transit', '2026-02-23', '2026-03-01', NULL, 'DHL', '1ca8d653-e028-4b58-8'),
('SHIP00000062', 'WH001', '29040 Jennifer Ports Apt. 061
Crawfordbury, AK 67469', 'returned', '2026-02-10', '2026-02-14', '2026-02-17', 'DHL', '397a1714-f5b0-48f1-9'),
('SHIP00000063', 'WH010', '709 Howard Crescent Apt. 999
Carolland, AR 98332', 'returned', '2026-02-10', '2026-02-13', '2026-02-12', 'Amazon', '54b1aa90-7392-4d0c-8'),
('SHIP00000064', 'WH006', '24966 Pruitt Forks Apt. 123
Lake Candiceside, NY 83177', 'in_transit', '2026-02-09', '2026-02-11', '2026-02-11', 'DHL', '0da96212-874f-4cc7-b'),
('SHIP00000065', 'WH007', '254 John Square Apt. 124
East Mark, SC 18568', 'returned', '2026-01-28', '2026-01-29', NULL, 'UPS', 'faab3e03-97f6-498a-8'),
('SHIP00000066', 'WH008', 'PSC 5530, Box 6189
APO AE 17844', 'delivered', '2026-02-05', '2026-02-09', '2026-02-08', 'FedEx', 'f8de9f90-f9a4-4957-8'),
('SHIP00000067', 'WH008', '8642 Kevin Loop Apt. 591
West Vickieside, SC 07391', 'delivered', '2026-02-24', '2026-03-03', '2026-03-04', 'DHL', '94aecfb3-7da2-4560-9'),
('SHIP00000068', 'WH007', '667 Derrick Mountain Apt. 198
Perezstad, DC 45607', 'returned', '2026-01-28', '2026-01-29', '2026-02-01', 'USPS', '2b78164e-5ca8-42d9-a'),
('SHIP00000069', 'WH003', '25907 Scott Shoal
South Bonnie, ME 55354', 'delivered', '2026-01-29', '2026-02-01', '2026-02-01', 'USPS', 'f0b74f9e-b977-4d05-9'),
('SHIP00000070', 'WH005', '049 Norma Plaza
East Brian, AR 23826', 'lost', '2026-02-18', '2026-02-22', NULL, 'USPS', 'c5b81533-fb0b-4275-a'),
('SHIP00000071', 'WH009', '1818 Lisa Plaza Suite 651
Pricechester, HI 85737', 'in_transit', '2026-02-06', '2026-02-07', '2026-02-08', 'FedEx', '0fbc921d-3cd1-4dbf-a'),
('SHIP00000072', 'WH007', '512 Kelly Oval
West Kristen, IA 18533', 'returned', '2026-02-07', '2026-02-12', '2026-02-14', 'USPS', '66bff6e4-c096-4df7-8'),
('SHIP00000073', 'WH001', '31206 Johnson Parkways Apt. 817
North Kevinberg, UT 38799', 'lost', '2026-01-28', '2026-02-04', NULL, 'USPS', '832e6776-1ca1-4251-b'),
('SHIP00000074', 'WH003', '0165 Chelsea Wells
Port Breannafort, IL 95946', 'pending', '2026-02-16', '2026-02-20', NULL, 'Amazon', '8bd87961-66f0-4a88-8'),
('SHIP00000075', 'WH009', '28040 Cook Park
Lindseyview, IA 30277', 'in_transit', '2026-02-21', '2026-02-23', '2026-02-21', 'USPS', '6889c145-e496-4bbe-b'),
('SHIP00000076', 'WH001', '300 Wilson Locks Apt. 572
Sawyerville, GA 88643', 'lost', '2026-02-14', '2026-02-21', '2026-02-23', 'DHL', 'a269962b-be4c-41c1-b'),
('SHIP00000077', 'WH001', '721 Meghan Trail
Vazquezville, VI 76650', 'lost', '2026-02-14', '2026-02-20', '2026-02-20', 'Amazon', '3cb0934b-ee28-4429-b'),
('SHIP00000078', 'WH007', '7983 Cheyenne Ports Suite 163
South Rebekah, NJ 83164', 'delivered', '2026-02-04', '2026-02-09', '2026-02-11', 'FedEx', '06efd3be-5eeb-4c7b-9'),
('SHIP00000079', 'WH008', '44193 Morrow Stravenue
Simmonsstad, PR 12513', 'delivered', '2026-02-20', '2026-02-26', '2026-03-01', 'Amazon', 'c67b9fa3-c4df-4e71-b'),
('SHIP00000080', 'WH002', '149 Mike Roads
North Bryan, NC 88489', 'lost', '2026-02-20', '2026-02-22', '2026-02-23', 'Amazon', 'fef2bc18-7726-44ab-9'),
('SHIP00000081', 'WH008', '88781 Colin Rapids
Lake Ruth, CO 93306', 'pending', '2026-01-29', '2026-01-31', NULL, 'DHL', 'd22df05f-227e-432d-b'),
('SHIP00000082', 'WH002', '83096 Graves Club Apt. 034
Michaelborough, SD 01059', 'lost', '2026-02-22', '2026-02-28', NULL, 'Amazon', 'fa71364f-94a0-430e-a'),
('SHIP00000083', 'WH001', '683 Martinez Island
Marcfort, ND 37889', 'delivered', '2026-02-09', '2026-02-10', '2026-02-08', 'UPS', '7e174547-9985-477c-9'),
('SHIP00000084', 'WH006', 'USNS Mahoney
FPO AE 65683', 'delivered', '2026-02-19', '2026-02-26', '2026-02-28', 'DHL', '7f50df61-da7c-424f-8'),
('SHIP00000085', 'WH004', 'USS Perez
FPO AA 81774', 'delivered', '2026-02-05', '2026-02-06', '2026-02-04', 'USPS', '491dac6a-1255-4467-8'),
('SHIP00000086', 'WH001', '2823 Hansen Haven Apt. 939
Kathleenville, AL 36437', 'returned', '2026-02-18', '2026-02-23', '2026-02-26', 'USPS', '3e3390e5-2f44-4de4-a'),
('SHIP00000087', 'WH007', '66153 Alexander Via
East Rebecca, TX 68475', 'pending', '2026-01-29', '2026-02-02', '2026-02-01', 'USPS', '423fbc1d-bf5d-4650-9'),
('SHIP00000088', 'WH010', '7255 Weber Underpass Apt. 941
Joneston, SC 44321', 'delivered', '2026-02-13', '2026-02-20', '2026-02-23', 'UPS', 'd118453c-e611-403a-a'),
('SHIP00000089', 'WH006', '085 Diaz Port Suite 618
New Vickichester, AS 09914', 'lost', '2026-01-26', '2026-01-28', NULL, 'UPS', '543388ea-f6fe-462d-9'),
('SHIP00000090', 'WH002', '2803 Adams Shore
West Helen, MP 45627', 'delivered', '2026-02-01', '2026-02-08', NULL, 'Amazon', 'e1ef6ef9-f2a3-4d04-a'),
('SHIP00000091', 'WH009', '8084 Adams Pass
Romanbury, IA 05944', 'in_transit', '2026-01-28', '2026-02-03', '2026-02-04', 'DHL', '0e5193c0-254a-4cb5-8'),
('SHIP00000092', 'WH006', '905 Chung Green
Nguyenmouth, MI 05447', 'in_transit', '2026-02-03', '2026-02-09', NULL, 'DHL', '31f75092-d96c-4c7d-a'),
('SHIP00000093', 'WH005', '6384 Peterson Trace Suite 272
New Amy, IL 40345', 'in_transit', '2026-02-05', '2026-02-12', '2026-02-12', 'DHL', '4d4edc38-2684-487f-9'),
('SHIP00000094', 'WH005', '424 Jason Station Apt. 176
New Rebeccaburgh, MS 04904', 'returned', '2026-02-17', '2026-02-18', NULL, 'Amazon', '77982a30-b788-4784-b'),
('SHIP00000095', 'WH007', '54025 Bryan Well Apt. 887
Ericberg, OK 75628', 'in_transit', '2026-02-17', '2026-02-24', '2026-02-23', 'USPS', '57f1395d-5b25-4089-a'),
('SHIP00000096', 'WH010', '80416 Hale Stream
Port Jacobview, NY 15425', 'lost', '2026-02-15', '2026-02-16', '2026-02-19', 'DHL', 'a7e1b9eb-61cd-42af-b'),
('SHIP00000097', 'WH003', '3667 Wilson Stream Suite 411
Carrieborough, PR 92623', 'delivered', '2026-02-18', '2026-02-21', '2026-02-20', 'DHL', '816e922d-7d45-46f3-9'),
('SHIP00000098', 'WH002', '171 Paula Ville Suite 641
Lake Michaelfurt, TN 74588', 'delivered', '2026-02-09', '2026-02-14', '2026-02-15', 'Amazon', 'd6427978-31bc-4faa-9'),
('SHIP00000099', 'WH007', '61216 Johnson Unions Suite 919
Smithside, PA 30117', 'delivered', '2026-02-12', '2026-02-14', NULL, 'FedEx', '9e5d5ba9-dac8-4117-a'),
('SHIP00000100', 'WH009', '8129 Hensley Dam Apt. 496
Port Julie, MI 92197', 'in_transit', '2026-02-09', '2026-02-12', '2026-02-12', 'FedEx', 'b95c0878-6153-4c03-8'),
('SHIP00000101', 'WH007', '0040 Cohen Crossroad
Pamelamouth, RI 18411', 'delivered', '2026-02-05', '2026-02-12', '2026-02-14', 'DHL', '6202f831-a667-4aba-b'),
('SHIP00000102', 'WH003', '08899 Brittany Canyon
Estradaview, PW 81286', 'delivered', '2026-02-14', '2026-02-19', '2026-02-19', 'UPS', '5fdfa45e-71ac-48cc-8'),
('SHIP00000103', 'WH005', '145 Vanessa Rapids Apt. 006
East William, ID 28753', 'delivered', '2026-02-18', '2026-02-19', NULL, 'FedEx', 'ed3e743e-d8b3-4726-b'),
('SHIP00000104', 'WH010', '871 Woods Route
Jamesfurt, AS 99901', 'lost', '2026-02-03', '2026-02-06', '2026-02-05', 'DHL', '7fa7b1cc-34c4-4874-8'),
('SHIP00000105', 'WH005', '782 Melton Extension
Davidborough, MI 16471', 'delivered', '2026-02-07', '2026-02-08', '2026-02-07', 'Amazon', '84419349-844b-4964-9'),
('SHIP00000106', 'WH003', '33961 Carl Mall
West Susan, AL 50974', 'lost', '2026-02-06', '2026-02-11', NULL, 'UPS', 'dfa2b697-dfe1-429c-9'),
('SHIP00000107', 'WH008', '46989 Brian Isle
Haileyview, IN 83151', 'returned', '2026-02-17', '2026-02-24', NULL, 'DHL', '25ae2748-05c9-4e89-b'),
('SHIP00000108', 'WH007', '7679 Hart Locks Apt. 673
Lake Anitashire, ID 68051', 'pending', '2026-01-28', '2026-01-29', '2026-01-27', 'FedEx', '7f5e6a91-0849-42e0-8'),
('SHIP00000109', 'WH010', '3929 Todd Spur
Donovanmouth, GU 76828', 'delivered', '2026-02-18', '2026-02-25', NULL, 'UPS', '68b6a588-1a6c-44dc-9'),
('SHIP00000110', 'WH005', '4540 Martin Creek Suite 157
Christianchester, ME 05621', 'lost', '2026-02-16', '2026-02-20', '2026-02-19', 'UPS', 'b947c75c-fbde-4991-a'),
('SHIP00000111', 'WH009', '8119 Miller Unions Suite 230
South Kelli, NJ 24183', 'pending', '2026-02-09', '2026-02-16', NULL, 'USPS', 'eb13d400-7ae9-4e00-a'),
('SHIP00000112', 'WH001', '5240 Maldonado Burg
Davidsonbury, MO 78053', 'pending', '2026-02-12', '2026-02-16', '2026-02-17', 'USPS', '526cdb79-0218-423a-8'),
('SHIP00000113', 'WH004', '681 Leslie Meadows Suite 632
Mendezville, CA 69103', 'lost', '2026-02-08', '2026-02-12', '2026-02-11', 'Amazon', 'ecce9732-3952-4348-8'),
('SHIP00000114', 'WH006', '9924 Zamora Garden
Silvaberg, VA 18513', 'delivered', '2026-01-26', '2026-01-31', NULL, 'USPS', '05938760-aa92-4924-8'),
('SHIP00000115', 'WH005', 'PSC 3745, Box 0718
APO AA 54945', 'pending', '2026-02-16', '2026-02-18', '2026-02-17', 'USPS', '25785838-4573-4e40-b'),
('SHIP00000116', 'WH010', 'USNV Cobb
FPO AA 10030', 'delivered', '2026-02-24', '2026-03-03', NULL, 'DHL', 'd8b533af-7c01-431d-a'),
('SHIP00000117', 'WH009', '92149 Timothy Inlet Suite 445
New Eric, AS 34655', 'pending', '2026-01-26', '2026-01-30', '2026-01-29', 'USPS', 'efcb39ba-cdd8-401c-9'),
('SHIP00000118', 'WH008', '5833 Jennifer Keys
Reynoldshaven, KY 47482', 'delivered', '2026-02-11', '2026-02-17', NULL, 'UPS', '183a1b5f-77d7-4145-a'),
('SHIP00000119', 'WH002', '552 Michael Fields
Turnerchester, AK 71479', 'lost', '2026-02-07', '2026-02-13', '2026-02-11', 'DHL', '2081f89a-8b16-4a5b-9'),
('SHIP00000120', 'WH009', '9678 Amy Avenue
New Lauren, ND 40132', 'returned', '2026-02-19', '2026-02-25', '2026-02-28', 'DHL', 'bcf62263-7b80-4a72-8'),
('SHIP00000121', 'WH006', '1495 Flores Lakes
Ericberg, AK 42127', 'delivered', '2026-02-09', '2026-02-14', '2026-02-14', 'Amazon', '0b094b72-76cc-43b1-b'),
('SHIP00000122', 'WH002', '21760 Shane Junctions Suite 034
Jesusport, MA 29864', 'in_transit', '2026-01-30', '2026-01-31', NULL, 'DHL', '8f89cca3-6559-4521-a'),
('SHIP00000123', 'WH004', '8811 Ashley Streets
West Sharon, FM 78448', 'delivered', '2026-02-12', '2026-02-15', NULL, 'FedEx', 'd6592ba2-94bb-4ce8-a'),
('SHIP00000124', 'WH007', '4891 Corey Island
New Cynthia, DC 55547', 'delivered', '2026-02-09', '2026-02-15', '2026-02-15', 'UPS', '9d4cf526-9062-4d50-9'),
('SHIP00000125', 'WH005', '16218 Erica Bridge
Ruizview, IL 51171', 'lost', '2026-02-06', '2026-02-13', '2026-02-16', 'Amazon', '4f947aff-c680-452c-b'),
('SHIP00000126', 'WH003', '887 Amy Ranch Suite 147
Candacefort, MA 01357', 'delivered', '2026-02-13', '2026-02-19', NULL, 'USPS', '1aed163d-fd73-4be6-b'),
('SHIP00000127', 'WH009', '632 Hays Plaza
East Kathymouth, IN 58626', 'pending', '2026-02-18', '2026-02-20', NULL, 'Amazon', '24dbe11d-64c0-48c0-b'),
('SHIP00000128', 'WH008', '0862 John Squares
North Kim, ME 19126', 'in_transit', '2026-02-15', '2026-02-17', '2026-02-16', 'USPS', '52cfef5f-9620-4ae0-a'),
('SHIP00000129', 'WH010', '82620 Mary Shores
West Kevin, MI 33617', 'pending', '2026-02-05', '2026-02-06', '2026-02-06', 'UPS', '409522a4-706c-4e33-b'),
('SHIP00000130', 'WH004', '864 Lori Landing Apt. 653
Rodriguezhaven, PA 22705', 'pending', '2026-02-16', '2026-02-21', NULL, 'UPS', '82e78084-157e-42c3-8'),
('SHIP00000131', 'WH001', '638 Matthew Squares Suite 568
East Carolyn, GA 64828', 'returned', '2026-02-18', '2026-02-21', '2026-02-20', 'DHL', 'fb214e51-8b3d-4e07-8'),
('SHIP00000132', 'WH009', '11233 West Spurs
Lake Briantown, HI 40612', 'lost', '2026-01-30', '2026-02-03', '2026-02-06', 'Amazon', '5925cba3-882c-42f1-9'),
('SHIP00000133', 'WH009', '9904 Amy Forges Apt. 446
Scottside, VA 46575', 'delivered', '2026-02-24', '2026-02-26', NULL, 'FedEx', '7c0fd7f3-bfe2-42e5-b'),
('SHIP00000134', 'WH007', '59415 Boyer Junction
Wintersport, AK 68043', 'returned', '2026-02-20', '2026-02-23', '2026-02-25', 'Amazon', 'c1a14506-ce22-4764-b'),
('SHIP00000135', 'WH010', '9959 Andrew Grove
Jonathonside, OR 55340', 'returned', '2026-02-11', '2026-02-18', '2026-02-19', 'UPS', 'd033ccd5-d887-42e6-a'),
('SHIP00000136', 'WH010', '2246 Ramirez Points
North Thomas, GA 89706', 'delivered', '2026-02-06', '2026-02-10', '2026-02-11', 'UPS', '468d92fe-87dd-4a52-9'),
('SHIP00000137', 'WH004', '37368 Jessica Tunnel
Collinsport, FL 17182', 'pending', '2026-02-11', '2026-02-14', '2026-02-17', 'DHL', '5b4f1956-a560-4f77-8'),
('SHIP00000138', 'WH007', '2422 Victoria Club Apt. 461
New Caitlin, VA 39965', 'delivered', '2026-02-17', '2026-02-24', '2026-02-24', 'USPS', 'd6c7e485-0d96-4ab8-b'),
('SHIP00000139', 'WH002', '07257 Lopez Light
North Cliffordshire, NC 48300', 'lost', '2026-02-18', '2026-02-25', NULL, 'FedEx', 'f0b4cf30-f651-4221-8'),
('SHIP00000140', 'WH004', '747 Christine Station Suite 455
Thomasmouth, IL 00513', 'delivered', '2026-02-01', '2026-02-02', '2026-01-31', 'UPS', 'cd5e0f85-9390-47fa-b'),
('SHIP00000141', 'WH005', '603 Garcia Highway Suite 786
Melissatown, PW 39369', 'lost', '2026-02-14', '2026-02-21', '2026-02-23', 'DHL', 'cb0e689b-74e2-4ac2-b'),
('SHIP00000142', 'WH004', '91519 Rachel Inlet
Christophertown, IN 28178', 'returned', '2026-02-14', '2026-02-20', NULL, 'FedEx', '8c0a3241-d54a-4092-9'),
('SHIP00000143', 'WH010', '112 Wright Mission
Port Jeffshire, WA 98402', 'pending', '2026-01-29', '2026-02-01', NULL, 'USPS', 'd2e03f68-8758-4529-a'),
('SHIP00000144', 'WH008', '921 Theresa Village
Anthonyton, IN 29039', 'delivered', '2026-02-08', '2026-02-13', '2026-02-11', 'USPS', 'f190872c-c361-44d1-a'),
('SHIP00000145', 'WH002', '6139 Heather Freeway
Cooperton, TX 86893', 'delivered', '2026-01-28', '2026-02-01', '2026-02-01', 'UPS', '7f1550c0-7333-4d73-a'),
('SHIP00000146', 'WH003', 'PSC 1797, Box 7050
APO AA 70067', 'pending', '2026-02-21', '2026-02-24', NULL, 'UPS', 'd8c5ce21-12a6-4484-b'),
('SHIP00000147', 'WH007', '000 Ayers Lodge Apt. 468
South Jeremymouth, TX 59465', 'in_transit', '2026-01-26', '2026-01-30', '2026-01-30', 'UPS', '93697cb3-a1ab-46f6-8'),
('SHIP00000148', 'WH009', '9229 Bartlett Plains Apt. 202
Ortizport, UT 22547', 'pending', '2026-01-28', '2026-02-01', '2026-01-30', 'USPS', 'bc0013a7-bc17-4a93-a'),
('SHIP00000149', 'WH004', '30932 Adams Forest
Port Gregorychester, IA 29092', 'pending', '2026-02-17', '2026-02-23', '2026-02-25', 'UPS', 'adc30e52-ea55-4866-a'),
('SHIP00000150', 'WH003', 'USNV Jones
FPO AA 71375', 'returned', '2026-02-15', '2026-02-19', NULL, 'DHL', '3648ee13-4fc0-45bf-8'),
('SHIP00000151', 'WH008', '573 Brooks Track
North Cynthia, ME 31737', 'in_transit', '2026-02-15', '2026-02-16', '2026-02-17', 'FedEx', 'b586812e-e8a4-487d-b'),
('SHIP00000152', 'WH001', '0071 Suzanne Station Suite 653
Martinezhaven, MD 22193', 'pending', '2026-01-26', '2026-02-02', '2026-02-03', 'Amazon', '8ea0aa64-74a3-49ce-b'),
('SHIP00000153', 'WH003', '56223 Daniel Bypass
South David, OH 21708', 'returned', '2026-02-11', '2026-02-13', NULL, 'UPS', '0c7e82d1-1aee-465a-b'),
('SHIP00000154', 'WH002', '8470 Davis Pike
East Joshuafort, SD 65771', 'lost', '2026-01-28', '2026-01-29', '2026-01-28', 'Amazon', '10e0970b-cf8e-4fea-a'),
('SHIP00000155', 'WH002', '3874 Hill Drives Suite 847
Brendaport, SC 54292', 'pending', '2026-02-21', '2026-02-27', '2026-03-01', 'FedEx', '60fad53e-d78f-432f-a'),
('SHIP00000156', 'WH003', '48173 Joseph Lane Suite 479
Tranview, MN 49321', 'delivered', '2026-02-18', '2026-02-24', '2026-02-23', 'Amazon', '53717882-6bbb-47eb-b'),
('SHIP00000157', 'WH001', '147 Charles Common
Prattstad, MN 01879', 'delivered', '2026-02-06', '2026-02-13', '2026-02-11', 'UPS', 'f943881d-15ee-4d92-9'),
('SHIP00000158', 'WH003', 'PSC 9501, Box 5956
APO AA 05488', 'delivered', '2026-02-06', '2026-02-13', NULL, 'USPS', '14675639-8f97-4678-a'),
('SHIP00000159', 'WH010', '50912 Long Divide
Johnfort, VA 89571', 'delivered', '2026-01-30', '2026-02-03', '2026-02-03', 'FedEx', '0397677a-2b77-4351-9'),
('SHIP00000160', 'WH002', '68137 Sanchez Divide Suite 740
Port James, AL 96300', 'lost', '2026-02-19', '2026-02-20', '2026-02-22', 'FedEx', '4ac0057e-b35a-4701-a'),
('SHIP00000161', 'WH009', '834 Samuel Land Suite 384
North David, SC 58020', 'delivered', '2026-01-31', '2026-02-04', '2026-02-06', 'DHL', 'cdb44654-6a60-452f-b'),
('SHIP00000162', 'WH001', '29406 Elliott Orchard
South Monicaborough, NH 90220', 'pending', '2026-02-08', '2026-02-12', NULL, 'DHL', 'e4ab4ce9-8fbc-4527-8'),
('SHIP00000163', 'WH001', '399 Cooper Coves Suite 983
Julieshire, CA 91471', 'returned', '2026-02-19', '2026-02-22', NULL, 'Amazon', '9939a9f7-7a00-44f7-b'),
('SHIP00000164', 'WH003', 'Unit 8761 Box 3217
DPO AA 80114', 'in_transit', '2026-02-01', '2026-02-07', '2026-02-07', 'UPS', '54c6c0d8-4e91-4d53-a'),
('SHIP00000165', 'WH003', '70250 Andrews Pass
North Williamland, UT 54629', 'pending', '2026-02-05', '2026-02-11', '2026-02-11', 'FedEx', '56938ac4-0f33-40fe-a'),
('SHIP00000166', 'WH010', '9909 Hanson Valleys
Rodriguezburgh, SC 39183', 'returned', '2026-01-27', '2026-02-01', '2026-02-01', 'UPS', 'f39c8235-211f-439e-9'),
('SHIP00000167', 'WH003', '97160 Mitchell Pines Suite 982
East Christopher, MH 10075', 'returned', '2026-02-22', '2026-02-28', '2026-02-28', 'USPS', '9db9eb48-bdb8-4d62-a'),
('SHIP00000168', 'WH003', '665 Walters Turnpike Suite 937
West Erin, AK 17612', 'delivered', '2026-02-16', '2026-02-21', '2026-02-24', 'UPS', 'cf17e7d2-921e-4d26-a'),
('SHIP00000169', 'WH001', 'PSC 1934, Box 2815
APO AE 87094', 'in_transit', '2026-01-26', '2026-01-29', '2026-01-28', 'DHL', '8e004a88-b289-400d-a'),
('SHIP00000170', 'WH010', 'USS Barnes
FPO AP 31200', 'delivered', '2026-02-07', '2026-02-09', '2026-02-08', 'FedEx', 'f1d89943-136a-452a-a'),
('SHIP00000171', 'WH002', 'USCGC Schwartz
FPO AP 92773', 'returned', '2026-02-12', '2026-02-18', '2026-02-21', 'DHL', 'f50d9efd-f443-4acd-8'),
('SHIP00000172', 'WH004', '154 Wilson River Suite 014
Gutierrezside, OR 56590', 'returned', '2026-02-15', '2026-02-20', '2026-02-18', 'USPS', '8b510c89-0254-4321-8'),
('SHIP00000173', 'WH008', '28593 David Junction Apt. 118
Port Davidfort, FM 78883', 'delivered', '2026-01-28', '2026-01-31', '2026-01-29', 'USPS', '2590bc9b-69b9-4e61-8'),
('SHIP00000174', 'WH002', '007 Miller Place Suite 223
Jenniferhaven, AR 74262', 'in_transit', '2026-02-24', '2026-03-03', NULL, 'DHL', '0b8d2fe6-3f18-4e6f-b'),
('SHIP00000175', 'WH002', '5422 Hester Course Apt. 463
Angelamouth, AK 88614', 'pending', '2026-01-28', '2026-01-31', NULL, 'UPS', 'ebe9d36d-bea8-4c60-8'),
('SHIP00000176', 'WH004', '36006 Bauer Junction Suite 378
North Karenside, IN 69403', 'lost', '2026-02-04', '2026-02-11', NULL, 'UPS', 'f63cb40f-c13c-43e2-8'),
('SHIP00000177', 'WH002', 'PSC 3806, Box 0879
APO AA 05335', 'returned', '2026-02-17', '2026-02-22', '2026-02-23', 'USPS', '7ed94ebe-514d-4f81-8'),
('SHIP00000178', 'WH010', '56765 Collin Lakes Apt. 053
Whitneyborough, OK 46389', 'in_transit', '2026-01-30', '2026-02-06', '2026-02-04', 'Amazon', 'ba483ef3-6656-4e03-8'),
('SHIP00000179', 'WH009', '203 Walton Passage Suite 463
Lake Jenniferside, AR 10948', 'returned', '2026-02-11', '2026-02-17', '2026-02-20', 'USPS', 'a0583ced-c56b-421d-9'),
('SHIP00000180', 'WH006', '6897 Francis Brooks Suite 967
Karenfurt, RI 64270', 'in_transit', '2026-02-05', '2026-02-07', '2026-02-10', 'USPS', '97271f30-f137-4f99-9'),
('SHIP00000181', 'WH004', '998 Steven Place
East Aprilport, MS 96886', 'lost', '2026-02-07', '2026-02-11', '2026-02-13', 'UPS', 'd2198583-1040-4fa7-8'),
('SHIP00000182', 'WH005', '455 Thomas Tunnel Suite 809
North Taylormouth, TN 31166', 'in_transit', '2026-02-08', '2026-02-11', '2026-02-10', 'USPS', '709e374c-8add-4fbf-a'),
('SHIP00000183', 'WH008', '199 Wang Isle
Meganfort, WI 86852', 'delivered', '2026-02-06', '2026-02-09', '2026-02-08', 'Amazon', 'a04334c1-6d42-4324-b'),
('SHIP00000184', 'WH007', '4896 Roberts Streets
Jamiemouth, AR 33690', 'in_transit', '2026-01-27', '2026-01-30', '2026-02-01', 'Amazon', '5b58f20b-8579-4da9-9'),
('SHIP00000185', 'WH005', '50478 David Run Apt. 627
North Jim, NV 27351', 'in_transit', '2026-01-28', '2026-02-02', '2026-02-03', 'USPS', '0ad0029b-eadd-4f2b-a'),
('SHIP00000186', 'WH005', '5985 Williams Garden Suite 129
Cartershire, MS 27760', 'delivered', '2026-02-18', '2026-02-23', '2026-02-22', 'DHL', '6ef070c4-6013-4a9c-9'),
('SHIP00000187', 'WH009', '928 Richard Well
South Michaelton, CT 41357', 'returned', '2026-02-15', '2026-02-21', '2026-02-23', 'Amazon', '9f2e8ea8-3db7-4a44-a'),
('SHIP00000188', 'WH001', '2956 Kenneth Mill
South Johnport, MS 03384', 'lost', '2026-02-16', '2026-02-19', '2026-02-18', 'DHL', '83f2aa2b-a826-4b9b-9'),
('SHIP00000189', 'WH004', '260 Christopher Loop
West Aaron, NY 75709', 'in_transit', '2026-01-28', '2026-01-30', '2026-01-29', 'FedEx', '1402c58d-a675-41b4-a'),
('SHIP00000190', 'WH002', '649 Jackson Junctions
Matthewmouth, VA 27282', 'returned', '2026-02-14', '2026-02-21', '2026-02-19', 'Amazon', '8575b6fc-d860-455b-a'),
('SHIP00000191', 'WH008', '29565 Scott River
South Jennifer, CA 73807', 'delivered', '2026-02-11', '2026-02-16', '2026-02-17', 'FedEx', 'b6fed074-8eb0-485f-a'),
('SHIP00000192', 'WH006', '92852 West Skyway
Ianstad, SC 50425', 'delivered', '2026-02-08', '2026-02-12', '2026-02-14', 'UPS', '09a4e50e-9ab3-4a35-b'),
('SHIP00000193', 'WH005', 'USNS Dominguez
FPO AA 81755', 'in_transit', '2026-02-18', '2026-02-24', '2026-02-23', 'DHL', '2243c0b4-4c7d-423b-8'),
('SHIP00000194', 'WH010', '5028 Matthews Manors
East Robert, ID 54636', 'in_transit', '2026-02-17', '2026-02-20', '2026-02-20', 'DHL', '844f2f3e-697c-4b76-b'),
('SHIP00000195', 'WH001', '154 Floyd Plain Suite 470
Port Melissa, OH 88691', 'pending', '2026-02-19', '2026-02-23', NULL, 'UPS', 'e95d001a-fc0a-4589-9'),
('SHIP00000196', 'WH008', '12320 Whitney Spring
South Amy, UT 08378', 'delivered', '2026-02-11', '2026-02-18', NULL, 'USPS', '60b294b9-a958-4b23-b'),
('SHIP00000197', 'WH002', '277 Tiffany Throughway
New Laura, RI 20937', 'in_transit', '2026-02-08', '2026-02-13', '2026-02-13', 'USPS', '309b29b1-bb62-46b6-8'),
('SHIP00000198', 'WH007', '8528 Taylor Parkways Suite 474
Mccannstad, VA 46924', 'pending', '2026-01-29', '2026-01-31', '2026-01-31', 'DHL', '949d502d-0d0a-42be-b'),
('SHIP00000199', 'WH005', '616 Smith Points Suite 696
West Roberthaven, AK 89389', 'lost', '2026-02-18', '2026-02-19', NULL, 'UPS', 'a906f6af-4dd0-4cad-a'),
('SHIP00000200', 'WH009', '831 Jason Crest
Williamshaven, KY 14488', 'pending', '2026-01-27', '2026-01-31', NULL, 'UPS', 'c04b4038-8fd5-45a1-a'),
('SHIP00000201', 'WH009', '9825 Osborn Lakes Suite 920
North Randy, VI 19409', 'returned', '2026-01-27', '2026-02-01', NULL, 'USPS', '7d758df9-6a67-4ee3-b'),
('SHIP00000202', 'WH002', '3491 Larry Heights
North Kellymouth, ME 59411', 'delivered', '2026-02-21', '2026-02-26', NULL, 'Amazon', 'dcf35b85-05d8-4c23-a'),
('SHIP00000203', 'WH009', '848 Jack Corner Suite 149
Port Andre, NE 33815', 'pending', '2026-02-22', '2026-02-28', NULL, 'DHL', '1996fb27-a564-47bf-8'),
('SHIP00000204', 'WH004', 'USS Taylor
FPO AE 81326', 'returned', '2026-02-10', '2026-02-15', '2026-02-14', 'DHL', 'd5172719-c5f6-4cc9-b'),
('SHIP00000205', 'WH010', '6935 Arthur Shores Apt. 321
West Julieville, RI 01076', 'pending', '2026-02-08', '2026-02-09', '2026-02-08', 'UPS', '05c84901-4dbb-401a-a'),
('SHIP00000206', 'WH001', 'USNV Smith
FPO AA 85446', 'returned', '2026-02-10', '2026-02-11', NULL, 'USPS', '785033fd-b85f-4d1c-a'),
('SHIP00000207', 'WH006', '70793 Margaret Plains
Taylormouth, TN 01806', 'pending', '2026-01-28', '2026-01-29', '2026-01-29', 'UPS', 'd7aab70e-2932-40a9-8'),
('SHIP00000208', 'WH009', '9448 Carlson Ports Apt. 573
West Amanda, ME 63356', 'in_transit', '2026-02-06', '2026-02-08', '2026-02-07', 'DHL', '5d6415b4-086e-4f58-9'),
('SHIP00000209', 'WH006', '84885 Schwartz Glen Suite 358
East Travis, IN 65403', 'delivered', '2026-01-28', '2026-02-01', '2026-02-03', 'FedEx', '4133754a-2732-4bdc-8'),
('SHIP00000210', 'WH003', 'Unit 3145 Box 8181
DPO AA 59949', 'in_transit', '2026-02-13', '2026-02-17', NULL, 'DHL', '5f48937f-ea81-4794-8'),
('SHIP00000211', 'WH008', '207 Joshua Inlet Apt. 645
Lisaview, CO 41524', 'pending', '2026-02-23', '2026-02-27', NULL, 'FedEx', '410bc693-b8e9-4e94-a'),
('SHIP00000212', 'WH009', '261 Underwood Station
Hollandbury, NV 86776', 'pending', '2026-02-09', '2026-02-15', '2026-02-18', 'FedEx', '4c8a4437-8440-4fe4-9'),
('SHIP00000213', 'WH007', '571 Sharon Locks Suite 640
North Kellyport, ME 71270', 'delivered', '2026-02-23', '2026-02-26', '2026-02-27', 'FedEx', 'f6a1f3c4-ab19-45b7-8'),
('SHIP00000214', 'WH008', '3157 Shawn Roads
South Mario, FM 13003', 'in_transit', '2026-02-05', '2026-02-10', '2026-02-12', 'USPS', '2a0c2626-dfbd-4c71-b'),
('SHIP00000215', 'WH003', 'PSC 1262, Box 0494
APO AE 17307', 'in_transit', '2026-01-28', '2026-02-02', NULL, 'FedEx', '07bf2c74-a589-438b-b'),
('SHIP00000216', 'WH008', '02740 Allison Ridge
Port Joseph, MP 05826', 'delivered', '2026-01-26', '2026-01-30', NULL, 'FedEx', 'e09481a7-0aca-458a-a'),
('SHIP00000217', 'WH009', '9484 Freeman Island Apt. 334
New Christopher, NH 73335', 'in_transit', '2026-02-04', '2026-02-05', '2026-02-05', 'USPS', '6a50905c-1a43-4f78-9'),
('SHIP00000218', 'WH003', '41150 Griffith Station
Jeffreyburgh, AK 22075', 'in_transit', '2026-02-20', '2026-02-22', '2026-02-23', 'FedEx', '01bf84ee-7fbc-4163-8'),
('SHIP00000219', 'WH006', '33906 Joseph Land
Jenniferburgh, HI 49177', 'lost', '2026-02-08', '2026-02-14', '2026-02-17', 'FedEx', '710d118e-eed8-4411-9'),
('SHIP00000220', 'WH006', '9440 John Locks Apt. 141
Lovemouth, GA 38238', 'lost', '2026-02-08', '2026-02-15', '2026-02-18', 'UPS', 'e31cfe96-0d63-443e-9'),
('SHIP00000221', 'WH009', '16466 Matthew Garden Apt. 014
Savannahborough, MI 15935', 'lost', '2026-02-20', '2026-02-22', '2026-02-24', 'FedEx', '3aa4163c-ca70-4b0f-8'),
('SHIP00000222', 'WH007', 'USNS Morrison
FPO AE 21869', 'delivered', '2026-02-24', '2026-03-02', NULL, 'UPS', '12c6c97f-a822-49fd-8'),
('SHIP00000223', 'WH002', '5117 Lopez Mews
East Rodney, VA 25916', 'pending', '2026-02-02', '2026-02-03', NULL, 'UPS', '22d96384-c973-424f-a'),
('SHIP00000224', 'WH006', '32250 Fisher Ridges Apt. 301
South Melissa, TX 90437', 'returned', '2026-02-20', '2026-02-26', NULL, 'FedEx', '784d4bd5-6a9d-4e3f-9'),
('SHIP00000225', 'WH004', '0341 Robinson Causeway Suite 001
Donaldtown, WV 58546', 'in_transit', '2026-02-08', '2026-02-14', '2026-02-13', 'Amazon', 'ca78e9e1-c635-4fb2-a'),
('SHIP00000226', 'WH010', '73491 Gilmore Park
Lake Andrewfurt, NC 87610', 'pending', '2026-02-20', '2026-02-25', '2026-02-28', 'USPS', '4e2efbda-2e52-4eb9-b'),
('SHIP00000227', 'WH009', '7361 Erin Oval
Davidport, ME 48610', 'pending', '2026-02-06', '2026-02-08', NULL, 'DHL', '070da424-8bac-4926-9'),
('SHIP00000228', 'WH004', 'Unit 3380 Box 2372
DPO AA 42736', 'lost', '2026-02-01', '2026-02-07', '2026-02-08', 'DHL', 'a4133f42-a763-4cdb-a'),
('SHIP00000229', 'WH005', '038 Johnson Station Apt. 818
Ingramton, CO 73445', 'returned', '2026-01-26', '2026-02-01', '2026-02-02', 'USPS', '5a950600-be0e-485a-8'),
('SHIP00000230', 'WH001', '37455 Vazquez Stravenue Apt. 159
New Ryanchester, IL 72503', 'pending', '2026-02-20', '2026-02-26', '2026-02-24', 'DHL', 'd2bd2eb5-50ad-42b5-b'),
('SHIP00000231', 'WH003', 'USNS Martinez
FPO AE 85021', 'lost', '2026-02-14', '2026-02-17', '2026-02-16', 'FedEx', 'e7b882f2-3d32-49f6-b'),
('SHIP00000232', 'WH007', '26596 Nicole Ports Apt. 568
Port Jenna, CT 72296', 'in_transit', '2026-02-23', '2026-02-24', '2026-02-22', 'DHL', '6fbcfd7e-02fb-48bc-8'),
('SHIP00000233', 'WH003', '563 Phillips Shoal
North Jeffrey, MO 85008', 'in_transit', '2026-01-27', '2026-01-30', '2026-01-31', 'Amazon', '4c0bd2be-e8dd-461c-b'),
('SHIP00000234', 'WH001', '0675 Ryan Turnpike
Haaston, UT 86645', 'delivered', '2026-02-18', '2026-02-23', '2026-02-24', 'FedEx', 'e9fc25aa-9f06-4060-9'),
('SHIP00000235', 'WH005', '12046 Harris Walk Apt. 376
New Jeffreymouth, MT 77665', 'lost', '2026-02-22', '2026-02-23', NULL, 'DHL', '1da78af6-1817-4b18-a'),
('SHIP00000236', 'WH002', '9882 Watts Spur Suite 808
Lake Roberthaven, FL 63160', 'in_transit', '2026-02-16', '2026-02-22', '2026-02-23', 'USPS', '275cd426-cb00-4c30-b'),
('SHIP00000237', 'WH003', 'PSC 6830, Box 3334
APO AP 54584', 'lost', '2026-02-22', '2026-02-25', NULL, 'UPS', '09135692-6e00-458a-a'),
('SHIP00000238', 'WH003', '6786 Nathan Run
Lake Kimberly, MS 98611', 'returned', '2026-02-04', '2026-02-05', '2026-02-06', 'UPS', '209c2381-8393-4fb1-a'),
('SHIP00000239', 'WH005', '85903 Leonard Greens Suite 798
East Richardberg, SC 76533', 'in_transit', '2026-02-03', '2026-02-06', '2026-02-06', 'UPS', '08ded183-a93f-4927-9'),
('SHIP00000240', 'WH004', '4086 Tara Mill
Port James, PA 69439', 'in_transit', '2026-02-04', '2026-02-11', NULL, 'UPS', '0f84f812-5966-4645-b'),
('SHIP00000241', 'WH001', '10516 Ramirez Port Apt. 245
Teresamouth, NY 02790', 'in_transit', '2026-02-04', '2026-02-07', '2026-02-10', 'DHL', 'd10efdaa-98b5-4162-9'),
('SHIP00000242', 'WH010', '619 Kelly Junctions
Margaretborough, DE 14072', 'pending', '2026-01-28', '2026-02-03', '2026-02-02', 'DHL', '21bbff14-c5e2-4eb0-9'),
('SHIP00000243', 'WH005', 'PSC 6343, Box 7714
APO AE 64336', 'returned', '2026-02-13', '2026-02-19', '2026-02-20', 'UPS', '09e7ee30-42d7-4a2e-a'),
('SHIP00000244', 'WH010', '38976 Amy Flats
Lake Natalie, NC 05435', 'pending', '2026-02-16', '2026-02-19', NULL, 'FedEx', 'a7a31324-2c9e-4f88-9'),
('SHIP00000245', 'WH008', '181 Wheeler Springs
Port Meganburgh, AZ 84518', 'in_transit', '2026-01-28', '2026-02-01', NULL, 'USPS', 'd92a4894-600e-41e0-9'),
('SHIP00000246', 'WH009', 'USNS Evans
FPO AA 89446', 'in_transit', '2026-01-28', '2026-02-01', NULL, 'Amazon', 'd9e1a0d6-24d2-4c16-a'),
('SHIP00000247', 'WH008', '92629 Hernandez Camp Apt. 258
Wilsonville, VA 78271', 'delivered', '2026-01-26', '2026-02-01', NULL, 'UPS', '69f45ff7-5dee-4d57-a'),
('SHIP00000248', 'WH008', '42409 Jason Throughway
Lake Barbara, WI 06885', 'delivered', '2026-02-15', '2026-02-22', '2026-02-24', 'UPS', 'bd0bb1c9-368e-4ff5-a'),
('SHIP00000249', 'WH008', '797 Andersen Port
Jasonberg, AS 19165', 'returned', '2026-02-17', '2026-02-19', '2026-02-17', 'DHL', '463492dd-7c1a-41cc-8'),
('SHIP00000250', 'WH005', '436 Nathaniel Row Apt. 586
West Terri, WY 41376', 'pending', '2026-02-18', '2026-02-23', '2026-02-22', 'DHL', 'b735c11a-7f41-4bd3-8'),
('SHIP00000251', 'WH006', '009 Dustin Ports
Conradstad, IA 03606', 'pending', '2026-02-09', '2026-02-11', '2026-02-11', 'Amazon', 'd9166a40-1a6c-4c57-8'),
('SHIP00000252', 'WH006', '87413 Soto Shoals Apt. 554
Lake Robert, MS 66336', 'delivered', '2026-02-20', '2026-02-23', NULL, 'UPS', '57448b0a-aa68-40d9-a'),
('SHIP00000253', 'WH007', '62679 Garcia Ville Apt. 649
East Sean, WA 64411', 'pending', '2026-02-07', '2026-02-11', NULL, 'DHL', 'd6c5e2db-0a59-4ab8-a'),
('SHIP00000254', 'WH005', '3691 Webster Groves
New Jeffreyborough, AS 88627', 'returned', '2026-02-02', '2026-02-09', NULL, 'DHL', '7dbacf12-5727-4835-a'),
('SHIP00000255', 'WH006', '73244 Kennedy Village Suite 504
South Ariana, IL 88235', 'lost', '2026-01-27', '2026-01-30', '2026-01-31', 'USPS', 'e6e0b14b-5b95-46ab-8'),
('SHIP00000256', 'WH006', 'Unit 4745 Box 4143
DPO AE 74890', 'pending', '2026-02-10', '2026-02-11', '2026-02-10', 'FedEx', 'fc1cc12b-8237-41ef-9'),
('SHIP00000257', 'WH009', '206 Bullock Drive
East Jenniferville, MO 21789', 'in_transit', '2026-02-02', '2026-02-04', NULL, 'FedEx', '47d8e32b-4e31-4765-a'),
('SHIP00000258', 'WH003', '286 Dwayne Shores
South Ashleestad, CT 34332', 'lost', '2026-02-11', '2026-02-18', '2026-02-16', 'DHL', '39f767bf-3b54-4dc8-9'),
('SHIP00000259', 'WH003', '004 Teresa Forks Apt. 811
South John, PW 54223', 'in_transit', '2026-01-26', '2026-02-02', NULL, 'Amazon', '065457cb-2698-403f-9'),
('SHIP00000260', 'WH010', '37283 Robert Square
New Lindachester, MN 56669', 'pending', '2026-02-22', '2026-02-28', NULL, 'UPS', '7d0bb10f-c3cf-425b-a'),
('SHIP00000261', 'WH005', '2693 Scott Ports Suite 715
New Susanport, VT 32062', 'returned', '2026-02-10', '2026-02-12', '2026-02-14', 'UPS', '4b23e08e-4224-4cca-9'),
('SHIP00000262', 'WH001', '8593 Barnes Hollow
Timothystad, HI 24620', 'lost', '2026-01-27', '2026-02-02', NULL, 'DHL', '2cd6a1d8-cc53-4690-a'),
('SHIP00000263', 'WH001', '29885 Timothy Court Apt. 571
Guzmanview, OK 31893', 'pending', '2026-01-27', '2026-02-02', NULL, 'DHL', 'df2f6fa9-5467-41d2-9'),
('SHIP00000264', 'WH001', '3397 Campbell Forest
Frostton, FL 36255', 'delivered', '2026-02-15', '2026-02-18', '2026-02-18', 'DHL', '626ab7a7-8b3a-4b96-b'),
('SHIP00000265', 'WH008', '0585 Laura Pine
Erichaven, VT 14280', 'returned', '2026-02-17', '2026-02-20', NULL, 'FedEx', 'ac7fac9e-3aa1-4c88-8'),
('SHIP00000266', 'WH003', '4366 Williams Divide Apt. 185
Meltonmouth, WI 59918', 'lost', '2026-02-17', '2026-02-24', NULL, 'DHL', '3635b33c-955f-42a1-a'),
('SHIP00000267', 'WH008', '218 Ward Club Apt. 071
New Coreystad, AZ 86719', 'delivered', '2026-01-30', '2026-02-05', '2026-02-05', 'USPS', '998f5594-94ba-4f1a-b'),
('SHIP00000268', 'WH004', '8119 Dwayne Lakes Apt. 991
Adamland, ID 30034', 'delivered', '2026-02-20', '2026-02-23', '2026-02-25', 'Amazon', '10ad4973-d69c-44f6-a'),
('SHIP00000269', 'WH004', '8682 Brown Pines
Nelsonmouth, VA 50122', 'lost', '2026-02-24', '2026-02-27', NULL, 'UPS', 'bb884bc1-48b3-4404-a'),
('SHIP00000270', 'WH007', '2932 Morrison Views Apt. 765
West Mariah, ME 13128', 'lost', '2026-01-31', '2026-02-02', NULL, 'DHL', '9a0d6e6a-18d9-4142-a'),
('SHIP00000271', 'WH007', '7283 Gregory Loop
Jasmineshire, HI 68179', 'returned', '2026-02-08', '2026-02-14', NULL, 'FedEx', '15173911-6d25-425e-b'),
('SHIP00000272', 'WH001', '13693 Cynthia Plains Apt. 982
Davidbury, PR 41634', 'pending', '2026-02-23', '2026-02-28', '2026-02-28', 'DHL', '3e9916e0-0385-4922-b'),
('SHIP00000273', 'WH004', '38811 Rebecca Stravenue Apt. 729
Myersberg, RI 20558', 'delivered', '2026-01-29', '2026-01-30', NULL, 'USPS', 'b252c88a-5fac-4d36-a'),
('SHIP00000274', 'WH003', '9595 Jones Stream
East Susan, PA 74714', 'pending', '2026-02-15', '2026-02-16', NULL, 'FedEx', '2fa3c391-bd7b-4653-9'),
('SHIP00000275', 'WH006', '39712 Sherry Mountain
Sanchezfort, CO 48991', 'in_transit', '2026-02-15', '2026-02-21', '2026-02-21', 'Amazon', 'aca04e01-7481-4b31-b'),
('SHIP00000276', 'WH009', '2051 Beck Estate
South Chelsea, MH 14005', 'returned', '2026-02-07', '2026-02-11', '2026-02-12', 'FedEx', '197bd4d5-7384-41df-8'),
('SHIP00000277', 'WH004', '1470 Hill Centers Suite 168
Rachelmouth, FM 36794', 'returned', '2026-02-19', '2026-02-24', '2026-02-22', 'USPS', '96ada3a4-ee14-43a6-b'),
('SHIP00000278', 'WH010', '1741 Brian Junctions
Jerryfort, IN 27634', 'pending', '2026-01-28', '2026-02-04', '2026-02-06', 'FedEx', '8b97d332-0e51-4785-9'),
('SHIP00000279', 'WH009', '347 Amber Vista
New Laura, MO 76165', 'delivered', '2026-01-29', '2026-02-02', '2026-02-04', 'DHL', 'd98827b4-0083-409d-a'),
('SHIP00000280', 'WH003', '0785 Jonathan Alley
Brownton, IN 06340', 'pending', '2026-02-06', '2026-02-09', '2026-02-11', 'UPS', '36b8456f-2223-47c4-9'),
('SHIP00000281', 'WH002', '261 Gonzales Lake
Danaville, NV 85261', 'lost', '2026-01-31', '2026-02-07', '2026-02-10', 'DHL', '7d6370f3-cbfc-48ed-a'),
('SHIP00000282', 'WH004', '67985 Mary Vista Suite 463
Lake Juan, TN 53258', 'lost', '2026-01-31', '2026-02-03', '2026-02-04', 'FedEx', '33d3bdf3-ce19-44d8-9'),
('SHIP00000283', 'WH010', '4213 Cannon Tunnel Apt. 343
North Paulshire, ME 64814', 'pending', '2026-02-16', '2026-02-17', '2026-02-20', 'Amazon', '9291a8ce-e882-4a50-8'),
('SHIP00000284', 'WH006', 'PSC 7442, Box 7184
APO AP 37032', 'in_transit', '2026-02-03', '2026-02-09', '2026-02-11', 'DHL', '5953a789-4d0a-4e3b-8'),
('SHIP00000285', 'WH006', '592 Cooley Place
Lake Christopherchester, OK 21967', 'pending', '2026-01-29', '2026-01-31', NULL, 'UPS', '7b90181f-268c-4732-b'),
('SHIP00000286', 'WH007', '36410 Tracy Divide
Williamsmouth, WI 48760', 'lost', '2026-02-02', '2026-02-07', NULL, 'UPS', '04e86aac-ede6-421e-a'),
('SHIP00000287', 'WH010', '79710 Pearson Harbor
Stewartstad, UT 72567', 'delivered', '2026-02-04', '2026-02-06', '2026-02-07', 'Amazon', 'b8647e1f-40cf-4096-9'),
('SHIP00000288', 'WH006', '181 James Stravenue Apt. 745
Williamtown, WA 93719', 'in_transit', '2026-02-14', '2026-02-15', '2026-02-13', 'DHL', 'a144359b-d4f1-4f44-b'),
('SHIP00000289', 'WH004', '77794 Jeffrey Summit
West Robertchester, NY 41314', 'delivered', '2026-02-05', '2026-02-08', '2026-02-08', 'UPS', '97b3beb2-fde7-479c-a'),
('SHIP00000290', 'WH007', '3835 Dana Villages
North Paulbury, CT 95130', 'delivered', '2026-01-29', '2026-02-04', '2026-02-04', 'FedEx', '1e834fe0-f9e4-4228-a'),
('SHIP00000291', 'WH004', '75817 Kristen Ridge Apt. 410
North Vanessa, FL 27411', 'returned', '2026-01-29', '2026-02-01', '2026-02-03', 'FedEx', '454401f5-6b7b-4a39-b'),
('SHIP00000292', 'WH005', '6429 Timothy Neck
Petersonborough, OR 36679', 'returned', '2026-02-18', '2026-02-19', '2026-02-22', 'DHL', '19c2142f-fec1-4a32-9'),
('SHIP00000293', 'WH009', '73790 Bryce Alley Suite 330
South Margaret, DE 56535', 'delivered', '2026-02-16', '2026-02-22', NULL, 'FedEx', 'd5747262-56b1-4e66-8'),
('SHIP00000294', 'WH001', '9719 Danielle Road
West Ruthborough, RI 22280', 'lost', '2026-02-01', '2026-02-02', '2026-02-02', 'Amazon', '44fac007-c55a-4577-b'),
('SHIP00000295', 'WH002', 'Unit 0374 Box 8295
DPO AA 54853', 'returned', '2026-02-02', '2026-02-09', NULL, 'Amazon', '4f2b7bbf-6aac-402d-8'),
('SHIP00000296', 'WH002', 'PSC 8004, Box 7296
APO AP 64238', 'pending', '2026-02-22', '2026-02-23', '2026-02-23', 'FedEx', '695d7494-02b3-41a0-8'),
('SHIP00000297', 'WH009', '5015 Crystal Burg Suite 403
Lake Brenda, MT 63727', 'pending', '2026-02-03', '2026-02-08', NULL, 'UPS', '2d710bf3-5826-408e-a'),
('SHIP00000298', 'WH009', '7997 Michael Club Apt. 762
Marioborough, SD 27905', 'delivered', '2026-02-23', '2026-02-26', NULL, 'FedEx', '8aa3e566-912e-4f5f-b'),
('SHIP00000299', 'WH002', '387 Nichols Ferry
Gregorychester, CA 69195', 'pending', '2026-02-23', '2026-03-02', '2026-03-04', 'USPS', '65ef9222-946c-47a8-8'),
('SHIP00000300', 'WH008', '03928 Andrew Crest Apt. 214
Port Michael, VT 14224', 'returned', '2026-02-12', '2026-02-16', '2026-02-18', 'UPS', '3eeb5196-c601-4968-8'),
('SHIP00000301', 'WH010', '07740 Rivas Corner
North Jennifer, SC 17522', 'returned', '2026-01-30', '2026-02-04', '2026-02-02', 'FedEx', 'f4d1d8ef-dbbc-48e4-8'),
('SHIP00000302', 'WH001', '10255 Simmons Fall
Hamiltonstad, KY 73058', 'lost', '2026-02-20', '2026-02-24', NULL, 'FedEx', 'e3d72d31-5df7-44e1-9'),
('SHIP00000303', 'WH007', 'USCGC Burton
FPO AA 52156', 'lost', '2026-01-30', '2026-02-01', '2026-02-01', 'UPS', '1a5cace4-b924-4919-8'),
('SHIP00000304', 'WH010', '2716 Moore Row Apt. 403
West Jacqueline, VT 37458', 'pending', '2026-02-12', '2026-02-14', NULL, 'USPS', '6219dc2d-940a-4206-9'),
('SHIP00000305', 'WH002', '63621 Cuevas Canyon
Harrishaven, KS 48860', 'in_transit', '2026-02-06', '2026-02-09', '2026-02-10', 'UPS', '1e3ffb2a-f3ad-49c7-9'),
('SHIP00000306', 'WH002', '26989 Cruz Stravenue Apt. 966
East Robert, ID 79540', 'returned', '2026-02-24', '2026-02-27', '2026-03-02', 'DHL', 'a1852e31-916a-4188-9'),
('SHIP00000307', 'WH006', '8272 Bobby Common
South Timothyshire, NH 47857', 'returned', '2026-01-26', '2026-02-01', '2026-02-03', 'UPS', '35d8cec5-e994-4ba3-9'),
('SHIP00000308', 'WH006', '1605 Ross Vista
Chenchester, MT 00844', 'in_transit', '2026-01-28', '2026-01-31', '2026-02-02', 'UPS', 'fe18029b-384b-4be4-a'),
('SHIP00000309', 'WH004', '642 Peggy Walks
New Edward, NM 54584', 'lost', '2026-02-19', '2026-02-21', '2026-02-21', 'UPS', '85113db6-7c47-4ad2-8'),
('SHIP00000310', 'WH010', '243 Miller Rest
Lake Dawnside, AZ 51498', 'in_transit', '2026-02-07', '2026-02-12', '2026-02-15', 'FedEx', '6e77551c-3bbd-450c-8'),
('SHIP00000311', 'WH004', '833 Michael Cove
Amyview, WI 65278', 'pending', '2026-02-21', '2026-02-23', NULL, 'FedEx', 'ab572992-b7aa-462e-8'),
('SHIP00000312', 'WH007', '7990 Phillip Oval
North Seanburgh, FL 65296', 'in_transit', '2026-02-08', '2026-02-12', '2026-02-14', 'UPS', 'ea229c7a-0c47-4f71-8'),
('SHIP00000313', 'WH009', '09792 Baker Ramp Apt. 442
Gibbsfort, CT 16787', 'returned', '2026-01-30', '2026-02-04', NULL, 'USPS', '5650a2d4-d3ad-445f-9'),
('SHIP00000314', 'WH010', 'USCGC Arroyo
FPO AP 12658', 'pending', '2026-02-07', '2026-02-08', '2026-02-07', 'FedEx', '0eca52c9-56ce-4555-9'),
('SHIP00000315', 'WH005', '78670 Antonio Tunnel
North Virginiaside, CO 82880', 'delivered', '2026-02-16', '2026-02-19', NULL, 'DHL', '030d3102-a92d-4b61-b'),
('SHIP00000316', 'WH004', '315 Kelly Field
Port Tamara, PW 77687', 'pending', '2026-02-11', '2026-02-12', '2026-02-15', 'USPS', '6b5e0b6d-18bb-42cd-9'),
('SHIP00000317', 'WH007', '525 Adam Glens
Lake Amanda, MD 57599', 'pending', '2026-01-26', '2026-01-28', '2026-01-26', 'Amazon', '0214a438-5acc-4f3c-8'),
('SHIP00000318', 'WH008', '5791 Walsh Meadow Apt. 515
North Raymond, VA 98220', 'lost', '2026-02-13', '2026-02-20', '2026-02-21', 'DHL', '808603f2-6eaf-4783-9'),
('SHIP00000319', 'WH004', '433 Morales Mission Suite 341
Lake Louishaven, AZ 19018', 'in_transit', '2026-02-06', '2026-02-10', '2026-02-08', 'DHL', 'a03ab33e-bcb1-4aa3-8'),
('SHIP00000320', 'WH005', '4261 James Hollow
New Kelly, WI 92327', 'lost', '2026-01-31', '2026-02-02', NULL, 'Amazon', 'de6c1a92-6fc4-44ca-b'),
('SHIP00000321', 'WH005', '35524 Lewis Landing Suite 370
North Stephanie, NY 19337', 'in_transit', '2026-02-14', '2026-02-21', '2026-02-19', 'USPS', 'c252ec2a-8251-4415-9'),
('SHIP00000322', 'WH002', '132 Vincent Heights
Port Devinberg, VA 18035', 'lost', '2026-02-14', '2026-02-15', '2026-02-14', 'USPS', '0a8f144f-146d-45c4-8'),
('SHIP00000323', 'WH009', '702 George Burg Suite 463
New Walter, AL 23343', 'delivered', '2026-01-26', '2026-01-27', '2026-01-25', 'DHL', '059bd051-7c9d-4539-8'),
('SHIP00000324', 'WH009', '152 Becker Heights
Port Tyler, AZ 22895', 'pending', '2026-02-15', '2026-02-22', '2026-02-22', 'Amazon', '66b4fbe7-649c-43f6-a'),
('SHIP00000325', 'WH001', '77917 Mccarthy Plaza Suite 921
East Norman, WV 23197', 'pending', '2026-02-11', '2026-02-15', '2026-02-18', 'FedEx', '382c5d35-49a5-4e1c-b'),
('SHIP00000326', 'WH009', '117 Megan Loop Suite 966
West Jason, NM 86327', 'delivered', '2026-02-18', '2026-02-25', NULL, 'UPS', '9bfbadd6-2fb8-4be3-8'),
('SHIP00000327', 'WH008', '520 Allen Cove Apt. 946
Ewingbury, ME 54631', 'pending', '2026-02-01', '2026-02-06', '2026-02-04', 'FedEx', '6cfbc88f-7443-4bae-b'),
('SHIP00000328', 'WH005', '777 Garrett Rapid
Zamorafurt, GA 65979', 'returned', '2026-01-26', '2026-01-30', NULL, 'DHL', '6f9664c7-0054-459a-8'),
('SHIP00000329', 'WH010', '33273 Mcdonald Neck Suite 534
Port Devinville, IL 77149', 'returned', '2026-01-30', '2026-02-01', NULL, 'USPS', 'ec7e27b6-9394-400a-9'),
('SHIP00000330', 'WH010', '90295 Mooney Glen Suite 005
Lake Alanchester, NJ 18942', 'delivered', '2026-01-28', '2026-02-01', '2026-02-01', 'FedEx', 'd68704ae-9e6d-4ba2-b'),
('SHIP00000331', 'WH001', '497 Wright Locks
North Kimberly, KS 51104', 'in_transit', '2026-02-13', '2026-02-18', '2026-02-19', 'Amazon', 'a11c1194-ff76-4fe1-b'),
('SHIP00000332', 'WH006', '474 Pham Loop
South Vanessa, UT 86082', 'lost', '2026-02-12', '2026-02-13', NULL, 'DHL', '68f1b9d2-1cea-409a-a'),
('SHIP00000333', 'WH002', '2177 Michael Shoal
South Sethmouth, MT 22885', 'pending', '2026-01-29', '2026-01-31', '2026-02-03', 'UPS', '4bf95970-b487-4fa4-9'),
('SHIP00000334', 'WH010', '4523 Erik Terrace Suite 652
West James, ND 45485', 'pending', '2026-02-15', '2026-02-18', NULL, 'FedEx', 'a7247b6b-53fa-4954-b'),
('SHIP00000335', 'WH010', '651 Matthew Rapids Apt. 961
South Melissafort, AS 61665', 'returned', '2026-01-31', '2026-02-07', '2026-02-05', 'DHL', '66cb3751-84c1-43b3-a'),
('SHIP00000336', 'WH007', '279 Ashley Grove
Lowechester, CA 74458', 'lost', '2026-01-26', '2026-01-31', '2026-01-29', 'USPS', 'e6a65a51-8ba1-450d-b'),
('SHIP00000337', 'WH001', '63101 Evans Well Suite 213
Port Kevin, MO 57843', 'delivered', '2026-02-20', '2026-02-27', '2026-02-27', 'FedEx', '022417d8-4cd7-49fc-9'),
('SHIP00000338', 'WH007', '151 Hill Terrace Suite 162
Jonesport, MH 86564', 'returned', '2026-02-14', '2026-02-20', '2026-02-19', 'DHL', '894e1364-99fe-4d7e-a'),
('SHIP00000339', 'WH001', '012 Johnson Forge Suite 676
Nicholasmouth, PW 78219', 'returned', '2026-02-16', '2026-02-23', '2026-02-23', 'DHL', 'a18b6030-24bf-4f89-b'),
('SHIP00000340', 'WH002', '32410 Adams Alley
Richside, WA 77361', 'in_transit', '2026-02-24', '2026-02-25', '2026-02-23', 'UPS', '0709d9ef-04a4-4091-9'),
('SHIP00000341', 'WH001', '451 Adams Plaza
Morrisville, WA 52212', 'returned', '2026-02-08', '2026-02-12', '2026-02-14', 'USPS', '3982cb6a-505e-4009-8'),
('SHIP00000342', 'WH010', '603 George Stream
Lake Brian, WA 74604', 'returned', '2026-02-11', '2026-02-14', '2026-02-14', 'Amazon', 'b8fe06df-d570-4a26-b'),
('SHIP00000343', 'WH003', '4535 Jonathan Hollow Apt. 108
South Alexander, KY 20115', 'delivered', '2026-02-19', '2026-02-23', '2026-02-21', 'UPS', '93fa89a4-112c-450e-b'),
('SHIP00000344', 'WH002', '04638 Brandon Lights
North Matthewton, OK 04056', 'delivered', '2026-01-29', '2026-02-02', '2026-01-31', 'FedEx', '83b40cfd-bd6e-45ee-9'),
('SHIP00000345', 'WH002', '49786 Steven Spur
Lake Jenniferview, NH 62817', 'pending', '2026-02-22', '2026-02-27', '2026-02-25', 'Amazon', 'c176f656-7ba0-4f98-b'),
('SHIP00000346', 'WH002', '410 James Groves
New Crystalport, NV 99548', 'delivered', '2026-02-04', '2026-02-11', NULL, 'USPS', '95e9355d-ea5b-4cf6-a'),
('SHIP00000347', 'WH008', '057 Joseph Inlet Suite 848
Lake Dianaland, RI 56500', 'lost', '2026-01-31', '2026-02-03', '2026-02-03', 'FedEx', '86a7cb45-f725-4ed3-b'),
('SHIP00000348', 'WH009', '86354 Jennings Neck
East Joshuaborough, NE 38067', 'lost', '2026-02-20', '2026-02-27', '2026-02-26', 'FedEx', 'f426fee6-eede-47de-8'),
('SHIP00000349', 'WH004', '847 Schmidt Locks Suite 181
Alexandrialand, NH 55529', 'in_transit', '2026-02-04', '2026-02-07', '2026-02-09', 'UPS', '5e8dbd66-6fd8-40bd-a'),
('SHIP00000350', 'WH005', '846 Amy Branch
South Thomasborough, AK 22861', 'in_transit', '2026-02-22', '2026-03-01', '2026-03-01', 'Amazon', 'aa74827f-1334-4cbb-a'),
('SHIP00000351', 'WH005', '59856 Heather Roads
Markview, NE 17451', 'returned', '2026-02-20', '2026-02-24', NULL, 'USPS', '27123de1-04bd-48b7-8'),
('SHIP00000352', 'WH008', '726 Kaylee Plaza
Port Juan, MA 49848', 'in_transit', '2026-02-07', '2026-02-10', NULL, 'DHL', '77e532fb-31de-4cc3-a'),
('SHIP00000353', 'WH003', 'Unit 6825 Box 3996
DPO AE 64033', 'returned', '2026-02-08', '2026-02-12', '2026-02-12', 'FedEx', 'd0e9f975-d1eb-4ebf-a'),
('SHIP00000354', 'WH009', '90613 Estrada Villages
North Michaelfort, MH 86961', 'returned', '2026-02-02', '2026-02-04', '2026-02-07', 'Amazon', 'b163240d-e814-483e-9'),
('SHIP00000355', 'WH010', 'USNS Travis
FPO AP 59572', 'in_transit', '2026-02-06', '2026-02-11', '2026-02-13', 'USPS', '39aa93c6-39a1-45d5-9'),
('SHIP00000356', 'WH001', '525 Marshall Passage
South Anna, FM 26074', 'pending', '2026-02-16', '2026-02-17', NULL, 'FedEx', '6c727e22-a7f6-4759-9'),
('SHIP00000357', 'WH009', '379 Gonzalez Drive
Willismouth, MH 02083', 'returned', '2026-02-12', '2026-02-19', '2026-02-20', 'Amazon', '7ee6dc7f-25d9-411c-9'),
('SHIP00000358', 'WH006', '58912 Marc Rest Apt. 527
Smithborough, LA 39981', 'lost', '2026-01-27', '2026-01-30', '2026-02-02', 'USPS', '7c5e9889-fccf-439e-9'),
('SHIP00000359', 'WH006', '414 Morris Land Suite 390
North Richardmouth, WV 27526', 'lost', '2026-02-18', '2026-02-25', '2026-02-28', 'DHL', 'a696c5ad-e539-4224-b'),
('SHIP00000360', 'WH005', '89951 Angela Pines
Jacobsonview, NY 04966', 'returned', '2026-02-22', '2026-02-28', '2026-02-28', 'Amazon', 'f50c3251-ebdc-4d6d-b'),
('SHIP00000361', 'WH005', '95122 Bender Estate Apt. 317
Dudleyfurt, WA 77351', 'pending', '2026-02-15', '2026-02-16', NULL, 'UPS', '4ac52c1f-be02-45d4-b'),
('SHIP00000362', 'WH004', '93337 Nelson Views
New Amberside, LA 28110', 'returned', '2026-02-07', '2026-02-14', '2026-02-14', 'DHL', '8a32ea63-260d-4a9e-8'),
('SHIP00000363', 'WH006', '2259 Mike Parks Apt. 810
Port Amanda, PW 95813', 'returned', '2026-02-15', '2026-02-18', '2026-02-18', 'DHL', '8900078c-458b-4c29-9'),
('SHIP00000364', 'WH009', '0855 Courtney Corner Apt. 912
East Carolyn, NY 07770', 'lost', '2026-02-13', '2026-02-20', '2026-02-19', 'DHL', '9108d671-22f3-48df-b'),
('SHIP00000365', 'WH004', '9535 Kayla Light
Duranland, PW 58824', 'lost', '2026-02-13', '2026-02-19', '2026-02-17', 'DHL', 'dda2a481-5780-4a78-9'),
('SHIP00000366', 'WH004', '6795 Smith Via
Port Donaldhaven, TX 88853', 'lost', '2026-02-04', '2026-02-05', NULL, 'DHL', '54d62a91-3947-46e0-b'),
('SHIP00000367', 'WH009', '805 Paula Viaduct Apt. 618
Carlaview, PW 35517', 'returned', '2026-02-10', '2026-02-14', NULL, 'Amazon', 'd728d08a-44aa-4488-9'),
('SHIP00000368', 'WH007', '0433 Serrano Vista Apt. 770
Melissafurt, ND 65849', 'lost', '2026-02-07', '2026-02-10', NULL, 'Amazon', 'a0c367ac-a316-4bfa-8'),
('SHIP00000369', 'WH001', '947 Waller Vista Suite 863
South Alan, HI 79817', 'lost', '2026-02-09', '2026-02-13', '2026-02-16', 'FedEx', '72cbed73-df11-44c9-8'),
('SHIP00000370', 'WH003', '098 Anthony Via
West John, IL 67711', 'in_transit', '2026-02-02', '2026-02-03', '2026-02-01', 'UPS', '7880423e-987d-42e9-a'),
('SHIP00000371', 'WH003', '0803 Jack Villages
South Angela, MI 68052', 'returned', '2026-02-13', '2026-02-18', NULL, 'UPS', 'd9cee974-7a45-48fc-9'),
('SHIP00000372', 'WH010', '2061 Moore Village Apt. 146
Lake Alecborough, RI 56732', 'lost', '2026-02-10', '2026-02-12', '2026-02-11', 'Amazon', '09cb4952-ef1d-4e3e-9'),
('SHIP00000373', 'WH003', '53023 Brandon Spur
Lauraport, CT 27583', 'lost', '2026-02-20', '2026-02-23', NULL, 'USPS', 'bf27ca74-b143-4a77-b'),
('SHIP00000374', 'WH002', '47658 Freeman Mountain
East Dustin, NC 47466', 'returned', '2026-02-23', '2026-02-28', '2026-02-26', 'UPS', 'dcf819dc-c1b9-4855-9'),
('SHIP00000375', 'WH004', '566 Shaw Crossing
South Joseph, MI 59545', 'returned', '2026-02-14', '2026-02-21', NULL, 'UPS', '3aa2b9b2-453c-4bcd-9'),
('SHIP00000376', 'WH004', '1113 Lawrence Station
Craigstad, NV 29668', 'delivered', '2026-02-06', '2026-02-07', NULL, 'DHL', '365ca874-da94-45f4-9'),
('SHIP00000377', 'WH008', '255 Kimberly Village
Parsonsside, NC 54839', 'returned', '2026-01-27', '2026-02-01', NULL, 'FedEx', 'c077f5fd-9d11-44be-a'),
('SHIP00000378', 'WH005', '7370 Maynard Harbors
East Jimmy, MS 62212', 'lost', '2026-02-10', '2026-02-16', '2026-02-16', 'FedEx', '7abad339-2d18-45a8-9'),
('SHIP00000379', 'WH003', '65205 Michael Stream
New Jeremy, GU 74152', 'returned', '2026-01-26', '2026-01-31', '2026-01-31', 'FedEx', '72251dd0-f9ff-4cf6-a'),
('SHIP00000380', 'WH005', '261 Nicholas Key
South David, PW 55781', 'in_transit', '2026-01-30', '2026-02-02', '2026-02-01', 'DHL', '3487a4f5-cb28-48d7-a'),
('SHIP00000381', 'WH001', '326 Anthony Stream Suite 946
Charleneview, NY 76250', 'pending', '2026-02-13', '2026-02-15', '2026-02-16', 'UPS', 'b59f74a8-badb-4d79-a'),
('SHIP00000382', 'WH002', 'USNS Adams
FPO AA 88938', 'delivered', '2026-02-17', '2026-02-19', '2026-02-20', 'FedEx', '1e81aac2-f22b-4510-b'),
('SHIP00000383', 'WH007', '77989 Matthew Lock
Lake Mariahburgh, VA 44476', 'pending', '2026-02-20', '2026-02-27', '2026-03-02', 'USPS', 'ee9c54fb-fae3-45db-9'),
('SHIP00000384', 'WH003', '35235 Clark Manors Apt. 945
Lake Christinetown, ME 69954', 'returned', '2026-02-13', '2026-02-14', NULL, 'FedEx', 'f8b432d3-fc30-4c3b-9'),
('SHIP00000385', 'WH007', '29249 Little Roads
New Matthewhaven, AZ 50479', 'in_transit', '2026-02-09', '2026-02-15', '2026-02-14', 'USPS', 'f0b0968e-ac83-48ad-8'),
('SHIP00000386', 'WH006', '2867 Freeman Glen Suite 210
West Nicholaston, VA 76427', 'pending', '2026-02-07', '2026-02-13', NULL, 'Amazon', 'cb710647-76d6-449b-a'),
('SHIP00000387', 'WH006', '02738 Lowe Square Suite 970
East Tiffanyside, CA 46969', 'returned', '2026-02-13', '2026-02-14', '2026-02-17', 'DHL', '29c6eae2-4e88-40af-8'),
('SHIP00000388', 'WH003', 'PSC 6048, Box 8621
APO AA 51031', 'delivered', '2026-02-10', '2026-02-14', '2026-02-13', 'DHL', '39ab0bb5-8876-40f6-9'),
('SHIP00000389', 'WH009', '9217 Jesus Forest
Warrenstad, IN 31823', 'pending', '2026-02-18', '2026-02-22', NULL, 'UPS', '7d8da65e-80cf-430e-a'),
('SHIP00000390', 'WH009', '25039 Parrish Gateway
Thomasfort, UT 06938', 'lost', '2026-02-05', '2026-02-09', '2026-02-10', 'USPS', '9a1e6076-5c9d-4a4b-b'),
('SHIP00000391', 'WH008', '1159 Craig Fields Apt. 726
Lake Tanner, OH 51718', 'returned', '2026-01-30', '2026-02-06', '2026-02-05', 'FedEx', 'b1db3f7e-4baa-474f-a'),
('SHIP00000392', 'WH009', 'USNS Bowers
FPO AA 27039', 'pending', '2026-01-27', '2026-01-31', '2026-01-30', 'DHL', 'd1af7f62-4fe7-4b65-8'),
('SHIP00000393', 'WH008', '547 Johnson Plaza Suite 963
Jamesstad, MT 93945', 'delivered', '2026-02-05', '2026-02-07', '2026-02-08', 'Amazon', 'a784078c-5615-4944-9'),
('SHIP00000394', 'WH006', '4354 Kidd Roads
Richardsshire, CA 01430', 'in_transit', '2026-02-22', '2026-02-24', '2026-02-24', 'USPS', '9b03c7dc-00a6-457a-8'),
('SHIP00000395', 'WH008', '4322 Spencer Crossroad
Andreshire, WA 00910', 'returned', '2026-02-24', '2026-03-03', NULL, 'FedEx', 'eb90b021-ac3a-4d75-a'),
('SHIP00000396', 'WH005', '89785 Moore Isle
Lisamouth, MS 41619', 'pending', '2026-02-24', '2026-03-03', NULL, 'DHL', '0a3636a1-62e8-4e0d-8'),
('SHIP00000397', 'WH001', '869 Foley Plains Apt. 740
Conleyfort, WY 38442', 'pending', '2026-02-06', '2026-02-08', '2026-02-10', 'USPS', 'd43be736-f958-4c8c-8'),
('SHIP00000398', 'WH008', '7590 Jared Viaduct
South Christine, IA 21100', 'in_transit', '2026-02-12', '2026-02-18', NULL, 'UPS', '889fc8f7-0f13-4a40-b'),
('SHIP00000399', 'WH008', '76239 Davis Run Suite 906
Evansland, IA 04893', 'lost', '2026-02-21', '2026-02-22', NULL, 'DHL', '2553d970-6c0b-4f3d-b'),
('SHIP00000400', 'WH003', '822 Tyler Flats Apt. 224
Peterfort, MN 59291', 'delivered', '2026-02-18', '2026-02-23', '2026-02-23', 'USPS', '127a1550-301b-403e-a'),
('SHIP00000401', 'WH007', '13409 Alvarez Motorway
Karenburgh, MA 14513', 'pending', '2026-01-30', '2026-02-04', NULL, 'Amazon', '382ebc08-4afd-42e1-a'),
('SHIP00000402', 'WH005', '745 Castillo Coves Apt. 624
Garciaborough, PR 18224', 'returned', '2026-01-30', '2026-01-31', '2026-02-03', 'Amazon', '3e0d10a7-6715-4df8-8'),
('SHIP00000403', 'WH005', '2372 Wong Squares
East Marvintown, FL 16897', 'pending', '2026-01-27', '2026-02-03', NULL, 'USPS', '12247460-6f65-4207-b'),
('SHIP00000404', 'WH008', '2620 Smith Forest
South Samantha, LA 95863', 'pending', '2026-02-24', '2026-03-03', NULL, 'Amazon', 'f5839e4b-54cf-40b9-8'),
('SHIP00000405', 'WH002', '5026 Jerry Roads
West Johnnymouth, OH 77315', 'pending', '2026-02-07', '2026-02-11', '2026-02-14', 'FedEx', '8b0a1d86-2f54-42a7-8'),
('SHIP00000406', 'WH006', '2344 Alexander River
Port Tom, OK 98840', 'lost', '2026-02-24', '2026-03-01', '2026-02-27', 'DHL', 'a0750bf1-bed2-472b-9'),
('SHIP00000407', 'WH003', '25277 Chad Pine
Josephview, NE 39977', 'returned', '2026-01-28', '2026-02-03', '2026-02-01', 'USPS', '332e5ec2-22d7-491a-8'),
('SHIP00000408', 'WH010', '9371 Gary Port
Micheleville, WV 42599', 'returned', '2026-02-05', '2026-02-07', NULL, 'DHL', 'a5a4a6c6-799e-4469-9'),
('SHIP00000409', 'WH002', '15942 Christopher Estate Suite 284
Romeroland, FM 22416', 'returned', '2026-01-31', '2026-02-03', '2026-02-03', 'FedEx', 'b21b58b2-2345-4a9b-9'),
('SHIP00000410', 'WH010', '85690 Smith Underpass Apt. 040
Kevinfort, PW 23134', 'lost', '2026-02-16', '2026-02-18', '2026-02-20', 'FedEx', 'ddb8e4d1-7b0a-43f3-9'),
('SHIP00000411', 'WH010', '05970 Justin Crescent
West Markfort, NJ 84368', 'pending', '2026-01-29', '2026-01-31', '2026-01-31', 'Amazon', 'de41c8e6-479e-48ad-b'),
('SHIP00000412', 'WH001', '0019 Reginald Falls Suite 445
New Scottton, NE 71833', 'in_transit', '2026-02-18', '2026-02-19', NULL, 'FedEx', '8f0ad357-d8e3-401c-a'),
('SHIP00000413', 'WH008', '084 Brett Drive
Port Laura, DC 12982', 'returned', '2026-02-02', '2026-02-05', '2026-02-05', 'DHL', '742c69f2-59c2-4c4c-b'),
('SHIP00000414', 'WH004', '1035 Christina Center Apt. 369
Kimberlyfort, GU 40143', 'lost', '2026-01-26', '2026-01-29', '2026-02-01', 'FedEx', '24e6a85d-8e9a-41b4-a'),
('SHIP00000415', 'WH004', '8666 Donna Island
New Sandratown, VT 72703', 'returned', '2026-01-29', '2026-01-30', NULL, 'UPS', '76ac1fd4-650f-4673-8'),
('SHIP00000416', 'WH010', '5110 Jacob Inlet
Shannonfort, AZ 64954', 'in_transit', '2026-02-05', '2026-02-12', '2026-02-10', 'DHL', '5da6481e-9349-4c6f-9'),
('SHIP00000417', 'WH007', '864 Chelsea Turnpike
Jasminberg, TX 86364', 'returned', '2026-02-22', '2026-02-23', '2026-02-21', 'DHL', '9a5f6009-6529-4443-a'),
('SHIP00000418', 'WH010', '81171 Jeffrey Corners
Cynthiaberg, PR 25335', 'lost', '2026-01-26', '2026-01-27', '2026-01-29', 'Amazon', '97fba9ca-40b3-4b10-8'),
('SHIP00000419', 'WH004', '03799 Paige Springs
Joseborough, OK 33494', 'returned', '2026-02-06', '2026-02-10', NULL, 'FedEx', 'd1af30f0-7d6e-4f17-a'),
('SHIP00000420', 'WH007', 'PSC 1910, Box 3544
APO AP 02181', 'delivered', '2026-02-15', '2026-02-16', '2026-02-19', 'DHL', 'c710a873-7e7e-4986-b'),
('SHIP00000421', 'WH001', '9506 White Stravenue Apt. 581
Freemanton, MN 97296', 'returned', '2026-02-20', '2026-02-26', '2026-02-26', 'USPS', '78708d90-9df8-431f-8'),
('SHIP00000422', 'WH010', '7989 David View Suite 990
Josephburgh, MS 36713', 'pending', '2026-02-12', '2026-02-18', NULL, 'FedEx', '82ebaac4-da84-418a-9'),
('SHIP00000423', 'WH003', '62006 Donald Garden Suite 747
Lake Lawrenceville, HI 21848', 'lost', '2026-02-23', '2026-03-02', NULL, 'Amazon', 'd7c71745-1518-4633-b'),
('SHIP00000424', 'WH004', '36755 Mack Squares
Port Thomas, PW 14568', 'in_transit', '2026-02-23', '2026-02-24', '2026-02-22', 'USPS', '4c269310-91c8-4e0e-b'),
('SHIP00000425', 'WH002', '636 Pearson Landing
Lake Kellyhaven, ID 47193', 'returned', '2026-02-20', '2026-02-24', NULL, 'DHL', 'cbff9635-3275-4f4e-a'),
('SHIP00000426', 'WH005', 'PSC 2568, Box 8217
APO AP 97061', 'returned', '2026-01-30', '2026-01-31', NULL, 'DHL', 'dc27f92a-ed37-4652-9'),
('SHIP00000427', 'WH010', '08529 Cochran Vista Suite 382
Mejiaville, MA 91012', 'returned', '2026-01-28', '2026-02-03', NULL, 'USPS', '513984ed-1938-4acd-a'),
('SHIP00000428', 'WH002', '115 David Village Apt. 369
Lake Amanda, NY 27721', 'delivered', '2026-01-28', '2026-02-04', '2026-02-03', 'UPS', 'adadd3bf-df94-4900-9'),
('SHIP00000429', 'WH008', '114 Williams Prairie
Ryanhaven, HI 10365', 'pending', '2026-02-21', '2026-02-27', '2026-03-02', 'Amazon', '3dbc982c-139e-4c6e-9'),
('SHIP00000430', 'WH002', '637 Marisa Cliff Apt. 173
New Deborahshire, TX 89196', 'pending', '2026-02-23', '2026-03-01', NULL, 'FedEx', '9f373bfa-5c82-42f3-9'),
('SHIP00000431', 'WH004', '38749 Joanna Walks
North Davidville, AS 86713', 'pending', '2026-02-18', '2026-02-23', '2026-02-24', 'DHL', '7a40fe25-0a69-4c12-8'),
('SHIP00000432', 'WH006', '20829 Long Pines Suite 977
Maryburgh, CA 25665', 'delivered', '2026-02-05', '2026-02-07', NULL, 'Amazon', 'a1c6a0d1-5f37-448b-9'),
('SHIP00000433', 'WH008', '6415 Patricia Vista
Matthewview, PW 98980', 'pending', '2026-02-20', '2026-02-21', NULL, 'DHL', '75538f5d-7204-4684-b'),
('SHIP00000434', 'WH003', '711 Watson Cape
Wallaceburgh, MA 30841', 'lost', '2026-02-23', '2026-02-28', NULL, 'Amazon', 'd842909c-c9b5-4e9f-a'),
('SHIP00000435', 'WH006', '9995 Joshua Branch Apt. 374
Alvarezmouth, PA 76541', 'in_transit', '2026-02-19', '2026-02-21', NULL, 'DHL', '9d189150-de95-4e9f-a'),
('SHIP00000436', 'WH006', '682 Joshua Prairie
Grahamport, VA 53113', 'returned', '2026-02-03', '2026-02-09', '2026-02-08', 'FedEx', 'c96860a1-6095-4b4b-b'),
('SHIP00000437', 'WH008', '53805 York Coves
New Kendraview, OK 66527', 'delivered', '2026-02-10', '2026-02-15', '2026-02-16', 'DHL', 'd087047c-4eae-4ea3-9'),
('SHIP00000438', 'WH009', '9862 White Mills
Port Jasmine, GU 36074', 'in_transit', '2026-02-01', '2026-02-07', NULL, 'USPS', '574fc81f-5926-4048-8'),
('SHIP00000439', 'WH006', '127 Steven Walk
Brentmouth, VT 14294', 'in_transit', '2026-02-20', '2026-02-22', NULL, 'UPS', '83b0288d-d3b7-46bb-b'),
('SHIP00000440', 'WH007', '131 Watson Shore Apt. 221
Teresahaven, CT 91273', 'returned', '2026-02-03', '2026-02-09', '2026-02-10', 'Amazon', '1319f65b-3143-420d-9'),
('SHIP00000441', 'WH002', '902 Rodriguez Keys Apt. 992
Maryberg, SD 42767', 'returned', '2026-01-26', '2026-01-29', '2026-01-28', 'DHL', '51a40a55-14ce-481a-9'),
('SHIP00000442', 'WH010', '875 Henry Squares Suite 989
West Thomasland, MD 28570', 'returned', '2026-01-31', '2026-02-04', NULL, 'UPS', '8c243715-0952-4a24-b'),
('SHIP00000443', 'WH007', 'Unit 3576 Box 0893
DPO AP 18806', 'delivered', '2026-02-04', '2026-02-07', '2026-02-08', 'DHL', 'a4dd17b8-2637-47d2-b'),
('SHIP00000444', 'WH005', '7573 Catherine Circles
Lake Samuel, MS 11409', 'delivered', '2026-02-10', '2026-02-11', NULL, 'UPS', '2081ee3a-dea3-48c2-b'),
('SHIP00000445', 'WH009', '3584 Lutz Viaduct
Port Christopherberg, NV 93556', 'lost', '2026-02-23', '2026-03-02', '2026-03-05', 'DHL', '1acf800d-c3d7-4d80-a'),
('SHIP00000446', 'WH006', '45938 Marissa Throughway
North Nicole, AK 62639', 'pending', '2026-02-15', '2026-02-21', '2026-02-22', 'UPS', 'eb82583f-f24b-4035-b'),
('SHIP00000447', 'WH005', '310 Nicholas Mall
Normanport, VI 98098', 'returned', '2026-02-14', '2026-02-21', '2026-02-24', 'UPS', '4f6589bc-afc8-4e52-b'),
('SHIP00000448', 'WH001', '81663 Bell Islands
North Kelli, WV 54904', 'returned', '2026-02-24', '2026-03-03', '2026-03-04', 'FedEx', 'aa1cf6a3-6a0f-4a68-8'),
('SHIP00000449', 'WH010', '06376 Wright Park Apt. 493
Carlton, DE 88905', 'pending', '2026-02-14', '2026-02-17', '2026-02-16', 'USPS', 'cd8a2203-3f3e-432f-b'),
('SHIP00000450', 'WH003', '340 Penny Cape
North Robert, KS 24148', 'pending', '2026-02-16', '2026-02-21', '2026-02-20', 'DHL', '86a4b84b-d5c4-48a4-b'),
('SHIP00000451', 'WH005', '5015 Smith Island Apt. 343
Mooneymouth, CA 18771', 'in_transit', '2026-01-30', '2026-02-01', '2026-02-02', 'Amazon', '7dd71e3a-4247-4f4a-9'),
('SHIP00000452', 'WH007', '179 Erika Roads
North Laurie, TX 44998', 'in_transit', '2026-01-27', '2026-02-03', '2026-02-04', 'FedEx', '814f2dcc-46fe-4a55-8'),
('SHIP00000453', 'WH004', '9125 Jessica Highway
Codymouth, MD 65141', 'in_transit', '2026-02-12', '2026-02-16', '2026-02-19', 'UPS', 'd22e4df1-6919-4a77-a'),
('SHIP00000454', 'WH002', '35532 Walter Fork Suite 434
Ashleestad, UT 73950', 'in_transit', '2026-02-11', '2026-02-17', '2026-02-20', 'DHL', '919b7eca-057a-411e-a'),
('SHIP00000455', 'WH003', 'Unit 2997 Box 3908
DPO AP 48583', 'in_transit', '2026-01-31', '2026-02-05', '2026-02-07', 'USPS', 'a588d722-6ea0-41c5-b'),
('SHIP00000456', 'WH001', '6791 Wright Village
North Cristian, DC 71020', 'lost', '2026-02-21', '2026-02-26', '2026-02-27', 'Amazon', '047c85d6-0cca-4c0f-b'),
('SHIP00000457', 'WH003', '43735 Ronald Causeway Apt. 035
Kiddton, DC 04923', 'lost', '2026-02-09', '2026-02-10', '2026-02-12', 'FedEx', 'fe20fbd2-8083-4de5-a'),
('SHIP00000458', 'WH002', '636 Jenny Park
West Steve, PW 97075', 'returned', '2026-02-02', '2026-02-05', NULL, 'Amazon', 'b74d4e2b-c7ae-4927-b'),
('SHIP00000459', 'WH001', '974 Morales Landing Suite 246
South Tylerport, NE 64632', 'delivered', '2026-02-01', '2026-02-02', '2026-02-03', 'DHL', '25f1e5db-5c74-4192-9'),
('SHIP00000460', 'WH007', '319 Brian Center
North Jason, ME 48543', 'pending', '2026-02-15', '2026-02-22', '2026-02-25', 'UPS', '772d2c24-f4dd-44bd-b'),
('SHIP00000461', 'WH008', '762 Jennifer Dam
Port Kimberlyshire, TN 79419', 'delivered', '2026-02-19', '2026-02-25', '2026-02-23', 'DHL', 'd415e1c2-1587-43b5-b'),
('SHIP00000462', 'WH003', 'PSC 2637, Box 7671
APO AP 62404', 'lost', '2026-02-09', '2026-02-16', '2026-02-14', 'UPS', 'aa0a1a3a-d979-4cf0-a'),
('SHIP00000463', 'WH001', '4005 Robert Roads Suite 752
North Jennifer, MA 89982', 'delivered', '2026-02-16', '2026-02-23', '2026-02-21', 'Amazon', '71a566f3-e137-4151-b'),
('SHIP00000464', 'WH006', '406 Sexton Extension Suite 529
Ayalaland, SC 23420', 'returned', '2026-02-21', '2026-02-25', '2026-02-27', 'Amazon', '79c51026-0e4c-41d7-a'),
('SHIP00000465', 'WH004', '71986 Laura Mews Suite 238
Lake Jeffrey, NH 47125', 'returned', '2026-01-27', '2026-01-30', '2026-01-31', 'USPS', 'dc16989a-3fc2-41d0-9'),
('SHIP00000466', 'WH003', '65418 Jonathan Estate Apt. 296
South Michelle, NY 52372', 'returned', '2026-02-04', '2026-02-05', '2026-02-05', 'FedEx', 'ce47f256-ae6b-4aef-8'),
('SHIP00000467', 'WH010', 'USNV Strong
FPO AP 85640', 'pending', '2026-02-05', '2026-02-12', '2026-02-14', 'FedEx', '24381383-3c58-4745-b'),
('SHIP00000468', 'WH007', '55505 Freeman Ports
Lake Christopherhaven, SD 61795', 'returned', '2026-02-22', '2026-02-28', '2026-03-03', 'UPS', 'f8b4912a-9174-40a7-8'),
('SHIP00000469', 'WH005', 'USNV Saunders
FPO AP 07992', 'lost', '2026-02-16', '2026-02-19', '2026-02-17', 'Amazon', '10eab032-e81a-496b-8'),
('SHIP00000470', 'WH003', '0622 Guerra Parks Suite 255
New Tylerfort, CA 64370', 'returned', '2026-01-28', '2026-01-31', '2026-01-30', 'UPS', '65553e24-9b34-456a-9'),
('SHIP00000471', 'WH004', '549 West Flat
Port Christopherfurt, GU 89244', 'pending', '2026-02-23', '2026-03-02', NULL, 'Amazon', '29d618d3-3247-4bcf-9'),
('SHIP00000472', 'WH002', '4218 King Mount
Kimberlyland, MP 50781', 'lost', '2026-02-10', '2026-02-13', NULL, 'FedEx', '5f1d2ac3-0632-487c-9'),
('SHIP00000473', 'WH009', '28527 Stephanie Plain
New Annettehaven, CO 46602', 'pending', '2026-02-11', '2026-02-18', '2026-02-20', 'FedEx', '2569f6d5-dbaf-4d56-9'),
('SHIP00000474', 'WH003', '0779 Pitts Shores Apt. 569
New Michelle, VA 77911', 'delivered', '2026-02-09', '2026-02-15', '2026-02-17', 'USPS', 'b8ddba50-3a20-43df-b'),
('SHIP00000475', 'WH003', '94470 Mcmillan Locks
North Heather, NE 33628', 'pending', '2026-02-08', '2026-02-10', '2026-02-11', 'FedEx', '38408976-8658-43dd-b'),
('SHIP00000476', 'WH008', '306 Alyssa Loop
Mikeberg, NJ 67350', 'in_transit', '2026-02-19', '2026-02-24', '2026-02-25', 'Amazon', '597d630f-8216-492d-8'),
('SHIP00000477', 'WH010', '06817 Cannon Road
Port Rogerstad, WV 36113', 'lost', '2026-02-12', '2026-02-18', '2026-02-21', 'DHL', '7b431ab7-c3fa-46be-8'),
('SHIP00000478', 'WH004', 'Unit 7248 Box 0710
DPO AA 21015', 'returned', '2026-01-31', '2026-02-04', '2026-02-02', 'FedEx', '135828dc-8d13-4790-b'),
('SHIP00000479', 'WH005', '967 James Burg
West Brianberg, OK 63726', 'pending', '2026-02-14', '2026-02-15', '2026-02-18', 'FedEx', '4f994585-5a8b-439e-a'),
('SHIP00000480', 'WH006', '1245 Meyer Vista Apt. 627
West Lisa, MI 79048', 'pending', '2026-02-21', '2026-02-24', NULL, 'Amazon', '22b9ceae-4d20-4eea-a'),
('SHIP00000481', 'WH002', '0065 Oneal Drive
West Jenniferhaven, MT 72776', 'delivered', '2026-02-10', '2026-02-17', '2026-02-15', 'FedEx', '8d9efbfa-b9b1-45be-8'),
('SHIP00000482', 'WH005', '1151 May Forks
Port Annaland, NE 38222', 'returned', '2026-02-15', '2026-02-22', '2026-02-21', 'FedEx', 'fec17790-c206-4f19-8'),
('SHIP00000483', 'WH005', '44490 Flynn Vista Suite 227
Normanville, AS 91969', 'delivered', '2026-01-26', '2026-02-02', '2026-02-01', 'UPS', '48e822cc-2eb4-4bf2-9'),
('SHIP00000484', 'WH004', '604 Kimberly Plaza
New Ginahaven, TX 59848', 'lost', '2026-01-29', '2026-02-04', '2026-02-03', 'DHL', '3d5cf802-5807-45b6-a'),
('SHIP00000485', 'WH007', 'USNS Lane
FPO AP 03229', 'in_transit', '2026-02-14', '2026-02-18', '2026-02-18', 'DHL', '31189e52-b501-4252-b'),
('SHIP00000486', 'WH002', '590 Lindsay Vista
South Jesus, CA 68179', 'returned', '2026-02-08', '2026-02-11', '2026-02-13', 'USPS', '5858a2ac-171b-4fad-8'),
('SHIP00000487', 'WH002', '941 Davis Fort
Port Amanda, SC 15169', 'returned', '2026-02-08', '2026-02-13', '2026-02-16', 'UPS', '7cf47cfe-2a60-4ca8-8'),
('SHIP00000488', 'WH006', '2210 Drew Plains Suite 847
East Michael, CA 88513', 'pending', '2026-01-29', '2026-02-02', NULL, 'DHL', '90843bee-7439-4c1a-8'),
('SHIP00000489', 'WH005', '747 Claire Neck
South Donborough, KS 56370', 'delivered', '2026-02-21', '2026-02-28', '2026-02-26', 'DHL', '4cf57959-977e-4c07-a'),
('SHIP00000490', 'WH003', '800 Terry Overpass Suite 199
Patelhaven, MN 29163', 'delivered', '2026-02-13', '2026-02-18', '2026-02-20', 'Amazon', '877fddf0-2890-467b-8'),
('SHIP00000491', 'WH008', '166 Curry Corner
Bairdfurt, VA 70357', 'returned', '2026-02-07', '2026-02-11', '2026-02-13', 'USPS', '754edc28-0669-4438-a'),
('SHIP00000492', 'WH007', '9892 Anthony Walk
Port Christina, NE 49970', 'pending', '2026-02-07', '2026-02-13', NULL, 'DHL', '10037607-eae4-4f80-9'),
('SHIP00000493', 'WH003', 'PSC 6882, Box 1372
APO AA 48848', 'in_transit', '2026-02-16', '2026-02-20', '2026-02-23', 'DHL', 'a83953d4-d3dd-444a-8'),
('SHIP00000494', 'WH010', '39095 Ayala Island Suite 886
Tanyaview, GU 85433', 'pending', '2026-01-30', '2026-02-03', '2026-02-03', 'FedEx', '562e02a7-b85d-4bab-8'),
('SHIP00000495', 'WH006', '69346 Osborn Landing
Alexistown, NM 08135', 'pending', '2026-02-22', '2026-02-25', NULL, 'USPS', 'f4efcb1a-4468-471e-b'),
('SHIP00000496', 'WH008', '712 Lisa Road
Wellsfort, FL 29872', 'returned', '2026-02-16', '2026-02-22', '2026-02-20', 'UPS', '62517725-4f75-4fe4-8'),
('SHIP00000497', 'WH001', '27514 Randy Road Suite 179
South Gregory, AS 25640', 'delivered', '2026-01-30', '2026-02-05', '2026-02-06', 'DHL', '5ecbc922-3fbb-4caa-9'),
('SHIP00000498', 'WH001', '1455 Randy Curve
Stanleyville, PR 27854', 'lost', '2026-02-02', '2026-02-06', '2026-02-06', 'UPS', 'd5325a93-d0dd-4606-b'),
('SHIP00000499', 'WH002', '53196 Javier Union Apt. 680
Port Mary, IN 93937', 'pending', '2026-01-26', '2026-02-02', '2026-02-02', 'USPS', '90685ca9-2404-4f01-8'),
('SHIP00000500', 'WH007', '8571 Riley Vista
Thompsonville, NE 35674', 'lost', '2026-02-01', '2026-02-06', '2026-02-08', 'UPS', 'ca561c62-4a88-41a0-b');