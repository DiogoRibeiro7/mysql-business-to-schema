-- Demo data for insurance_db
USE insurance_db;

SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE policies;
TRUNCATE TABLE claims;
TRUNCATE TABLE customers;
SET FOREIGN_KEY_CHECKS = 1;

-- Insert customers
INSERT INTO customers (customer_id, first_name, last_name, email, phone, date_of_birth, address, risk_score) VALUES
(1, 'Heather', 'Moore', 'chandave@example.com', '615.773.5366', '1961-08-15', '50614 Pittman Groves Apt. 108
Port Valeriebury, PA 19283', 0.69),
(2, 'Brandon', 'Olsen', 'onealleslie@example.net', '(465)295-5245x189', '1988-09-23', '8601 White Oval Suite 906
Jessicafurt, AZ 52335', 0.82),
(3, 'John', 'Wong', 'james69@example.net', '951.262.6870', '1998-02-27', '62620 Becker Loop
Myerston, AL 57333', 1.0),
(4, 'Dale', 'Haynes', 'patricia14@example.org', '001-803-960-7055x569', '1970-02-18', '143 Morgan Garden Suite 162
Lake Christopher, DE 74230', 0.36),
(5, 'Ronald', 'Murphy', 'dominicmiller@example.net', '6417353026', '1958-07-17', 'Unit 7260 Box 2084
DPO AE 94209', 0.44),
(6, 'Donna', 'Foster', 'evan78@example.org', '815-775-7711', '1995-11-25', '3721 Leonard Ways Suite 432
Port Madisonborough, CO 12316', 0.59),
(7, 'Sharon', 'Abbott', 'kwebb@example.net', '(431)788-3543x9770', '1955-11-26', '53783 Nicholas Canyon Suite 808
East Samanthaside, MT 86031', 0.84),
(8, 'Rhonda', 'Craig', 'chenry@example.net', '+1-848-605-0772x0116', '1964-05-18', '47127 Mary Way
Juliefort, MP 71949', 0.72),
(9, 'Taylor', 'Marshall', 'xchen@example.com', '7063694034', '1989-07-03', 'USNS Santos
FPO AA 96056', 0.18),
(10, 'Heather', 'Scott', 'christina16@example.com', '(443)943-1215', '1979-11-29', '858 Shawn Street
Lake Coltonburgh, NJ 95622', 0.96),
(11, 'Megan', 'Chung', 'jillian39@example.org', '(920)463-4896x12885', '1984-03-06', '028 Kristina Canyon Apt. 361
South Lisabury, NY 75373', 0.76),
(12, 'John', 'Douglas', 'andrew55@example.com', '688.667.9750', '1956-12-23', '27042 Tanner Way
Pricefort, NC 98403', 0.72),
(13, 'Michelle', 'Trevino', 'gentrybrandi@example.com', '(870)553-1666', '1972-08-22', '6772 Harry Mountain
Manuelborough, SC 08147', 0.83),
(14, 'Cory', 'Kirk', 'portermichael@example.com', '752-339-9177x9800', '1962-01-14', '95245 Mark Isle Apt. 860
West Andrew, PW 58989', 0.77),
(15, 'Stanley', 'Golden', 'carmen74@example.org', '860.571.1129x102', '1980-06-06', '0950 Vargas Summit Apt. 550
South Brianbury, NY 37585', 0.98),
(16, 'Jose', 'Macdonald', 'pdowns@example.net', '(362)276-5784x65440', '1988-01-25', '212 Evans Expressway
North Lisa, NE 22480', 0.89),
(17, 'Rachel', 'Clark', 'tiffany02@example.net', '490-401-0632x593', '1979-08-19', '7476 Mitchell Motorway
Sloanport, PR 91351', 0.2),
(18, 'Deborah', 'Skinner', 'michellebrown@example.net', '465-665-5715x557', '1976-11-06', '25838 John Drives
West Stephanieton, PA 42548', 0.53),
(19, 'Courtney', 'Edwards', 'reneedouglas@example.org', '(756)545-3392x0206', '1986-05-05', 'PSC 3312, Box 4720
APO AA 91757', 0.33),
(20, 'Joseph', 'Lopez', 'tyrone02@example.net', '+1-861-447-7190', '1990-01-17', 'Unit 5763 Box 2754
DPO AE 19845', 0.44),
(21, 'Justin', 'Ramirez', 'tfuller@example.com', '423.292.6262', '1992-09-21', '224 Strickland Branch
Davisport, DE 26603', 0.44),
(22, 'Veronica', 'Palmer', 'jbolton@example.net', '(300)837-5699x1150', '1985-06-12', '719 Woods Locks
Munozberg, SC 03413', 0.67),
(23, 'Laura', 'Mack', 'larsonjonathan@example.com', '945-826-0061x4898', '1979-03-27', '1184 Jenna Parkways
East Katherinemouth, NE 43821', 0.38),
(24, 'Jeffrey', 'Coleman', 'andrea61@example.org', '(332)220-3871x75931', '1998-06-27', '98411 Samantha Causeway
North Jaclynside, CA 08770', 0.26),
(25, 'Kelly', 'Hardy', 'dwilliams@example.net', '532.586.2964x29444', '1987-11-03', '16174 White Light Suite 456
Port Noahbury, UT 26392', 0.17),
(26, 'Brandy', 'Russell', 'donna34@example.com', '(358)591-0833', '1986-05-18', '18378 Patty Courts Apt. 767
Lake Matthewmouth, LA 93902', 0.15),
(27, 'Tara', 'Shannon', 'robbinsjohn@example.org', '7602148412', '2000-08-23', '81611 Mills Tunnel Apt. 269
Blakeborough, FL 99856', 0.39),
(28, 'Jacob', 'Dixon', 'onelson@example.net', '581.278.3880x096', '1998-07-16', '079 Hamilton Squares
Stephensfurt, SD 32653', 0.78),
(29, 'Ashley', 'Perez', 'danielle38@example.com', '(662)848-6515', '1995-06-07', '5049 Jimmy Vista Apt. 856
North Darrenport, NV 65229', 0.17),
(30, 'Ashley', 'Garcia', 'agay@example.com', '001-488-811-6346x460', '1973-10-14', '062 Diane Centers
Andrewshire, MO 23618', 0.81),
(31, 'Allison', 'Dixon', 'masseydiane@example.com', '001-787-925-1952x550', '1980-08-26', '152 Vanessa Plain Suite 634
Suarezburgh, AL 54493', 0.1),
(32, 'Carol', 'Woodward', 'oryan@example.com', '(513)996-3435x2566', '1965-06-16', '180 Johnson Common Suite 002
West Austinshire, KY 34044', 0.89),
(33, 'Calvin', 'Shea', 'mark48@example.net', '6766267986', '1978-05-02', '01035 Bonnie Rapids Apt. 298
South Alishaview, NC 15255', 0.2),
(34, 'Garrett', 'Callahan', 'melissapena@example.org', '(380)293-4431x788', '1986-02-25', '14857 Bell Flat
Port Markton, MT 66563', 0.27),
(35, 'Travis', 'Ford', 'fpineda@example.com', '747-464-2362x5720', '1973-10-26', '642 Mitchell Mill
West Patrickmouth, NH 80986', 0.15),
(36, 'Katie', 'Vincent', 'billy65@example.net', '481.228.6439', '2000-03-12', '760 Johnson Club
Bestberg, WA 15768', 0.99),
(37, 'Jim', 'Neal', 'imoore@example.org', '+1-412-669-7179x044', '1990-05-04', '372 April Way Suite 932
North Lori, MN 14316', 0.25),
(38, 'Autumn', 'Hammond', 'brooksraymond@example.org', '+1-871-846-1419x6779', '1986-10-19', '2542 Francis Skyway
West Christine, MP 70022', 0.86),
(39, 'Kevin', 'Lucas', 'marie08@example.org', '(286)631-1592', '1960-04-16', '9636 Joshua Garden Apt. 375
North Henry, DC 89204', 0.6),
(40, 'David', 'Williams', 'alexis50@example.net', '366.620.6886x4254', '1972-09-26', 'PSC 6313, Box 5303
APO AA 08049', 0.97),
(41, 'Mary', 'Robles', 'chapmanjonathan@example.com', '842.954.0169', '1983-09-17', '96988 Lori Hollow Apt. 323
North Wandafort, OH 28141', 0.61),
(42, 'Elaine', 'Chen', 'justin28@example.com', '(292)559-6424x379', '2001-06-28', '20988 James Ports
West Ashleytown, PA 93163', 0.28),
(43, 'Danielle', 'Clark', 'florestracy@example.org', '(522)883-9216', '1987-08-20', '24359 Emily Crescent Apt. 151
Scottbury, WI 62990', 0.74),
(44, 'Carolyn', 'Davis', 'levykyle@example.org', '001-244-590-4107', '2005-03-20', '2890 Ellis Court Suite 265
Randolphstad, IN 64001', 0.91),
(45, 'Tammy', 'Green', 'melissamartin@example.com', '001-484-447-2131', '1956-10-19', '30615 Erik Courts
South Samueltown, WV 92854', 0.9),
(46, 'Darren', 'Camacho', 'kellyronald@example.org', '475.877.9861', '1955-04-16', '61926 Martinez Courts Apt. 027
Brookechester, KS 91070', 0.56),
(47, 'Brian', 'Abbott', 'fmitchell@example.net', '674-721-6238x00705', '1994-04-04', '9758 Perkins Stream
Port Michaelbury, IL 24560', 0.93),
(48, 'Caleb', 'Pearson', 'warnermariah@example.net', '6177235836', '2005-04-07', '770 Bishop Unions
Lisabury, MI 02520', 0.7),
(49, 'Kara', 'Brown', 'johnwhite@example.net', '908-490-2053x42680', '1955-05-04', 'USNS Adams
FPO AA 05684', 0.49),
(50, 'Whitney', 'Velazquez', 'townsendderek@example.org', '656-594-5225x272', '1976-07-13', 'USS Hood
FPO AE 20211', 0.83),
(51, 'Eric', 'Brown', 'collin24@example.net', '686-670-0161', '1966-04-10', '04717 Parker Summit Apt. 162
North Austin, PW 32868', 0.13),
(52, 'David', 'Wyatt', 'lwilliams@example.net', '571-474-9332x5385', '1989-07-23', '342 Patricia Corners
Lake Lee, AZ 44469', 0.25),
(53, 'Sonia', 'Rodriguez', 'mathewsalas@example.net', '7623169481', '1985-05-16', '590 Jonathan Field Suite 445
Lake Dawn, IL 57223', 0.59),
(54, 'Jennifer', 'Meyer', 'adam99@example.org', '(705)226-5994x164', '1961-07-15', '4084 Joseph Burgs Apt. 225
Kyleborough, UT 00949', 0.84),
(55, 'Tyler', 'Humphrey', 'deborahking@example.com', '574-732-9495x64515', '1973-10-28', '7221 Best Light Apt. 918
Mcdanielside, LA 15826', 1.0),
(56, 'Cindy', 'Webb', 'asherman@example.org', '001-235-215-5002', '1996-07-29', 'PSC 9662, Box 4447
APO AA 53760', 0.38),
(57, 'Marie', 'Davis', 'fmoreno@example.net', '9028182347', '1959-11-22', '7443 Christina Glens
Lake Sergio, IA 13977', 0.68),
(58, 'Madeline', 'Young', 'ericharper@example.org', '+1-284-462-7863', '1982-08-12', '4548 Perez Haven Apt. 906
East Josephside, AS 95433', 0.45),
(59, 'Felicia', 'Fuller', 'reyessteven@example.com', '601-694-2924', '1979-09-27', '102 Whitaker Forge
Port Timothy, WI 60139', 0.77),
(60, 'Jessica', 'Carter', 'jwalters@example.org', '001-506-479-1495x650', '1970-12-08', '8935 Harris Forge
Jamesbury, WV 84853', 0.11),
(61, 'Austin', 'David', 'erica30@example.com', '(531)507-9987x47592', '2002-09-30', 'USCGC Moyer
FPO AE 98376', 0.32),
(62, 'Timothy', 'Gardner', 'clarkallen@example.org', '926.354.0101', '1966-07-30', '80671 Douglas Mill
Port Michael, RI 77081', 0.53),
(63, 'Kurt', 'Hughes', 'rcook@example.com', '869-941-3912x16726', '1956-10-24', '51508 Stephens Track
Tiffanyfort, TX 01994', 0.75),
(64, 'Michael', 'Brooks', 'gflores@example.org', '(618)396-8315', '1965-10-02', '031 Michelle Loop Suite 896
Troyshire, OK 25516', 0.4),
(65, 'Andrew', 'Rivera', 'moralesgregory@example.com', '(585)730-5872x707', '1995-07-06', '20764 Brewer Dale Apt. 180
South Valerie, HI 99214', 0.84),
(66, 'William', 'Singleton', 'jamesstone@example.com', '224-545-9730', '1975-08-09', '543 Allison Rapids
North Aliciaville, VT 01172', 0.76),
(67, 'Anthony', 'Smith', 'huntchristy@example.net', '4186990795', '1978-12-26', '064 Monique Glens Apt. 238
Patriciafurt, IN 34174', 0.75),
(68, 'Gabriel', 'Roberts', 'joshua47@example.net', '964.944.7240', '1985-11-05', '3184 Scott Wells Apt. 484
Kevinfort, IA 93013', 0.1),
(69, 'Philip', 'Smith', 'guerrarebecca@example.org', '594.815.9416x543', '1988-11-22', '6486 Tom Road Suite 415
Murphymouth, HI 78928', 0.94),
(70, 'Carmen', 'Mack', 'jonathanwalters@example.com', '001-323-686-3252', '1974-08-22', '85561 Black Trail Apt. 631
New Brandonton, VT 97336', 0.21),
(71, 'Jeff', 'Fuentes', 'steelesara@example.net', '631-957-4128', '1985-01-15', '0439 Smith Crest Apt. 882
Jordanville, MS 25244', 0.76),
(72, 'Katelyn', 'Clark', 'oconnorleonard@example.net', '627-703-3723x9727', '2001-06-20', '191 Schmidt Squares
Nicholasberg, VT 52950', 0.82),
(73, 'Sandra', 'Wilson', 'cabrerajoshua@example.com', '+1-207-258-3146x6278', '2003-07-20', '9329 Elizabeth Ferry Apt. 652
Shannontown, AK 32938', 0.83),
(74, 'Michael', 'Mclean', 'munozdavid@example.net', '892.810.4311', '1977-08-01', '308 Dudley Haven
Brockmouth, NM 39258', 0.55),
(75, 'Eric', 'Rice', 'dana87@example.net', '285.611.9967x459', '1988-03-28', '404 Brian Turnpike Suite 790
New Gregory, PW 10516', 0.39),
(76, 'Shawn', 'Wise', 'drivera@example.net', '640-291-2118x4958', '1998-04-03', '681 Carlos Valley Apt. 122
East Joseph, AL 11901', 0.76),
(77, 'Allison', 'Rogers', 'rhernandez@example.org', '+1-354-804-0662x4331', '1999-12-01', 'USCGC Garcia
FPO AA 86505', 0.68),
(78, 'David', 'Anthony', 'ycampbell@example.net', '001-471-968-6332', '1960-07-13', '088 Wiggins Locks Suite 176
Smithchester, NC 37525', 0.92),
(79, 'Tracy', 'Fleming', 'kimberly22@example.net', '001-651-919-7112x507', '1988-03-21', '4145 Jerome Mountains
Richardschester, WA 07784', 0.65),
(80, 'Timothy', 'Manning', 'ywilliams@example.org', '(426)398-5757x69402', '1956-02-29', '88888 Vega Fields
New Michaelfort, PW 11023', 0.72),
(81, 'Vincent', 'Kemp', 'vincent95@example.com', '7618297929', '1957-10-01', 'USCGC Johnson
FPO AA 89905', 0.15),
(82, 'Paul', 'Stevenson', 'victoriataylor@example.net', '001-558-988-4115x781', '1979-11-07', '409 Brock Green Apt. 351
Millerburgh, UT 65590', 0.31),
(83, 'Joshua', 'Malone', 'rachelnicholson@example.com', '290-913-5190x25142', '2003-05-13', '790 John Plains
Leeside, LA 53356', 0.12),
(84, 'Kelsey', 'Taylor', 'ariana86@example.org', '(523)717-5597', '1983-10-28', '4643 Jennifer Field
Patricialand, PW 65617', 0.62),
(85, 'Pamela', 'Alvarado', 'jamiewest@example.com', '001-549-902-9402x588', '1996-05-30', '089 Harrison Burgs
Mitchellstad, GA 99881', 0.5),
(86, 'Patrick', 'Norris', 'garrettjesse@example.org', '(724)895-1806', '1971-05-16', '0221 Ashlee Rapid
Suarezside, PW 35488', 0.85),
(87, 'Andrea', 'Rivera', 'denise73@example.org', '(503)816-7167', '1958-08-25', '4171 Miller Forks Apt. 994
West Thomasport, SC 98026', 0.38),
(88, 'Kimberly', 'Stanton', 'bushjames@example.com', '588-329-7399', '1990-09-23', '6132 Young Plains Suite 040
Hochester, MA 26389', 0.67),
(89, 'Jacqueline', 'Martinez', 'vangruben@example.com', '765.740.3904', '1972-05-21', '93007 Campos Hills
North Nicole, MN 36958', 0.6),
(90, 'David', 'Davis', 'thomas59@example.net', '001-263-957-0042x215', '2003-06-22', '6132 Williams Ville Suite 350
Jonesmouth, OH 03957', 0.34),
(91, 'Brian', 'Cruz', 'russellchristopher@example.org', '001-913-503-2662', '1956-07-09', '030 Kennedy Alley Apt. 622
East Marcus, VA 35190', 0.83),
(92, 'Thomas', 'Jones', 'tinawebb@example.net', '+1-641-377-1095x521', '1984-06-24', '73669 Jared Views Apt. 510
South Jasmine, VA 06129', 0.56),
(93, 'Michael', 'Zamora', 'calebmendoza@example.org', '(343)995-3633x0703', '1972-01-22', '56807 Michael Port
Port Travis, CA 71326', 0.51),
(94, 'Alex', 'Thompson', 'wcamacho@example.org', '+1-287-289-0014x194', '1966-01-03', '2864 Patton Orchard
Torresville, VI 36222', 0.99),
(95, 'Leslie', 'Murray', 'rickyjackson@example.org', '+1-409-880-1293', '1971-09-18', '739 Mora Shoal Suite 645
Kennethchester, DE 09837', 0.55),
(96, 'Shirley', 'Elliott', 'meltontamara@example.org', '001-943-790-6384x569', '1995-07-13', '522 Ferguson Ways
South Brenda, NE 95541', 0.41),
(97, 'Dana', 'Preston', 'lwhite@example.com', '001-450-311-3718', '1969-10-20', '59982 Ortega Squares Suite 934
Lake Anthony, WY 43684', 0.95),
(98, 'Jasmine', 'Smith', 'uharris@example.com', '(490)236-6368x16801', '1982-11-14', '041 Pruitt Vista
East Williamton, TX 87623', 0.62),
(99, 'Meagan', 'Miller', 'williamsjoshua@example.com', '001-887-386-3380x846', '1991-08-23', '57961 Edwin Loaf Suite 156
Yolandachester, MD 19602', 0.63),
(100, 'Christina', 'Price', 'christopher64@example.org', '832.918.6588', '1980-08-22', '8322 Evelyn Valley
Michaelton, MS 17693', 0.82),
(101, 'Kenneth', 'Armstrong', 'robinescobar@example.org', '628-901-5835', '2001-01-10', '682 Bartlett Brook
Lake Sherri, MH 70947', 0.26),
(102, 'Cory', 'Scott', 'rcarpenter@example.com', '001-294-638-0352x527', '1992-05-03', '667 Deborah Lake Apt. 334
South Maria, SD 19947', 0.28),
(103, 'Laura', 'Hernandez', 'xthomas@example.net', '(471)564-8304x1543', '1975-12-25', '3697 Sloan Spur
South David, VT 13332', 0.37),
(104, 'Kimberly', 'Torres', 'ravenboyle@example.net', '(641)573-8768', '1998-10-12', '809 Cohen Manors Apt. 471
Lake Amandaville, SC 83140', 0.18),
(105, 'Andrew', 'Vega', 'robertharris@example.com', '670-636-9357x48018', '1973-04-21', '4718 Rebecca Port
Brittanyborough, MA 83476', 0.81),
(106, 'Michelle', 'Anderson', 'dcrawford@example.com', '(923)781-8195x91688', '1997-03-12', '6530 Fox Burgs Suite 173
East Jamesfort, MT 92830', 0.66),
(107, 'Angela', 'Rowe', 'debbie37@example.org', '(322)357-1819x475', '2005-06-18', '8005 Nathan Shoals
Lake Susan, MT 86850', 0.83),
(108, 'Bridget', 'Alvarez', 'davisbrenda@example.org', '431-472-2901x4787', '1965-02-27', '71290 Wright Field
Port Ronnieshire, ID 16196', 0.21),
(109, 'Nancy', 'Martinez', 'davidgarcia@example.org', '+1-679-760-2969x032', '1998-02-26', '6246 Carpenter Underpass Suite 309
Port William, MP 03592', 0.66),
(110, 'Adam', 'Johnson', 'maypaula@example.org', '8448636762', '1958-09-24', '79855 Monroe Meadows Apt. 341
Gravesborough, OH 31359', 0.43),
(111, 'Felicia', 'Brooks', 'rachel03@example.org', '217-831-9688x6710', '1966-07-01', '4385 Samantha Crest Apt. 240
Sanchezfurt, AL 35286', 0.87),
(112, 'Rodney', 'Williams', 'colleenwise@example.net', '(794)950-9423', '1995-09-14', '8564 Franklin Mews Suite 976
West Laurenmouth, OH 24713', 0.75),
(113, 'Wendy', 'Phillips', 'millerdawn@example.com', '(653)939-8344x1543', '1980-07-07', '191 Susan Highway Apt. 291
Martinberg, MA 94991', 0.65),
(114, 'Eric', 'Young', 'markmontgomery@example.net', '987-875-1287', '1993-02-04', '725 Alicia Terrace Apt. 814
Kerrview, SD 76565', 0.8),
(115, 'Patricia', 'Jones', 'oholder@example.com', '691.434.7071', '1987-11-11', '202 Mark Plains Suite 210
Lake Gerald, VT 43235', 0.78),
(116, 'Jennifer', 'Kennedy', 'morrisonjohn@example.net', '+1-605-855-4533', '1966-03-21', '699 Gates Port Suite 271
Christopherside, MN 72125', 0.8),
(117, 'Edward', 'Banks', 'nicolemccoy@example.com', '3555929345', '1985-12-18', '28840 Veronica Shoals
New Patrick, OR 61102', 0.76),
(118, 'Joshua', 'Stevens', 'michael44@example.com', '(237)258-6349', '1994-12-31', '27841 Pacheco Island
Lake Joelville, NJ 17768', 0.89),
(119, 'William', 'Underwood', 'leahporter@example.org', '001-307-375-7556', '1978-05-14', '6643 Casey Cliff Suite 401
Lake Larry, RI 72832', 0.61),
(120, 'Todd', 'Taylor', 'courtney62@example.net', '900-848-7024x523', '1988-04-01', '6086 Jessica Spur
Mccannmouth, WA 35854', 0.34),
(121, 'Andre', 'Williams', 'daniel03@example.com', '+1-260-650-5583x5533', '1966-05-12', '209 Patrick Extension Apt. 415
North Richard, LA 42888', 0.93),
(122, 'Thomas', 'Houston', 'jamestorres@example.net', '908.662.5017x319', '1971-09-22', '306 Farley Expressway Apt. 066
Lake Justinland, VT 84019', 0.87),
(123, 'Erika', 'Fleming', 'taylorjeffrey@example.org', '334.371.4546x7141', '1983-12-19', '725 Becker Lodge
East Daniel, OH 65846', 0.26),
(124, 'Tyler', 'Rose', 'nicholasmontgomery@example.com', '001-469-601-9531x559', '1966-12-01', '546 Ryan Shores
Rodriguezfort, PW 58204', 0.35),
(125, 'Leonard', 'Jones', 'harrislee@example.net', '608.861.3297x14827', '1956-07-21', '3975 Jasmine Stream Apt. 118
Bakerside, TX 89323', 0.77),
(126, 'Jacob', 'Castro', 'pholland@example.net', '(497)829-3082', '2001-11-06', '66717 Glenn Lane
North Amandachester, MA 73373', 0.97),
(127, 'Christina', 'Martinez', 'thompsonjohn@example.org', '(399)602-4443x920', '1965-06-04', '426 Dennis Falls
Lake Tina, VT 85702', 0.11),
(128, 'John', 'Stevens', 'kimberlywagner@example.net', '866-599-3650x3358', '1980-07-29', '3960 Stark Square Apt. 681
Gallegosberg, MH 36255', 0.6),
(129, 'Lisa', 'Bailey', 'romeromichelle@example.net', '+1-360-670-7405x2503', '1971-05-15', 'PSC 2452, Box 2800
APO AA 78289', 0.55),
(130, 'Tanya', 'Mosley', 'glenevans@example.org', '+1-269-870-1982', '1976-01-12', '3969 Laura Haven
West Davidfort, TX 27934', 0.31),
(131, 'Emily', 'Avila', 'xfreeman@example.net', '528-426-7601', '1962-04-19', '86481 Salas Bypass Suite 375
Youngberg, AK 27162', 0.33),
(132, 'Aaron', 'Heath', 'omcgee@example.net', '001-800-947-1606x149', '1960-02-25', 'PSC 8858, Box 2408
APO AE 98411', 0.95),
(133, 'John', 'Reed', 'qpitts@example.org', '+1-414-578-9171x1392', '1974-07-21', '13049 Donald Cliffs
Leechester, LA 03757', 0.55),
(134, 'Kristen', 'Jones', 'bhernandez@example.org', '4592819034', '1986-07-21', '2529 Garcia Landing
Port Bridget, PW 60544', 0.8),
(135, 'Alicia', 'Wilson', 'benjamingreer@example.org', '211.404.0288', '1957-08-01', '1252 Miller Circle Suite 555
Wardmouth, MH 46465', 0.18),
(136, 'Theresa', 'Wright', 'lesliechase@example.net', '568.939.8823x436', '1980-10-16', '021 Tanner Lodge
Normanton, ND 63776', 0.31),
(137, 'Joe', 'Thomas', 'williambarber@example.com', '736.804.5836', '1984-07-11', '7620 Savage Heights
South Melanieport, NC 52347', 0.9),
(138, 'Ashley', 'Hayes', 'spencerzachary@example.com', '(776)744-4706x721', '1987-09-24', '56130 Barrett Brook
Mendozaton, PW 63561', 0.89),
(139, 'David', 'Morgan', 'crodriguez@example.org', '(334)395-6688x4506', '1966-02-03', '07193 Jimenez Street Apt. 195
West Stephen, ME 77686', 0.64),
(140, 'Amber', 'Meyer', 'samueldawson@example.net', '523.852.4976', '1980-06-02', '994 Williams Passage Apt. 446
North Jessicaville, MP 45936', 0.81),
(141, 'Kristopher', 'Moses', 'wadeapril@example.com', '457-731-3800x304', '1978-07-16', '377 Linda Hollow
Mooretown, WY 85118', 0.87),
(142, 'Jill', 'Walsh', 'chavezedward@example.com', '664.374.2833', '1989-12-05', '32996 Jennifer Via Apt. 177
North Lisa, FM 89168', 0.81),
(143, 'David', 'Chapman', 'sharon67@example.org', '001-203-569-5342', '1963-10-08', '5164 Adams Ville
West Robertstad, PR 50823', 0.47),
(144, 'Amy', 'Nielsen', 'lgraves@example.com', '(288)415-4193', '1982-08-25', '74719 Reyes Island Apt. 803
New William, AS 17819', 0.45),
(145, 'Brett', 'Garrett', 'lopezgeorge@example.com', '2525822769', '1973-11-18', '42662 Calvin Mission Apt. 132
Benjaminshire, VA 38707', 0.62),
(146, 'Autumn', 'Byrd', 'carnold@example.org', '370.605.2750', '1980-06-01', '923 Hughes Orchard
Levineland, AR 46168', 0.19),
(147, 'Erin', 'Jones', 'vincentcarter@example.org', '961-233-2837', '1991-07-19', '2500 Ramos Dale Apt. 629
Lake Jason, LA 28291', 0.35),
(148, 'Colin', 'Mullen', 'hudsonsean@example.net', '001-640-893-9317', '1975-08-25', '502 Steven Falls
Morenomouth, OK 03995', 0.2),
(149, 'Collin', 'Robertson', 'morrischristina@example.com', '001-626-449-4963x994', '1955-10-30', '12494 Roberto Lake Suite 549
West Ashleyside, UT 65490', 0.35),
(150, 'Robert', 'Ramos', 'oross@example.com', '537.415.7178x3820', '1963-08-31', '01688 Alex Expressway Apt. 141
Anthonyborough, NJ 55754', 0.56),
(151, 'Andrew', 'Nelson', 'elizabethkim@example.org', '322-810-1851', '1989-09-12', '707 Shelia Islands
East Alexishaven, PA 90353', 0.27),
(152, 'Angela', 'Jones', 'qbarnes@example.org', '9928220248', '1963-03-18', '8085 Hunter Fall
Port Maryview, AR 17277', 0.64),
(153, 'Gwendolyn', 'Villa', 'sperez@example.net', '910-875-1406', '1977-08-06', '506 Coleman Shore
Jessicashire, TX 76736', 0.11),
(154, 'Stephen', 'Griffin', 'markscott@example.net', '(254)356-9747x4483', '1997-05-22', '60511 Benjamin Burg
East Kaitlynside, WA 66763', 0.23),
(155, 'Carrie', 'Elliott', 'elizabethphillips@example.com', '(368)415-5937x107', '2000-06-21', '9441 Michael Squares
Eddieville, PW 13882', 0.79),
(156, 'Jason', 'Jackson', 'linda93@example.net', '+1-997-329-9030x010', '1998-07-10', '3407 Taylor Fort Apt. 301
Fritzchester, IA 58499', 0.76),
(157, 'Brianna', 'Watkins', 'stonemaria@example.net', '001-311-363-6985x326', '1956-07-30', '0989 Denise Mount
Christopherview, KS 51110', 0.77),
(158, 'Karl', 'Robertson', 'coxjon@example.com', '706.705.4114x0826', '1971-02-20', 'USCGC Cole
FPO AP 78754', 0.34),
(159, 'Erika', 'Charles', 'josewalker@example.org', '202.919.3842', '1991-02-03', '9259 Susan Rapid
East Rhondaton, TN 27337', 0.31),
(160, 'Jon', 'Rose', 'wrose@example.net', '(748)681-2981x89299', '1961-01-08', '35896 Ponce Isle
East Elizabethhaven, GU 32444', 0.69),
(161, 'Joseph', 'Tran', 'carlos07@example.com', '+1-362-309-3279x1819', '1977-11-24', '681 Rivas Freeway
East Tiffany, KY 63157', 0.42),
(162, 'Daniel', 'Mercer', 'shawn61@example.org', '283.776.1299x86313', '1973-08-21', '403 Leblanc Plaza
East Morganburgh, AZ 71668', 0.94),
(163, 'Juan', 'Campbell', 'garciakristen@example.net', '467-512-4716x37886', '2007-05-23', '750 Malik Fort
East Travistown, SD 05981', 1.0),
(164, 'Karen', 'Collins', 'moniqueware@example.com', '265-384-7608x371', '1972-02-16', '3287 Collins Pike
Port Benjaminchester, PW 75795', 0.75),
(165, 'Jessica', 'Duran', 'lawsonmason@example.org', '001-565-904-7298x133', '1971-01-06', '292 Robert Shores Suite 476
Port Margarethaven, NJ 10380', 0.15),
(166, 'Melissa', 'Hale', 'ysantos@example.net', '001-291-339-9129x119', '1973-04-22', '85952 Rubio Cove Suite 684
Smithfurt, GA 35482', 0.65),
(167, 'Steven', 'Rivera', 'donna97@example.org', '+1-378-933-2191x6710', '1986-09-29', '5175 Corey Road Suite 690
Lake Robert, KY 58834', 0.95),
(168, 'Harold', 'Rodriguez', 'whitney71@example.org', '740-497-9095x7697', '1966-11-08', '6087 Robbins Land Apt. 515
Michaelfurt, IA 76758', 0.57),
(169, 'Sean', 'Phillips', 'scottjohnson@example.com', '979-935-5678x401', '1974-03-09', '6258 Kyle Lakes
Carlosmouth, NY 70586', 0.82),
(170, 'Jessica', 'Thomas', 'christopherwilliams@example.org', '001-634-705-4411x156', '1965-05-05', 'USCGC Graham
FPO AA 49530', 0.59),
(171, 'Ian', 'Henry', 'clarkemily@example.org', '001-451-270-5649', '1985-09-23', '378 Jennifer Mountains
East Lukeview, AK 88507', 0.15),
(172, 'William', 'Graham', 'john31@example.net', '385-581-6181x7060', '1986-06-11', '3376 Kevin Circle
Jameshaven, LA 67991', 0.23),
(173, 'Brooke', 'Shaw', 'martinezgregory@example.com', '(877)633-9007x1596', '1972-09-21', '146 Megan Underpass
West Jessicamouth, GA 16938', 0.7),
(174, 'Tracy', 'Bell', 'audrey19@example.com', '001-846-850-7229x547', '1984-12-17', '25195 Brianna Court Apt. 022
Aprilchester, ID 68745', 0.89),
(175, 'Peter', 'Fletcher', 'colematthew@example.com', '(369)648-0288', '1994-04-14', 'Unit 3144 Box 2987
DPO AA 98733', 0.77),
(176, 'Bryan', 'Smith', 'yharrison@example.net', '232.399.7773', '2006-05-24', '95870 Joseph Points Apt. 802
West Conniestad, MT 72500', 0.67),
(177, 'Lisa', 'Mitchell', 'thompsonnicole@example.com', '001-369-908-5520x308', '1992-01-01', '54147 Priscilla Spring
South Jennifer, MI 95508', 0.61),
(178, 'Veronica', 'Griffin', 'aknight@example.net', '991-245-8455x9737', '1958-04-21', '3033 Mcdaniel Circle
Amandaside, GU 17626', 0.47),
(179, 'Brandi', 'Robinson', 'smithjohn@example.com', '292.351.1369', '1998-04-30', 'PSC 8863, Box 3819
APO AA 26859', 0.75),
(180, 'David', 'Alvarez', 'jamessparks@example.com', '6843004985', '1971-03-18', '56998 Stevens Dale Suite 580
West Nicole, TX 44444', 0.43),
(181, 'Jacob', 'Lynch', 'jasonavila@example.net', '911-234-8036x9094', '1972-04-05', '65858 David Island
Margaretchester, ME 80667', 0.96),
(182, 'Christopher', 'Wyatt', 'matthewcruz@example.org', '403-467-7348', '1994-10-05', '6357 Hampton Walk Apt. 013
New Jonathan, VA 83696', 0.65),
(183, 'Mark', 'Thomas', 'kanekarina@example.org', '484-915-8651', '1986-11-24', '210 Robertson Plaza Suite 126
New Victor, PW 96175', 0.69),
(184, 'Matthew', 'Williams', 'jody28@example.org', '001-907-934-6713', '2003-10-21', 'USS Mccullough
FPO AP 75602', 0.35),
(185, 'Danielle', 'Williams', 'morrowbryan@example.net', '835-476-2738', '1994-01-12', '89593 Nguyen Points Apt. 489
West Alicia, GU 22534', 0.78),
(186, 'Randall', 'Schmidt', 'leejennifer@example.com', '474.791.4770x175', '2006-05-07', '9752 Thomas Forges Suite 029
Lake Shaneburgh, FL 98838', 0.14),
(187, 'Jesus', 'Page', 'samantha62@example.com', '787-803-5814x69131', '1996-08-07', '09093 Hodges Village
New Edward, VT 32401', 0.12),
(188, 'Tiffany', 'Davis', 'katherine69@example.org', '379.593.0495x7552', '2001-03-15', '669 Mueller Mountains
Lambertborough, IA 58407', 0.71),
(189, 'Eric', 'Rivera', 'phillipssuzanne@example.com', '(291)496-1720x34360', '1998-12-11', '32063 Campbell Station
Jonesbury, WV 22081', 0.92),
(190, 'Alyssa', 'Li', 'brianpeterson@example.net', '442-731-7047', '1975-10-31', '5216 Stevenson Manor
Ronaldshire, GA 39670', 0.52),
(191, 'Anthony', 'Davis', 'craig49@example.net', '740-959-1205x2767', '2003-09-07', '788 Hall Mill Suite 151
Cassandratown, AZ 85527', 0.82),
(192, 'Jonathan', 'Reyes', 'lhunt@example.net', '(229)275-6242', '2002-07-29', '624 Thompson Roads
Port Haleyburgh, AS 21881', 0.53),
(193, 'Brittany', 'Young', 'robinburke@example.com', '001-766-470-7200x256', '2007-06-06', '35061 Glenn Stravenue Suite 982
South Jeffreyberg, NM 68100', 0.93),
(194, 'Valerie', 'Estrada', 'gravesmary@example.org', '356.592.6457', '1980-05-02', '827 Middleton Light
Port Kristen, FL 06111', 0.23),
(195, 'April', 'Sullivan', 'lmiller@example.com', '(769)333-8254x67646', '1995-04-07', '4965 Tammy Camp
Briannastad, AK 20122', 0.71),
(196, 'Christopher', 'Hart', 'joshuawilson@example.net', '989.862.5066x42931', '1956-10-15', '4924 Novak Islands Apt. 564
Lake Manuelshire, FL 91989', 0.56),
(197, 'Amanda', 'Turner', 'lynchmatthew@example.com', '823-760-2423x298', '1986-05-05', '08404 Larsen Alley
Catherinefurt, CA 46930', 0.65),
(198, 'Justin', 'Le', 'stephanie02@example.org', '290-967-2257x5196', '1986-05-14', 'PSC 3162, Box 3623
APO AP 80293', 0.56),
(199, 'Jonathan', 'Williams', 'richard36@example.com', '001-341-410-4084x939', '1978-11-29', '07091 Destiny Cliff
Amandaton, RI 05813', 0.49),
(200, 'Aaron', 'Meyer', 'sabrinagoodman@example.net', '001-813-598-3900x814', '1975-07-09', '505 Carpenter Haven Suite 760
Jeffreyside, LA 07388', 0.15),
(201, 'Kiara', 'Taylor', 'erichmond@example.net', '001-275-484-0935x112', '1994-03-20', '4879 Scott Mews
Thomasbury, MP 05715', 0.11),
(202, 'John', 'Estes', 'davidsmith@example.org', '5486746043', '1987-09-07', '7728 Perry Passage Apt. 800
Zacharychester, DC 26450', 0.94),
(203, 'William', 'Avila', 'tlowe@example.com', '(815)898-2266x1639', '1982-11-07', '8805 Kevin Fall
Susanhaven, PR 09179', 0.16),
(204, 'Kevin', 'Murphy', 'uwebb@example.org', '001-345-396-6439', '2006-12-13', '6382 Morgan Roads Suite 990
New Anthony, DC 15910', 0.42),
(205, 'Alfred', 'Moore', 'ashleypeters@example.net', '(503)273-8685x357', '1992-11-14', '15139 Kimberly Plains
Riverafort, KY 22397', 0.46),
(206, 'Zachary', 'Ramos', 'taylorthomas@example.org', '399-283-2538', '1962-12-12', '15666 Drake Summit Suite 307
North Barrybury, AS 67536', 0.85),
(207, 'Anne', 'Riley', 'rachael33@example.net', '+1-757-336-4537x0031', '1963-05-30', '100 Williams Crossroad
Lauraborough, DC 13685', 0.33),
(208, 'Nicholas', 'Gomez', 'rodriguezallison@example.org', '(262)986-9012', '2007-09-07', '35642 Hendrix Lane
East Julian, LA 50088', 0.93),
(209, 'David', 'Wood', 'williamsmith@example.com', '(579)555-4779', '1969-01-22', '47170 Christopher Creek
Franklinfurt, IL 20592', 0.79),
(210, 'Hunter', 'Reynolds', 'jessica44@example.org', '001-245-273-6915', '1997-03-27', '6905 Jones Loop Suite 166
Port David, AS 15349', 0.87),
(211, 'Danielle', 'Ferguson', 'gporter@example.org', '484-725-4187x576', '1970-10-19', '02304 Richardson Square Apt. 904
Woodardfort, NE 59365', 0.42),
(212, 'Jodi', 'Brown', 'twatkins@example.net', '911-516-8445', '1972-06-24', '18200 Javier Creek Apt. 628
North Johnborough, LA 22785', 0.87),
(213, 'Jessica', 'Marshall', 'bryanford@example.org', '+1-701-362-0725', '1960-04-03', '839 Wiggins Haven Apt. 612
New Travis, MD 43924', 0.71),
(214, 'Ronnie', 'Clark', 'shawnnewton@example.net', '864.201.4280x941', '2001-11-05', '07484 Maria Divide Suite 931
Andersonmouth, DC 43399', 0.88),
(215, 'Colleen', 'Elliott', 'qlang@example.net', '928.267.0686x029', '1971-05-17', '6100 Tyler Land
North Shawn, LA 73942', 0.36),
(216, 'Melissa', 'Caldwell', 'fgutierrez@example.com', '(315)967-3731', '2003-01-28', '813 Amanda Centers Suite 680
Angelaborough, NH 33196', 0.29),
(217, 'Alex', 'Frank', 'jessicawilliams@example.org', '310-325-0827', '1978-04-04', '985 Turner Ridges Apt. 454
East Kevin, KS 00867', 0.8),
(218, 'Cody', 'Obrien', 'debrapruitt@example.net', '491.740.3001', '1980-12-28', '8612 Blake Village Apt. 693
Hicksfurt, NH 17015', 0.24),
(219, 'Charles', 'Barnes', 'annette83@example.org', '266-404-2767x357', '1960-05-12', '201 Rebecca Cliff Suite 938
New Jennifer, ND 78374', 0.79),
(220, 'Christine', 'Jones', 'jennifer97@example.com', '(386)541-8264x57547', '1998-08-06', '38549 Grimes Springs Suite 309
Lake Christopherborough, MH 08644', 0.24),
(221, 'Sara', 'Santana', 'crystalkennedy@example.com', '9417953707', '1955-07-05', '073 Osborne Run
West Patrick, ME 15605', 0.37),
(222, 'Kimberly', 'Clark', 'rowlandjacob@example.com', '001-864-615-9620', '1978-08-28', '96268 Ramirez Lane
Fordport, NC 97278', 0.8),
(223, 'Andrew', 'Solis', 'theresa27@example.com', '(761)945-3323x7264', '2001-05-12', '64589 Briggs Lake
Lopezmouth, MS 37883', 0.98),
(224, 'Christopher', 'James', 'nwilliams@example.org', '001-544-433-2619', '1992-09-22', '490 Castro Forest
South John, PA 82078', 0.78),
(225, 'Melanie', 'Clayton', 'wowens@example.net', '+1-608-675-7428x405', '1961-02-13', '258 Matthew River Suite 242
West Frankburgh, WI 86469', 0.21),
(226, 'Sean', 'Brooks', 'uhoover@example.net', '671.222.9544', '1964-11-16', '5567 Jesse Trace
New Larryland, LA 85919', 0.44),
(227, 'Michael', 'Peters', 'robertchung@example.com', '+1-850-375-5842x028', '1960-11-19', '4474 Christopher Drive
Kevinton, MN 93389', 0.88),
(228, 'Tina', 'Pearson', 'ecase@example.net', '001-606-341-1846x671', '1988-09-09', '07505 Adam Manor
South Joan, WI 72209', 0.94),
(229, 'Cindy', 'Coleman', 'padillapaul@example.com', '304.663.1801', '1997-10-04', '84392 Victoria Tunnel Apt. 154
Roberttown, VA 54883', 0.7),
(230, 'Katherine', 'Wilcox', 'olivermartha@example.org', '(596)689-0708', '2004-04-10', '471 Amy Track Suite 357
Jasonport, CA 92155', 0.88),
(231, 'Meghan', 'Soto', 'clinton86@example.com', '6004828647', '1977-04-01', '2459 Victoria Track
New Tyler, NE 15780', 0.39),
(232, 'Mark', 'Long', 'alvin36@example.org', '815-629-1984', '1986-07-01', '278 Mitchell Hill
West Vincentburgh, NE 73177', 0.97),
(233, 'Nicole', 'Dixon', 'michellepalmer@example.net', '(767)670-1037x9339', '1979-05-05', '21181 Christopher Place Suite 515
Richardmouth, NE 33431', 0.2),
(234, 'Allison', 'Jones', 'avega@example.com', '+1-886-773-0504x2390', '2003-02-26', '97770 Allison Street Apt. 013
East Markberg, ME 83411', 0.62),
(235, 'Melissa', 'Ramirez', 'moorejohnny@example.org', '(326)350-1748x06354', '1975-06-18', '8753 Martin Underpass Suite 991
Westshire, WV 62948', 0.38),
(236, 'Melissa', 'Parker', 'amanda18@example.net', '6039184041', '1983-04-22', '7869 Mitchell Lodge Apt. 141
New Teresa, IN 17772', 0.5),
(237, 'Patricia', 'Miller', 'shannonwilliams@example.com', '903-410-7699x6409', '1995-11-02', '30344 Craig Expressway
New Aliciaside, AL 66826', 0.77),
(238, 'Nicholas', 'Page', 'jennysnyder@example.org', '783-240-8696', '1961-09-17', '871 James Squares
Angelicaberg, AK 21913', 0.46),
(239, 'Jose', 'Shepard', 'robertstamara@example.org', '573-385-2252x85055', '1989-01-19', '970 Bradley Fords Apt. 552
South Lance, RI 83510', 0.68),
(240, 'Emily', 'Gentry', 'cmcintosh@example.org', '(796)388-3139', '1964-08-05', 'PSC 9874, Box 9413
APO AE 70627', 0.77),
(241, 'Amber', 'Johnson', 'cherylphillips@example.net', '(712)608-8873', '1973-06-08', '9270 Kristen Wells Suite 430
Lake Stacy, AR 43320', 0.71),
(242, 'Dakota', 'Banks', 'amyluna@example.net', '+1-702-707-1223x8842', '1992-06-20', '2114 Graham Union
Strongstad, KS 59453', 0.67),
(243, 'Vanessa', 'Castro', 'khall@example.org', '(911)673-6541', '1957-02-17', '94519 Ashley Dale
Tamarashire, ME 30243', 0.67),
(244, 'Maria', 'Smith', 'kimberly44@example.net', '(920)422-3584x63923', '1983-01-22', '364 Brian Rest
Lisaton, NY 85078', 0.23),
(245, 'Rebecca', 'Murphy', 'angelabolton@example.org', '874.975.3971x15874', '1999-12-02', '5858 Danielle Valleys Suite 228
Jacquelineberg, GU 08027', 0.99),
(246, 'Sandra', 'Bailey', 'jmyers@example.net', '426-697-4031x3956', '1969-08-30', 'PSC 0571, Box 0981
APO AP 94763', 0.69),
(247, 'Tyrone', 'Newman', 'ewright@example.net', '610.716.7537x10347', '1961-11-22', '31880 Baker Square
South Christinabury, MS 10493', 0.99),
(248, 'Lance', 'Duncan', 'sherri50@example.org', '904-937-4975x20385', '1999-03-03', '3506 Andrew Common
Patrickburgh, OK 10483', 0.69),
(249, 'Jeffrey', 'Clark', 'garrettjohn@example.org', '+1-226-341-4134x944', '1960-01-07', '2636 Anderson Springs Suite 380
Marymouth, DC 92276', 0.45),
(250, 'Jason', 'Fox', 'james53@example.net', '414.613.6385x62032', '1986-10-30', '692 Weber Loaf Apt. 199
Nguyenberg, WV 49892', 0.14),
(251, 'Steven', 'Herrera', 'brentfrye@example.com', '(530)309-7667x11222', '1971-11-20', '6410 Landry Tunnel
West Carl, AR 89826', 0.25),
(252, 'Melissa', 'Sexton', 'garciaanthony@example.org', '688.335.2148x390', '2008-01-17', '493 Jonathan Ville
North Jacquelinehaven, LA 23232', 0.56),
(253, 'Kimberly', 'Jenkins', 'dianathomas@example.org', '8334554238', '1995-07-24', '64701 Rachel Curve Suite 500
South Ianmouth, VT 98507', 0.69),
(254, 'William', 'Gordon', 'istone@example.com', '962-494-9316x5292', '1970-12-25', 'Unit 0966 Box 1653
DPO AA 17720', 0.35),
(255, 'Julia', 'Key', 'sramsey@example.com', '001-912-241-6551x279', '1990-06-24', 'PSC 7605, Box 3324
APO AE 16739', 0.72),
(256, 'Julia', 'Tanner', 'scallahan@example.com', '258.639.7665', '1985-01-12', 'PSC 5222, Box 9136
APO AE 92460', 0.34),
(257, 'Kimberly', 'Smith', 'omullins@example.net', '001-682-480-0354x532', '1996-06-19', '2120 Fernandez Road
New Debraville, OH 81415', 0.52),
(258, 'Jason', 'Myers', 'williamscolton@example.net', '267.504.3194x137', '1981-10-10', '98201 William Hollow
Michaelfort, MP 68229', 0.82),
(259, 'Heather', 'Morgan', 'jennifer18@example.org', '849.674.2890', '1959-10-16', '253 George Groves Suite 433
Brianfurt, FL 38157', 0.78),
(260, 'Mariah', 'Le', 'nlopez@example.net', '862-307-3055', '1961-05-18', '73476 Estrada Spur Suite 531
Port James, MH 33791', 0.58),
(261, 'Kimberly', 'Ramos', 'melissaburton@example.org', '001-378-366-1702x772', '1962-10-06', '1710 Ian Summit
Lake Tylermouth, PA 16777', 0.49),
(262, 'Laura', 'Dixon', 'tammyperez@example.com', '248.651.2569', '2004-06-25', '9989 Ariel Gateway
East Samantha, HI 24381', 0.28),
(263, 'Robert', 'Miller', 'roycarrie@example.com', '(696)585-6528', '1985-12-05', '802 Small Land Apt. 675
West Samuelshire, ME 04404', 0.91),
(264, 'Emily', 'Alexander', 'woodronald@example.net', '213.232.2160', '1984-01-04', 'PSC 1117, Box 7758
APO AE 92314', 0.3),
(265, 'Rebecca', 'Reed', 'zhuang@example.net', '400.965.9519x87338', '1999-06-23', '4021 Young Roads
Elijahmouth, ND 34210', 0.7),
(266, 'Steven', 'Hahn', 'nortonmelanie@example.com', '+1-956-733-9958x3355', '1982-11-04', '617 William Mill Suite 925
East Corey, MH 30138', 0.96),
(267, 'Joshua', 'Moore', 'samantha91@example.org', '+1-944-365-1647x6872', '1985-05-26', '4599 Jonathan Land Apt. 875
Hunterhaven, RI 49657', 0.16),
(268, 'Sarah', 'Barker', 'brandi82@example.net', '001-736-887-7132x629', '1955-03-12', '3257 Rhonda Canyon
Robertland, AK 09941', 0.43),
(269, 'Alan', 'Bradshaw', 'perezjuan@example.com', '6006956041', '1966-10-13', '3936 Clark Streets
New Jefferytown, NC 90403', 0.39),
(270, 'James', 'Morgan', 'tlittle@example.org', '001-670-279-4979', '1975-11-26', '3965 Richmond Hill
East Diana, NJ 12498', 0.53),
(271, 'Jacqueline', 'Porter', 'kmccarthy@example.org', '492.792.3059x78510', '2002-04-09', '37531 Cox Land
South Kyle, WA 02328', 0.19),
(272, 'Tina', 'Mays', 'jonesnicole@example.net', '(851)703-0096', '1988-11-20', '81209 Hannah Stravenue Suite 517
Johnsonfurt, MN 94322', 0.27),
(273, 'Laurie', 'Garcia', 'clarknicole@example.net', '(866)292-7745', '2001-02-05', '99490 Johnson Ridge
New Amandatown, HI 75086', 0.97),
(274, 'William', 'Wheeler', 'qgutierrez@example.com', '(658)304-7971x70497', '1977-10-28', '184 Lance Stravenue Apt. 655
Smithland, AK 78734', 0.39),
(275, 'Christopher', 'Jenkins', 'santoschristie@example.net', '376.427.3036x80846', '1994-05-23', '57424 Bright Forks Apt. 489
Yorkside, WA 66867', 0.77),
(276, 'Debra', 'Stewart', 'jacobbaker@example.net', '823-551-8689', '1961-12-14', '549 Cole Rapid Apt. 525
Ramirezhaven, MI 17626', 0.6),
(277, 'Laura', 'Anderson', 'earlgarcia@example.org', '648-642-3048x823', '1985-03-01', '139 Tina Turnpike
Whitneytown, MT 93108', 0.46),
(278, 'Robert', 'Ramirez', 'joshua65@example.org', '5573553511', '2008-02-14', '6128 Nicole Roads
Shawfurt, IN 92201', 0.89),
(279, 'Amy', 'Jones', 'kwatson@example.net', '338-835-6475', '1992-08-26', '499 Cassandra Green
Davidland, WY 45969', 0.71),
(280, 'Jill', 'Knapp', 'rmartinez@example.com', '(309)551-6809', '1969-07-20', '0645 Heather Burg
West Curtisstad, NC 05666', 0.59),
(281, 'Roberta', 'Burch', 'megan36@example.net', '654.488.0325x1407', '1987-10-21', '973 Santiago Drives
West Rachelfurt, WA 89985', 0.87),
(282, 'Cody', 'Hicks', 'victorlamb@example.org', '(637)515-0913x62954', '1969-07-10', '066 Mcguire Hollow Suite 886
West Jeffrey, VA 39700', 0.23),
(283, 'Kenneth', 'Gonzalez', 'aingram@example.com', '975-564-5658', '1974-12-06', '495 Ann Lane
Hughesbury, CO 97458', 0.45),
(284, 'Cynthia', 'Chang', 'andersonjoseph@example.com', '001-288-958-0402x994', '1956-09-01', '718 Michael Village Apt. 157
Patrickview, TN 14411', 0.81),
(285, 'Todd', 'Lamb', 'cphelps@example.net', '845.242.1703x2655', '1980-01-30', '79747 Mikayla Light Suite 113
South Morgan, FM 32029', 0.24),
(286, 'Emily', 'Gibson', 'alicia38@example.net', '+1-724-615-0748x2462', '1992-09-22', '9845 Paul Union Apt. 606
Jerrychester, ID 53437', 0.22),
(287, 'Jessica', 'Willis', 'gbryant@example.com', '(662)450-6729x65678', '1967-03-08', '0435 Cassandra Prairie
Port Melissa, MD 85127', 0.55),
(288, 'Jacob', 'Duran', 'brettreed@example.net', '(472)673-0551x68226', '1988-08-23', '37958 King Causeway Apt. 611
Calebton, NE 76101', 0.12),
(289, 'Kathleen', 'Robinson', 'kristinesmith@example.org', '309-487-8829', '1960-11-30', '9160 Jill Canyon Suite 583
Monicaburgh, PR 70401', 0.53),
(290, 'Ronnie', 'Pierce', 'adkinskevin@example.net', '227.248.2313', '1982-12-01', '2431 Mccoy Drive
West Justin, NJ 79007', 0.39),
(291, 'Melissa', 'Ramsey', 'alexandra77@example.com', '001-515-599-4084x335', '1979-04-21', '15823 Donna Point
Kimside, DC 31052', 0.28),
(292, 'Holly', 'King', 'lovekevin@example.com', '+1-221-393-7676x099', '1965-02-27', '69299 Rivera Branch
New Karenmouth, OK 15252', 0.96),
(293, 'Brian', 'Turner', 'pgonzalez@example.com', '001-981-612-5232x946', '1980-10-09', '6817 Davis Common Apt. 489
South Christopherton, MP 67083', 0.16),
(294, 'Benjamin', 'Lynch', 'smithbrooke@example.net', '703-534-8542', '1992-10-07', '9290 Jennifer Crossing Suite 313
North Gailstad, TX 99943', 0.28),
(295, 'Dakota', 'Black', 'darmstrong@example.com', '001-412-276-8411', '1993-04-30', '4188 Roberts Station
Aaronville, PW 32913', 0.41),
(296, 'Margaret', 'Perez', 'ldavis@example.org', '(918)711-3992x0557', '1976-07-11', 'PSC 1442, Box 3143
APO AE 00664', 0.21),
(297, 'Chase', 'House', 'justin71@example.com', '(597)773-7316x6825', '1957-04-21', '539 Walker Street Suite 654
Stanleychester, DE 87554', 0.64),
(298, 'Jonathan', 'Hoover', 'jessica95@example.net', '529.928.9810', '1998-04-02', '19720 Cruz Divide
Port Cynthia, CA 18257', 0.16),
(299, 'Christopher', 'Clark', 'msmith@example.org', '001-566-306-0415x250', '1968-05-18', '0868 Caroline Lakes
West Brian, VT 83883', 0.48),
(300, 'Dustin', 'Martinez', 'jenniferturner@example.org', '001-975-768-6878x109', '1969-11-13', '97675 Shea Tunnel Suite 756
Lake Christopher, MD 34227', 0.7),
(301, 'Jeremy', 'Rios', 'potterjuan@example.org', '238.376.6374x1045', '1984-07-12', '44389 Anderson Flat
Port Jackfort, NE 28486', 0.31),
(302, 'Kyle', 'Ryan', 'aaronskinner@example.com', '001-495-880-9008x883', '1961-10-18', '493 Anthony Ranch Apt. 752
East Jackchester, IL 23250', 0.86),
(303, 'Jamie', 'Odom', 'watkinscameron@example.net', '527.577.2143', '1976-01-16', '309 Cole Springs
East Jennaside, FL 91936', 0.3),
(304, 'Jonathan', 'Adams', 'hahnemily@example.org', '+1-720-699-0176', '1976-03-14', '50015 Taylor Plaza
East Kristen, DC 09185', 0.85),
(305, 'Laura', 'Jennings', 'katherine00@example.org', '+1-269-997-6553x7963', '1997-12-15', '08792 Karen Island Apt. 318
West Jason, WA 41113', 0.39),
(306, 'Jesus', 'Hernandez', 'rmclaughlin@example.org', '2587487988', '1967-04-03', 'Unit 7481 Box 1256
DPO AE 18940', 0.23),
(307, 'Derrick', 'Marks', 'oskinner@example.net', '+1-279-492-7181', '1979-10-08', '0977 Theresa Forest Suite 568
Rodriguezfort, AS 27287', 0.24),
(308, 'Gabrielle', 'Smith', 'ronald75@example.com', '7724540779', '1959-06-24', '29191 Armstrong Curve
West Oliviashire, MN 89833', 0.33),
(309, 'Nicholas', 'Wood', 'samuel17@example.net', '859.683.3771x975', '2000-02-05', '851 Michael Meadows Apt. 211
North Christopherhaven, TX 41520', 0.46),
(310, 'Anthony', 'Nelson', 'ndixon@example.org', '894-310-5414x595', '1977-02-15', '175 Roman Road
South Johnburgh, FL 48345', 0.71),
(311, 'Robert', 'Ramirez', 'kevinkent@example.net', '001-423-220-7208x022', '2002-08-09', '82574 Jacobs Oval
Teresaburgh, MA 58242', 0.68),
(312, 'Andrea', 'Wilcox', 'kelly98@example.net', '733.988.4400x7563', '2007-04-17', 'PSC 9566, Box 4476
APO AA 23728', 0.73),
(313, 'Alex', 'Schmitt', 'alyssawiley@example.com', '+1-688-677-2448x4708', '1976-08-09', 'Unit 5361 Box 4584
DPO AA 08228', 0.45),
(314, 'Susan', 'Sanford', 'wattselizabeth@example.com', '2722742803', '1977-03-03', '154 David Circle Suite 432
Port Thomasfurt, MO 58921', 0.68),
(315, 'Renee', 'Green', 'ndominguez@example.org', '3499517863', '1972-03-16', '090 Todd Springs Suite 830
New Debraview, IL 21029', 0.33),
(316, 'Travis', 'Smith', 'dfritz@example.net', '(994)957-8065x87383', '1969-06-25', '991 Romero Haven Apt. 188
Walkerhaven, UT 48763', 0.27),
(317, 'Tracy', 'Barnett', 'shannonthompson@example.org', '001-964-606-8858x390', '2002-01-28', '72855 Richardson Mission Apt. 776
Melissaland, CA 47099', 0.1),
(318, 'Justin', 'Scott', 'sandramccormick@example.net', '+1-681-344-4434x3397', '1972-05-17', 'Unit 2909 Box 3482
DPO AP 15311', 0.93),
(319, 'James', 'Sandoval', 'bradshawrobert@example.org', '001-542-251-9713x211', '1979-09-09', '61885 Darrell Ridges
Barbaraberg, TX 02579', 0.45),
(320, 'Peter', 'Shea', 'nataliecastaneda@example.org', '001-717-212-5020x909', '1988-05-30', '7564 Wood Estate Suite 141
North Haroldland, AK 25799', 0.81),
(321, 'Alexandra', 'Harris', 'egentry@example.net', '6617256930', '1958-03-09', '673 Michelle Squares
South Manuelfort, NE 38300', 0.55),
(322, 'Joseph', 'Turner', 'timothykim@example.net', '(664)362-4599x246', '1955-12-06', '4506 Erin Spring Suite 750
Brittneychester, SC 51284', 0.98),
(323, 'Brittany', 'Miles', 'sanderson@example.net', '001-802-715-7026', '1972-10-12', '4968 Victoria Ramp Apt. 657
Thomasport, PW 27340', 0.23),
(324, 'Mark', 'Brown', 'colemanmeghan@example.com', '226-293-7927x214', '1961-06-17', '534 Moore Valley Apt. 804
East James, MD 34119', 0.46),
(325, 'Michael', 'Li', 'millerrobert@example.com', '380-306-9251x639', '1966-01-28', '225 Duane Lodge Apt. 268
Brandonview, SC 58982', 0.81),
(326, 'Steve', 'Flores', 'laurensteele@example.org', '333.382.4313', '1993-10-11', '482 Haley Canyon Suite 059
Jameshaven, CT 85102', 0.97),
(327, 'Jonathan', 'Howard', 'jamie04@example.net', '+1-247-209-1850x3365', '1962-03-30', 'Unit 6323 Box 7960
DPO AA 86974', 0.51),
(328, 'Misty', 'Dawson', 'kyle86@example.net', '585-961-7475x25574', '1982-08-27', '60725 Allison Courts
Claudiaberg, DE 79862', 0.11),
(329, 'Katherine', 'Wagner', 'anapineda@example.com', '001-924-779-0336', '1986-10-02', '64118 Ruiz Row Apt. 769
Peckchester, NY 48922', 0.33),
(330, 'Ian', 'Bell', 'hharris@example.org', '818.891.9166x80915', '1969-11-30', 'PSC 7140, Box 5496
APO AA 83405', 0.73),
(331, 'Susan', 'Erickson', 'bellkristin@example.com', '(803)868-6453x15549', '1960-03-23', '16691 Laura Bridge Suite 796
East Joanna, MD 24773', 0.12),
(332, 'Ryan', 'Miller', 'johnprice@example.net', '6943163409', '1970-09-20', '35636 Amy Corner
East Jamesfurt, OR 15382', 0.64),
(333, 'Alexander', 'Hodges', 'williamrobinson@example.net', '6649335886', '1956-04-19', '17061 Chavez Summit
Gibsonside, MP 76814', 0.65),
(334, 'April', 'Johnson', 'ashley92@example.com', '803.971.6751', '1984-09-04', '937 Kevin Points Suite 840
East Laura, KY 55797', 0.5),
(335, 'Herbert', 'Burke', 'sonyabrown@example.com', '+1-267-669-3781x1405', '1976-08-31', '5162 Miller Creek Suite 754
Toddville, AL 73871', 0.36),
(336, 'Courtney', 'Barnes', 'carlsonjason@example.org', '+1-875-911-7275', '1981-12-05', '268 Natasha Park
New Candiceshire, MP 02404', 0.85),
(337, 'John', 'Smith', 'johnsonthomas@example.net', '468.920.9283x9276', '1971-05-04', '3967 Howell Hill Apt. 874
Arnoldhaven, PW 86458', 0.73),
(338, 'Michele', 'Brown', 'davissean@example.com', '7592983581', '1967-10-17', '13187 Levine Mills
South Monica, GU 59014', 0.36),
(339, 'Luis', 'Mendoza', 'scottmary@example.net', '(993)524-7965x7207', '1998-01-02', '75498 Jacobs Junctions Suite 832
Margaretburgh, MI 30396', 0.1),
(340, 'Anthony', 'Beard', 'ahenderson@example.org', '(981)489-6535x88303', '2000-06-20', '193 Olson Grove
Lake Coreyhaven, MO 87845', 0.88),
(341, 'James', 'Savage', 'jennifer88@example.org', '+1-282-819-2904', '1961-12-22', '2576 Emily Views
East Kellie, SC 36598', 0.13),
(342, 'Michael', 'Miller', 'bdavis@example.net', '445-933-8367x18809', '2006-01-17', '60774 Patton Circles Apt. 081
New Craig, NY 61601', 0.65),
(343, 'Michelle', 'Miller', 'patrickfarmer@example.net', '240-999-2201x3142', '1959-02-09', '89203 Brooke Lake
Travisshire, OK 68280', 0.7),
(344, 'Stephanie', 'Christian', 'samanthasaunders@example.org', '001-765-780-3701x657', '1991-08-04', '2030 Kevin Mills
Lucasborough, MT 54913', 0.59),
(345, 'Krista', 'Smith', 'loganmelissa@example.org', '(491)266-5394x2898', '1957-01-21', '368 Gonzalez Flat Apt. 652
Brianborough, SC 15956', 0.64),
(346, 'Joshua', 'Thompson', 'vallen@example.org', '+1-280-702-2398x3161', '1990-04-17', '783 James Row Suite 075
Carrollton, AS 83173', 0.61),
(347, 'Gregory', 'Allison', 'zoekeller@example.org', '440-459-8342x863', '1995-10-04', '016 Jennifer Creek
Jacksonburgh, LA 52271', 0.81),
(348, 'Julie', 'Gonzalez', 'tammy35@example.org', '222.614.7400', '1986-03-30', '67543 Alvarez Mews Suite 407
Mitchellside, OK 77555', 0.52),
(349, 'Wayne', 'Smith', 'rdavis@example.org', '505-524-5984x619', '1994-06-08', '86295 Adams Expressway
New Stephaniemouth, TN 67729', 0.74),
(350, 'Jessica', 'Wyatt', 'tiffanyhart@example.org', '(875)974-8256x116', '1962-02-15', '687 Leblanc Extension
Emilyshire, CT 36813', 0.38),
(351, 'Madison', 'Harrison', 'pattersonbrandon@example.org', '001-720-974-8637x721', '1955-07-17', '787 Parker Alley Suite 765
Lake Adrianmouth, ME 80121', 0.19),
(352, 'Troy', 'Wilson', 'sbrown@example.net', '(794)525-5301', '1969-08-13', '32528 Heidi Motorway Apt. 744
East Brian, OH 61811', 0.6),
(353, 'Nicole', 'Martin', 'jensenpatricia@example.com', '390-879-8066x16931', '1959-02-18', '37788 Andrea Mission Apt. 166
North Kevin, AR 42870', 0.17),
(354, 'Morgan', 'Wheeler', 'rosarioamanda@example.org', '+1-238-920-7847', '1997-10-10', '6006 Salinas Isle
Carolchester, OR 39556', 0.22),
(355, 'Kenneth', 'Jones', 'mphillips@example.org', '+1-858-300-2617x1454', '1981-03-25', '324 Jones Trail Apt. 461
Mackenziestad, OR 19770', 0.56),
(356, 'George', 'Mccullough', 'ryanfrench@example.org', '(243)995-7083x3592', '1991-03-01', '6653 Lisa Turnpike Apt. 098
Harrisonfort, SC 12848', 0.63),
(357, 'Joshua', 'Fisher', 'greenesherri@example.net', '266-367-8663', '1991-12-22', '6991 Richards Shores
New Gailborough, MO 09065', 0.96),
(358, 'Devin', 'Ortiz', 'smoore@example.com', '584-212-8141x6027', '1966-07-02', '5360 Monroe Junctions Suite 015
North David, MT 01012', 0.7),
(359, 'Cheryl', 'Stewart', 'troy00@example.org', '001-528-593-2979', '1991-01-12', '1362 Hernandez Walk Suite 739
Johnfurt, SD 98450', 0.11),
(360, 'Michael', 'Hobbs', 'janetanderson@example.org', '364-427-3894', '2007-11-14', '4045 Jensen Walks
Rhodesstad, TX 76326', 0.92),
(361, 'Ashley', 'Rodriguez', 'wsmith@example.com', '539-908-0700', '1989-12-04', '960 Jenna Camp Suite 746
Ballhaven, VT 13863', 0.18),
(362, 'Hannah', 'Mitchell', 'kellerrichard@example.com', '940-493-6377', '1966-08-14', '400 Mark Divide Apt. 986
Martinview, SC 87893', 0.44),
(363, 'Jillian', 'Morris', 'williamsscott@example.org', '681-621-8249', '1983-02-26', '32264 Peter Green Suite 682
Lisaville, DC 64193', 0.73),
(364, 'Savannah', 'Adams', 'sydneypatterson@example.org', '581.980.1847x0411', '2004-08-05', '54239 Stephanie Turnpike
Teresaview, SD 76819', 0.48),
(365, 'Brittany', 'Rice', 'fernandezamy@example.com', '558-302-6222x1779', '1995-06-19', '1009 Austin Dam Apt. 077
Amandaside, CA 30551', 0.26),
(366, 'Glenn', 'Gray', 'rodriguezronald@example.net', '(662)931-4837x83562', '1979-02-24', '567 Jensen Tunnel
Lake Manuel, RI 94715', 0.84),
(367, 'Mark', 'Martinez', 'mia43@example.com', '001-664-268-8399', '2002-03-29', '7920 Barry Springs Suite 665
Lake Bradley, RI 95514', 0.81),
(368, 'Lisa', 'Schroeder', 'raguirre@example.org', '7186249594', '1986-11-14', '3715 Lee Mews
Hayeshaven, TN 33438', 0.61),
(369, 'Brady', 'Calderon', 'kirk37@example.com', '001-840-675-4601x146', '1969-03-19', '9426 Smith Circle Apt. 129
New Jose, WI 22790', 0.54),
(370, 'Laura', 'Short', 'alexis02@example.com', '8105057713', '1963-02-14', '3872 King Via Apt. 790
Davidfurt, MP 70491', 0.46),
(371, 'John', 'Cooper', 'angel56@example.org', '907.866.1590', '1980-06-18', '5761 Amanda Ford
West Kevin, MI 75813', 0.59),
(372, 'Robert', 'Castro', 'baxtershelby@example.org', '768-292-8668', '2003-10-06', '777 Andrew River
Stricklandtown, UT 33022', 0.43),
(373, 'Dustin', 'Olson', 'mccoyapril@example.com', '+1-932-962-9528x3131', '2002-08-23', '479 Ryan Overpass Suite 397
North Ann, VA 27696', 0.99),
(374, 'Michelle', 'Lawrence', 'morenolaura@example.org', '001-716-881-6619x386', '1991-08-09', '92202 Kathleen Port Suite 817
Michaeltown, ME 20668', 0.35),
(375, 'James', 'Hall', 'nharrington@example.org', '468-237-3227x51554', '1983-03-14', '84790 Miller Mill
Lake Jon, LA 62945', 0.68),
(376, 'Melinda', 'Weber', 'wchan@example.com', '(927)813-1917x05490', '1966-02-28', '1889 Young Park
South Julie, MH 66592', 0.52),
(377, 'Patricia', 'Hanson', 'williamhowell@example.net', '001-695-506-2095x063', '1956-03-09', '950 Marco Drive
South Luis, NC 92055', 0.78),
(378, 'Donna', 'Leonard', 'hcole@example.net', '+1-400-800-3496', '1965-07-19', '126 Jeremy Estate Apt. 032
Hallfort, OH 38906', 0.12),
(379, 'Courtney', 'Evans', 'morgan98@example.com', '313-487-0281', '1993-08-18', '189 Fox Mill Apt. 622
South Wayne, IA 25587', 0.35),
(380, 'Mary', 'Johnson', 'victoriajohnson@example.net', '913-458-2013x9448', '2002-12-16', '597 Burton Tunnel Apt. 403
Carterchester, TN 93600', 0.31),
(381, 'Brian', 'Salazar', 'katherinereynolds@example.net', '777-264-7694x12306', '1974-03-03', '2658 Hill Green Apt. 369
West Kimberly, AS 01546', 0.85),
(382, 'Brittany', 'Martinez', 'austincoffey@example.com', '(866)608-7627', '1955-03-31', '84147 Guzman Terrace
West Cassandramouth, MD 58373', 0.6),
(383, 'Anita', 'Reynolds', 'marksandoval@example.org', '595-988-6923', '1981-11-25', '8442 Ryan Estates Apt. 052
New Roberthaven, OH 62901', 0.38),
(384, 'Autumn', 'Camacho', 'garciatanya@example.org', '(676)594-3468x7326', '1960-04-14', '48656 Shelby Plains
Garciaport, CA 14190', 0.5),
(385, 'Michael', 'Webster', 'hlevine@example.com', '612-594-8486x7124', '1955-12-08', '71790 Robert Dale Suite 880
Nelsonport, GA 71531', 0.57),
(386, 'Sherry', 'Parker', 'monica76@example.net', '001-486-571-1012', '2003-08-17', '018 Garza Shores Apt. 971
Gloriastad, AL 16801', 0.85),
(387, 'Nathan', 'Grant', 'brandy81@example.net', '+1-941-682-3055x3036', '1987-05-29', '7531 Villarreal Mountain
North Davidfort, GU 16910', 0.58),
(388, 'Zachary', 'Campos', 'ccoffey@example.net', '949.436.8849x78606', '1966-10-18', '56897 Anderson Street
Carlborough, VT 31759', 0.78),
(389, 'Joshua', 'Dean', 'blackburnsharon@example.com', '+1-598-217-8121', '1976-10-11', '597 Perez Extensions
North Jeanette, SD 86413', 0.13),
(390, 'Philip', 'Baker', 'nhogan@example.org', '(417)334-7744x329', '2004-05-24', '8636 Darren Court
Nicoleton, OK 45414', 0.18),
(391, 'Vanessa', 'Rhodes', 'brittanysolomon@example.org', '777.616.6846x492', '1972-04-12', '46922 Craig Roads
South Brian, NV 82379', 0.27),
(392, 'Jacob', 'Price', 'savannah78@example.org', '904-786-3041x505', '2001-06-19', '939 Steven River
West Vincentbury, LA 76464', 0.97),
(393, 'Alicia', 'Clarke', 'keithdickson@example.com', '8066273883', '1986-04-29', '2548 Garner Isle Apt. 787
Justinshire, HI 64089', 0.74),
(394, 'Stephanie', 'White', 'glenda25@example.net', '001-940-256-8854x163', '1992-02-15', '2124 Michael Trace
Simpsonton, IL 64547', 0.75),
(395, 'John', 'Foster', 'rwilson@example.org', '6428137465', '1998-01-07', '4702 Paul Parkway Apt. 003
South Amandaburgh, VI 07970', 0.62),
(396, 'Joseph', 'Valdez', 'ievans@example.com', '+1-310-880-2152', '1983-03-09', '30959 Lawrence Well
North Steven, VT 05580', 0.16),
(397, 'Joann', 'Chaney', 'kellymorales@example.org', '937.919.6415', '1997-11-23', '702 Green Branch
Grossland, GA 86597', 0.17),
(398, 'Steven', 'Miller', 'lynn11@example.org', '001-733-434-9634x235', '1976-06-17', '79349 Smith Throughway Apt. 057
Diazton, UT 90458', 0.98),
(399, 'Alyssa', 'Brown', 'richardwarner@example.org', '001-455-859-1083', '1966-01-17', '72860 Mary Court
Higginsmouth, CT 38420', 0.71),
(400, 'Stephanie', 'Brown', 'williamsjames@example.net', '(839)483-9947x91365', '1984-01-19', '94879 Dana Light
Brookeburgh, OR 52148', 0.11),
(401, 'Amanda', 'Chambers', 'jasonmatthews@example.net', '993-717-6530', '1983-06-10', '492 Tristan Village
Johnsonberg, WY 39483', 0.85),
(402, 'Matthew', 'Skinner', 'dbryant@example.net', '+1-652-682-1341', '1997-11-21', '32831 Wilcox Ramp Apt. 985
South Brandonmouth, NY 58240', 0.38),
(403, 'Daniel', 'Jones', 'lawrencealyssa@example.com', '(514)777-0806', '1956-05-10', '89242 Parker Avenue Suite 549
Woodshire, MN 80274', 0.39),
(404, 'Charles', 'Yang', 'hwilliams@example.net', '001-386-479-0875x241', '1959-10-14', '3722 Lauren Ford
Douglaschester, MD 22630', 0.67),
(405, 'Gregory', 'Dixon', 'ucarpenter@example.org', '995-680-1133x3082', '1963-03-26', '367 Jessica Spring
Robertville, WI 89716', 0.78),
(406, 'Tara', 'Casey', 'marybeck@example.com', '875.922.5958x53661', '1985-05-01', '284 Melissa Ville Suite 128
Port Nathaniel, MP 45773', 0.37),
(407, 'Karen', 'Clayton', 'gsingh@example.org', '352-609-7975x7784', '2004-07-29', '0638 Chen Trail
Port Charlottechester, MD 15041', 0.56),
(408, 'Jeffrey', 'Navarro', 'fyu@example.com', '698-472-2016', '1994-10-18', 'Unit 3502 Box 8315
DPO AP 72890', 0.4),
(409, 'James', 'Nguyen', 'oliviasanchez@example.org', '001-273-941-3966x315', '1964-09-08', '569 Soto Plaza
North Alexis, NJ 73735', 0.43),
(410, 'Paul', 'Watkins', 'gerald72@example.net', '883.301.4818x15719', '1995-09-29', '498 Odonnell Crest Suite 232
East Brooke, NH 52460', 0.73),
(411, 'Stephanie', 'Boyer', 'melindafreeman@example.com', '4709012163', '1968-05-08', '3116 Mason Dale
West Amanda, MN 15874', 0.45),
(412, 'Jeremiah', 'Webb', 'rogerschristine@example.org', '(287)305-7138', '1971-10-04', '71985 Joshua Mill
New Cassidychester, WV 12910', 0.21),
(413, 'Jaclyn', 'Reilly', 'rkim@example.com', '+1-305-668-2256x6311', '1968-06-29', '76876 Melanie Grove Apt. 686
East Brenda, MA 44950', 0.63),
(414, 'Katherine', 'Davis', 'howardmary@example.net', '001-795-901-5566x155', '1957-12-10', '393 Kevin Unions Suite 794
Stevenmouth, VA 54493', 0.52),
(415, 'Lori', 'Landry', 'patrickjordan@example.org', '(740)714-0713x96732', '1981-01-11', '79369 Heather Canyon
New Christopherstad, WA 08193', 0.71),
(416, 'Christopher', 'Watson', 'ogriffin@example.net', '001-233-548-4113x289', '1991-02-21', '5300 Russell Viaduct
Port Markstad, MD 51844', 0.19),
(417, 'Sara', 'Wang', 'brightmichael@example.org', '229-657-5976x2631', '1965-03-27', 'PSC 2755, Box 1538
APO AP 77233', 0.33),
(418, 'William', 'Morgan', 'wjones@example.net', '870-749-4667x85593', '1975-04-07', '4586 Hubbard Junction
Vazqueztown, NY 77800', 0.2),
(419, 'Walter', 'Lopez', 'lramsey@example.org', '738-218-2411', '1968-10-11', '8676 Larry Corners
Port Danielle, RI 47288', 0.87),
(420, 'Kathleen', 'Bryan', 'kennedyjason@example.net', '001-783-915-5618x762', '1964-10-03', '104 Turner Forest
Morsehaven, GU 85666', 0.84),
(421, 'John', 'Johnston', 'john64@example.com', '448-761-8691', '1990-05-27', '950 Jones Corner
West Randy, LA 72536', 0.81),
(422, 'Dale', 'Thomas', 'yford@example.com', '506-853-2380', '1974-07-12', 'Unit 4153 Box 5364
DPO AE 94441', 0.16),
(423, 'Trevor', 'Williamson', 'youngdavid@example.com', '865.837.3352x941', '1976-10-08', '8962 Tammy Terrace
Raymondburgh, NC 33295', 0.92),
(424, 'David', 'Perry', 'igarcia@example.net', '469.239.4222x9761', '2001-12-06', '3910 Christine Lodge
Heatherborough, IA 51965', 0.74),
(425, 'Rhonda', 'Martin', 'mooreebony@example.com', '917-632-0405', '1995-05-31', '89340 Lee View
North Michaelstad, MA 77984', 0.19),
(426, 'Steven', 'Miller', 'mmerritt@example.org', '206-883-7911x92402', '2002-10-01', '92032 Joann Divide
West Laurie, LA 16957', 0.48),
(427, 'Tonya', 'Boyd', 'davidsoncesar@example.com', '764-209-2317x5679', '2002-03-18', '054 Mark Route Suite 950
North Carmen, AS 44188', 0.24),
(428, 'Sarah', 'Anderson', 'lopezcrystal@example.org', '(768)970-1927', '1984-11-12', '95695 Jensen Trafficway
South Amy, GU 51289', 0.16),
(429, 'Katherine', 'Lane', 'pboyd@example.org', '001-459-690-1382', '1997-05-29', '562 Roberts Creek Apt. 784
West Kennethshire, CT 06665', 0.85),
(430, 'Benjamin', 'Jordan', 'roywalker@example.net', '2604655805', '1970-06-18', '80055 Michelle Loop
Wutown, MT 58416', 0.37),
(431, 'Ethan', 'Thomas', 'brandyphillips@example.net', '(352)492-3411x500', '1976-05-27', '6898 Barry Stravenue Apt. 964
Cathyview, MI 99925', 0.59),
(432, 'Kenneth', 'Davis', 'ocox@example.org', '(795)758-1379', '1958-09-20', 'Unit 9408 Box 4613
DPO AE 58697', 0.88),
(433, 'David', 'Martinez', 'sharonhamilton@example.net', '614-417-0983', '2001-04-19', '58362 Moss Divide
South Tracyburgh, MS 49273', 0.41),
(434, 'Corey', 'Green', 'carlsonjoseph@example.org', '963.220.1140x41439', '1982-03-08', '87965 Lindsey Meadows Suite 880
Lake Stephanie, CA 95826', 0.96),
(435, 'Amanda', 'Tate', 'brownkenneth@example.org', '+1-790-613-8616', '1987-06-30', '5627 Barrett Flats Apt. 428
Douglastown, HI 79080', 0.68),
(436, 'Colleen', 'Roberts', 'mckenziearnold@example.net', '432.608.1944x00698', '1988-01-25', '7085 Liu Port
Aaronchester, IN 06417', 0.6),
(437, 'David', 'Ortega', 'wwilson@example.org', '6344339522', '1955-06-06', '02874 Hill Spur Apt. 583
West Melanie, IA 45957', 0.39),
(438, 'Billy', 'Francis', 'fsalas@example.com', '(583)236-4765x95573', '1998-06-17', '5084 Brown Radial
Port Kayla, IL 23264', 0.32),
(439, 'Robert', 'Osborne', 'alexismitchell@example.com', '(636)785-7318', '1985-06-22', '30973 Larry Lodge Apt. 460
Lake Thomas, OR 04332', 0.55),
(440, 'Jacob', 'Banks', 'johnsonkyle@example.net', '825-491-4949', '1990-01-31', '5512 Jason Cliffs
New William, FM 19264', 0.63),
(441, 'Crystal', 'Mcclure', 'yjohnson@example.org', '320.501.6859x66816', '1961-07-30', '51880 Carla Crossroad
South Nicolebury, CT 19127', 0.82),
(442, 'Megan', 'Bowman', 'perryhunter@example.org', '+1-634-923-5366x9331', '1989-01-12', '7759 Kirk Valley
Lake Nancy, FL 92487', 0.26),
(443, 'Dennis', 'Gray', 'kellyjoshua@example.org', '001-299-612-6407x599', '1959-09-29', 'Unit 4051 Box 7925
DPO AA 19410', 0.92),
(444, 'Laura', 'Nolan', 'tward@example.com', '+1-430-964-2378x2176', '1963-08-10', '63386 Melanie Knolls
North Rebecca, UT 64449', 0.78),
(445, 'Melissa', 'Hall', 'kristen50@example.net', '8656086849', '1991-01-03', '86957 Anderson Well
South Daniel, WY 16939', 0.64),
(446, 'William', 'Fritz', 'wadetanya@example.com', '2887247444', '1961-05-03', '003 Yvonne Glens
East Hannahfort, VT 55222', 0.33),
(447, 'Morgan', 'Reynolds', 'karenhernandez@example.net', '(444)432-3158x842', '2005-03-18', '9393 Deborah Station Apt. 187
Lake Robert, OR 39494', 0.57),
(448, 'Michael', 'Stevens', 'daniel23@example.org', '001-697-550-7621', '1964-01-28', '27738 Long Crest Apt. 404
Kennedyburgh, SD 74385', 0.21),
(449, 'Connie', 'Mckenzie', 'alexpearson@example.org', '927-917-6514', '1973-11-23', '923 Guy Valley
Hicksburgh, KS 84574', 0.19),
(450, 'Brian', 'Mendoza', 'littlejeremy@example.net', '001-628-713-2447x317', '1979-09-29', '312 Leonard Stream Apt. 442
Brendaburgh, IL 95310', 0.95),
(451, 'Amanda', 'Price', 'davidli@example.org', '2427239132', '1999-05-26', 'PSC 5600, Box 3939
APO AP 85260', 0.55),
(452, 'Gary', 'Reyes', 'sandra39@example.net', '(328)222-6080', '1987-02-28', '79343 Parks Extensions Apt. 594
New Carlosview, OR 81061', 0.89),
(453, 'Jordan', 'Zavala', 'rchambers@example.org', '(916)926-0316x75359', '1959-04-27', '8909 Ortega Port
Jeffreyville, MI 48691', 0.25),
(454, 'Veronica', 'Peterson', 'amanda36@example.net', '613.209.9182', '1977-01-13', '73595 Hunter Heights
Seanberg, NJ 67715', 0.55),
(455, 'James', 'Greene', 'joshuaanderson@example.org', '593.715.9741x13685', '1999-10-05', '71916 Justin Terrace Suite 936
Lake Jenniferberg, PA 89556', 0.97),
(456, 'Kelly', 'Soto', 'keith53@example.com', '308.667.0713x14289', '1996-01-17', '4396 Martin Extensions
South Joseburgh, IA 00571', 0.72),
(457, 'Tina', 'Taylor', 'tyler90@example.net', '626.684.2763x672', '1993-06-16', '539 Wade Manors
West Rhonda, RI 57935', 0.37),
(458, 'Robert', 'Madden', 'stacy29@example.org', '(383)745-6726x74483', '2007-02-08', '4870 Mary Underpass
Christopherview, DC 91757', 0.92),
(459, 'Robert', 'Johnson', 'rwebb@example.net', '001-543-506-8802x575', '1958-12-15', '9643 Raymond Meadow
East Robertview, VT 93325', 0.15),
(460, 'Brandy', 'Santos', 'dana70@example.net', '667.954.1597', '1961-11-03', 'Unit 7918 Box 3887
DPO AA 22590', 0.4),
(461, 'Timothy', 'Flores', 'kristinaklein@example.org', '293-897-2228x04523', '1982-08-06', '6207 Julia Drive Suite 752
North Brittneyside, OH 05886', 0.28),
(462, 'Christopher', 'Barton', 'cory81@example.net', '8577843896', '1965-05-05', '1092 Hayes Junctions
Port Douglas, PW 61619', 0.5),
(463, 'Melissa', 'Brown', 'josephjohnson@example.net', '2629242667', '1994-01-14', 'Unit 1272 Box 0707
DPO AE 22419', 0.36),
(464, 'Daniel', 'Vargas', 'terrellbarbara@example.org', '001-533-352-8568x222', '2000-04-16', '617 Rose Island
Port Dannyberg, VI 22580', 0.17),
(465, 'Benjamin', 'Higgins', 'mariamerritt@example.net', '(524)656-7395x4883', '1962-06-18', '8536 Jesse Mount
East Jamestown, TN 53218', 0.19),
(466, 'Clifford', 'Herman', 'dawnpoole@example.org', '2679152462', '1966-06-05', 'PSC 6197, Box 4184
APO AP 63061', 0.7),
(467, 'Jennifer', 'Flores', 'jerrywatson@example.com', '580-396-5027x23104', '1997-05-09', '42489 Nicole Squares Apt. 422
Port Lauraview, KS 73185', 0.72),
(468, 'Bryan', 'Williams', 'amyflynn@example.net', '431.401.2272', '1997-07-10', 'PSC 8110, Box 9331
APO AA 77727', 0.66),
(469, 'Yvette', 'Brown', 'sara40@example.org', '001-739-665-6624', '2006-11-17', '3623 Cameron Spring
Sabrinaburgh, FM 98334', 0.6),
(470, 'Jennifer', 'Le', 'fsimmons@example.org', '715-981-0103x789', '1980-01-01', '92399 Sarah Underpass Suite 972
Angelabury, GA 23668', 0.56),
(471, 'Jeffrey', 'Smith', 'westpatrick@example.net', '+1-218-988-2933', '1994-06-13', '685 Tanner Heights
East Nathaniel, AZ 85332', 0.34),
(472, 'Jacob', 'Green', 'walkerdrew@example.com', '4826884412', '1973-07-26', '8321 Krystal Forges
Kimberlyton, VA 91648', 0.5),
(473, 'Ashley', 'Cortez', 'ramirezyolanda@example.org', '496.427.7374', '1967-03-11', '44445 Burns Keys
Ronaldville, NH 44513', 0.84),
(474, 'Shawn', 'Anderson', 'browndavid@example.org', '673.570.1531', '1990-07-04', '67998 Small Mission
North Marcus, KS 01735', 0.7),
(475, 'Nathan', 'Ryan', 'josephbell@example.org', '+1-365-551-2878x931', '1959-04-09', 'Unit 9096 Box 4893
DPO AA 58930', 0.19),
(476, 'Jessica', 'Hunter', 'breannabrown@example.org', '4297531426', '1960-12-31', '2590 Waters Stream
Lake Paulstad, MA 04874', 0.47),
(477, 'Joshua', 'Martinez', 'jennifercrawford@example.net', '(821)540-7245', '1987-04-23', '464 Jessica Rest
Christinefort, AZ 76951', 0.57),
(478, 'Anthony', 'Jones', 'jeffreyfuller@example.net', '543-892-2585x9242', '1956-07-20', '99405 Dickerson Extension
South Jamestown, NH 69398', 0.12),
(479, 'Samuel', 'Ponce', 'steven57@example.org', '+1-700-876-9832x0931', '1979-08-18', '48252 Diaz Fort Apt. 363
Smithhaven, AL 68848', 0.42),
(480, 'Daniel', 'Ball', 'joel76@example.com', '(846)880-6753', '2007-03-04', '482 Dominique Lodge
Lake Amyhaven, IA 00516', 0.54),
(481, 'Theresa', 'Brewer', 'kelseyhicks@example.org', '+1-761-445-0785x609', '1973-04-30', '043 Parker Forks
Port Meganfurt, CA 42686', 0.78),
(482, 'Shelby', 'Hill', 'uwilkins@example.com', '409-701-5886x0706', '1971-06-01', '37518 Valencia Drive Apt. 631
North Dustin, ID 00802', 0.12),
(483, 'Christopher', 'Castillo', 'donnawhite@example.com', '7482057936', '2002-08-21', '8409 Jordan View
East Barbara, MS 50205', 0.63),
(484, 'Erin', 'Moore', 'roberthendricks@example.org', '797-237-2744x55611', '1997-08-23', '8526 Courtney Burgs
Roweland, NJ 67811', 0.47),
(485, 'Barbara', 'Williamson', 'kthompson@example.com', '6328553606', '1961-08-16', '48420 Valdez Alley Apt. 659
Masonhaven, MH 35855', 0.37),
(486, 'Mikayla', 'Chapman', 'stacy09@example.com', '+1-395-924-3800x6415', '1978-07-20', '41161 Stewart Stream Apt. 359
West Ronald, MH 18373', 0.45),
(487, 'Melissa', 'Torres', 'samantha96@example.org', '001-200-564-5087x125', '2002-05-13', '986 Chris Parks Apt. 008
Joneschester, OR 63114', 0.22),
(488, 'Carly', 'Mccarty', 'obennett@example.com', '656-337-9214x751', '1984-02-23', '560 Wendy Cape
Lake Krystalhaven, SC 45253', 0.72),
(489, 'Michael', 'Pacheco', 'robinsontara@example.com', '437-241-9410x7651', '2004-08-28', 'Unit 9921 Box 8545
DPO AA 87294', 0.22),
(490, 'Michael', 'White', 'imartin@example.net', '+1-803-612-3048x6160', '1994-02-03', '495 Williams Loaf Suite 665
South Marystad, MD 08489', 0.5),
(491, 'Brian', 'Barrett', 'brownpenny@example.org', '+1-736-344-6105x1175', '1991-01-06', '26404 Henderson Ports
Amyville, MP 18791', 1.0),
(492, 'Linda', 'Cameron', 'brianwebster@example.net', '730.512.4295', '1988-02-22', '02034 Kristin Keys
South Tracy, MD 70317', 0.92),
(493, 'Michelle', 'Valencia', 'nicole68@example.com', '567.414.2735', '1974-01-03', '9325 Adams Tunnel Apt. 164
Haynesview, IN 06646', 0.69),
(494, 'Karen', 'Bates', 'bcarr@example.com', '001-392-456-5105', '1998-09-15', '96668 Michael Plain
Nelsonville, WI 68790', 0.97),
(495, 'Ruth', 'Wheeler', 'oelliott@example.net', '(940)832-0435', '1991-04-30', 'Unit 9383 Box 3956
DPO AA 86092', 0.58),
(496, 'Melinda', 'Phillips', 'fdavis@example.net', '402-638-1813', '1971-01-15', '577 Sheila Corner
Beverlyview, FL 04245', 0.14),
(497, 'Laura', 'Garrett', 'jon77@example.org', '(681)535-4725', '1966-05-07', '532 Williams Coves
Port Andrea, MP 94056', 0.11),
(498, 'Jessica', 'Lewis', 'dking@example.net', '601.612.1383', '1999-02-09', '38236 Franklin Spring
South Shannonshire, DE 96868', 0.94),
(499, 'Brittney', 'Hernandez', 'jennifer23@example.com', '(968)475-5001x74007', '1962-06-13', '42798 William Parkways
Henryfort, TN 27753', 0.49),
(500, 'Kristin', 'Velazquez', 'waynestrong@example.net', '6012877236', '1978-08-11', '77231 William Road
South Catherine, ND 01707', 0.79);

-- Insert policies
INSERT INTO policies (policy_number, customer_id, policy_type, start_date, end_date, premium_monthly, coverage_amount, deductible, status) VALUES
('POL00000001', 101, 'Life', '2026-02-08', '2027-02-08', 363.42, 972906.36, 4503.85, 'cancelled'),
('POL00000002', 105, 'Health', '2026-02-11', '2027-02-11', 185.71, 546566.65, 765.91, 'expired'),
('POL00000003', 376, 'Life', '2025-02-19', '2026-02-19', 213.29, 856661.26, 474.64, 'active'),
('POL00000004', 33, 'Life', '2025-11-28', '2026-11-28', 170.85, 326246.63, 2468.49, 'cancelled'),
('POL00000005', 228, 'Life', '2024-08-27', '2025-08-27', 500.74, 618446.39, 3841.64, 'cancelled'),
('POL00000006', 387, 'Auto', '2025-10-30', '2026-10-30', 540.19, 58272.58, 1561.82, 'active'),
('POL00000007', 271, 'Auto', '2024-07-07', '2025-07-07', 623.73, 721183.78, 2858.82, 'active'),
('POL00000008', 38, 'Life', '2024-08-08', '2025-08-08', 296.26, 806573.3, 3899.01, 'cancelled'),
('POL00000009', 114, 'Health', '2025-11-09', '2026-11-09', 493.84, 472443.87, 4087.87, 'active'),
('POL00000010', 206, 'Travel', '2025-12-09', '2026-12-09', 806.11, 409152.22, 3123.69, 'active'),
('POL00000011', 37, 'Health', '2024-02-28', '2025-02-27', 277.08, 27001.52, 2971.71, 'active'),
('POL00000012', 2, 'Life', '2025-10-29', '2026-10-29', 944.78, 588105.75, 1605.29, 'active'),
('POL00000013', 232, 'Auto', '2025-04-12', '2026-04-12', 583.78, 41108.07, 3301.6, 'expired'),
('POL00000014', 125, 'Auto', '2024-03-27', '2025-03-27', 744.56, 372223.24, 1419.16, 'expired'),
('POL00000015', 205, 'Business', '2025-08-03', '2026-08-03', 340.3, 707822.27, 2360.25, 'cancelled'),
('POL00000016', 409, 'Business', '2025-04-24', '2026-04-24', 153.22, 829916.82, 3859.07, 'cancelled'),
('POL00000017', 397, 'Life', '2026-02-05', '2027-02-05', 404.17, 787439.4, 2365.88, 'expired'),
('POL00000018', 358, 'Life', '2024-10-25', '2025-10-25', 51.69, 284978.01, 3932.81, 'cancelled'),
('POL00000019', 70, 'Home', '2024-12-31', '2025-12-31', 294.92, 744994.22, 1980.7, 'active'),
('POL00000020', 136, 'Travel', '2025-08-10', '2026-08-10', 976.26, 228741.84, 3069.45, 'expired'),
('POL00000021', 397, 'Auto', '2025-02-05', '2026-02-05', 811.92, 693875.03, 1058.62, 'expired'),
('POL00000022', 395, 'Life', '2025-05-11', '2026-05-11', 66.48, 757789.76, 275.13, 'expired'),
('POL00000023', 14, 'Auto', '2025-12-25', '2026-12-25', 841.87, 197449.67, 3090.07, 'active'),
('POL00000024', 238, 'Home', '2025-01-28', '2026-01-28', 130.86, 123027.53, 3125.95, 'cancelled'),
('POL00000025', 207, 'Health', '2024-08-07', '2025-08-07', 578.26, 198850.57, 4830.76, 'active'),
('POL00000026', 239, 'Auto', '2025-05-17', '2026-05-17', 903.84, 770829.35, 2502.57, 'cancelled'),
('POL00000027', 112, 'Life', '2025-09-16', '2026-09-16', 519.58, 432816.97, 1357.65, 'expired'),
('POL00000028', 286, 'Auto', '2024-05-07', '2025-05-07', 199.74, 776027.56, 3140.81, 'cancelled'),
('POL00000029', 85, 'Travel', '2024-03-09', '2025-03-09', 801.59, 513412.56, 341.27, 'cancelled'),
('POL00000030', 194, 'Auto', '2025-02-24', '2026-02-24', 217.75, 919496.21, 4908.69, 'cancelled'),
('POL00000031', 19, 'Travel', '2024-08-05', '2025-08-05', 325.04, 442368.07, 1281.84, 'active'),
('POL00000032', 310, 'Auto', '2025-11-02', '2026-11-02', 691.15, 223196.31, 1889.59, 'cancelled'),
('POL00000033', 344, 'Business', '2025-04-03', '2026-04-03', 711.55, 399054.37, 4268.51, 'cancelled'),
('POL00000034', 120, 'Home', '2025-04-23', '2026-04-23', 296.74, 428822.27, 4241.91, 'cancelled'),
('POL00000035', 50, 'Home', '2026-02-24', '2027-02-24', 613.05, 881399.57, 1851.53, 'expired'),
('POL00000036', 192, 'Business', '2025-11-17', '2026-11-17', 210.42, 740022.09, 4282.81, 'expired'),
('POL00000037', 115, 'Travel', '2024-09-05', '2025-09-05', 827.75, 55117.11, 410.43, 'cancelled'),
('POL00000038', 473, 'Business', '2025-07-04', '2026-07-04', 979.55, 794167.66, 1642.32, 'active'),
('POL00000039', 46, 'Travel', '2024-12-31', '2025-12-31', 509.88, 874887.0, 1552.91, 'expired'),
('POL00000040', 289, 'Auto', '2025-05-12', '2026-05-12', 666.36, 774169.85, 3071.51, 'cancelled'),
('POL00000041', 244, 'Home', '2025-09-12', '2026-09-12', 529.0, 557671.38, 3635.66, 'expired'),
('POL00000042', 393, 'Home', '2024-07-20', '2025-07-20', 501.79, 493556.61, 2096.64, 'expired'),
('POL00000043', 316, 'Home', '2024-09-19', '2025-09-19', 353.29, 89137.05, 488.56, 'cancelled'),
('POL00000044', 303, 'Life', '2024-05-10', '2025-05-10', 542.9, 49681.71, 3508.75, 'active'),
('POL00000045', 91, 'Health', '2024-08-04', '2025-08-04', 772.95, 553144.11, 3052.05, 'expired'),
('POL00000046', 327, 'Travel', '2024-08-17', '2025-08-17', 468.82, 61568.4, 3745.44, 'cancelled'),
('POL00000047', 125, 'Travel', '2024-09-16', '2025-09-16', 694.67, 618497.24, 3780.32, 'active'),
('POL00000048', 217, 'Travel', '2024-10-20', '2025-10-20', 634.65, 214870.45, 1307.46, 'expired'),
('POL00000049', 83, 'Travel', '2025-06-18', '2026-06-18', 981.6, 834404.91, 3814.11, 'cancelled'),
('POL00000050', 178, 'Home', '2024-03-19', '2025-03-19', 733.82, 795408.97, 1206.84, 'expired'),
('POL00000051', 263, 'Home', '2025-10-21', '2026-10-21', 537.15, 384834.17, 2148.14, 'cancelled'),
('POL00000052', 285, 'Home', '2025-02-12', '2026-02-12', 706.78, 636298.89, 4044.79, 'cancelled'),
('POL00000053', 305, 'Business', '2024-04-23', '2025-04-23', 822.95, 243729.43, 310.97, 'cancelled'),
('POL00000054', 247, 'Auto', '2026-02-12', '2027-02-12', 81.41, 240749.74, 4586.58, 'expired'),
('POL00000055', 433, 'Travel', '2025-04-07', '2026-04-07', 778.07, 537761.5, 2138.33, 'active'),
('POL00000056', 357, 'Auto', '2024-04-27', '2025-04-27', 890.65, 831515.16, 2905.28, 'cancelled'),
('POL00000057', 33, 'Auto', '2025-08-08', '2026-08-08', 646.06, 95100.59, 4960.6, 'expired'),
('POL00000058', 277, 'Travel', '2024-10-27', '2025-10-27', 146.25, 698468.91, 3790.38, 'expired'),
('POL00000059', 189, 'Home', '2024-08-26', '2025-08-26', 358.21, 916669.86, 3799.21, 'expired'),
('POL00000060', 385, 'Home', '2024-09-23', '2025-09-23', 188.56, 835541.56, 1073.41, 'cancelled'),
('POL00000061', 264, 'Life', '2024-10-13', '2025-10-13', 732.44, 707636.96, 3195.11, 'active'),
('POL00000062', 68, 'Health', '2025-10-14', '2026-10-14', 248.89, 217344.12, 2327.77, 'cancelled'),
('POL00000063', 226, 'Travel', '2025-08-28', '2026-08-28', 414.66, 623195.95, 1010.09, 'expired'),
('POL00000064', 350, 'Travel', '2024-12-11', '2025-12-11', 319.11, 134833.24, 3386.35, 'cancelled'),
('POL00000065', 273, 'Home', '2025-01-04', '2026-01-04', 591.9, 111931.47, 3499.45, 'active'),
('POL00000066', 377, 'Business', '2024-04-03', '2025-04-03', 531.71, 55416.8, 457.73, 'active'),
('POL00000067', 242, 'Business', '2024-03-31', '2025-03-31', 356.51, 180820.18, 2986.02, 'expired'),
('POL00000068', 494, 'Auto', '2024-05-19', '2025-05-19', 613.78, 877336.49, 2389.6, 'active'),
('POL00000069', 163, 'Travel', '2024-12-10', '2025-12-10', 613.57, 17084.23, 2323.6, 'expired'),
('POL00000070', 274, 'Life', '2025-06-10', '2026-06-10', 354.92, 642057.72, 1931.43, 'active'),
('POL00000071', 272, 'Life', '2024-05-22', '2025-05-22', 703.7, 961206.85, 2182.34, 'expired'),
('POL00000072', 212, 'Life', '2026-02-17', '2027-02-17', 983.53, 56698.97, 794.07, 'active'),
('POL00000073', 98, 'Life', '2024-05-26', '2025-05-26', 780.82, 788977.82, 2686.66, 'active'),
('POL00000074', 283, 'Auto', '2025-08-02', '2026-08-02', 264.29, 739898.83, 4479.51, 'expired'),
('POL00000075', 118, 'Business', '2026-01-14', '2027-01-14', 599.87, 573230.86, 302.35, 'expired'),
('POL00000076', 217, 'Business', '2024-11-29', '2025-11-29', 442.37, 473942.94, 2998.25, 'expired'),
('POL00000077', 318, 'Business', '2024-12-22', '2025-12-22', 967.18, 191741.03, 2455.59, 'expired'),
('POL00000078', 350, 'Home', '2025-07-01', '2026-07-01', 881.16, 563414.36, 3534.14, 'cancelled'),
('POL00000079', 94, 'Travel', '2024-05-24', '2025-05-24', 698.38, 55518.91, 2972.45, 'cancelled'),
('POL00000080', 233, 'Home', '2025-02-07', '2026-02-07', 119.25, 567632.02, 2196.69, 'expired'),
('POL00000081', 417, 'Health', '2025-08-26', '2026-08-26', 534.62, 926145.13, 3176.22, 'active'),
('POL00000082', 287, 'Travel', '2024-10-25', '2025-10-25', 431.27, 570793.82, 4482.68, 'expired'),
('POL00000083', 161, 'Travel', '2025-05-24', '2026-05-24', 409.46, 865287.56, 2762.89, 'cancelled'),
('POL00000084', 322, 'Travel', '2024-02-26', '2025-02-25', 462.95, 301111.27, 1671.65, 'expired'),
('POL00000085', 440, 'Travel', '2026-01-22', '2027-01-22', 628.44, 743696.02, 2096.45, 'active'),
('POL00000086', 437, 'Health', '2024-03-18', '2025-03-18', 844.57, 718545.34, 1197.62, 'cancelled'),
('POL00000087', 48, 'Health', '2024-09-17', '2025-09-17', 73.07, 20412.23, 4953.87, 'active'),
('POL00000088', 127, 'Auto', '2025-11-10', '2026-11-10', 519.27, 43275.37, 3238.88, 'cancelled'),
('POL00000089', 56, 'Home', '2025-12-28', '2026-12-28', 569.97, 306234.04, 2205.71, 'cancelled'),
('POL00000090', 13, 'Business', '2024-11-26', '2025-11-26', 745.72, 447755.22, 1653.55, 'active'),
('POL00000091', 57, 'Home', '2025-05-07', '2026-05-07', 398.88, 892573.9, 1959.63, 'expired'),
('POL00000092', 65, 'Home', '2025-02-02', '2026-02-02', 717.37, 178260.43, 3437.08, 'active'),
('POL00000093', 191, 'Auto', '2026-01-23', '2027-01-23', 562.86, 218524.4, 490.14, 'active'),
('POL00000094', 276, 'Health', '2025-07-23', '2026-07-23', 458.82, 601239.73, 4541.34, 'expired'),
('POL00000095', 56, 'Home', '2024-06-10', '2025-06-10', 996.42, 274860.08, 1593.96, 'expired'),
('POL00000096', 414, 'Health', '2025-03-16', '2026-03-16', 655.52, 127464.31, 1569.26, 'expired'),
('POL00000097', 310, 'Home', '2024-09-27', '2025-09-27', 559.85, 372032.72, 3404.31, 'active'),
('POL00000098', 464, 'Travel', '2025-10-12', '2026-10-12', 246.31, 580900.62, 4084.69, 'expired'),
('POL00000099', 328, 'Auto', '2025-07-30', '2026-07-30', 363.04, 234508.73, 2861.05, 'expired'),
('POL00000100', 166, 'Health', '2024-06-21', '2025-06-21', 974.97, 960419.16, 933.9, 'cancelled'),
('POL00000101', 231, 'Auto', '2024-03-04', '2025-03-04', 833.32, 995407.51, 4337.78, 'active'),
('POL00000102', 419, 'Auto', '2025-02-18', '2026-02-18', 722.85, 947363.58, 2983.58, 'active'),
('POL00000103', 184, 'Home', '2024-10-15', '2025-10-15', 280.74, 265295.05, 314.51, 'expired'),
('POL00000104', 398, 'Business', '2025-01-31', '2026-01-31', 782.3, 205316.02, 4170.23, 'cancelled'),
('POL00000105', 203, 'Travel', '2026-02-16', '2027-02-16', 778.01, 901250.77, 2553.47, 'cancelled'),
('POL00000106', 6, 'Health', '2024-08-17', '2025-08-17', 981.82, 651270.12, 4061.26, 'active'),
('POL00000107', 120, 'Home', '2025-04-12', '2026-04-12', 166.19, 139481.32, 336.19, 'active'),
('POL00000108', 192, 'Travel', '2025-03-12', '2026-03-12', 65.93, 491303.51, 4971.5, 'cancelled'),
('POL00000109', 203, 'Travel', '2024-06-28', '2025-06-28', 478.9, 739421.22, 3824.64, 'expired'),
('POL00000110', 346, 'Health', '2024-05-02', '2025-05-02', 838.11, 309576.42, 2283.76, 'active'),
('POL00000111', 352, 'Life', '2025-12-02', '2026-12-02', 843.39, 96602.03, 3077.14, 'active'),
('POL00000112', 78, 'Auto', '2025-02-10', '2026-02-10', 843.45, 729749.2, 2930.72, 'cancelled'),
('POL00000113', 181, 'Health', '2025-06-16', '2026-06-16', 299.15, 688712.91, 3219.21, 'cancelled'),
('POL00000114', 311, 'Home', '2025-05-19', '2026-05-19', 220.94, 71295.0, 651.57, 'expired'),
('POL00000115', 366, 'Life', '2025-01-25', '2026-01-25', 785.02, 653499.11, 3268.04, 'expired'),
('POL00000116', 70, 'Life', '2024-10-15', '2025-10-15', 455.78, 323370.94, 628.97, 'expired'),
('POL00000117', 61, 'Health', '2026-02-15', '2027-02-15', 523.47, 19274.03, 3513.45, 'cancelled'),
('POL00000118', 448, 'Travel', '2025-05-28', '2026-05-28', 97.63, 692217.36, 4490.93, 'cancelled'),
('POL00000119', 348, 'Life', '2024-07-19', '2025-07-19', 714.59, 438894.45, 1565.83, 'expired'),
('POL00000120', 161, 'Business', '2024-04-09', '2025-04-09', 186.61, 48503.72, 1488.56, 'active'),
('POL00000121', 116, 'Travel', '2024-12-10', '2025-12-10', 738.85, 14210.14, 1566.92, 'expired'),
('POL00000122', 253, 'Home', '2025-08-21', '2026-08-21', 378.2, 975616.56, 3390.54, 'cancelled'),
('POL00000123', 293, 'Life', '2024-11-21', '2025-11-21', 527.88, 388815.16, 2235.97, 'cancelled'),
('POL00000124', 186, 'Home', '2024-11-11', '2025-11-11', 936.01, 697606.14, 934.24, 'expired'),
('POL00000125', 395, 'Auto', '2024-12-17', '2025-12-17', 201.41, 565904.52, 1665.86, 'cancelled'),
('POL00000126', 494, 'Business', '2024-07-23', '2025-07-23', 596.45, 894579.64, 658.75, 'active'),
('POL00000127', 22, 'Life', '2025-04-04', '2026-04-04', 244.68, 442712.19, 1646.43, 'cancelled'),
('POL00000128', 262, 'Auto', '2025-09-23', '2026-09-23', 524.02, 266719.73, 3711.06, 'expired'),
('POL00000129', 358, 'Travel', '2025-06-15', '2026-06-15', 888.89, 23897.06, 1869.67, 'active'),
('POL00000130', 168, 'Business', '2024-10-09', '2025-10-09', 853.34, 441007.57, 4046.8, 'expired'),
('POL00000131', 44, 'Home', '2024-12-19', '2025-12-19', 130.28, 878031.46, 1196.39, 'cancelled'),
('POL00000132', 29, 'Travel', '2025-11-30', '2026-11-30', 73.07, 407301.15, 3901.17, 'cancelled'),
('POL00000133', 114, 'Travel', '2024-08-29', '2025-08-29', 294.43, 407329.64, 1020.18, 'active'),
('POL00000134', 61, 'Health', '2025-03-01', '2026-03-01', 998.72, 464059.93, 4447.24, 'expired'),
('POL00000135', 60, 'Home', '2025-12-31', '2026-12-31', 619.18, 462733.22, 1846.98, 'cancelled'),
('POL00000136', 255, 'Auto', '2024-07-10', '2025-07-10', 748.74, 837977.53, 3822.08, 'cancelled'),
('POL00000137', 372, 'Health', '2024-05-04', '2025-05-04', 825.61, 849699.06, 355.01, 'expired'),
('POL00000138', 108, 'Health', '2024-04-21', '2025-04-21', 203.43, 866274.21, 346.08, 'cancelled'),
('POL00000139', 376, 'Life', '2025-02-05', '2026-02-05', 895.54, 85912.47, 2570.21, 'cancelled'),
('POL00000140', 195, 'Home', '2025-12-20', '2026-12-20', 403.27, 876125.23, 452.85, 'cancelled'),
('POL00000141', 450, 'Travel', '2024-04-04', '2025-04-04', 845.13, 398012.73, 1610.89, 'expired'),
('POL00000142', 165, 'Business', '2024-05-06', '2025-05-06', 392.96, 256695.85, 3103.78, 'active'),
('POL00000143', 382, 'Business', '2024-07-18', '2025-07-18', 101.27, 688031.9, 3017.91, 'expired'),
('POL00000144', 428, 'Travel', '2024-07-01', '2025-07-01', 785.25, 98238.35, 1666.23, 'expired'),
('POL00000145', 318, 'Home', '2024-03-03', '2025-03-03', 715.74, 449746.27, 461.63, 'cancelled'),
('POL00000146', 460, 'Home', '2025-10-23', '2026-10-23', 853.11, 341949.78, 1559.78, 'cancelled'),
('POL00000147', 290, 'Auto', '2024-06-03', '2025-06-03', 480.68, 847683.79, 1602.8, 'expired'),
('POL00000148', 281, 'Home', '2025-07-20', '2026-07-20', 965.82, 43527.1, 1178.22, 'expired'),
('POL00000149', 469, 'Business', '2024-06-25', '2025-06-25', 251.33, 570731.13, 485.85, 'active'),
('POL00000150', 34, 'Business', '2025-02-07', '2026-02-07', 295.46, 389271.17, 3835.98, 'active'),
('POL00000151', 76, 'Auto', '2024-07-26', '2025-07-26', 787.86, 478152.94, 2178.1, 'cancelled'),
('POL00000152', 246, 'Business', '2024-07-01', '2025-07-01', 900.73, 523465.38, 1807.96, 'active'),
('POL00000153', 414, 'Health', '2024-08-22', '2025-08-22', 224.43, 60125.27, 1226.51, 'expired'),
('POL00000154', 69, 'Travel', '2024-10-08', '2025-10-08', 223.25, 859644.93, 3523.37, 'active'),
('POL00000155', 185, 'Health', '2025-09-04', '2026-09-04', 149.06, 114847.23, 3612.95, 'cancelled'),
('POL00000156', 30, 'Business', '2025-05-29', '2026-05-29', 465.04, 284986.68, 1559.28, 'expired'),
('POL00000157', 493, 'Home', '2025-02-24', '2026-02-24', 532.38, 723885.79, 2662.72, 'active'),
('POL00000158', 146, 'Home', '2025-09-30', '2026-09-30', 717.81, 425076.88, 415.39, 'cancelled'),
('POL00000159', 354, 'Travel', '2026-01-10', '2027-01-10', 209.32, 994882.68, 3538.12, 'expired'),
('POL00000160', 456, 'Business', '2024-03-27', '2025-03-27', 179.17, 862120.79, 3425.86, 'expired'),
('POL00000161', 142, 'Auto', '2024-12-01', '2025-12-01', 262.77, 216730.24, 4571.22, 'cancelled'),
('POL00000162', 194, 'Life', '2025-12-05', '2026-12-05', 562.5, 255720.77, 630.13, 'expired'),
('POL00000163', 28, 'Life', '2025-03-04', '2026-03-04', 750.31, 814737.69, 3909.77, 'active'),
('POL00000164', 145, 'Auto', '2024-04-29', '2025-04-29', 269.17, 767283.88, 4545.61, 'cancelled'),
('POL00000165', 414, 'Home', '2025-02-08', '2026-02-08', 979.95, 502237.14, 346.42, 'active'),
('POL00000166', 78, 'Auto', '2024-11-20', '2025-11-20', 785.86, 396653.16, 2765.18, 'expired'),
('POL00000167', 412, 'Home', '2025-01-11', '2026-01-11', 535.35, 410074.59, 2503.78, 'expired'),
('POL00000168', 95, 'Life', '2025-06-16', '2026-06-16', 974.1, 112948.63, 1527.14, 'active'),
('POL00000169', 265, 'Travel', '2024-04-15', '2025-04-15', 846.14, 994225.04, 834.15, 'cancelled'),
('POL00000170', 434, 'Life', '2025-01-27', '2026-01-27', 213.34, 824069.61, 3470.64, 'cancelled'),
('POL00000171', 105, 'Home', '2025-01-30', '2026-01-30', 999.59, 114501.72, 1502.22, 'cancelled'),
('POL00000172', 250, 'Business', '2024-07-29', '2025-07-29', 907.96, 768572.15, 3565.78, 'cancelled'),
('POL00000173', 407, 'Home', '2025-11-25', '2026-11-25', 333.16, 782868.25, 3811.41, 'active'),
('POL00000174', 344, 'Life', '2024-04-29', '2025-04-29', 760.24, 165767.6, 3843.33, 'active'),
('POL00000175', 28, 'Travel', '2025-01-24', '2026-01-24', 725.77, 106208.77, 3163.7, 'expired'),
('POL00000176', 309, 'Business', '2026-01-30', '2027-01-30', 834.61, 548342.54, 2648.48, 'active'),
('POL00000177', 109, 'Health', '2024-11-30', '2025-11-30', 153.86, 391677.75, 2640.17, 'cancelled'),
('POL00000178', 260, 'Auto', '2024-12-10', '2025-12-10', 769.37, 757029.68, 299.01, 'active'),
('POL00000179', 499, 'Health', '2025-04-19', '2026-04-19', 579.21, 702140.48, 4886.94, 'cancelled'),
('POL00000180', 428, 'Life', '2024-07-23', '2025-07-23', 744.52, 87420.17, 4671.56, 'expired'),
('POL00000181', 434, 'Travel', '2026-01-17', '2027-01-17', 641.78, 164653.83, 1604.58, 'expired'),
('POL00000182', 449, 'Health', '2024-03-17', '2025-03-17', 215.07, 140742.58, 1805.97, 'expired'),
('POL00000183', 189, 'Auto', '2025-07-15', '2026-07-15', 737.59, 259157.97, 3750.69, 'active'),
('POL00000184', 150, 'Home', '2026-02-02', '2027-02-02', 403.0, 567472.09, 3674.79, 'active'),
('POL00000185', 286, 'Life', '2025-06-20', '2026-06-20', 134.84, 194640.02, 3577.34, 'cancelled'),
('POL00000186', 26, 'Auto', '2025-11-26', '2026-11-26', 62.41, 771873.47, 561.79, 'active'),
('POL00000187', 191, 'Auto', '2024-12-18', '2025-12-18', 631.19, 408241.5, 1293.01, 'expired'),
('POL00000188', 400, 'Health', '2025-10-23', '2026-10-23', 116.65, 421390.74, 1315.94, 'active'),
('POL00000189', 103, 'Auto', '2024-06-03', '2025-06-03', 356.45, 347281.9, 1074.69, 'expired'),
('POL00000190', 334, 'Auto', '2024-09-23', '2025-09-23', 491.17, 449144.84, 3655.64, 'expired'),
('POL00000191', 107, 'Health', '2024-12-21', '2025-12-21', 204.08, 137826.11, 4719.14, 'active'),
('POL00000192', 138, 'Health', '2026-01-03', '2027-01-03', 685.31, 900238.26, 548.91, 'active'),
('POL00000193', 228, 'Travel', '2025-01-04', '2026-01-04', 82.73, 175504.0, 1703.85, 'cancelled'),
('POL00000194', 213, 'Life', '2024-06-17', '2025-06-17', 344.47, 614260.39, 2861.77, 'cancelled'),
('POL00000195', 246, 'Health', '2024-06-03', '2025-06-03', 540.41, 997184.36, 2332.38, 'active'),
('POL00000196', 145, 'Health', '2024-09-27', '2025-09-27', 883.09, 163929.09, 4207.29, 'expired'),
('POL00000197', 233, 'Home', '2025-09-28', '2026-09-28', 468.91, 263772.95, 2593.5, 'active'),
('POL00000198', 96, 'Home', '2024-08-15', '2025-08-15', 54.37, 629000.36, 3106.15, 'cancelled'),
('POL00000199', 304, 'Life', '2024-08-18', '2025-08-18', 668.68, 812570.22, 3203.14, 'cancelled'),
('POL00000200', 219, 'Home', '2024-08-06', '2025-08-06', 811.34, 177960.19, 1717.88, 'expired'),
('POL00000201', 425, 'Home', '2025-09-02', '2026-09-02', 985.2, 745013.92, 4306.43, 'cancelled'),
('POL00000202', 439, 'Life', '2026-01-25', '2027-01-25', 319.14, 341868.78, 2855.46, 'expired'),
('POL00000203', 438, 'Home', '2025-12-13', '2026-12-13', 200.78, 803945.43, 2566.16, 'expired'),
('POL00000204', 282, 'Auto', '2024-05-19', '2025-05-19', 263.76, 646655.03, 1832.99, 'active'),
('POL00000205', 152, 'Auto', '2025-07-04', '2026-07-04', 975.98, 112989.75, 4351.01, 'active'),
('POL00000206', 83, 'Health', '2025-07-24', '2026-07-24', 960.95, 846515.7, 4602.43, 'expired'),
('POL00000207', 348, 'Travel', '2025-08-08', '2026-08-08', 80.4, 707369.63, 302.06, 'active'),
('POL00000208', 476, 'Health', '2025-08-29', '2026-08-29', 816.06, 811673.01, 3043.45, 'active'),
('POL00000209', 167, 'Auto', '2024-05-28', '2025-05-28', 331.08, 784888.1, 4855.66, 'active'),
('POL00000210', 492, 'Life', '2025-04-09', '2026-04-09', 328.19, 539005.19, 952.48, 'expired'),
('POL00000211', 206, 'Health', '2024-07-25', '2025-07-25', 173.04, 51935.04, 3703.67, 'cancelled'),
('POL00000212', 330, 'Auto', '2024-04-26', '2025-04-26', 515.91, 326524.14, 4936.55, 'cancelled'),
('POL00000213', 246, 'Travel', '2024-05-16', '2025-05-16', 930.53, 899894.59, 3378.38, 'expired'),
('POL00000214', 476, 'Business', '2025-11-25', '2026-11-25', 473.43, 240336.21, 1753.42, 'expired'),
('POL00000215', 355, 'Life', '2024-07-07', '2025-07-07', 663.37, 478536.29, 4027.3, 'cancelled'),
('POL00000216', 351, 'Business', '2026-01-25', '2027-01-25', 250.27, 865050.22, 4486.84, 'active'),
('POL00000217', 273, 'Home', '2024-07-21', '2025-07-21', 747.54, 367790.02, 1059.29, 'cancelled'),
('POL00000218', 207, 'Travel', '2025-11-17', '2026-11-17', 466.37, 168069.35, 2818.8, 'expired'),
('POL00000219', 386, 'Home', '2025-07-30', '2026-07-30', 920.79, 733708.03, 4145.52, 'cancelled'),
('POL00000220', 17, 'Home', '2024-07-08', '2025-07-08', 274.68, 483583.71, 2886.19, 'cancelled'),
('POL00000221', 261, 'Travel', '2024-11-09', '2025-11-09', 246.85, 576174.21, 3580.24, 'active'),
('POL00000222', 204, 'Life', '2024-08-20', '2025-08-20', 635.1, 758478.39, 2873.05, 'cancelled'),
('POL00000223', 418, 'Health', '2024-12-20', '2025-12-20', 652.76, 725307.56, 471.16, 'expired'),
('POL00000224', 1, 'Health', '2024-10-03', '2025-10-03', 284.78, 609292.74, 4420.45, 'expired'),
('POL00000225', 417, 'Home', '2024-11-03', '2025-11-03', 762.02, 425695.81, 517.96, 'cancelled'),
('POL00000226', 263, 'Life', '2025-08-30', '2026-08-30', 714.91, 775445.53, 4817.7, 'expired'),
('POL00000227', 186, 'Business', '2025-01-07', '2026-01-07', 978.12, 584383.55, 1978.71, 'active'),
('POL00000228', 50, 'Auto', '2024-05-15', '2025-05-15', 418.1, 506892.23, 4232.59, 'active'),
('POL00000229', 112, 'Business', '2024-07-06', '2025-07-06', 593.64, 71721.49, 3954.0, 'active'),
('POL00000230', 82, 'Business', '2025-08-03', '2026-08-03', 910.87, 40902.89, 319.53, 'active'),
('POL00000231', 28, 'Business', '2024-10-02', '2025-10-02', 882.84, 304159.76, 4842.46, 'cancelled'),
('POL00000232', 353, 'Home', '2025-05-23', '2026-05-23', 547.28, 564620.76, 2492.32, 'cancelled'),
('POL00000233', 213, 'Travel', '2024-04-15', '2025-04-15', 186.39, 403376.8, 4305.57, 'cancelled'),
('POL00000234', 487, 'Auto', '2025-01-31', '2026-01-31', 224.23, 141196.58, 1910.04, 'cancelled'),
('POL00000235', 79, 'Travel', '2024-09-04', '2025-09-04', 997.94, 449844.46, 4729.94, 'active'),
('POL00000236', 135, 'Business', '2024-10-06', '2025-10-06', 951.84, 745636.44, 4403.61, 'cancelled'),
('POL00000237', 237, 'Home', '2026-02-12', '2027-02-12', 904.42, 310305.73, 3031.66, 'active'),
('POL00000238', 453, 'Life', '2025-02-01', '2026-02-01', 644.13, 436304.55, 3314.91, 'active'),
('POL00000239', 71, 'Travel', '2025-02-02', '2026-02-02', 117.25, 955711.52, 4823.11, 'cancelled'),
('POL00000240', 337, 'Health', '2025-05-26', '2026-05-26', 227.95, 872238.56, 929.6, 'expired'),
('POL00000241', 31, 'Health', '2024-04-06', '2025-04-06', 347.32, 387833.62, 4562.47, 'expired'),
('POL00000242', 340, 'Health', '2025-04-20', '2026-04-20', 116.28, 526835.22, 3827.0, 'expired'),
('POL00000243', 462, 'Life', '2024-10-19', '2025-10-19', 135.26, 950747.25, 965.04, 'active'),
('POL00000244', 213, 'Travel', '2025-08-11', '2026-08-11', 830.94, 847529.42, 3075.04, 'cancelled'),
('POL00000245', 462, 'Home', '2026-01-12', '2027-01-12', 759.56, 312088.71, 4758.18, 'active'),
('POL00000246', 89, 'Health', '2025-06-05', '2026-06-05', 176.52, 968280.03, 1961.66, 'active'),
('POL00000247', 332, 'Business', '2026-02-05', '2027-02-05', 840.76, 332357.19, 4182.2, 'expired'),
('POL00000248', 446, 'Life', '2024-08-27', '2025-08-27', 845.8, 744418.05, 1691.67, 'cancelled'),
('POL00000249', 157, 'Business', '2024-12-07', '2025-12-07', 484.14, 544180.0, 4389.33, 'active'),
('POL00000250', 350, 'Auto', '2025-12-22', '2026-12-22', 933.99, 717976.7, 2070.4, 'expired'),
('POL00000251', 188, 'Business', '2024-09-21', '2025-09-21', 81.94, 48246.81, 1763.39, 'cancelled'),
('POL00000252', 468, 'Health', '2025-01-27', '2026-01-27', 855.45, 748767.75, 3621.57, 'active'),
('POL00000253', 155, 'Health', '2024-09-12', '2025-09-12', 378.3, 48030.44, 2554.21, 'expired'),
('POL00000254', 325, 'Business', '2024-08-14', '2025-08-14', 764.13, 952487.3, 2477.72, 'expired'),
('POL00000255', 199, 'Business', '2024-06-29', '2025-06-29', 520.3, 891511.85, 1839.25, 'expired'),
('POL00000256', 62, 'Travel', '2024-08-02', '2025-08-02', 556.28, 22564.56, 4460.35, 'active'),
('POL00000257', 249, 'Travel', '2025-10-16', '2026-10-16', 390.77, 961303.84, 973.25, 'cancelled'),
('POL00000258', 212, 'Travel', '2025-10-28', '2026-10-28', 989.66, 470566.49, 2894.27, 'cancelled'),
('POL00000259', 267, 'Travel', '2025-04-27', '2026-04-27', 731.67, 981136.29, 3080.64, 'expired'),
('POL00000260', 378, 'Business', '2025-02-16', '2026-02-16', 736.19, 597366.58, 2789.11, 'active'),
('POL00000261', 57, 'Auto', '2025-01-11', '2026-01-11', 128.44, 852646.92, 4595.06, 'active'),
('POL00000262', 153, 'Life', '2025-03-01', '2026-03-01', 430.0, 480586.66, 4761.96, 'expired'),
('POL00000263', 57, 'Travel', '2024-09-08', '2025-09-08', 112.35, 104789.59, 2876.12, 'cancelled'),
('POL00000264', 133, 'Business', '2025-07-30', '2026-07-30', 198.63, 38663.31, 2449.0, 'expired'),
('POL00000265', 376, 'Business', '2025-05-16', '2026-05-16', 507.76, 124359.47, 4865.95, 'active'),
('POL00000266', 261, 'Auto', '2024-10-01', '2025-10-01', 54.44, 80138.85, 4585.09, 'expired'),
('POL00000267', 160, 'Life', '2025-06-29', '2026-06-29', 499.17, 861164.14, 2926.99, 'active'),
('POL00000268', 399, 'Travel', '2025-08-30', '2026-08-30', 886.72, 885617.54, 3708.02, 'expired'),
('POL00000269', 227, 'Health', '2024-09-25', '2025-09-25', 73.71, 100058.65, 2669.49, 'cancelled'),
('POL00000270', 176, 'Business', '2024-08-14', '2025-08-14', 51.74, 99453.68, 4611.7, 'cancelled'),
('POL00000271', 341, 'Business', '2024-12-30', '2025-12-30', 803.97, 886391.11, 1081.61, 'cancelled'),
('POL00000272', 235, 'Life', '2026-01-08', '2027-01-08', 878.49, 837508.12, 3001.86, 'active'),
('POL00000273', 398, 'Life', '2025-01-12', '2026-01-12', 683.39, 541541.91, 1491.07, 'cancelled'),
('POL00000274', 375, 'Home', '2025-04-16', '2026-04-16', 275.33, 303894.2, 850.25, 'cancelled'),
('POL00000275', 253, 'Health', '2024-03-03', '2025-03-03', 282.47, 823230.33, 1164.58, 'cancelled'),
('POL00000276', 177, 'Life', '2024-10-14', '2025-10-14', 74.04, 534049.08, 2635.51, 'expired'),
('POL00000277', 254, 'Life', '2025-01-06', '2026-01-06', 509.78, 768785.1, 2283.16, 'active'),
('POL00000278', 145, 'Auto', '2025-03-15', '2026-03-15', 813.37, 790933.06, 3004.75, 'cancelled'),
('POL00000279', 238, 'Auto', '2024-05-23', '2025-05-23', 922.33, 800924.2, 3822.08, 'active'),
('POL00000280', 451, 'Auto', '2024-10-16', '2025-10-16', 534.88, 601361.66, 953.93, 'expired'),
('POL00000281', 93, 'Business', '2025-07-09', '2026-07-09', 968.93, 614625.88, 1406.2, 'cancelled'),
('POL00000282', 338, 'Auto', '2024-12-25', '2025-12-25', 655.71, 744693.06, 2437.67, 'cancelled'),
('POL00000283', 420, 'Home', '2024-10-20', '2025-10-20', 104.24, 905935.72, 1958.74, 'cancelled'),
('POL00000284', 423, 'Auto', '2025-12-11', '2026-12-11', 306.7, 904111.34, 1706.3, 'cancelled'),
('POL00000285', 131, 'Home', '2024-10-18', '2025-10-18', 366.71, 631918.6, 1954.04, 'active'),
('POL00000286', 380, 'Home', '2025-03-16', '2026-03-16', 399.57, 168360.93, 2006.7, 'active'),
('POL00000287', 114, 'Home', '2025-10-20', '2026-10-20', 109.73, 448472.87, 3538.13, 'cancelled'),
('POL00000288', 329, 'Auto', '2024-04-08', '2025-04-08', 268.47, 937853.91, 3326.33, 'cancelled'),
('POL00000289', 437, 'Home', '2024-05-28', '2025-05-28', 53.89, 672797.3, 3776.98, 'active'),
('POL00000290', 266, 'Life', '2024-03-19', '2025-03-19', 470.6, 104726.04, 3487.04, 'cancelled'),
('POL00000291', 91, 'Travel', '2025-12-03', '2026-12-03', 195.42, 257612.32, 2306.23, 'active'),
('POL00000292', 30, 'Life', '2025-11-17', '2026-11-17', 851.16, 153779.01, 463.91, 'expired'),
('POL00000293', 308, 'Auto', '2024-06-03', '2025-06-03', 250.72, 414372.76, 2527.2, 'expired'),
('POL00000294', 484, 'Home', '2024-06-16', '2025-06-16', 411.93, 577902.04, 3742.34, 'expired'),
('POL00000295', 462, 'Travel', '2024-12-09', '2025-12-09', 298.84, 726132.53, 1375.02, 'cancelled'),
('POL00000296', 429, 'Travel', '2024-03-31', '2025-03-31', 797.34, 553433.22, 2682.7, 'expired'),
('POL00000297', 93, 'Home', '2024-04-06', '2025-04-06', 664.72, 266101.73, 801.51, 'expired'),
('POL00000298', 146, 'Life', '2026-01-24', '2027-01-24', 209.22, 383198.56, 1506.69, 'cancelled'),
('POL00000299', 366, 'Travel', '2024-08-04', '2025-08-04', 363.82, 265448.79, 4348.27, 'expired'),
('POL00000300', 173, 'Auto', '2024-08-30', '2025-08-30', 571.75, 456439.08, 908.98, 'expired'),
('POL00000301', 420, 'Life', '2024-07-29', '2025-07-29', 191.49, 360814.5, 261.35, 'expired'),
('POL00000302', 151, 'Home', '2024-08-19', '2025-08-19', 709.16, 419496.71, 1383.95, 'active'),
('POL00000303', 495, 'Health', '2024-08-27', '2025-08-27', 347.36, 471626.61, 1033.91, 'cancelled'),
('POL00000304', 440, 'Home', '2025-01-17', '2026-01-17', 646.96, 164785.74, 3718.1, 'expired'),
('POL00000305', 461, 'Travel', '2024-12-29', '2025-12-29', 826.84, 685923.61, 4603.11, 'expired'),
('POL00000306', 141, 'Health', '2024-04-13', '2025-04-13', 546.96, 806305.54, 2705.6, 'expired'),
('POL00000307', 194, 'Business', '2025-10-04', '2026-10-04', 467.27, 69813.67, 4644.66, 'cancelled'),
('POL00000308', 82, 'Health', '2024-11-13', '2025-11-13', 483.9, 814286.34, 2391.61, 'cancelled'),
('POL00000309', 349, 'Travel', '2024-07-22', '2025-07-22', 854.74, 987918.47, 1879.26, 'cancelled'),
('POL00000310', 198, 'Health', '2025-12-23', '2026-12-23', 932.35, 560709.02, 3122.95, 'expired'),
('POL00000311', 178, 'Auto', '2025-04-14', '2026-04-14', 51.55, 128018.28, 3540.17, 'active'),
('POL00000312', 6, 'Travel', '2024-12-22', '2025-12-22', 101.27, 439981.7, 4289.79, 'cancelled'),
('POL00000313', 297, 'Travel', '2024-12-09', '2025-12-09', 299.71, 593491.95, 3755.08, 'cancelled'),
('POL00000314', 182, 'Travel', '2025-11-23', '2026-11-23', 411.43, 750171.73, 2898.58, 'expired'),
('POL00000315', 10, 'Life', '2025-10-20', '2026-10-20', 311.7, 605844.05, 1315.32, 'active'),
('POL00000316', 158, 'Travel', '2025-12-13', '2026-12-13', 586.43, 902232.67, 2002.86, 'expired'),
('POL00000317', 94, 'Auto', '2024-12-27', '2025-12-27', 686.77, 34716.71, 2788.07, 'cancelled'),
('POL00000318', 275, 'Home', '2024-11-26', '2025-11-26', 175.43, 885863.31, 643.32, 'active'),
('POL00000319', 298, 'Travel', '2024-04-13', '2025-04-13', 392.18, 462054.31, 3420.37, 'expired'),
('POL00000320', 32, 'Travel', '2026-02-10', '2027-02-10', 969.84, 558567.18, 2481.0, 'cancelled'),
('POL00000321', 360, 'Travel', '2024-03-08', '2025-03-08', 531.38, 276100.64, 3281.15, 'expired'),
('POL00000322', 333, 'Travel', '2024-08-24', '2025-08-24', 334.51, 987121.44, 4554.41, 'active'),
('POL00000323', 364, 'Auto', '2025-06-02', '2026-06-02', 904.61, 807679.32, 422.31, 'expired'),
('POL00000324', 440, 'Travel', '2026-02-14', '2027-02-14', 418.29, 815368.42, 4597.47, 'cancelled'),
('POL00000325', 246, 'Travel', '2024-12-25', '2025-12-25', 683.94, 922833.63, 3786.24, 'cancelled'),
('POL00000326', 460, 'Travel', '2024-06-06', '2025-06-06', 840.92, 200433.43, 428.79, 'expired'),
('POL00000327', 176, 'Life', '2024-06-04', '2025-06-04', 784.89, 553746.51, 1853.62, 'active'),
('POL00000328', 241, 'Health', '2024-11-01', '2025-11-01', 515.14, 113662.98, 1958.23, 'cancelled'),
('POL00000329', 369, 'Life', '2025-06-30', '2026-06-30', 389.21, 85899.34, 1500.85, 'active'),
('POL00000330', 359, 'Auto', '2024-05-26', '2025-05-26', 590.61, 139593.31, 1986.0, 'active'),
('POL00000331', 101, 'Life', '2025-10-22', '2026-10-22', 653.28, 213885.74, 3632.45, 'active'),
('POL00000332', 228, 'Life', '2025-03-03', '2026-03-03', 394.16, 107045.48, 4958.7, 'expired'),
('POL00000333', 44, 'Auto', '2024-12-15', '2025-12-15', 71.38, 406378.77, 4414.9, 'expired'),
('POL00000334', 399, 'Business', '2024-04-09', '2025-04-09', 299.66, 230922.4, 4168.24, 'expired'),
('POL00000335', 123, 'Health', '2024-09-07', '2025-09-07', 732.48, 235864.79, 1641.57, 'active'),
('POL00000336', 19, 'Health', '2024-08-18', '2025-08-18', 429.44, 425827.76, 1386.43, 'cancelled'),
('POL00000337', 460, 'Home', '2024-10-08', '2025-10-08', 181.88, 743396.41, 3803.91, 'expired'),
('POL00000338', 320, 'Home', '2024-10-11', '2025-10-11', 173.33, 340827.62, 3032.38, 'cancelled'),
('POL00000339', 464, 'Travel', '2025-10-16', '2026-10-16', 698.26, 438566.45, 2271.93, 'cancelled'),
('POL00000340', 274, 'Auto', '2025-08-06', '2026-08-06', 619.82, 673006.46, 3132.9, 'cancelled'),
('POL00000341', 410, 'Travel', '2024-06-06', '2025-06-06', 935.61, 286252.49, 3913.04, 'expired'),
('POL00000342', 29, 'Health', '2024-05-12', '2025-05-12', 106.66, 187106.91, 1792.55, 'active'),
('POL00000343', 86, 'Home', '2025-06-10', '2026-06-10', 801.46, 519908.85, 4431.42, 'active'),
('POL00000344', 85, 'Auto', '2025-03-16', '2026-03-16', 812.15, 255918.38, 3133.01, 'expired'),
('POL00000345', 428, 'Travel', '2024-06-15', '2025-06-15', 901.21, 88743.56, 2010.89, 'cancelled'),
('POL00000346', 280, 'Business', '2025-12-22', '2026-12-22', 56.4, 183120.98, 3209.5, 'expired'),
('POL00000347', 56, 'Life', '2025-07-27', '2026-07-27', 642.94, 406147.23, 2383.07, 'active'),
('POL00000348', 338, 'Health', '2025-11-11', '2026-11-11', 897.48, 998775.05, 3582.84, 'active'),
('POL00000349', 471, 'Home', '2024-10-10', '2025-10-10', 724.56, 814010.97, 3233.77, 'expired'),
('POL00000350', 177, 'Home', '2025-05-01', '2026-05-01', 543.72, 198620.1, 1251.07, 'cancelled'),
('POL00000351', 443, 'Business', '2024-04-04', '2025-04-04', 99.85, 517923.91, 4117.33, 'active'),
('POL00000352', 287, 'Home', '2024-05-21', '2025-05-21', 282.99, 688466.12, 340.18, 'active'),
('POL00000353', 472, 'Life', '2024-05-02', '2025-05-02', 999.64, 485662.4, 1504.95, 'expired'),
('POL00000354', 12, 'Health', '2025-04-18', '2026-04-18', 612.02, 962631.06, 2849.54, 'cancelled'),
('POL00000355', 85, 'Auto', '2024-06-12', '2025-06-12', 114.87, 958656.25, 3091.34, 'expired'),
('POL00000356', 162, 'Health', '2024-08-20', '2025-08-20', 162.1, 180116.57, 1940.28, 'active'),
('POL00000357', 273, 'Health', '2024-06-20', '2025-06-20', 246.6, 437904.38, 4526.84, 'cancelled'),
('POL00000358', 208, 'Life', '2024-10-08', '2025-10-08', 878.88, 957308.25, 3959.2, 'cancelled'),
('POL00000359', 59, 'Auto', '2025-12-14', '2026-12-14', 384.42, 123604.08, 3202.44, 'active'),
('POL00000360', 80, 'Business', '2025-10-30', '2026-10-30', 779.26, 772127.93, 4472.19, 'cancelled'),
('POL00000361', 113, 'Business', '2025-05-30', '2026-05-30', 707.54, 703225.13, 1670.28, 'active'),
('POL00000362', 463, 'Life', '2025-06-08', '2026-06-08', 610.9, 643871.53, 3456.38, 'expired'),
('POL00000363', 296, 'Life', '2025-02-24', '2026-02-24', 706.15, 31209.14, 4394.35, 'cancelled'),
('POL00000364', 81, 'Life', '2026-01-10', '2027-01-10', 701.01, 495955.06, 1985.83, 'expired'),
('POL00000365', 139, 'Life', '2025-03-01', '2026-03-01', 936.03, 711819.55, 1258.29, 'active'),
('POL00000366', 200, 'Travel', '2025-01-29', '2026-01-29', 451.4, 669959.46, 3625.49, 'expired'),
('POL00000367', 127, 'Auto', '2025-07-12', '2026-07-12', 852.31, 287156.45, 4168.18, 'cancelled'),
('POL00000368', 103, 'Health', '2025-11-18', '2026-11-18', 363.02, 548693.1, 2223.11, 'active'),
('POL00000369', 312, 'Home', '2025-01-08', '2026-01-08', 405.05, 314620.81, 4624.16, 'active'),
('POL00000370', 86, 'Health', '2025-09-05', '2026-09-05', 880.16, 287608.89, 1853.1, 'active'),
('POL00000371', 162, 'Travel', '2025-01-05', '2026-01-05', 51.74, 721393.34, 489.93, 'cancelled'),
('POL00000372', 421, 'Home', '2024-07-02', '2025-07-02', 237.15, 906116.42, 2411.52, 'cancelled'),
('POL00000373', 44, 'Home', '2025-12-15', '2026-12-15', 725.08, 816664.12, 1427.67, 'cancelled'),
('POL00000374', 79, 'Life', '2025-12-18', '2026-12-18', 995.18, 347191.81, 4943.07, 'cancelled'),
('POL00000375', 138, 'Business', '2025-09-02', '2026-09-02', 351.96, 665715.89, 1051.6, 'cancelled'),
('POL00000376', 394, 'Travel', '2025-07-06', '2026-07-06', 346.88, 614392.38, 2804.53, 'active'),
('POL00000377', 244, 'Life', '2024-03-09', '2025-03-09', 983.39, 914294.68, 999.02, 'cancelled'),
('POL00000378', 302, 'Auto', '2024-06-10', '2025-06-10', 785.78, 983670.31, 3910.01, 'cancelled'),
('POL00000379', 234, 'Home', '2024-12-27', '2025-12-27', 658.52, 690884.3, 278.34, 'expired'),
('POL00000380', 57, 'Health', '2026-02-15', '2027-02-15', 186.11, 815981.86, 4995.13, 'active'),
('POL00000381', 415, 'Health', '2025-02-09', '2026-02-09', 615.28, 76481.88, 2911.7, 'cancelled'),
('POL00000382', 353, 'Home', '2025-07-05', '2026-07-05', 698.12, 963215.08, 1516.35, 'active'),
('POL00000383', 6, 'Business', '2025-06-29', '2026-06-29', 909.88, 591432.84, 1199.28, 'cancelled'),
('POL00000384', 126, 'Business', '2025-06-28', '2026-06-28', 591.85, 436447.69, 3295.31, 'expired'),
('POL00000385', 137, 'Home', '2025-08-05', '2026-08-05', 116.97, 601806.49, 505.45, 'expired'),
('POL00000386', 153, 'Business', '2024-09-25', '2025-09-25', 90.81, 465692.91, 738.9, 'cancelled'),
('POL00000387', 350, 'Travel', '2025-05-19', '2026-05-19', 277.61, 353093.04, 4828.29, 'expired'),
('POL00000388', 261, 'Health', '2024-08-03', '2025-08-03', 785.08, 705271.66, 428.56, 'expired'),
('POL00000389', 305, 'Auto', '2024-08-28', '2025-08-28', 988.64, 676001.37, 1500.5, 'expired'),
('POL00000390', 364, 'Auto', '2025-09-02', '2026-09-02', 290.01, 163206.21, 519.24, 'expired'),
('POL00000391', 75, 'Auto', '2024-12-07', '2025-12-07', 973.59, 317609.94, 3631.79, 'expired'),
('POL00000392', 343, 'Home', '2025-12-09', '2026-12-09', 285.5, 809574.15, 343.55, 'cancelled'),
('POL00000393', 29, 'Health', '2024-10-22', '2025-10-22', 440.2, 273103.0, 1502.9, 'cancelled'),
('POL00000394', 474, 'Home', '2024-11-17', '2025-11-17', 81.32, 85035.21, 923.91, 'active'),
('POL00000395', 58, 'Auto', '2025-02-19', '2026-02-19', 718.02, 951100.97, 1731.76, 'active'),
('POL00000396', 63, 'Home', '2024-07-14', '2025-07-14', 111.34, 95374.62, 2538.61, 'cancelled'),
('POL00000397', 190, 'Auto', '2026-01-27', '2027-01-27', 762.59, 166777.88, 1548.62, 'active'),
('POL00000398', 207, 'Travel', '2025-12-07', '2026-12-07', 874.13, 44837.26, 3573.02, 'cancelled'),
('POL00000399', 376, 'Home', '2024-10-27', '2025-10-27', 576.88, 526190.99, 4306.04, 'cancelled'),
('POL00000400', 274, 'Business', '2025-03-25', '2026-03-25', 124.94, 716073.83, 4648.45, 'active'),
('POL00000401', 169, 'Health', '2024-04-14', '2025-04-14', 228.74, 295314.3, 2542.71, 'active'),
('POL00000402', 427, 'Health', '2024-03-15', '2025-03-15', 100.45, 710952.08, 1060.21, 'active'),
('POL00000403', 289, 'Auto', '2024-04-07', '2025-04-07', 93.41, 991823.65, 1102.93, 'active'),
('POL00000404', 380, 'Business', '2025-07-20', '2026-07-20', 572.05, 29298.22, 4914.26, 'expired'),
('POL00000405', 399, 'Travel', '2024-10-05', '2025-10-05', 530.81, 612008.66, 849.19, 'expired'),
('POL00000406', 300, 'Business', '2025-12-19', '2026-12-19', 157.15, 149021.54, 3034.0, 'expired'),
('POL00000407', 432, 'Auto', '2025-06-15', '2026-06-15', 379.75, 22121.84, 2175.87, 'active'),
('POL00000408', 112, 'Business', '2025-07-14', '2026-07-14', 651.63, 950166.53, 3597.03, 'expired'),
('POL00000409', 385, 'Life', '2025-07-12', '2026-07-12', 614.61, 435075.08, 4449.22, 'active'),
('POL00000410', 154, 'Travel', '2024-07-08', '2025-07-08', 321.5, 989920.75, 3991.21, 'active'),
('POL00000411', 319, 'Health', '2024-06-05', '2025-06-05', 200.73, 317496.98, 2683.98, 'expired'),
('POL00000412', 22, 'Auto', '2025-12-09', '2026-12-09', 722.17, 92321.81, 2859.87, 'expired'),
('POL00000413', 320, 'Travel', '2025-05-01', '2026-05-01', 85.12, 659785.02, 3411.2, 'expired'),
('POL00000414', 330, 'Health', '2025-02-16', '2026-02-16', 724.34, 530171.64, 3123.7, 'cancelled'),
('POL00000415', 291, 'Life', '2024-08-09', '2025-08-09', 718.95, 745549.23, 2361.16, 'active'),
('POL00000416', 130, 'Auto', '2025-10-09', '2026-10-09', 907.23, 762418.72, 2298.04, 'expired'),
('POL00000417', 234, 'Auto', '2025-12-17', '2026-12-17', 653.93, 182757.46, 3579.14, 'expired'),
('POL00000418', 230, 'Health', '2024-05-10', '2025-05-10', 687.53, 245152.26, 3617.32, 'active'),
('POL00000419', 467, 'Auto', '2024-05-15', '2025-05-15', 662.88, 631900.78, 1554.8, 'expired'),
('POL00000420', 413, 'Home', '2025-12-20', '2026-12-20', 824.77, 399453.45, 2225.32, 'cancelled'),
('POL00000421', 379, 'Business', '2025-07-17', '2026-07-17', 103.47, 158550.32, 3217.94, 'expired'),
('POL00000422', 381, 'Auto', '2024-10-31', '2025-10-31', 939.95, 363562.35, 3628.96, 'active'),
('POL00000423', 301, 'Auto', '2025-06-10', '2026-06-10', 672.05, 234088.14, 3347.87, 'expired'),
('POL00000424', 84, 'Business', '2024-12-19', '2025-12-19', 291.52, 181903.46, 4817.88, 'cancelled'),
('POL00000425', 246, 'Health', '2025-03-14', '2026-03-14', 106.7, 912221.4, 797.99, 'cancelled'),
('POL00000426', 294, 'Life', '2025-02-17', '2026-02-17', 600.35, 696682.62, 997.42, 'active'),
('POL00000427', 76, 'Auto', '2024-06-04', '2025-06-04', 284.32, 853288.67, 1991.77, 'expired'),
('POL00000428', 157, 'Travel', '2024-10-13', '2025-10-13', 255.69, 890837.05, 2763.86, 'active'),
('POL00000429', 310, 'Life', '2025-12-02', '2026-12-02', 952.15, 90193.72, 2544.67, 'expired'),
('POL00000430', 183, 'Auto', '2024-08-31', '2025-08-31', 251.17, 908652.64, 754.1, 'active'),
('POL00000431', 328, 'Health', '2024-06-03', '2025-06-03', 743.1, 479737.14, 3025.71, 'active'),
('POL00000432', 152, 'Travel', '2024-09-21', '2025-09-21', 916.64, 369882.52, 3304.3, 'cancelled'),
('POL00000433', 257, 'Business', '2024-03-26', '2025-03-26', 607.87, 207164.45, 3577.86, 'cancelled'),
('POL00000434', 390, 'Auto', '2025-07-24', '2026-07-24', 592.51, 545617.81, 4555.69, 'cancelled'),
('POL00000435', 451, 'Auto', '2025-12-28', '2026-12-28', 883.5, 729955.86, 583.11, 'active'),
('POL00000436', 469, 'Life', '2025-04-16', '2026-04-16', 891.64, 737019.86, 981.23, 'expired'),
('POL00000437', 458, 'Auto', '2025-03-09', '2026-03-09', 367.13, 394522.26, 311.14, 'expired'),
('POL00000438', 67, 'Home', '2024-07-19', '2025-07-19', 479.8, 416306.26, 1857.52, 'active'),
('POL00000439', 201, 'Life', '2024-11-06', '2025-11-06', 287.83, 37307.88, 1121.65, 'active'),
('POL00000440', 324, 'Life', '2025-02-17', '2026-02-17', 625.88, 640492.25, 4855.84, 'expired'),
('POL00000441', 362, 'Home', '2025-05-31', '2026-05-31', 505.55, 636977.65, 3639.02, 'expired'),
('POL00000442', 69, 'Life', '2025-04-29', '2026-04-29', 827.49, 118044.25, 1747.96, 'expired'),
('POL00000443', 413, 'Travel', '2024-05-17', '2025-05-17', 275.36, 646069.52, 1246.88, 'expired'),
('POL00000444', 192, 'Auto', '2026-02-07', '2027-02-07', 249.8, 101240.4, 2336.61, 'expired'),
('POL00000445', 298, 'Auto', '2024-09-04', '2025-09-04', 850.81, 821525.16, 4958.89, 'cancelled'),
('POL00000446', 303, 'Travel', '2025-07-21', '2026-07-21', 321.6, 565217.64, 4575.28, 'expired'),
('POL00000447', 452, 'Health', '2025-02-04', '2026-02-04', 870.68, 620975.54, 3015.7, 'active'),
('POL00000448', 63, 'Auto', '2024-06-14', '2025-06-14', 619.26, 297957.88, 1585.02, 'cancelled'),
('POL00000449', 287, 'Business', '2025-05-21', '2026-05-21', 283.22, 600608.42, 3062.21, 'expired'),
('POL00000450', 75, 'Auto', '2026-02-11', '2027-02-11', 775.99, 519469.94, 2766.9, 'active'),
('POL00000451', 351, 'Business', '2025-01-15', '2026-01-15', 554.77, 803311.67, 564.49, 'expired'),
('POL00000452', 399, 'Home', '2024-06-03', '2025-06-03', 455.08, 167467.44, 3434.74, 'expired'),
('POL00000453', 280, 'Auto', '2025-03-02', '2026-03-02', 765.33, 963410.93, 1188.89, 'expired'),
('POL00000454', 226, 'Travel', '2025-06-07', '2026-06-07', 662.34, 583466.6, 3698.0, 'cancelled'),
('POL00000455', 99, 'Auto', '2024-04-27', '2025-04-27', 922.04, 35575.3, 4140.19, 'active'),
('POL00000456', 205, 'Business', '2025-08-24', '2026-08-24', 477.16, 423835.51, 2366.05, 'expired'),
('POL00000457', 162, 'Home', '2024-10-06', '2025-10-06', 866.95, 279410.2, 2113.75, 'expired'),
('POL00000458', 240, 'Life', '2024-04-22', '2025-04-22', 692.07, 952836.03, 1929.12, 'active'),
('POL00000459', 55, 'Travel', '2025-09-18', '2026-09-18', 238.9, 162422.72, 516.4, 'cancelled'),
('POL00000460', 332, 'Auto', '2024-11-26', '2025-11-26', 198.16, 465738.35, 1345.61, 'cancelled'),
('POL00000461', 74, 'Home', '2024-04-13', '2025-04-13', 285.69, 656899.93, 4937.92, 'expired'),
('POL00000462', 106, 'Life', '2026-02-11', '2027-02-11', 896.9, 401535.87, 3574.71, 'active'),
('POL00000463', 91, 'Business', '2025-05-22', '2026-05-22', 261.88, 19946.61, 3667.3, 'cancelled'),
('POL00000464', 14, 'Auto', '2025-02-12', '2026-02-12', 964.44, 36396.7, 3817.87, 'cancelled'),
('POL00000465', 393, 'Auto', '2025-07-11', '2026-07-11', 991.55, 89023.09, 906.84, 'active'),
('POL00000466', 70, 'Business', '2025-05-31', '2026-05-31', 575.84, 792213.44, 1456.43, 'expired'),
('POL00000467', 466, 'Health', '2024-04-16', '2025-04-16', 51.64, 322904.58, 1042.06, 'active'),
('POL00000468', 237, 'Auto', '2025-10-09', '2026-10-09', 803.01, 640220.12, 1334.24, 'active'),
('POL00000469', 315, 'Home', '2024-05-27', '2025-05-27', 795.15, 49833.01, 4389.84, 'cancelled'),
('POL00000470', 248, 'Business', '2024-10-02', '2025-10-02', 935.99, 145384.98, 4400.85, 'active'),
('POL00000471', 262, 'Life', '2024-06-07', '2025-06-07', 863.06, 353367.26, 4526.72, 'cancelled'),
('POL00000472', 417, 'Health', '2024-03-01', '2025-03-01', 429.29, 260340.08, 1275.3, 'active'),
('POL00000473', 405, 'Travel', '2024-07-12', '2025-07-12', 349.94, 783269.35, 819.83, 'cancelled'),
('POL00000474', 182, 'Business', '2025-05-06', '2026-05-06', 686.36, 996679.13, 805.87, 'active'),
('POL00000475', 413, 'Business', '2024-03-10', '2025-03-10', 428.93, 385358.07, 4027.06, 'active'),
('POL00000476', 180, 'Life', '2025-04-28', '2026-04-28', 656.13, 472173.63, 4628.23, 'active'),
('POL00000477', 166, 'Life', '2025-03-06', '2026-03-06', 645.03, 596098.31, 1968.41, 'active'),
('POL00000478', 344, 'Auto', '2026-02-01', '2027-02-01', 577.4, 453015.34, 3933.55, 'cancelled'),
('POL00000479', 7, 'Home', '2024-06-07', '2025-06-07', 203.63, 42042.66, 2162.77, 'active'),
('POL00000480', 17, 'Travel', '2025-10-08', '2026-10-08', 916.74, 936827.95, 2458.47, 'cancelled'),
('POL00000481', 144, 'Auto', '2026-01-21', '2027-01-21', 416.87, 424647.19, 3618.72, 'active'),
('POL00000482', 215, 'Travel', '2026-02-14', '2027-02-14', 653.19, 336037.72, 4797.8, 'expired'),
('POL00000483', 345, 'Home', '2025-12-29', '2026-12-29', 889.73, 288826.83, 2796.47, 'active'),
('POL00000484', 155, 'Health', '2025-12-12', '2026-12-12', 237.33, 687577.6, 2932.98, 'expired'),
('POL00000485', 329, 'Business', '2024-04-04', '2025-04-04', 594.03, 565958.12, 894.42, 'expired'),
('POL00000486', 333, 'Auto', '2024-04-10', '2025-04-10', 444.24, 136911.8, 3350.99, 'expired'),
('POL00000487', 391, 'Home', '2025-07-06', '2026-07-06', 696.67, 234144.68, 1420.13, 'expired'),
('POL00000488', 13, 'Life', '2025-04-27', '2026-04-27', 902.78, 306059.6, 723.1, 'expired'),
('POL00000489', 62, 'Life', '2025-04-22', '2026-04-22', 148.92, 647233.89, 3806.38, 'cancelled'),
('POL00000490', 216, 'Auto', '2024-09-17', '2025-09-17', 366.49, 809219.39, 3876.16, 'expired'),
('POL00000491', 356, 'Life', '2025-04-11', '2026-04-11', 173.3, 346021.84, 1816.2, 'cancelled'),
('POL00000492', 90, 'Health', '2025-11-18', '2026-11-18', 930.08, 708575.81, 1151.16, 'active'),
('POL00000493', 205, 'Home', '2025-04-23', '2026-04-23', 664.91, 212010.23, 1502.7, 'cancelled'),
('POL00000494', 86, 'Business', '2024-07-26', '2025-07-26', 110.73, 925785.78, 3051.19, 'expired'),
('POL00000495', 496, 'Travel', '2024-03-19', '2025-03-19', 565.0, 998907.28, 1576.21, 'cancelled'),
('POL00000496', 428, 'Auto', '2024-03-24', '2025-03-24', 857.83, 822708.36, 2901.63, 'active'),
('POL00000497', 155, 'Auto', '2025-08-06', '2026-08-06', 860.64, 800822.04, 2985.93, 'cancelled'),
('POL00000498', 311, 'Business', '2025-06-21', '2026-06-21', 645.99, 920195.98, 489.34, 'expired'),
('POL00000499', 50, 'Life', '2026-01-04', '2027-01-04', 992.59, 901245.72, 1251.15, 'active'),
('POL00000500', 437, 'Business', '2025-02-24', '2026-02-24', 851.73, 89618.22, 1651.96, 'cancelled'),
('POL00000501', 262, 'Auto', '2024-08-23', '2025-08-23', 719.47, 725175.52, 1420.48, 'active'),
('POL00000502', 315, 'Business', '2024-07-23', '2025-07-23', 296.69, 65196.64, 4759.17, 'cancelled'),
('POL00000503', 459, 'Home', '2025-04-15', '2026-04-15', 985.76, 656754.65, 1401.63, 'cancelled'),
('POL00000504', 369, 'Business', '2025-12-08', '2026-12-08', 893.15, 567328.77, 2982.21, 'active'),
('POL00000505', 227, 'Travel', '2025-09-20', '2026-09-20', 545.3, 38189.32, 4454.53, 'active'),
('POL00000506', 480, 'Home', '2025-04-06', '2026-04-06', 361.49, 763497.25, 509.08, 'cancelled'),
('POL00000507', 315, 'Auto', '2024-03-22', '2025-03-22', 575.17, 829306.98, 4637.83, 'active'),
('POL00000508', 189, 'Home', '2024-11-02', '2025-11-02', 296.63, 220343.82, 4992.86, 'expired'),
('POL00000509', 95, 'Life', '2026-01-21', '2027-01-21', 248.97, 205337.95, 4132.61, 'expired'),
('POL00000510', 426, 'Business', '2024-04-10', '2025-04-10', 122.14, 470744.08, 1931.44, 'cancelled'),
('POL00000511', 105, 'Auto', '2026-01-21', '2027-01-21', 95.7, 416542.96, 2527.38, 'expired'),
('POL00000512', 84, 'Travel', '2025-01-13', '2026-01-13', 381.2, 669279.18, 2609.82, 'active'),
('POL00000513', 472, 'Health', '2024-09-24', '2025-09-24', 478.44, 693446.86, 2971.46, 'expired'),
('POL00000514', 295, 'Health', '2025-08-09', '2026-08-09', 536.46, 180840.37, 2842.01, 'active'),
('POL00000515', 283, 'Business', '2025-10-01', '2026-10-01', 969.61, 147229.7, 2142.22, 'active'),
('POL00000516', 314, 'Business', '2025-02-13', '2026-02-13', 660.36, 929860.29, 4076.08, 'expired'),
('POL00000517', 276, 'Business', '2024-04-11', '2025-04-11', 991.92, 579263.68, 642.84, 'active'),
('POL00000518', 292, 'Home', '2024-10-21', '2025-10-21', 85.14, 301814.42, 730.03, 'expired'),
('POL00000519', 295, 'Auto', '2024-11-11', '2025-11-11', 455.28, 938646.05, 756.52, 'cancelled'),
('POL00000520', 442, 'Life', '2026-01-24', '2027-01-24', 992.54, 399398.04, 2403.16, 'cancelled'),
('POL00000521', 39, 'Auto', '2025-02-16', '2026-02-16', 182.89, 659578.57, 1050.43, 'expired'),
('POL00000522', 82, 'Life', '2024-12-17', '2025-12-17', 550.62, 947119.85, 4624.36, 'active'),
('POL00000523', 113, 'Health', '2024-12-21', '2025-12-21', 690.19, 819361.7, 4491.36, 'expired'),
('POL00000524', 426, 'Health', '2025-03-22', '2026-03-22', 439.46, 799807.04, 1849.03, 'expired'),
('POL00000525', 342, 'Life', '2025-08-01', '2026-08-01', 220.82, 334178.47, 3464.72, 'active'),
('POL00000526', 297, 'Auto', '2024-05-31', '2025-05-31', 879.56, 454182.6, 1061.44, 'cancelled'),
('POL00000527', 28, 'Travel', '2025-06-13', '2026-06-13', 332.69, 994486.11, 2015.41, 'active'),
('POL00000528', 44, 'Travel', '2024-06-13', '2025-06-13', 783.11, 592118.41, 1901.02, 'active'),
('POL00000529', 422, 'Life', '2024-07-26', '2025-07-26', 804.19, 663867.18, 3438.55, 'active'),
('POL00000530', 144, 'Travel', '2024-06-12', '2025-06-12', 920.61, 346736.91, 2750.44, 'active'),
('POL00000531', 101, 'Life', '2025-07-03', '2026-07-03', 424.73, 28936.79, 1744.88, 'cancelled'),
('POL00000532', 72, 'Health', '2024-04-30', '2025-04-30', 342.71, 990011.13, 4896.82, 'active'),
('POL00000533', 464, 'Health', '2025-12-11', '2026-12-11', 967.21, 787879.59, 1959.68, 'active'),
('POL00000534', 39, 'Business', '2024-08-26', '2025-08-26', 572.13, 407921.57, 2687.55, 'active'),
('POL00000535', 347, 'Auto', '2024-07-02', '2025-07-02', 55.48, 460200.72, 1538.47, 'cancelled'),
('POL00000536', 424, 'Life', '2025-12-21', '2026-12-21', 892.42, 289535.72, 658.61, 'expired'),
('POL00000537', 498, 'Health', '2026-02-17', '2027-02-17', 450.03, 122306.8, 627.42, 'expired'),
('POL00000538', 484, 'Life', '2025-06-28', '2026-06-28', 159.59, 557576.8, 4779.1, 'cancelled'),
('POL00000539', 2, 'Health', '2026-02-20', '2027-02-20', 338.78, 691513.38, 1182.59, 'cancelled'),
('POL00000540', 88, 'Auto', '2025-05-19', '2026-05-19', 649.72, 47731.0, 781.0, 'active'),
('POL00000541', 78, 'Health', '2025-10-18', '2026-10-18', 715.69, 994117.08, 3404.47, 'expired'),
('POL00000542', 160, 'Health', '2025-07-29', '2026-07-29', 581.75, 754492.78, 4431.84, 'cancelled'),
('POL00000543', 470, 'Home', '2024-09-14', '2025-09-14', 481.35, 663827.85, 433.09, 'active'),
('POL00000544', 490, 'Health', '2024-11-21', '2025-11-21', 322.52, 178206.93, 2178.96, 'expired'),
('POL00000545', 371, 'Home', '2024-07-26', '2025-07-26', 588.55, 405367.0, 2052.44, 'active'),
('POL00000546', 14, 'Home', '2024-07-20', '2025-07-20', 618.34, 787818.91, 533.19, 'cancelled'),
('POL00000547', 310, 'Travel', '2025-10-03', '2026-10-03', 585.43, 244077.35, 998.91, 'cancelled'),
('POL00000548', 378, 'Business', '2025-11-26', '2026-11-26', 927.86, 702956.85, 784.45, 'active'),
('POL00000549', 356, 'Home', '2024-09-16', '2025-09-16', 369.12, 665763.37, 4874.15, 'cancelled'),
('POL00000550', 50, 'Business', '2024-06-26', '2025-06-26', 565.32, 317712.75, 782.79, 'active'),
('POL00000551', 27, 'Health', '2024-06-06', '2025-06-06', 263.98, 244619.26, 1870.61, 'expired'),
('POL00000552', 154, 'Life', '2024-04-25', '2025-04-25', 698.31, 680946.78, 382.49, 'active'),
('POL00000553', 415, 'Business', '2025-05-03', '2026-05-03', 602.05, 806229.03, 2315.91, 'expired'),
('POL00000554', 48, 'Travel', '2026-01-04', '2027-01-04', 577.2, 147250.0, 2774.39, 'expired'),
('POL00000555', 278, 'Auto', '2024-10-12', '2025-10-12', 183.5, 741140.23, 1050.65, 'cancelled'),
('POL00000556', 367, 'Home', '2025-10-17', '2026-10-17', 282.92, 645733.32, 4814.98, 'expired'),
('POL00000557', 428, 'Auto', '2025-07-20', '2026-07-20', 272.84, 490527.4, 2999.8, 'active'),
('POL00000558', 208, 'Life', '2024-08-22', '2025-08-22', 765.52, 452848.02, 3932.53, 'active'),
('POL00000559', 115, 'Auto', '2024-03-18', '2025-03-18', 90.15, 531005.4, 4014.22, 'expired'),
('POL00000560', 161, 'Home', '2025-07-24', '2026-07-24', 216.62, 922970.3, 3155.78, 'cancelled'),
('POL00000561', 1, 'Auto', '2024-03-11', '2025-03-11', 819.92, 716936.73, 3680.68, 'expired'),
('POL00000562', 344, 'Business', '2026-02-14', '2027-02-14', 848.23, 372193.99, 1554.94, 'active'),
('POL00000563', 430, 'Auto', '2025-01-27', '2026-01-27', 331.2, 617500.81, 3969.54, 'active'),
('POL00000564', 338, 'Home', '2024-08-30', '2025-08-30', 336.03, 697034.22, 2734.15, 'cancelled'),
('POL00000565', 490, 'Business', '2026-01-16', '2027-01-16', 722.67, 474437.03, 3650.53, 'expired'),
('POL00000566', 431, 'Auto', '2025-01-28', '2026-01-28', 632.9, 450278.51, 4960.03, 'cancelled'),
('POL00000567', 332, 'Auto', '2024-02-26', '2025-02-25', 208.69, 867769.36, 522.12, 'active'),
('POL00000568', 180, 'Business', '2026-01-17', '2027-01-17', 112.86, 47114.01, 2962.35, 'active'),
('POL00000569', 71, 'Business', '2025-03-09', '2026-03-09', 876.15, 474166.35, 957.78, 'active'),
('POL00000570', 1, 'Auto', '2024-07-11', '2025-07-11', 364.8, 438891.13, 1916.13, 'expired'),
('POL00000571', 164, 'Health', '2025-10-15', '2026-10-15', 844.13, 751588.44, 1965.89, 'expired'),
('POL00000572', 16, 'Business', '2026-01-15', '2027-01-15', 832.91, 351661.91, 4030.95, 'expired'),
('POL00000573', 3, 'Auto', '2025-02-11', '2026-02-11', 489.94, 411167.88, 3701.67, 'active'),
('POL00000574', 17, 'Health', '2025-03-07', '2026-03-07', 336.46, 173946.02, 4646.8, 'active'),
('POL00000575', 453, 'Travel', '2024-02-26', '2025-02-25', 323.96, 63421.53, 3980.72, 'cancelled'),
('POL00000576', 198, 'Travel', '2025-06-16', '2026-06-16', 585.92, 925652.2, 3554.54, 'active'),
('POL00000577', 379, 'Health', '2024-03-02', '2025-03-02', 552.58, 954112.51, 4896.5, 'active'),
('POL00000578', 409, 'Business', '2024-05-18', '2025-05-18', 522.17, 694277.11, 883.73, 'expired'),
('POL00000579', 178, 'Business', '2025-07-30', '2026-07-30', 418.78, 607692.6, 1414.63, 'active'),
('POL00000580', 98, 'Home', '2025-03-01', '2026-03-01', 244.73, 801059.97, 4045.31, 'active'),
('POL00000581', 218, 'Health', '2025-05-12', '2026-05-12', 423.08, 490500.2, 4973.49, 'active'),
('POL00000582', 310, 'Life', '2025-07-27', '2026-07-27', 513.09, 853170.72, 1533.58, 'expired'),
('POL00000583', 67, 'Travel', '2025-10-21', '2026-10-21', 969.16, 703403.57, 2828.08, 'active'),
('POL00000584', 261, 'Business', '2025-08-24', '2026-08-24', 393.79, 87445.7, 3838.37, 'cancelled'),
('POL00000585', 395, 'Health', '2024-08-11', '2025-08-11', 900.29, 330202.86, 1473.92, 'expired'),
('POL00000586', 305, 'Auto', '2025-12-25', '2026-12-25', 975.44, 84267.8, 825.96, 'active'),
('POL00000587', 144, 'Health', '2025-12-08', '2026-12-08', 468.51, 38414.75, 4852.71, 'expired'),
('POL00000588', 270, 'Life', '2025-05-31', '2026-05-31', 256.73, 404655.84, 2860.41, 'active'),
('POL00000589', 317, 'Travel', '2024-08-27', '2025-08-27', 210.45, 968175.57, 2410.1, 'active'),
('POL00000590', 447, 'Life', '2026-01-23', '2027-01-23', 167.21, 857463.61, 2157.47, 'cancelled'),
('POL00000591', 22, 'Auto', '2025-02-22', '2026-02-22', 772.09, 998844.47, 4191.03, 'expired'),
('POL00000592', 54, 'Business', '2024-07-06', '2025-07-06', 901.16, 408376.05, 2967.96, 'expired'),
('POL00000593', 238, 'Life', '2024-08-25', '2025-08-25', 286.12, 779851.66, 400.47, 'cancelled'),
('POL00000594', 242, 'Business', '2024-03-06', '2025-03-06', 508.88, 339995.1, 2699.8, 'cancelled'),
('POL00000595', 95, 'Auto', '2024-11-19', '2025-11-19', 446.68, 804792.28, 2365.07, 'cancelled'),
('POL00000596', 60, 'Health', '2024-03-30', '2025-03-30', 498.12, 205501.49, 4548.1, 'cancelled'),
('POL00000597', 90, 'Auto', '2025-01-22', '2026-01-22', 582.12, 398422.63, 2483.86, 'expired'),
('POL00000598', 61, 'Home', '2025-08-09', '2026-08-09', 341.09, 100075.94, 829.33, 'cancelled'),
('POL00000599', 401, 'Home', '2025-04-29', '2026-04-29', 750.46, 860211.53, 450.85, 'cancelled'),
('POL00000600', 227, 'Business', '2025-09-21', '2026-09-21', 602.23, 250200.33, 2358.0, 'cancelled'),
('POL00000601', 488, 'Health', '2025-02-25', '2026-02-25', 320.18, 786882.67, 4562.56, 'cancelled'),
('POL00000602', 104, 'Travel', '2025-10-05', '2026-10-05', 150.01, 95164.74, 2273.7, 'active'),
('POL00000603', 105, 'Home', '2024-08-20', '2025-08-20', 515.85, 664938.67, 252.51, 'active'),
('POL00000604', 466, 'Health', '2025-11-10', '2026-11-10', 423.46, 28520.79, 3189.14, 'active'),
('POL00000605', 458, 'Travel', '2024-08-07', '2025-08-07', 947.44, 830757.01, 854.81, 'cancelled'),
('POL00000606', 59, 'Health', '2024-03-12', '2025-03-12', 421.91, 649213.11, 1407.75, 'active'),
('POL00000607', 74, 'Travel', '2025-05-27', '2026-05-27', 197.59, 803979.93, 3161.95, 'expired'),
('POL00000608', 99, 'Travel', '2025-11-18', '2026-11-18', 209.45, 854254.23, 1689.35, 'cancelled'),
('POL00000609', 72, 'Life', '2024-10-29', '2025-10-29', 603.23, 152113.35, 4410.64, 'expired'),
('POL00000610', 62, 'Life', '2025-10-02', '2026-10-02', 635.64, 355479.41, 3085.35, 'cancelled'),
('POL00000611', 408, 'Life', '2024-10-20', '2025-10-20', 61.09, 396558.46, 2164.91, 'expired'),
('POL00000612', 124, 'Auto', '2026-01-12', '2027-01-12', 269.66, 106700.43, 3408.86, 'active'),
('POL00000613', 137, 'Life', '2025-11-08', '2026-11-08', 307.56, 569540.93, 1096.0, 'expired'),
('POL00000614', 485, 'Life', '2024-11-12', '2025-11-12', 702.74, 255530.0, 2373.0, 'cancelled'),
('POL00000615', 22, 'Life', '2025-01-08', '2026-01-08', 201.17, 438385.14, 3703.03, 'expired'),
('POL00000616', 12, 'Auto', '2024-03-06', '2025-03-06', 784.75, 592334.56, 3546.81, 'expired'),
('POL00000617', 480, 'Home', '2025-08-09', '2026-08-09', 993.03, 907952.12, 2939.18, 'active'),
('POL00000618', 141, 'Health', '2025-10-23', '2026-10-23', 451.13, 293470.64, 4346.89, 'active'),
('POL00000619', 82, 'Auto', '2025-05-20', '2026-05-20', 224.45, 144623.64, 1212.13, 'cancelled'),
('POL00000620', 453, 'Health', '2025-12-03', '2026-12-03', 930.76, 972986.43, 1134.66, 'expired'),
('POL00000621', 151, 'Home', '2025-03-07', '2026-03-07', 802.92, 952281.51, 1128.1, 'cancelled'),
('POL00000622', 202, 'Travel', '2026-02-21', '2027-02-21', 531.62, 215663.63, 2657.4, 'cancelled'),
('POL00000623', 177, 'Travel', '2025-06-01', '2026-06-01', 748.29, 486622.77, 2170.98, 'cancelled'),
('POL00000624', 389, 'Home', '2025-02-08', '2026-02-08', 461.85, 420335.17, 3341.19, 'expired'),
('POL00000625', 2, 'Travel', '2025-09-28', '2026-09-28', 981.48, 520023.32, 348.55, 'cancelled'),
('POL00000626', 39, 'Home', '2024-02-26', '2025-02-25', 923.56, 932012.12, 2626.51, 'cancelled'),
('POL00000627', 121, 'Home', '2024-09-26', '2025-09-26', 813.81, 597281.53, 1096.78, 'active'),
('POL00000628', 427, 'Auto', '2024-07-20', '2025-07-20', 910.72, 653687.47, 4027.24, 'cancelled'),
('POL00000629', 441, 'Home', '2024-11-02', '2025-11-02', 374.55, 965792.3, 276.78, 'cancelled'),
('POL00000630', 489, 'Health', '2025-06-12', '2026-06-12', 176.78, 707898.47, 2886.36, 'cancelled'),
('POL00000631', 76, 'Business', '2024-08-05', '2025-08-05', 838.55, 787004.87, 3547.51, 'cancelled'),
('POL00000632', 34, 'Travel', '2024-08-04', '2025-08-04', 865.87, 60928.44, 1235.96, 'active'),
('POL00000633', 133, 'Business', '2025-02-04', '2026-02-04', 963.2, 560619.96, 2322.47, 'cancelled'),
('POL00000634', 135, 'Home', '2025-10-28', '2026-10-28', 987.9, 808266.87, 4082.32, 'active'),
('POL00000635', 79, 'Business', '2024-08-06', '2025-08-06', 176.44, 455941.53, 783.17, 'cancelled'),
('POL00000636', 243, 'Life', '2024-08-01', '2025-08-01', 91.27, 95213.0, 4672.92, 'expired'),
('POL00000637', 430, 'Business', '2025-08-20', '2026-08-20', 74.06, 798575.07, 4099.49, 'active'),
('POL00000638', 450, 'Life', '2025-06-01', '2026-06-01', 380.06, 765455.13, 4493.56, 'active'),
('POL00000639', 33, 'Life', '2024-08-22', '2025-08-22', 702.33, 241243.09, 2030.23, 'cancelled'),
('POL00000640', 184, 'Business', '2026-01-17', '2027-01-17', 791.04, 907696.82, 3809.66, 'active'),
('POL00000641', 319, 'Health', '2024-03-31', '2025-03-31', 713.18, 562644.11, 2695.71, 'active'),
('POL00000642', 36, 'Life', '2025-05-05', '2026-05-05', 134.85, 189580.65, 1557.33, 'cancelled'),
('POL00000643', 338, 'Auto', '2024-11-16', '2025-11-16', 936.61, 213514.72, 787.46, 'active'),
('POL00000644', 260, 'Life', '2024-11-03', '2025-11-03', 112.02, 258522.97, 4393.25, 'active'),
('POL00000645', 350, 'Home', '2024-06-18', '2025-06-18', 922.31, 672184.32, 938.45, 'expired'),
('POL00000646', 292, 'Auto', '2024-12-15', '2025-12-15', 740.13, 653987.99, 1676.49, 'cancelled'),
('POL00000647', 393, 'Travel', '2025-06-05', '2026-06-05', 848.68, 208900.54, 2530.16, 'expired'),
('POL00000648', 420, 'Health', '2025-07-22', '2026-07-22', 413.7, 694184.83, 4392.21, 'active'),
('POL00000649', 66, 'Business', '2025-11-14', '2026-11-14', 221.97, 459306.19, 359.75, 'cancelled'),
('POL00000650', 230, 'Business', '2026-02-23', '2027-02-23', 605.98, 112613.46, 3390.32, 'expired'),
('POL00000651', 393, 'Home', '2024-04-08', '2025-04-08', 929.94, 799045.8, 1048.79, 'active'),
('POL00000652', 154, 'Auto', '2025-11-18', '2026-11-18', 840.53, 756394.22, 2420.61, 'active'),
('POL00000653', 449, 'Auto', '2026-01-25', '2027-01-25', 941.02, 880691.82, 3336.2, 'expired'),
('POL00000654', 411, 'Health', '2025-04-10', '2026-04-10', 54.26, 875837.28, 389.02, 'active'),
('POL00000655', 65, 'Home', '2025-08-17', '2026-08-17', 475.69, 311695.51, 4974.23, 'expired'),
('POL00000656', 113, 'Business', '2024-12-15', '2025-12-15', 255.26, 436038.35, 3191.37, 'cancelled'),
('POL00000657', 356, 'Travel', '2025-10-01', '2026-10-01', 307.44, 552466.15, 1180.86, 'active'),
('POL00000658', 388, 'Life', '2025-05-11', '2026-05-11', 99.84, 255105.03, 813.73, 'cancelled'),
('POL00000659', 435, 'Life', '2025-09-14', '2026-09-14', 758.98, 146640.82, 2034.46, 'active'),
('POL00000660', 478, 'Business', '2024-08-12', '2025-08-12', 431.95, 876535.21, 3593.81, 'expired'),
('POL00000661', 38, 'Home', '2025-03-31', '2026-03-31', 219.38, 956198.47, 1822.33, 'active'),
('POL00000662', 220, 'Auto', '2024-04-13', '2025-04-13', 778.43, 271370.17, 1450.04, 'expired'),
('POL00000663', 402, 'Health', '2025-09-12', '2026-09-12', 738.21, 669588.26, 4597.76, 'cancelled'),
('POL00000664', 482, 'Health', '2024-09-07', '2025-09-07', 713.49, 197900.83, 1773.33, 'expired'),
('POL00000665', 119, 'Life', '2025-06-15', '2026-06-15', 473.9, 769036.36, 3445.57, 'active'),
('POL00000666', 68, 'Travel', '2024-11-04', '2025-11-04', 822.5, 667448.5, 2724.65, 'expired'),
('POL00000667', 228, 'Travel', '2024-05-19', '2025-05-19', 247.23, 246376.04, 4959.64, 'expired'),
('POL00000668', 260, 'Health', '2026-02-22', '2027-02-22', 101.91, 864192.76, 2145.63, 'active'),
('POL00000669', 264, 'Health', '2024-08-12', '2025-08-12', 732.36, 180046.04, 1361.92, 'active'),
('POL00000670', 57, 'Life', '2024-11-24', '2025-11-24', 473.32, 16947.51, 4708.69, 'expired'),
('POL00000671', 449, 'Business', '2024-06-22', '2025-06-22', 304.54, 17556.94, 2458.42, 'active'),
('POL00000672', 318, 'Travel', '2025-05-20', '2026-05-20', 819.39, 677123.75, 3358.28, 'active'),
('POL00000673', 170, 'Life', '2024-04-30', '2025-04-30', 124.66, 180997.47, 3181.61, 'cancelled'),
('POL00000674', 71, 'Home', '2025-03-13', '2026-03-13', 338.75, 382533.62, 4406.77, 'active'),
('POL00000675', 222, 'Auto', '2024-10-27', '2025-10-27', 168.04, 796264.9, 1088.9, 'cancelled'),
('POL00000676', 9, 'Travel', '2025-07-15', '2026-07-15', 371.53, 313258.73, 3829.59, 'cancelled'),
('POL00000677', 379, 'Business', '2024-09-17', '2025-09-17', 787.94, 865168.84, 1726.4, 'expired'),
('POL00000678', 406, 'Business', '2024-06-09', '2025-06-09', 200.67, 616725.1, 432.19, 'active'),
('POL00000679', 79, 'Life', '2024-04-07', '2025-04-07', 716.29, 823756.38, 3260.5, 'expired'),
('POL00000680', 145, 'Auto', '2025-06-22', '2026-06-22', 573.37, 559086.28, 492.16, 'active'),
('POL00000681', 391, 'Travel', '2024-11-22', '2025-11-22', 949.55, 436069.7, 2550.71, 'cancelled'),
('POL00000682', 170, 'Health', '2025-08-19', '2026-08-19', 356.49, 304421.67, 3108.35, 'cancelled'),
('POL00000683', 143, 'Auto', '2024-11-23', '2025-11-23', 797.65, 407240.02, 4480.28, 'active'),
('POL00000684', 304, 'Home', '2025-04-30', '2026-04-30', 553.26, 909069.99, 1071.46, 'cancelled'),
('POL00000685', 100, 'Auto', '2025-09-20', '2026-09-20', 265.12, 809351.62, 648.12, 'cancelled'),
('POL00000686', 80, 'Health', '2025-08-11', '2026-08-11', 758.83, 64380.93, 2975.56, 'active'),
('POL00000687', 392, 'Health', '2024-04-13', '2025-04-13', 614.99, 596678.72, 3671.99, 'active'),
('POL00000688', 67, 'Travel', '2024-10-07', '2025-10-07', 82.27, 549796.0, 3659.57, 'active'),
('POL00000689', 59, 'Home', '2025-04-20', '2026-04-20', 305.62, 690796.33, 341.4, 'expired'),
('POL00000690', 354, 'Home', '2026-02-04', '2027-02-04', 984.2, 38521.78, 561.22, 'active'),
('POL00000691', 293, 'Health', '2024-04-09', '2025-04-09', 960.21, 581181.24, 2623.58, 'expired'),
('POL00000692', 336, 'Travel', '2025-11-12', '2026-11-12', 171.22, 357725.82, 439.21, 'expired'),
('POL00000693', 479, 'Auto', '2025-11-04', '2026-11-04', 333.38, 723637.15, 4076.87, 'expired'),
('POL00000694', 98, 'Life', '2025-03-14', '2026-03-14', 561.64, 869418.34, 662.24, 'expired'),
('POL00000695', 57, 'Business', '2025-10-18', '2026-10-18', 497.47, 953704.14, 717.97, 'active'),
('POL00000696', 79, 'Life', '2025-07-27', '2026-07-27', 86.78, 613914.46, 1411.65, 'cancelled'),
('POL00000697', 469, 'Business', '2025-05-10', '2026-05-10', 58.47, 927652.27, 2637.91, 'active'),
('POL00000698', 298, 'Life', '2024-07-14', '2025-07-14', 747.27, 520283.96, 1865.1, 'expired'),
('POL00000699', 384, 'Auto', '2025-10-20', '2026-10-20', 420.4, 289555.28, 1201.85, 'cancelled'),
('POL00000700', 465, 'Life', '2024-10-01', '2025-10-01', 57.3, 72341.54, 509.18, 'cancelled'),
('POL00000701', 419, 'Home', '2024-06-07', '2025-06-07', 204.32, 496840.43, 4997.77, 'active'),
('POL00000702', 150, 'Travel', '2025-03-13', '2026-03-13', 877.79, 153192.97, 484.68, 'active'),
('POL00000703', 247, 'Auto', '2024-09-24', '2025-09-24', 476.63, 860002.92, 3254.76, 'expired'),
('POL00000704', 208, 'Life', '2024-08-06', '2025-08-06', 989.79, 599288.75, 1870.88, 'expired'),
('POL00000705', 94, 'Business', '2025-03-23', '2026-03-23', 224.54, 23984.43, 2888.56, 'cancelled'),
('POL00000706', 131, 'Travel', '2025-10-12', '2026-10-12', 684.93, 467775.12, 3786.96, 'expired'),
('POL00000707', 36, 'Business', '2025-07-01', '2026-07-01', 989.01, 738579.38, 2224.92, 'active'),
('POL00000708', 295, 'Home', '2025-11-14', '2026-11-14', 736.66, 956596.89, 1595.24, 'active'),
('POL00000709', 249, 'Life', '2025-01-25', '2026-01-25', 960.07, 55796.85, 2209.16, 'cancelled'),
('POL00000710', 309, 'Life', '2024-10-18', '2025-10-18', 858.87, 782996.12, 2257.11, 'active'),
('POL00000711', 33, 'Auto', '2025-05-30', '2026-05-30', 727.03, 438561.21, 2402.36, 'cancelled'),
('POL00000712', 365, 'Auto', '2024-03-14', '2025-03-14', 835.45, 662850.51, 4484.51, 'cancelled'),
('POL00000713', 267, 'Auto', '2024-12-25', '2025-12-25', 800.74, 222444.86, 1318.74, 'active'),
('POL00000714', 391, 'Travel', '2025-08-21', '2026-08-21', 409.33, 536561.96, 3663.69, 'active'),
('POL00000715', 422, 'Home', '2024-12-20', '2025-12-20', 161.46, 455340.52, 998.33, 'active'),
('POL00000716', 60, 'Health', '2024-12-27', '2025-12-27', 100.19, 24205.02, 1191.03, 'cancelled'),
('POL00000717', 500, 'Travel', '2025-07-13', '2026-07-13', 745.02, 178553.46, 3805.33, 'expired'),
('POL00000718', 265, 'Life', '2026-01-27', '2027-01-27', 58.64, 793642.26, 1125.77, 'cancelled'),
('POL00000719', 209, 'Auto', '2024-10-27', '2025-10-27', 983.58, 710689.91, 817.95, 'active'),
('POL00000720', 220, 'Travel', '2024-12-23', '2025-12-23', 929.05, 313923.84, 2209.42, 'expired'),
('POL00000721', 18, 'Health', '2024-06-15', '2025-06-15', 793.8, 995310.59, 355.49, 'active'),
('POL00000722', 80, 'Health', '2024-06-04', '2025-06-04', 437.53, 638278.98, 1285.71, 'expired'),
('POL00000723', 36, 'Home', '2024-11-01', '2025-11-01', 191.07, 444992.01, 2616.01, 'cancelled'),
('POL00000724', 348, 'Home', '2025-09-21', '2026-09-21', 464.47, 658671.96, 4105.17, 'cancelled'),
('POL00000725', 431, 'Travel', '2025-01-28', '2026-01-28', 565.2, 636063.78, 2142.06, 'cancelled'),
('POL00000726', 365, 'Business', '2024-07-04', '2025-07-04', 627.91, 236938.93, 4633.73, 'active'),
('POL00000727', 341, 'Life', '2025-10-20', '2026-10-20', 920.36, 415698.6, 2723.76, 'expired'),
('POL00000728', 136, 'Auto', '2026-01-27', '2027-01-27', 592.24, 197327.77, 3054.94, 'expired'),
('POL00000729', 292, 'Health', '2025-01-06', '2026-01-06', 198.34, 767978.77, 2057.48, 'cancelled'),
('POL00000730', 24, 'Life', '2025-06-30', '2026-06-30', 527.89, 449808.5, 4736.88, 'cancelled'),
('POL00000731', 297, 'Health', '2024-12-03', '2025-12-03', 459.81, 707453.63, 2479.92, 'expired'),
('POL00000732', 378, 'Life', '2024-04-11', '2025-04-11', 138.22, 429306.71, 4134.94, 'expired'),
('POL00000733', 438, 'Home', '2025-08-23', '2026-08-23', 571.92, 627797.05, 2292.09, 'active'),
('POL00000734', 328, 'Auto', '2024-03-17', '2025-03-17', 691.75, 571032.54, 328.59, 'active'),
('POL00000735', 379, 'Business', '2025-06-26', '2026-06-26', 100.01, 290461.43, 4084.88, 'expired'),
('POL00000736', 274, 'Auto', '2025-05-06', '2026-05-06', 221.89, 495061.53, 4371.64, 'cancelled'),
('POL00000737', 301, 'Auto', '2025-06-28', '2026-06-28', 421.06, 986907.43, 3598.59, 'expired'),
('POL00000738', 383, 'Life', '2025-11-13', '2026-11-13', 795.44, 118469.12, 4941.17, 'cancelled'),
('POL00000739', 442, 'Travel', '2024-05-22', '2025-05-22', 122.93, 344413.92, 3926.01, 'active'),
('POL00000740', 42, 'Business', '2026-01-29', '2027-01-29', 684.74, 767577.73, 1098.6, 'active'),
('POL00000741', 274, 'Life', '2025-06-10', '2026-06-10', 597.85, 915626.6, 2353.87, 'active'),
('POL00000742', 366, 'Auto', '2024-08-12', '2025-08-12', 517.29, 275396.78, 4873.77, 'expired'),
('POL00000743', 117, 'Auto', '2025-07-28', '2026-07-28', 386.95, 720667.87, 4843.42, 'expired'),
('POL00000744', 372, 'Business', '2024-07-03', '2025-07-03', 331.13, 877619.0, 3153.73, 'cancelled'),
('POL00000745', 142, 'Home', '2025-11-23', '2026-11-23', 991.3, 19298.79, 3442.67, 'cancelled'),
('POL00000746', 71, 'Auto', '2025-06-14', '2026-06-14', 137.39, 385452.22, 640.97, 'active'),
('POL00000747', 215, 'Travel', '2025-07-11', '2026-07-11', 320.91, 435555.05, 3903.39, 'expired'),
('POL00000748', 332, 'Auto', '2025-03-01', '2026-03-01', 863.55, 575213.26, 3942.35, 'cancelled'),
('POL00000749', 4, 'Auto', '2026-02-22', '2027-02-22', 429.88, 364412.58, 3578.16, 'cancelled'),
('POL00000750', 447, 'Auto', '2025-02-18', '2026-02-18', 221.46, 886707.22, 3281.62, 'expired'),
('POL00000751', 26, 'Business', '2024-10-30', '2025-10-30', 942.88, 343705.71, 1803.22, 'active'),
('POL00000752', 416, 'Auto', '2024-10-09', '2025-10-09', 197.36, 231129.32, 2228.91, 'cancelled'),
('POL00000753', 303, 'Travel', '2025-05-29', '2026-05-29', 131.56, 133319.82, 3230.19, 'expired'),
('POL00000754', 330, 'Auto', '2025-04-09', '2026-04-09', 521.17, 41996.03, 4073.47, 'active'),
('POL00000755', 397, 'Auto', '2024-06-23', '2025-06-23', 358.15, 525936.13, 1458.84, 'active'),
('POL00000756', 66, 'Life', '2024-05-01', '2025-05-01', 739.51, 939911.39, 4285.81, 'active'),
('POL00000757', 451, 'Business', '2025-08-05', '2026-08-05', 650.78, 748093.91, 2309.27, 'active'),
('POL00000758', 479, 'Home', '2025-11-02', '2026-11-02', 961.49, 184962.29, 4658.27, 'cancelled'),
('POL00000759', 64, 'Travel', '2024-10-22', '2025-10-22', 377.29, 191640.31, 4570.61, 'active'),
('POL00000760', 100, 'Life', '2025-06-04', '2026-06-04', 777.03, 935403.63, 4508.5, 'cancelled'),
('POL00000761', 419, 'Travel', '2025-03-22', '2026-03-22', 894.42, 457133.0, 1614.36, 'active'),
('POL00000762', 11, 'Travel', '2025-09-10', '2026-09-10', 735.13, 704626.95, 4181.52, 'cancelled'),
('POL00000763', 193, 'Health', '2025-01-13', '2026-01-13', 292.03, 725008.37, 1080.06, 'active'),
('POL00000764', 92, 'Health', '2024-12-21', '2025-12-21', 513.57, 675124.95, 4366.4, 'cancelled'),
('POL00000765', 339, 'Travel', '2025-09-29', '2026-09-29', 209.05, 299003.53, 1555.44, 'active'),
('POL00000766', 342, 'Travel', '2025-05-19', '2026-05-19', 476.66, 789425.74, 658.48, 'expired'),
('POL00000767', 481, 'Travel', '2024-04-16', '2025-04-16', 863.86, 444554.36, 1785.47, 'expired'),
('POL00000768', 292, 'Travel', '2024-06-27', '2025-06-27', 73.98, 22640.22, 2474.45, 'expired'),
('POL00000769', 34, 'Health', '2025-03-05', '2026-03-05', 704.75, 64000.39, 2165.49, 'active'),
('POL00000770', 120, 'Home', '2024-09-15', '2025-09-15', 846.73, 579320.18, 1742.06, 'expired'),
('POL00000771', 1, 'Health', '2025-07-13', '2026-07-13', 807.44, 806434.28, 756.54, 'active'),
('POL00000772', 167, 'Auto', '2024-03-19', '2025-03-19', 914.19, 930076.32, 2339.04, 'cancelled'),
('POL00000773', 184, 'Auto', '2024-08-12', '2025-08-12', 374.91, 74777.31, 4057.99, 'active'),
('POL00000774', 474, 'Life', '2025-03-26', '2026-03-26', 144.24, 982993.67, 1727.61, 'expired'),
('POL00000775', 427, 'Business', '2025-04-07', '2026-04-07', 289.81, 867019.64, 1879.75, 'active'),
('POL00000776', 228, 'Home', '2024-07-23', '2025-07-23', 841.58, 193332.17, 402.2, 'active'),
('POL00000777', 258, 'Auto', '2024-04-28', '2025-04-28', 290.99, 815882.9, 4394.65, 'cancelled'),
('POL00000778', 154, 'Travel', '2026-01-05', '2027-01-05', 162.97, 717798.99, 1822.23, 'cancelled'),
('POL00000779', 74, 'Health', '2025-06-09', '2026-06-09', 363.95, 793545.8, 3241.42, 'expired'),
('POL00000780', 325, 'Life', '2025-09-28', '2026-09-28', 856.27, 763918.55, 3002.44, 'expired'),
('POL00000781', 231, 'Health', '2025-05-15', '2026-05-15', 788.81, 110761.46, 4848.14, 'cancelled'),
('POL00000782', 146, 'Life', '2024-06-18', '2025-06-18', 146.82, 404401.35, 3723.1, 'active'),
('POL00000783', 500, 'Life', '2025-11-07', '2026-11-07', 772.69, 190635.48, 3201.61, 'active'),
('POL00000784', 157, 'Business', '2025-06-17', '2026-06-17', 795.35, 587720.23, 2630.95, 'cancelled'),
('POL00000785', 15, 'Home', '2024-10-08', '2025-10-08', 603.8, 94628.75, 2617.0, 'expired'),
('POL00000786', 190, 'Travel', '2024-04-18', '2025-04-18', 575.62, 411363.43, 3908.26, 'cancelled'),
('POL00000787', 500, 'Auto', '2025-09-03', '2026-09-03', 108.52, 28084.81, 3877.1, 'expired'),
('POL00000788', 150, 'Life', '2024-04-10', '2025-04-10', 946.07, 241066.2, 4760.5, 'active'),
('POL00000789', 340, 'Health', '2025-02-23', '2026-02-23', 938.43, 703060.88, 711.97, 'cancelled'),
('POL00000790', 404, 'Travel', '2026-01-18', '2027-01-18', 696.24, 131374.0, 3656.78, 'cancelled'),
('POL00000791', 93, 'Auto', '2025-05-22', '2026-05-22', 581.37, 808305.03, 1159.96, 'active'),
('POL00000792', 482, 'Business', '2025-02-27', '2026-02-27', 893.62, 547319.81, 359.56, 'cancelled'),
('POL00000793', 252, 'Travel', '2025-04-15', '2026-04-15', 662.0, 846385.49, 4971.38, 'active'),
('POL00000794', 186, 'Business', '2025-01-30', '2026-01-30', 825.84, 954561.39, 3066.28, 'expired'),
('POL00000795', 318, 'Travel', '2024-03-12', '2025-03-12', 411.13, 180597.69, 294.62, 'cancelled'),
('POL00000796', 487, 'Health', '2025-10-24', '2026-10-24', 91.97, 495341.99, 4696.7, 'cancelled'),
('POL00000797', 149, 'Life', '2025-09-01', '2026-09-01', 71.62, 113336.16, 729.17, 'cancelled'),
('POL00000798', 165, 'Auto', '2024-11-14', '2025-11-14', 304.14, 160288.04, 1417.69, 'cancelled'),
('POL00000799', 466, 'Health', '2025-04-14', '2026-04-14', 79.56, 823045.18, 3728.62, 'active'),
('POL00000800', 219, 'Life', '2024-10-21', '2025-10-21', 197.5, 712383.39, 956.55, 'expired'),
('POL00000801', 88, 'Business', '2024-08-19', '2025-08-19', 901.6, 801158.64, 1550.18, 'expired'),
('POL00000802', 117, 'Auto', '2024-04-06', '2025-04-06', 924.36, 433858.6, 2722.99, 'cancelled'),
('POL00000803', 436, 'Auto', '2024-12-25', '2025-12-25', 804.49, 126634.07, 2953.12, 'expired'),
('POL00000804', 395, 'Auto', '2025-06-29', '2026-06-29', 809.34, 781381.79, 1061.18, 'cancelled'),
('POL00000805', 178, 'Auto', '2024-09-30', '2025-09-30', 810.46, 441311.66, 2737.9, 'expired'),
('POL00000806', 453, 'Health', '2025-02-26', '2026-02-26', 665.36, 942459.72, 1073.85, 'expired'),
('POL00000807', 362, 'Business', '2025-10-18', '2026-10-18', 845.12, 802701.35, 3146.28, 'cancelled'),
('POL00000808', 294, 'Auto', '2025-03-25', '2026-03-25', 398.39, 916051.03, 3210.84, 'active'),
('POL00000809', 180, 'Travel', '2026-01-25', '2027-01-25', 257.57, 144167.05, 2396.23, 'expired'),
('POL00000810', 267, 'Health', '2024-06-25', '2025-06-25', 129.27, 446530.79, 1801.0, 'active'),
('POL00000811', 419, 'Health', '2024-10-03', '2025-10-03', 695.7, 367065.96, 2972.05, 'expired'),
('POL00000812', 77, 'Business', '2024-08-15', '2025-08-15', 542.21, 506924.48, 347.75, 'expired'),
('POL00000813', 5, 'Home', '2025-08-11', '2026-08-11', 345.14, 529628.48, 2266.05, 'active'),
('POL00000814', 277, 'Life', '2025-05-27', '2026-05-27', 599.99, 738855.23, 2437.18, 'expired'),
('POL00000815', 354, 'Travel', '2024-09-05', '2025-09-05', 759.6, 756296.48, 2470.27, 'cancelled'),
('POL00000816', 456, 'Business', '2025-12-02', '2026-12-02', 606.66, 702358.05, 663.0, 'active'),
('POL00000817', 19, 'Travel', '2025-09-19', '2026-09-19', 54.28, 759873.31, 256.55, 'cancelled'),
('POL00000818', 95, 'Health', '2025-10-12', '2026-10-12', 832.88, 262974.84, 1699.15, 'expired'),
('POL00000819', 138, 'Home', '2026-02-21', '2027-02-21', 564.95, 768626.23, 4738.87, 'expired'),
('POL00000820', 140, 'Auto', '2025-10-19', '2026-10-19', 449.97, 906154.45, 4342.52, 'expired'),
('POL00000821', 133, 'Business', '2025-09-17', '2026-09-17', 730.84, 515459.47, 534.69, 'expired'),
('POL00000822', 186, 'Auto', '2025-07-07', '2026-07-07', 425.58, 316480.33, 4807.9, 'active'),
('POL00000823', 359, 'Business', '2024-07-10', '2025-07-10', 171.28, 660609.43, 3252.02, 'expired'),
('POL00000824', 180, 'Travel', '2026-01-09', '2027-01-09', 683.04, 247799.07, 4825.68, 'expired'),
('POL00000825', 379, 'Travel', '2024-06-03', '2025-06-03', 368.71, 447507.58, 3164.11, 'active'),
('POL00000826', 174, 'Home', '2026-02-12', '2027-02-12', 328.21, 198692.43, 2084.05, 'active'),
('POL00000827', 448, 'Health', '2026-02-08', '2027-02-08', 435.99, 114353.28, 3326.61, 'expired'),
('POL00000828', 212, 'Home', '2024-08-16', '2025-08-16', 104.93, 293450.59, 3533.22, 'active'),
('POL00000829', 356, 'Travel', '2025-07-07', '2026-07-07', 230.21, 232014.53, 4581.61, 'expired'),
('POL00000830', 178, 'Life', '2025-11-12', '2026-11-12', 555.38, 442015.1, 2080.57, 'cancelled'),
('POL00000831', 409, 'Health', '2024-11-07', '2025-11-07', 780.7, 359505.23, 1583.23, 'active'),
('POL00000832', 178, 'Business', '2025-12-10', '2026-12-10', 275.9, 685824.9, 909.75, 'active'),
('POL00000833', 133, 'Business', '2024-08-15', '2025-08-15', 636.03, 181124.55, 3607.52, 'expired'),
('POL00000834', 21, 'Life', '2025-10-07', '2026-10-07', 721.87, 506214.69, 3234.89, 'expired'),
('POL00000835', 241, 'Health', '2025-11-24', '2026-11-24', 154.38, 169481.77, 4408.81, 'expired'),
('POL00000836', 300, 'Travel', '2025-08-26', '2026-08-26', 932.72, 407895.0, 4083.7, 'expired'),
('POL00000837', 138, 'Health', '2025-01-07', '2026-01-07', 931.97, 147872.6, 2495.76, 'active'),
('POL00000838', 500, 'Travel', '2024-04-19', '2025-04-19', 84.67, 183704.25, 2351.96, 'cancelled'),
('POL00000839', 54, 'Business', '2025-01-31', '2026-01-31', 289.86, 401073.5, 4331.39, 'expired'),
('POL00000840', 64, 'Business', '2024-12-09', '2025-12-09', 853.87, 948283.48, 2770.17, 'cancelled'),
('POL00000841', 388, 'Life', '2025-01-13', '2026-01-13', 698.27, 917793.74, 3035.98, 'active'),
('POL00000842', 3, 'Business', '2025-03-04', '2026-03-04', 158.37, 39802.82, 4527.62, 'expired'),
('POL00000843', 250, 'Travel', '2024-12-12', '2025-12-12', 623.8, 939648.79, 1804.59, 'expired'),
('POL00000844', 289, 'Home', '2025-04-05', '2026-04-05', 571.93, 277992.98, 4135.29, 'expired'),
('POL00000845', 382, 'Home', '2024-10-12', '2025-10-12', 839.78, 876366.75, 3134.12, 'cancelled'),
('POL00000846', 153, 'Life', '2025-01-18', '2026-01-18', 358.76, 214733.16, 1209.25, 'expired'),
('POL00000847', 28, 'Business', '2025-08-12', '2026-08-12', 112.41, 199760.85, 1968.39, 'cancelled'),
('POL00000848', 17, 'Home', '2024-11-02', '2025-11-02', 347.28, 106020.88, 1461.2, 'active'),
('POL00000849', 233, 'Auto', '2025-02-20', '2026-02-20', 445.18, 705848.43, 838.09, 'cancelled'),
('POL00000850', 259, 'Life', '2026-01-19', '2027-01-19', 803.24, 976379.71, 4652.79, 'expired'),
('POL00000851', 499, 'Home', '2024-06-13', '2025-06-13', 353.88, 839923.21, 2288.02, 'active'),
('POL00000852', 112, 'Home', '2024-12-10', '2025-12-10', 206.71, 308947.48, 3762.7, 'active'),
('POL00000853', 300, 'Life', '2025-09-19', '2026-09-19', 697.92, 999217.64, 538.4, 'cancelled'),
('POL00000854', 304, 'Auto', '2025-06-05', '2026-06-05', 724.07, 15342.8, 3701.94, 'active'),
('POL00000855', 447, 'Auto', '2025-02-05', '2026-02-05', 960.61, 54640.62, 2068.47, 'active'),
('POL00000856', 60, 'Travel', '2026-02-20', '2027-02-20', 707.82, 422094.23, 1890.33, 'cancelled'),
('POL00000857', 386, 'Health', '2025-03-28', '2026-03-28', 543.53, 881288.13, 2938.29, 'cancelled'),
('POL00000858', 121, 'Travel', '2024-07-16', '2025-07-16', 442.03, 430175.54, 2132.93, 'expired'),
('POL00000859', 337, 'Travel', '2024-04-24', '2025-04-24', 945.13, 96804.04, 3697.89, 'cancelled'),
('POL00000860', 492, 'Business', '2025-08-05', '2026-08-05', 763.63, 483249.48, 1057.42, 'expired'),
('POL00000861', 229, 'Travel', '2025-10-08', '2026-10-08', 139.03, 861946.9, 1780.17, 'expired'),
('POL00000862', 164, 'Health', '2025-02-03', '2026-02-03', 897.3, 569311.78, 3500.16, 'expired'),
('POL00000863', 50, 'Health', '2025-07-30', '2026-07-30', 812.35, 866294.03, 3897.02, 'cancelled'),
('POL00000864', 62, 'Health', '2025-05-17', '2026-05-17', 688.92, 90171.12, 2334.3, 'expired'),
('POL00000865', 460, 'Business', '2024-05-30', '2025-05-30', 577.77, 654610.65, 676.88, 'cancelled'),
('POL00000866', 37, 'Auto', '2025-03-22', '2026-03-22', 945.19, 145804.58, 4252.42, 'active'),
('POL00000867', 166, 'Health', '2024-12-15', '2025-12-15', 772.1, 34000.23, 2730.39, 'expired'),
('POL00000868', 247, 'Home', '2024-04-11', '2025-04-11', 297.49, 938203.56, 762.77, 'expired'),
('POL00000869', 119, 'Health', '2024-02-25', '2025-02-24', 618.58, 470905.4, 3315.66, 'cancelled'),
('POL00000870', 288, 'Travel', '2024-07-27', '2025-07-27', 193.06, 500009.29, 4396.59, 'cancelled'),
('POL00000871', 333, 'Auto', '2024-09-20', '2025-09-20', 98.09, 270673.55, 4949.63, 'active'),
('POL00000872', 324, 'Health', '2024-03-21', '2025-03-21', 656.81, 310124.46, 1637.97, 'active'),
('POL00000873', 365, 'Auto', '2025-12-26', '2026-12-26', 524.53, 143852.11, 3379.77, 'cancelled'),
('POL00000874', 46, 'Auto', '2024-04-23', '2025-04-23', 700.84, 94368.09, 3027.58, 'cancelled'),
('POL00000875', 250, 'Travel', '2025-05-24', '2026-05-24', 115.33, 235891.87, 2901.9, 'expired'),
('POL00000876', 396, 'Business', '2025-09-18', '2026-09-18', 654.19, 97504.25, 4056.38, 'expired'),
('POL00000877', 91, 'Travel', '2025-04-28', '2026-04-28', 601.86, 974628.71, 3550.44, 'expired'),
('POL00000878', 146, 'Health', '2025-03-24', '2026-03-24', 654.0, 546875.38, 1102.98, 'cancelled'),
('POL00000879', 69, 'Home', '2024-06-04', '2025-06-04', 71.69, 986292.21, 3962.43, 'cancelled'),
('POL00000880', 256, 'Business', '2025-01-23', '2026-01-23', 277.52, 166644.64, 4957.0, 'expired'),
('POL00000881', 43, 'Travel', '2024-06-16', '2025-06-16', 539.59, 617138.48, 3154.49, 'active'),
('POL00000882', 296, 'Travel', '2025-07-20', '2026-07-20', 902.4, 137817.04, 2962.59, 'active'),
('POL00000883', 410, 'Auto', '2024-09-30', '2025-09-30', 633.22, 215713.71, 2189.09, 'expired'),
('POL00000884', 437, 'Travel', '2024-09-26', '2025-09-26', 342.38, 596640.13, 885.76, 'expired'),
('POL00000885', 394, 'Travel', '2025-02-02', '2026-02-02', 485.68, 336245.16, 4992.65, 'expired'),
('POL00000886', 498, 'Health', '2024-05-18', '2025-05-18', 172.66, 543243.95, 4042.18, 'expired'),
('POL00000887', 223, 'Health', '2025-03-01', '2026-03-01', 77.51, 769145.46, 1590.76, 'cancelled'),
('POL00000888', 300, 'Business', '2025-02-07', '2026-02-07', 379.37, 796270.72, 2807.48, 'active'),
('POL00000889', 131, 'Travel', '2025-09-12', '2026-09-12', 319.91, 473729.91, 742.98, 'cancelled'),
('POL00000890', 53, 'Home', '2024-08-08', '2025-08-08', 151.79, 37558.75, 3792.09, 'expired'),
('POL00000891', 249, 'Home', '2025-11-05', '2026-11-05', 351.98, 978804.68, 2978.65, 'active'),
('POL00000892', 326, 'Travel', '2025-01-28', '2026-01-28', 478.64, 732988.67, 926.2, 'expired'),
('POL00000893', 208, 'Home', '2024-05-13', '2025-05-13', 519.97, 210673.59, 1172.63, 'cancelled'),
('POL00000894', 178, 'Life', '2024-04-08', '2025-04-08', 521.77, 799373.24, 1898.81, 'active'),
('POL00000895', 18, 'Auto', '2026-01-29', '2027-01-29', 76.43, 94929.61, 1198.5, 'active'),
('POL00000896', 492, 'Travel', '2024-08-26', '2025-08-26', 354.77, 330149.88, 936.98, 'cancelled'),
('POL00000897', 164, 'Auto', '2026-02-23', '2027-02-23', 217.2, 662032.33, 4793.35, 'active'),
('POL00000898', 342, 'Health', '2026-02-08', '2027-02-08', 591.33, 126788.54, 407.42, 'active'),
('POL00000899', 284, 'Home', '2025-03-02', '2026-03-02', 388.04, 838445.3, 2617.87, 'active'),
('POL00000900', 145, 'Health', '2025-09-03', '2026-09-03', 524.1, 380405.11, 469.99, 'cancelled'),
('POL00000901', 275, 'Travel', '2025-08-14', '2026-08-14', 546.79, 377373.66, 3247.9, 'cancelled'),
('POL00000902', 169, 'Auto', '2025-10-30', '2026-10-30', 161.49, 686501.12, 4910.6, 'active'),
('POL00000903', 435, 'Health', '2025-11-06', '2026-11-06', 988.27, 234216.09, 3395.42, 'cancelled'),
('POL00000904', 243, 'Auto', '2024-10-05', '2025-10-05', 902.71, 645631.88, 1247.88, 'active'),
('POL00000905', 261, 'Home', '2024-09-08', '2025-09-08', 703.51, 469232.71, 835.55, 'cancelled'),
('POL00000906', 149, 'Auto', '2024-03-23', '2025-03-23', 779.04, 344090.0, 1337.95, 'expired'),
('POL00000907', 40, 'Life', '2026-01-28', '2027-01-28', 929.49, 53862.1, 3820.05, 'expired'),
('POL00000908', 44, 'Health', '2025-08-02', '2026-08-02', 664.21, 744639.09, 3975.32, 'active'),
('POL00000909', 309, 'Home', '2025-02-17', '2026-02-17', 68.16, 497190.6, 1492.2, 'expired'),
('POL00000910', 83, 'Auto', '2024-09-12', '2025-09-12', 730.88, 29523.61, 2995.8, 'cancelled'),
('POL00000911', 430, 'Travel', '2024-10-09', '2025-10-09', 929.42, 829698.44, 2642.84, 'expired'),
('POL00000912', 229, 'Travel', '2025-01-31', '2026-01-31', 556.62, 375341.44, 1936.18, 'cancelled'),
('POL00000913', 26, 'Life', '2025-11-05', '2026-11-05', 442.02, 782226.0, 2205.57, 'active'),
('POL00000914', 374, 'Life', '2024-07-24', '2025-07-24', 931.97, 418401.06, 3297.31, 'expired'),
('POL00000915', 21, 'Life', '2025-04-02', '2026-04-02', 270.06, 316134.87, 665.16, 'cancelled'),
('POL00000916', 160, 'Business', '2024-08-22', '2025-08-22', 622.68, 500239.42, 2549.35, 'active'),
('POL00000917', 324, 'Life', '2025-09-10', '2026-09-10', 929.04, 246891.8, 3438.78, 'cancelled'),
('POL00000918', 374, 'Home', '2026-01-19', '2027-01-19', 926.2, 553182.29, 1644.6, 'expired'),
('POL00000919', 443, 'Auto', '2024-09-17', '2025-09-17', 93.94, 393817.98, 1421.2, 'cancelled'),
('POL00000920', 298, 'Auto', '2025-02-21', '2026-02-21', 959.2, 393789.45, 4761.4, 'active'),
('POL00000921', 251, 'Home', '2024-08-16', '2025-08-16', 683.67, 463325.54, 816.89, 'cancelled'),
('POL00000922', 87, 'Auto', '2024-10-25', '2025-10-25', 608.45, 196069.05, 708.74, 'active'),
('POL00000923', 217, 'Health', '2025-03-25', '2026-03-25', 106.07, 497704.88, 352.67, 'active'),
('POL00000924', 96, 'Business', '2024-12-30', '2025-12-30', 453.5, 949992.35, 4249.19, 'cancelled'),
('POL00000925', 359, 'Health', '2025-08-23', '2026-08-23', 268.45, 921880.73, 1126.22, 'cancelled'),
('POL00000926', 469, 'Home', '2024-04-12', '2025-04-12', 693.77, 621426.51, 346.03, 'active'),
('POL00000927', 124, 'Life', '2024-07-24', '2025-07-24', 933.93, 362011.84, 1230.4, 'active'),
('POL00000928', 126, 'Travel', '2025-02-16', '2026-02-16', 580.38, 981993.58, 4399.89, 'cancelled'),
('POL00000929', 6, 'Health', '2025-01-09', '2026-01-09', 814.62, 480828.55, 4430.94, 'expired'),
('POL00000930', 254, 'Life', '2025-04-27', '2026-04-27', 983.69, 906989.46, 4780.29, 'cancelled'),
('POL00000931', 143, 'Health', '2024-03-09', '2025-03-09', 338.21, 246823.88, 2995.39, 'active'),
('POL00000932', 482, 'Home', '2026-01-24', '2027-01-24', 314.77, 193629.01, 3073.37, 'cancelled'),
('POL00000933', 458, 'Life', '2025-12-18', '2026-12-18', 744.16, 365388.93, 521.12, 'active'),
('POL00000934', 500, 'Life', '2024-09-20', '2025-09-20', 884.05, 319226.56, 1903.61, 'cancelled'),
('POL00000935', 426, 'Life', '2025-05-30', '2026-05-30', 278.1, 195668.5, 1611.42, 'expired'),
('POL00000936', 296, 'Home', '2025-07-23', '2026-07-23', 213.7, 868536.45, 1728.79, 'expired'),
('POL00000937', 63, 'Health', '2025-02-23', '2026-02-23', 159.9, 613008.96, 1260.08, 'expired'),
('POL00000938', 87, 'Health', '2024-08-04', '2025-08-04', 737.77, 109658.56, 3067.86, 'cancelled'),
('POL00000939', 144, 'Auto', '2024-08-23', '2025-08-23', 185.12, 528434.38, 617.62, 'expired'),
('POL00000940', 142, 'Travel', '2025-06-11', '2026-06-11', 593.68, 204628.74, 4662.95, 'cancelled'),
('POL00000941', 164, 'Home', '2025-03-15', '2026-03-15', 618.96, 898961.39, 2479.73, 'expired'),
('POL00000942', 149, 'Auto', '2024-08-31', '2025-08-31', 571.13, 40206.61, 4176.72, 'active'),
('POL00000943', 232, 'Health', '2024-05-29', '2025-05-29', 299.89, 686320.29, 1790.05, 'expired'),
('POL00000944', 457, 'Home', '2025-04-07', '2026-04-07', 423.59, 217554.64, 2470.98, 'cancelled'),
('POL00000945', 195, 'Travel', '2024-09-26', '2025-09-26', 587.15, 716295.77, 3975.01, 'expired'),
('POL00000946', 163, 'Auto', '2025-01-26', '2026-01-26', 462.5, 81668.8, 4668.09, 'cancelled'),
('POL00000947', 91, 'Life', '2025-05-14', '2026-05-14', 177.86, 922466.26, 3051.66, 'expired'),
('POL00000948', 214, 'Travel', '2025-02-08', '2026-02-08', 214.86, 362555.26, 4569.33, 'cancelled'),
('POL00000949', 401, 'Life', '2024-10-28', '2025-10-28', 290.78, 865778.95, 1268.14, 'expired'),
('POL00000950', 282, 'Life', '2025-12-28', '2026-12-28', 643.23, 87377.09, 702.95, 'active'),
('POL00000951', 84, 'Auto', '2024-10-24', '2025-10-24', 883.14, 218299.57, 2310.72, 'expired'),
('POL00000952', 487, 'Life', '2024-12-07', '2025-12-07', 780.81, 626412.61, 4955.12, 'expired'),
('POL00000953', 226, 'Travel', '2025-09-12', '2026-09-12', 137.57, 183821.29, 3847.03, 'active'),
('POL00000954', 421, 'Auto', '2025-08-22', '2026-08-22', 732.48, 795841.61, 2409.52, 'cancelled'),
('POL00000955', 459, 'Home', '2024-06-16', '2025-06-16', 694.07, 911001.2, 1835.96, 'active'),
('POL00000956', 284, 'Business', '2024-04-13', '2025-04-13', 677.53, 281962.82, 2229.58, 'cancelled'),
('POL00000957', 422, 'Life', '2024-04-23', '2025-04-23', 940.78, 419253.3, 4529.13, 'expired'),
('POL00000958', 200, 'Business', '2025-03-04', '2026-03-04', 222.71, 777220.88, 2563.64, 'cancelled'),
('POL00000959', 337, 'Life', '2024-04-19', '2025-04-19', 385.28, 49021.24, 1173.49, 'active'),
('POL00000960', 465, 'Auto', '2025-09-26', '2026-09-26', 665.57, 901696.56, 604.46, 'cancelled'),
('POL00000961', 432, 'Health', '2025-08-29', '2026-08-29', 241.13, 181466.28, 3847.22, 'active'),
('POL00000962', 127, 'Home', '2025-07-20', '2026-07-20', 777.6, 638340.62, 277.82, 'cancelled'),
('POL00000963', 412, 'Life', '2025-01-16', '2026-01-16', 379.44, 193636.57, 1123.61, 'active'),
('POL00000964', 17, 'Travel', '2025-07-07', '2026-07-07', 486.18, 168416.89, 3736.21, 'active'),
('POL00000965', 324, 'Travel', '2024-04-23', '2025-04-23', 180.51, 888641.5, 467.4, 'expired'),
('POL00000966', 359, 'Home', '2024-03-21', '2025-03-21', 469.71, 336950.72, 812.38, 'cancelled'),
('POL00000967', 135, 'Home', '2025-10-21', '2026-10-21', 476.81, 134142.15, 4223.89, 'active'),
('POL00000968', 454, 'Travel', '2024-07-12', '2025-07-12', 563.13, 540665.09, 1758.69, 'cancelled'),
('POL00000969', 146, 'Travel', '2025-08-18', '2026-08-18', 508.15, 725907.01, 4425.44, 'cancelled'),
('POL00000970', 224, 'Business', '2024-05-10', '2025-05-10', 910.48, 285235.75, 4949.53, 'expired'),
('POL00000971', 48, 'Life', '2026-02-20', '2027-02-20', 459.91, 813005.64, 4985.18, 'expired'),
('POL00000972', 301, 'Life', '2025-08-29', '2026-08-29', 130.12, 595336.64, 1610.61, 'active'),
('POL00000973', 261, 'Home', '2025-05-24', '2026-05-24', 642.31, 172736.36, 420.34, 'active'),
('POL00000974', 352, 'Life', '2025-09-12', '2026-09-12', 841.01, 758908.77, 270.19, 'active'),
('POL00000975', 495, 'Home', '2025-03-22', '2026-03-22', 747.79, 967395.61, 828.52, 'expired'),
('POL00000976', 381, 'Business', '2025-07-10', '2026-07-10', 66.09, 162191.89, 4746.8, 'active'),
('POL00000977', 417, 'Life', '2026-02-23', '2027-02-23', 941.62, 608432.11, 978.75, 'active'),
('POL00000978', 2, 'Travel', '2024-07-12', '2025-07-12', 116.16, 664639.47, 4815.85, 'active'),
('POL00000979', 226, 'Home', '2026-01-07', '2027-01-07', 303.19, 679666.68, 3257.57, 'active'),
('POL00000980', 279, 'Business', '2024-12-20', '2025-12-20', 490.44, 382627.13, 4000.84, 'cancelled'),
('POL00000981', 23, 'Life', '2025-01-11', '2026-01-11', 74.89, 812017.45, 916.8, 'cancelled'),
('POL00000982', 335, 'Business', '2024-04-24', '2025-04-24', 684.93, 677809.81, 4891.92, 'active'),
('POL00000983', 115, 'Business', '2025-09-08', '2026-09-08', 941.09, 800873.89, 818.3, 'cancelled'),
('POL00000984', 181, 'Health', '2024-07-17', '2025-07-17', 179.02, 286310.93, 2610.1, 'expired'),
('POL00000985', 415, 'Health', '2025-02-15', '2026-02-15', 861.65, 95171.88, 4084.04, 'expired'),
('POL00000986', 418, 'Home', '2024-07-13', '2025-07-13', 217.02, 608906.74, 2390.23, 'cancelled'),
('POL00000987', 407, 'Life', '2025-08-21', '2026-08-21', 802.7, 870298.76, 1266.22, 'expired'),
('POL00000988', 200, 'Life', '2024-02-25', '2025-02-24', 654.5, 208730.65, 3158.81, 'expired'),
('POL00000989', 366, 'Life', '2024-04-17', '2025-04-17', 244.01, 402655.38, 3698.45, 'expired'),
('POL00000990', 343, 'Home', '2025-07-20', '2026-07-20', 379.38, 732375.65, 493.84, 'active'),
('POL00000991', 290, 'Travel', '2025-05-04', '2026-05-04', 755.3, 422549.33, 2595.76, 'active'),
('POL00000992', 127, 'Business', '2025-09-19', '2026-09-19', 531.46, 171406.85, 2419.56, 'cancelled'),
('POL00000993', 129, 'Life', '2024-08-14', '2025-08-14', 618.07, 858942.29, 4766.8, 'expired'),
('POL00000994', 337, 'Business', '2024-11-05', '2025-11-05', 399.23, 278296.92, 3972.13, 'expired'),
('POL00000995', 109, 'Life', '2024-04-23', '2025-04-23', 332.68, 836001.91, 3539.3, 'active'),
('POL00000996', 227, 'Life', '2025-01-30', '2026-01-30', 251.31, 18023.16, 2244.79, 'active'),
('POL00000997', 43, 'Business', '2026-02-07', '2027-02-07', 52.62, 699574.67, 2396.82, 'expired'),
('POL00000998', 118, 'Auto', '2024-05-04', '2025-05-04', 921.9, 650906.36, 4423.64, 'cancelled'),
('POL00000999', 213, 'Health', '2025-01-04', '2026-01-04', 878.84, 758940.64, 2250.24, 'cancelled'),
('POL00001000', 226, 'Business', '2025-01-10', '2026-01-10', 761.29, 454259.26, 3393.69, 'active');